package BPM::Engine::Role::HandlesTaskdata;
BEGIN {
    $BPM::Engine::Role::HandlesTaskdata::VERSION   = '0.001';
    $BPM::Engine::Role::HandlesTaskdata::AUTHORITY = 'cpan:SITETECH';
    }

use namespace::autoclean;
use Moose::Role;
use Data::GUID;

requires qw/
    process_instance
    process
    /;

before 'execute_task' => sub {
    my ($self, $task, $activity_instance) = @_;

    my $pi       = $self->process_instance or die("Process instance not found");
    my $process  = $self->process or die("Process not found");
    my $activity = $activity_instance->activity or die("Activity not found");
    my $tdata    = $task->task_data;

    my $mtype    = $task->task_type eq 'Send' ? 'Message' : 'MessageIn';
    my $aparams  = $tdata->{$mtype}->{ActualParameters}->{ActualParameter};
    my $params   = _service_params($pi, $aparams);

    my $args = {
        meta => {
            # XXX Do GUID somewhere else (exec_impl) or not at all (same as activity_instance->id)?
            id                  => Data::GUID->new()->as_string,
            name                => $task->task_name || $activity->activity_name
                                || $activity->activity_uid,
            type                => $task->task_type,
            process_id          => $pi->process_id,
            process_instance_id => $pi->id,
            activity_id         => $activity->id,
            token_id            => $activity_instance->id,
            task_id             => $task->id,
            },
        parameters => $task->actual_params,
        service    => _service_vars($tdata->{'WebServiceOperation'}),
        message    => _message($tdata->{$mtype}, $process, $params),
        performers => _performers($activity->participants_rs),
        users      => _performers($process->participants_rs({
                participant_uid => $tdata->{Performers}->{Performer}
                })
            ),
        };

    $activity_instance->update({ taskdata => $args });

    return;
    };

sub _performers {
    my ($p_rs) = @_;

    my @p = ();
    while (my $rec = $p_rs->next) {
        push(@p, {
            id   => $rec->id,
            type => $rec->participant_type,
            uid  => $rec->participant_uid,
            description   => $rec->description,
            ext_reference => $rec->attributes->{ExternalReference},
            });
        }

    return \@p;
    }

sub _message {
    my ($msg, $process, $params) = @_;

    my $res = { args => $params  };

    foreach my $prop(qw/Id Name FaultName/) {
        $res->{lc($prop)} = $msg->{$prop} if $msg->{$prop};
        }

    foreach my $prop('To','From') {
        if($msg->{$prop}) {
            my $rs = $process->participants_rs({
                participant_uid => $msg->{$prop}
                });
            $res->{lc($prop)} = _performers($rs);
            }
        }

    return $res;
    }

sub _service_vars {
    my $svc  = shift;

    my $end  = $svc->{Service}->{EndPoint}->{ExternalReference};

    return {
        name      => $svc->{Service}->{ServiceName},
        operation => $svc->{OperationName},
        port      => $svc->{Service}->{PortName},
        type      => $svc->{Service}->{EndPoint}->{EndPointType},
        ext_reference => {
            xref      => $end->{xref},
            location  => $end->{location},
            namespace => $end->{namespace},
            }
        };
    }

sub _service_params {
    my ($pi, $params) = @_;

    my @results = ();
    foreach my $attr(@$params) {
        push(@results, $pi->attribute($attr->{content})->value);
        }

    return \@results;
    }

no Moose::Role;

1;
__END__

=pod

=encoding utf-8

=head1 NAME

BPM::Engine::Role::HandlesTaskdata - ProcessRunner role for storing task data

=head1 DESCRIPTION

This L<ProcessRunner> role fills the C<taskdata> attribute of an
ActivityInstance before C<execute_task()> is called.

This taskdata hash has the following keys:

=over 4

=item meta

This is a hash with the following keys:

=over 4

=item * id

Generated UUID for this task instance

=item * name

The task or activity name, or the activity uid

=item * type

The task type

=item * process_id

=item * process_instance_id

=item * activity_id

The id of the activity

=item * token_id

activity_instance->id

=item * task_id

The id of the task definition

=back

=item message

A hash representing the Message or MessageIn to send to the service.
Keys: to, from, faultname, name, args, id

=item service

Representation of the WebServiceOperation from task_data in Result::ActivityTask

=over 4

=item * name

=item * type

=item * operation

=item * port

=item * ext_reference

A hash with keys C<xref>, C<namespace> and C<location>

=back

=item performers

List of participants representing the activity performers

=item users

Task performers (as children of TaskUser or TaskManual)

=item parameters

ActualParameters for a TaskApplication-type task

=back

=head1 AUTHOR

Peter de Vos, C<< <sitetech@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2010, 2011 Peter de Vos C<< <sitetech@cpan.org> >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
