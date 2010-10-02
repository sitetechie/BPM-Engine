
package BPM::Engine::Handler::ActivityInstanceHandler;
BEGIN {
    $BPM::Engine::Handler::ActivityInstanceHandler::VERSION   = '0.001';
    $BPM::Engine::Handler::ActivityInstanceHandler::AUTHORITY = 'cpan:SITETECH';
    }

use Moose::Role;
use namespace::autoclean;

sub list_activity_instances {
    my ($self, @args) = @_;
    return $self->storage->resultset('ActivityInstance')->search_rs(@args);
    }

sub get_activity_instance {
    my ($self, $id) = @_;
    return $self->storage->resultset('ActivityInstance')->find($id);
    }

sub change_activity_instance_state {
    my ($self, $id, $state) = @_;
    my $instance = $self->get_activity_instance($id);

    eval {
        my $process_instance = $instance->process_instance;
        my $activity = $instance->activity;

        if ($state eq 'assign' #&& $ai->created() == null ||
                || $state eq 'finish') {    
            my $runner = $self->_runner($process_instance);            
            if($state eq 'assign') { # open.running
                # Execute the activity if it is now open.running.
                $runner->start_activity($activity, $instance, 1);
                }
            elsif($state eq 'finish') { # closed.completed
                # Fire the activity's efferent transitions if it is
                # now closed.complete.
                $runner->complete_activity($activity, $instance, 1);
                }
            } 
        else {
            $instance->apply_transition($state);
            }
    
    };    
    if($@) {
        die $@;
        }
    return;
    }

sub activity_instance_attribute {
    my $self = shift;
    my $id = shift;
    
    my $instance = $self->get_activity_instance($id);
    return $instance->attribute(@_);
    }

no Moose::Role;

1;
__END__
