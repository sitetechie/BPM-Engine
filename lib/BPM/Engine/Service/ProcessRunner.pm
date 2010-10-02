
package BPM::Engine::Service::ProcessRunner;
BEGIN {
    $BPM::Engine::Service::ProcessRunner::VERSION   = '0.001';
    $BPM::Engine::Service::ProcessRunner::AUTHORITY = 'cpan:SITETECH';
    }

use Moose;
use MooseX::StrictConstructor;
use DateTime;
use BPM::Engine::Types qw/Bool ArrayRef CodeRef/;
use BPM::Engine::Exceptions qw/throw_model throw_abstract throw_runner/;
use namespace::autoclean; # -also => [qr/^_/];

with qw/
    BPM::Engine::Role::WithLogger
    BPM::Engine::Role::WithCallback
    BPM::Engine::Service::ProcessRunnerRole::WithAssignments
    /;

BEGIN {
  for my $event (qw/start continue complete execute/){
    for my $entity (qw/process activity transition task/){
        __PACKAGE__->meta->add_method( "cb_$event\_$entity" => sub {
            my $self = shift;
            return 1 unless $self->has_callback;
            return $self->call_callback($entity, $event, @_);
            });
        }
    }
  }

has 'process' => (
    is => 'ro',
    isa => 'BPM::Engine::Store::Result::Process',
    );

has 'process_instance' => (
    is => 'ro',
    isa => 'BPM::Engine::Store::Result::ProcessInstance',
    );

with 'BPM::Engine::Service::ProcessRunnerRole::API';

has '_is_running' => ( 
    is => 'rw', 
    isa => Bool 
    );

has '_activity_stack' => (
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

has '_deferred_stack' => (
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
    
    $self->process_instance->apply_transition('start');
    
    foreach my $activity(@{ $self->process->start_activities }) {
        $activity->is_start_activity() or throw_model( error => 'Not a start event');
        if($activity->is_auto_start) {
            my $ai = $activity->new_instance({ 
                process_instance_id => $self->process_instance->id 
                });
            $self->start_activity($activity, $ai, 0);
            }
        }
    
    $self->_run();
    
    return;
    }

sub complete_process {
    my $self = shift;

    $self->cb_complete_process($self->process, $self->process_instance);    
    
    my $pi = $self->process_instance;
    $pi->apply_transition('finish');
    
    $self->_queue_clear();
    $self->_defer_clear();

    if($pi->parent_ai_id) {
        $self->_complete_parent_activity($pi->parent_activity_instance);
        }
    
    #$pi->update();
    }

sub start_activity {
    my ($self, $activity, $instance, $run) = @_;

    $self->cb_start_activity($activity, $instance);    
    
    $instance->apply_transition('assign');

    $self->_queue_push([$activity, $instance]);
    $self->_run() if $run;
    }

sub continue_activity {
    my ($self, $activity, $instance, $run) = @_;

    $self->cb_continue_activity($activity, $instance);

    $self->_queue_push([$activity, $instance]);
    $self->_run() if $run;
    }

sub complete_activity {
    my ($self, $activity, $instance, $run) = @_;

    $self->cb_complete_activity($activity, $instance);
        
    $instance->completed(DateTime->now());
    $instance->apply_transition('finish');

    if ($activity->is_end_activity()) {
        $self->complete_process();
        }
    else {
        $self->_execute_transitions($activity, $instance);
        }

    $self->_run() if $run;
    }

sub _run {
    my $self = shift;

    throw_runner("runner: ALREADY RUNNING") if $self->_is_running;
    return if $self->_is_running;
    $self->_is_running(1);

    # push all deferred activity instances for this process
    my @deferred = $self->process_instance->activity_instances #deferred->all;
        ->search({ deferred => \'IS NOT NULL' }, { order_by => \'deferred ASC' });
    foreach my $instance(@deferred) {
        $self->_defer_push([$instance->activity, $instance]);
        }

    while (my $act_ctx = $self->_queue_next) {
        eval {
            $self->_execute_activity_instance($act_ctx->[0], $act_ctx->[1]);
            };
        if($@) { die($@) } # handle_exception

        my %seen = ();
        while (my $act_ctx = $self->_defer_next) {
            my ($activity, $instance) = ($act_ctx->[0], $act_ctx->[1]);
            last if $seen{$instance->id}++; # full circle on current deferreds
            $self->_take_join($activity, $instance);
            }
        }

    $self->_is_running(0);
    }

sub _execute_activity_instance {
    my ($self, $activity, $instance) = @_;

    $self->cb_execute_activity($activity, $instance);
    
    my $completed = 0;
    # Route
    if($activity->is_route_type) {
        #$self->debug("runner: routing not implemented yet ...");
        $completed++;
        }
    # Implementations are No, Task, SubFlow or Reference
    elsif($activity->is_implementation_type) {
        #$self->debug("executor: executing implementation activity '" . $activity->activity_uid . "'");
        $completed = $self->_execute_implementation($activity, $instance);
        }
    # BlockActivity executes an ActivitySet
    elsif($activity->is_block_type) {
        $self->debug("runner: executing BlockActivity not implemented yet ...");
        throw_abstract( error => 'BlockActivity not implemented yet');
        }
    # Event
    elsif($activity->is_event_type) {
        $self->debug("runner: events not implemented yet ...");
        throw_abstract( error => 'Events not implemented yet');
        }
    else {
        throw_model( error => "Unsupported activity type " . $activity->activity_type);
        }    
    
    if ($completed && $activity->is_auto_finish) {
        $self->complete_activity($activity, $instance, 0);
        }
    }

sub _execute_implementation {
    my ($self, $activity, $instance) = @_;

    my $completed = 0;

    if($activity->is_impl_subflow) {
        $self->debug("runner: subflows not implemented yet ...");
        throw_abstract( error => 'Subflows not implemented yet');
        }
    elsif($activity->is_impl_reference) {
        $self->debug("runner: reference not implemented yet ...");
        throw_abstract( error => 'Reference not implemented yet');
        }
    elsif($activity->is_impl_task) {
        my ($i,$j) = (0,0);
        foreach my $task($activity->tasks->all) {
            # inject into sync/async event engine
            $i++ if $self->cb_execute_task($task, $instance);
            #$i++ if $task->run($activity, $instance);
            $j++;
            }
        $completed = $i == $j ? 1 : 0;
        }
    elsif($activity->is_impl_no) {
        # 'No' implementation completes immediately unless it is a manual-finish activity.
        $completed = $activity->is_auto_finish;
        }
    else {
        throw_model( error => "Invalid activity implementation definition" );
        }

    return $completed;
    }

sub _execute_transitions {
    my ($self, $activity, $instance) = @_;
    
    my $fired_count = 0;
    my ($otherwise, $exception) = ();

    my @transitions = $activity->split_type eq 'NONE' ?
        $activity->transitions->all : $activity->transitions_by_ref->all;
    unless(@transitions) {
        throw_model( error =>"XPDL error - no outgoing transitions for activity '" . ($activity->activity_name || $activity->activity_uid || $activity->id) . "'");
        }
    
    my (@instances) = ();

    # evaluate efferent transitions and activate successor activities
    foreach my $transition(@transitions) {
        my $tid = $transition->transition_uid || $transition->id || 'noid';
        #$self->debug("runner: executing transition $tid from " . $transition->from_activity->activity_uid . ' to ' . $transition->to_activity->activity_uid);
        if($transition->condition_type eq 'NONE' || $transition->condition_type eq 'CONDITION') {
            my $t_instance = $self->_execute_transition($transition, $instance, 0);
            if($t_instance) {
                push(@instances, [$transition, $t_instance]);
                $fired_count++;
                # only one transition in an XOR split can fire.
                last if $activity->split_type =~ /^(XOR|Exclusive)$/;
                }
            }
        elsif($transition->condition_type eq 'OTHERWISE') {
            $otherwise = $transition;
            }
        elsif($transition->condition_type eq 'DEFAULTEXCEPTION' || $transition->condition_type eq 'EXCEPTION') {
            $exception = $transition;
            }
        }

    if($fired_count == 0) {
        throw_model(error => "Deadlock: OTHERWISE transition missing on activity '" .  $activity->activity_uid . "'") unless $otherwise;
        my $t_instance = $self->_execute_transition($otherwise, $instance, 0);
        if($t_instance) {
            push(@instances, [$otherwise, $t_instance]);
            }
        }

    foreach my $inst(@instances) {
        my $r_instance   = $inst->[1];
        my $r_activity   = $r_instance->activity;
        $self->_take_join($r_activity, $r_instance);
        }

    return;
    }

sub _execute_transition {
    my ($self, $transition, $from_instance, $run) = @_;
    
    return unless $self->cb_execute_transition($transition, $from_instance);
   
    my $completed = 0;
    my $to_instance = eval { $transition->apply($from_instance); };

    my $err = $@;
    $err =~ s/\n//;
    #$self->debug("runner: executing transition '" . $transition->transition_uid . "' did not result in a new activity_instance : $@ (condition false or join not fired)") if($@);
    return 1 if($@ =~ /JoinShouldNotFire/ || $err =~ /JoinShouldNotFire/);
    return 0 if ($@ || $err);
    return unless $to_instance;
    return $to_instance unless $run;

    if($run) {
        $self->_run();
        }

    return 1;
    }

sub _take_join {
    my ($self, $activity, $instance) = @_;

    my $should_fire = 1;
    if($activity->join_type =~ /^(OR|Inclusive)$/) {
        #$self->debug("activity: Join for activity '" . $activity->activity_uid . "' instance " . $instance->id . " firing upstream ...");
        $should_fire = $instance->join_should_fire();
        }

    if($should_fire && $activity->is_auto_start) {
        if($instance->deferred) {
            #$instance->update({ deferred => \'NULL' });
            $instance->update({ deferred => undef });
            }
        $self->start_activity($activity, $instance, 0);
        }
    elsif(!$should_fire) {
        $instance->update({ deferred => DateTime->now });
        $self->_defer_push([$activity, $instance]);
        }
    }

__PACKAGE__->meta->make_immutable;

1;
__END__