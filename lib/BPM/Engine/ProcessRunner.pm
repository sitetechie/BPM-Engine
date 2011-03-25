package BPM::Engine::ProcessRunner;
BEGIN {
    $BPM::Engine::ProcessRunner::VERSION   = '0.001';
    $BPM::Engine::ProcessRunner::AUTHORITY = 'cpan:SITETECH';
    }

use Moose;
use MooseX::StrictConstructor;
use DateTime;
use BPM::Engine::Types qw/Bool ArrayRef CodeRef Exception Row/;
use BPM::Engine::Exceptions qw/throw_model throw_abstract throw_runner/;
use namespace::autoclean; # -also => [qr/^_/];

with qw/
    MooseX::Traits
    BPM::Engine::Role::WithLogger
    BPM::Engine::Role::WithCallback
    /;

BEGIN {
  for my $event (qw/start continue complete execute/){
    for my $entity (qw/process activity transition task/){
        __PACKAGE__->meta->add_method( "cb_$event\_$entity" => sub {
            my $self = shift;
            return 1 unless $self->has_callback;
            return $self->call_callback($self, $entity, $event, @_);
            });
        }
    }
  }

has '+_trait_namespace' => (
    default => 'BPM::Engine::Plugin'
    );

has 'engine'   => (
    is         => 'ro',
    isa        => 'BPM::Engine',
    weak_ref   => 1,
    );

has 'process'  => (
    is         => 'ro',
    isa        => Row['Process'],
    lazy_build => 1,
    );

has 'process_instance' => (
    is         => 'ro',
    isa        => Row['ProcessInstance'],
    required   => 1,
    );

has 'graph'    => (
    is         => 'rw',
    lazy_build => 1,
    );

with qw/
    BPM::Engine::Role::HandlesIO
    BPM::Engine::Role::HandlesTaskdata
    BPM::Engine::Role::HandlesAssignments
    /;
with 'BPM::Engine::Role::RunnerAPI';

sub _build_process {
    shift->process_instance->process;
    }

sub _build_graph {
    shift->process->graph;
    }

has '_is_running' => (
    is  => 'rw',
    isa => Bool
    );

has '_activity_stack' => ( # not a stack, but a queue
    isa => ArrayRef,
    is => 'rw',
    default => sub { [] },
    traits     => ['Array'],
    handles => {
        '_queue_count' => 'count',
        '_queue_next'  => 'shift',
        '_queue_push'  => 'push',
        '_queue_clear' => 'clear',
        }
    );

has '_deferred_stack' => ( # not a stack, but a queue
    isa => ArrayRef,
    is => 'rw',
    default => sub { [] },
    traits     => ['Array'],
    handles => {
        '_defer_count' => 'count',
        '_defer_next'  => 'shift',
        '_defer_push'  => 'push',
        '_defer_clear' => 'clear',
        }
    );

sub start_process {
    my $self = shift;

    $self->cb_start_process($self->process, $self->process_instance);

    eval {
        $self->process_instance->apply_transition('start');
        };
    if($@) {
        throw_runner error => "Could not start process: $@";
        }

    my @start = @{ $self->process->start_activities } or do {
        $self->complete_process;
        return;
        };
    
    foreach my $activity(@start) {
        $activity->is_start_activity or throw_model error => 'Not a start event';
        if($activity->is_auto_start) {
            my $ai = $activity->new_instance({
                process_instance_id => $self->process_instance->id
                });
            $self->start_activity($activity, $ai, 0);
            }
        }

    $self->_run;
    
    return;
    }

sub start_activity {
    my ($self, $activity, $instance, $run) = @_;

    $self->cb_start_activity($activity, $instance);

    $instance->apply_transition('assign');

    $self->_queue_push([$activity, $instance]);
    $self->_run if $run;
    }

sub continue_activity {
    my ($self, $activity, $instance, $run) = @_;

    $self->cb_continue_activity($activity, $instance);

    $self->_queue_push([$activity, $instance]);
    $self->_run if $run;
    }

sub _run {
    my $self = shift;

    throw_runner error => "runner: ALREADY RUNNING" if $self->_is_running;

    $self->_is_running(1);

    $self->debug("=========== START_run =================");

    my $did_something = 0;
    while (my $act_ctx = $self->_queue_next) {
        $did_something++;
        eval {
            $self->_execute_activity_instance($act_ctx->[0], $act_ctx->[1]);
            };
        if(my $err = $@) { 
            throw_runner error => "Could not execute activity: $err";
            }

        my %acted = ();
        $acted{$act_ctx->[0]->id}++;
        $self->debug("runner: _run DrainInner " . $act_ctx->[0]->activity_uid);
        # drain deferred queue
        my %seen = ();
        while (my $def_ctx = $self->_defer_next) {
            my ($activity, $instance) = ($def_ctx->[0], $def_ctx->[1]);
            last if $seen{$instance->id}++; # full circle on current deferreds
            next if $acted{$activity->id}++;
            $instance->discard_changes;
            next unless $instance->is_deferred;
            $instance->update({ deferred => undef });
            $self->debug("runner: _run draininner " . $activity->activity_uid);
            $self->_enqueue_ai($activity, $instance, 1);
            }
        }

    $self->debug("=========== /STOP _run =================");

    die("Inconclusive process state") if $self->_queue_count();

    if($did_something) {
        die("Inconclusive processdb state") if $self->_defer_count();
        $self->_defer_clear();
        $self->_is_running(0);
        }
    elsif($self->_defer_count) {
        $self->debug("runner: DrainAfter");
        my %seen = ();
        while (my $def_ctx = $self->_defer_next) {
            my ($activity, $instance) = ($def_ctx->[0], $def_ctx->[1]);
            last if $seen{$instance->id}++; # full circle on current deferreds
            #next if $acted{$activity->id}++;
            $instance->discard_changes;
            next unless $instance->is_deferred;
            $instance->update({ deferred => undef });
            $self->debug("runner: _run drainafter " . $activity->activity_uid);
            $self->_enqueue_ai($activity, $instance, 1);
            }

        $self->_is_running(0);

        if($self->_queue_count) {
            $self->warning("runner: SecondRun by DrainAfter");
            $self->_run;
            }
        }
    else {
        $self->_is_running(0);
        }
    
    return;
    }

## no critic (ProhibitCascadingIfElse)

sub _execute_activity_instance {
    my ($self, $activity, $instance) = @_;

    return unless $self->cb_execute_activity($activity, $instance);

    my $completed = 0;
    # Route
    if($activity->is_route_type) {
        #$self->debug("runner: route type " . $activity->activity_uid);
        $completed = 1;
        }
    # Implementations are No, Task, SubFlow or Reference
    elsif($activity->is_implementation_type) {
        $self->debug("runner: executing implementation activity '" .
            $activity->activity_uid . "'");
        $completed = $self->_execute_implementation($activity, $instance);
        }
    # BlockActivity executes an ActivitySet
    elsif($activity->is_block_type) {
        $self->error("runner: BlockActivity not implemented yet ...");
        throw_abstract error => 'BlockActivity not implemented yet';
        }
    # Events just complete, for now
    elsif($activity->is_event_type) {
        #$self->notice("runner: Events not implemented yet ...");
        #throw_abstract error => 'Events not implemented yet';
        $completed++;
        }
    else {
        throw_model
            error => "Unsupported activity type " . $activity->activity_type;
        }

    if ($completed && $activity->is_auto_finish) {
        $self->complete_activity($activity, $instance, 0);
        }
    }

sub _execute_implementation {
    my ($self, $activity, $instance) = @_;

    my $completed = 0;

    if($activity->is_impl_subflow) {
        $self->error("runner: subflows not implemented yet ...");
        throw_abstract error => 'Subflows not implemented yet';
        }
    elsif($activity->is_impl_reference) {
        $self->error("runner: reference not implemented yet ...");
        throw_abstract error => 'Reference not implemented yet';
        }
    elsif($activity->is_impl_task) {
        my ($i,$j) = (0,0);
        foreach my $task($activity->tasks->all) {
            # inject into sync/async event engine
            $i++ if($self->execute_task($task, $instance));
            #$i++ if $task->run($activity, $instance);
            $j++;
            }
        $completed = $i == $j ? 1 : 0;
        }
    elsif($activity->is_impl_no) {
        # 'No' implementation completes immediately
        $completed = 1;
        }
    else {
        throw_model error => "Invalid activity implementation definition";
        }

    return $completed;
    }

## use critic (ProhibitCascadingIfElse)

sub execute_task {
    my ($self, $task, $instance) = @_;

    if($self->cb_execute_task($task, $instance)) {
        return 1;
        }

    return 0;
    }

sub complete_activity {
    my ($self, $activity, $instance, $run) = @_;

    $self->cb_complete_activity($activity, $instance);

    $instance->apply_transition('finish');
    $instance->update({ completed => DateTime->now() });

    if($activity->is_end_activity()) {
        unless($self->process_instance->activity_instances_rs->active->count) {
            $self->complete_process();
            return;
            }
        }
    else {
        $self->_execute_transitions($activity, $instance);
        }

    if($run) {
        $self->_run;
        }
    }

sub complete_process {
    my $self = shift;

    my $pi = $self->process_instance;
    return unless $self->cb_complete_process($self->process, $pi);

    $pi->apply_transition('finish');
    $pi->update({ completed => DateTime->now() });

    $self->_queue_clear();
    $self->_defer_clear();

    if($pi->parent_ai_id) {
        my $pai = $pi->parent_activity_instance;
        $self->_complete_parent_activity($pai->activity, $pai);
        }
    }

sub _complete_parent_activity {
    my ($self, $activity, $instance) = @_;

    $self->error('runner: subflows not implemented');
    throw_abstract error => 'Subflows not implemented';
    }

sub _execute_transitions {
    my ($self, $activity, $instance) = @_;

    my $pref = { prefetch => ['from_activity', 'to_activity'] };
    my @transitions = $activity->is_split ?
        $activity->transitions_by_ref({},$pref)->all :
        $activity->transitions({},$pref)->all;
    unless(@transitions) {
        throw_model error =>
            "Model error: no outgoing transitions for activity '" .
            ($activity->activity_name || $activity->activity_uid ||
             $activity->id) . "'";
        }

    my (@instances)                    = ();
    my (@blocked)                      = ();
    my ($stop_following, $fired_count) = (0, 0);
    my ($otherwise, $exception)        = ();

    # evaluate efferent transitions
    foreach my $transition(@transitions) {
        my $count = scalar @transitions;
        if($transition->condition_type eq 'NONE' ||
           $transition->condition_type eq 'CONDITION') {
            my $t_instance;
            unless($stop_following) {
                $t_instance = $self->_execute_transition($transition, $instance, 0);
                }
            if($t_instance) {
                push(@instances, [$transition, $t_instance]);
                $fired_count++;
                # only one transition in an XOR split can fire.
                $stop_following++ if $activity->is_xor_split;
                }
            elsif($activity->is_split) {
                my $split = $instance->split
                    or die("No join found for split " . $activity->activity_uid);
                $split->set_transition($transition->id, 'blocked');
                push(@blocked, [$transition, $instance]);
                }
            }
        elsif($transition->condition_type eq 'OTHERWISE') {
            $otherwise = $transition;
            }
        elsif($transition->condition_type eq 'DEFAULTEXCEPTION'
            || $transition->condition_type eq 'EXCEPTION') {
            $exception = $transition;
            }

        }

    if($fired_count == 0) {
        unless($otherwise) {
            throw_model(error =>
                "Deadlock: OTHERWISE transition missing on activity '" .
                $activity->activity_uid . "'"
                );
            }
        my $t_instance = $self->_execute_transition($otherwise, $instance, 0);
        if($t_instance) {
            push(@instances, [$otherwise, $t_instance]);
            }
        else {
            throw_runner error => "Execution of transition with 'Otherwise' condition failed";
            }
        }
    elsif($otherwise && $activity->is_split) {
        my $split = $instance->split
            or die("No join found for split " . $activity->activity_uid);
        $split->set_transition($otherwise->id, 'blocked');
        }

    # activate successor activities
    my $followed_back = 0;
    foreach my $inst(@instances) {
        $followed_back++ if $inst->[0]->is_back_edge;
        my $r_instance = $inst->[1];
        my $r_activity = $r_instance->activity;
        $self->_enqueue_ai($r_activity, $r_instance);
        }

    # blocked paths may trigger downstream deferred activities which must now be
    # resolved; signal deferred activity instances on other branches in the
    # wf-net when paths were blocked and any transition downstream was followed
    if(scalar(@blocked) && $followed_back != scalar @instances) {
        $self->_signal_upstream_orjoins_if_in_split_branch(@blocked);
        }

    return;
    }

sub _execute_transition {
    my ($self, $transition, $from_instance, $run) = @_;

    #XXX mitigate expensive debugging
    my $tid = $transition->transition_uid || $transition->id || 'noid';
    $self->debug("runner: executing transition $tid from " .
        $transition->from_activity->activity_uid . ' to ' .
        $transition->to_activity->activity_uid
        );

    return unless $self->cb_execute_transition($transition, $from_instance);

    my $to_instance = eval {
        $transition->apply($from_instance);
        };

    my $err = $@;
    if($err) {
        $self->debug("runner: transition '" .
            $transition->transition_uid .
            "' did not result in a new activity_instance : $err"
            );
        if(is_Exception($err)) {
            # condition false
            return if $err->isa('BPM::Engine::Exception::Condition');
            #warn $err->trace->as_string;
            $err->rethrow;
            }
        else {
            $err =~ s/\n//;
            $self->error("Error applying transition: $err");
            throw_model error => $err;
            }
        }
    elsif(!$to_instance) {
        $self->error("Applying transition did not result in an instance");
        throw_runner error => "Applying transition did not return an instance";
        }
    
    $self->_run if $run;
    
    return $to_instance;    
    }

sub _enqueue_ai {
    my ($self, $activity, $instance, $deferred) = @_;

    $self->debug("runner: _enqueue activity " . $activity->activity_uid);
    my $should_fire = $activity->is_join ? $instance->is_enabled() : 1;
    if($should_fire) {
        if($instance->is_deferred) {
            #$instance->update({ deferred => \'NULL' });
            $instance->update({ deferred => undef })->discard_changes;
            }
        $instance->fire_join if $activity->is_join;

        if($activity->is_auto_start) {
            $self->debug("runner: _enqueue Pushing instance " .
                $activity->activity_uid . " to active queue");
            $self->start_activity($activity, $instance, 0);
            }
        }
    else {
        $instance->update({ deferred => DateTime->now });

        $self->debug("runner: _enqueue Pushing instance " .
            $activity->activity_uid . " to deferred queue");

        $self->_defer_push([$activity, $instance]) unless $deferred;
        }
    }

sub _signal_upstream_orjoins_if_in_split_branch {
    my ($self, @blocked) = @_;

    my @deferred = $self->process_instance->activity_instances->deferred->all;

    foreach my $instance(@deferred) {

        $self->debug("runner: _run Pushing db instance " .
            $instance->activity->activity_uid . " to deferred queue");

        my $graph = $self->graph;

        foreach my $block(@blocked) {
            my $tr   = $block->[0];
            my $ai   = $block->[1];
            my $a_to = $tr->to_activity;
            if($graph->is_reachable($a_to->id, $instance->activity->id)) {
                $self->_defer_push([$instance->activity, $instance]);
                }
            }

        }
    }

__PACKAGE__->meta->make_immutable;

1;
__END__

=pod

=encoding utf-8

=head1 NAME

BPM::Engine::ProcessRunner - Runs Processes

=head1 VERSION

0.001

=head1 SYNOPSIS

  use BPM::Engine::ProcessRunner;

  my $callback = sub {
        my($runner, $entity, $event, $node, $instance) = @_;
        ...
        };

  my $runner = BPM::Engine::ProcessRunner->new();
  $runner->start_process();

=head1 DESCRIPTION

Implements the workflow enactment logic.

=head1 CONSTRUCTOR

=head1 METHODS

=head2 start_process

    $runner->start_process;

Call the 'start_process' callback, set the process instance to the 'started' state,
and call start_activity() with an activity instance created for each of the
auto_start start activities.

=head2 start_activity

    $runner->start_activity($activity, $instance, $run);

C<start_activity()> takes an activity, an activity instance and an optional 'run' flag.
It calls the 'start_activity' callback, sets the activity instance state to 'assigned',
enqueues the activity instance to be executed, and optionally runs all queued activity instances

=head2 continue_activity

    $runner->continue_activity($activity, $instance, $run);

Call the 'continue_activity' callback, enqueue the activity instance to be executed,
and optionally run all queued activity instances.

=head2 execute_task

    $runner->execute_task($task, $instance);

Call the 'execute_task' callback, and returns 1 or 0 depending on the existance
of a callback return value. This method is called on activity implementation
when the activity instance is executed, and is meant to be used in Traits, not
to be called directly.

=head2 complete_activity

    $runner->complete_activity($activity, $instance, $run);

Call the 'complete_activity' callback, sets the activity instance state to 'closed.completed',
and sets the completion datetime.  and either calls complete_process()
Outgoing transitions, if any, are followed. If it's an end activity and there are no
active activity instances left, complete_process() is called, otherwise
it optionally runs all enqueued activity instances.

=head2 complete_process

    $runner->complete_process;

Return unless the 'complete_process' returns true. Set the process instance state to 'closed.completed',
set the completion datetime, and clear the activity instance execution queues.

=head1 LOGGING METHODS

    $runner->debug('Something happened');

log, debug, info, notice, warning, error, critical, alert, emergency

=head1 PRIVATE METHODS

=head2 _run

=head2 _execute_transitions

=head1 AUTHOR

Peter de Vos, C<< <sitetech@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2010, 2011 Peter de Vos C<< <sitetech@cpan.org> >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
