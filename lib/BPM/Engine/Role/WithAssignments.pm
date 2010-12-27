package BPM::Engine::Role::WithAssignments;
BEGIN {
    $BPM::Engine::Role::WithAssignments::VERSION   = '0.001';
    $BPM::Engine::Role::WithAssignments::AUTHORITY = 'cpan:SITETECH';
    }

use Moose::Role;
use BPM::Engine::Util::ExpressionEvaluator;
use namespace::autoclean;

before 'start_process' => sub {
    my $self = shift;
    
    my @assignments = $self->process->start_assignments;
    return unless scalar @assignments;

    my $evaluator = BPM::Engine::Util::ExpressionEvaluator->load(
        process          => $self->process,
        process_instance => $self->process_instance,
        #args              => [@args],
        );

    foreach my $ass(@assignments) {
        $evaluator->assign($ass->{Target}, $ass->{Expression});
        }
    };

before 'complete_process' => sub {
    my $self = shift;

    my @assignments = $self->process->end_assignments;
    return unless scalar @assignments;

    my $evaluator = BPM::Engine::Util::ExpressionEvaluator->load(
        process          => $self->process,
        process_instance => $self->process_instance,
        #args              => [@args],
        );

    foreach my $ass(@assignments) {
        $evaluator->assign($ass->{Target}, $ass->{Expression});
        }
    };

before 'start_activity' => sub {
    my ($self, $activity, $instance) = @_;
    
    my @assignments = $activity->start_assignments;
    return unless scalar @assignments;
    
    my $evaluator = BPM::Engine::Util::ExpressionEvaluator->load(
        activity          => $activity,
        activity_instance => $instance,
        #args              => [@args],
        );

    foreach my $ass(@assignments) {
        $evaluator->assign($ass->{Target}, $ass->{Expression});
        }
    };

before 'complete_activity' => sub {
    my ($self, $activity, $instance) = @_;
    
    my @assignments = $activity->end_assignments;
    return unless scalar @assignments;
    
    my $evaluator = BPM::Engine::Util::ExpressionEvaluator->load(
        activity          => $activity,
        activity_instance => $instance,
        #args              => [@args],
        );
    
    foreach my $ass(@assignments) {
        $evaluator->assign($ass->{Target}, $ass->{Expression});
        }
    };

around '_execute_transition' => sub {
    my ($orig, $self, $transition, $instance) = @_;
    
    my $evaluator = BPM::Engine::Util::ExpressionEvaluator->load(
        activity_instance => $instance,
        transition        => $transition,
        #args              => [@args],
        );

    foreach my $ass($transition->start_assignments) {
        $evaluator->assign($ass->{Target}, $ass->{Expression});
        }
    
    my $res = $self->$orig($transition, $instance);
    
    foreach my $ass($transition->end_assignments) {
        $evaluator->assign($ass->{Target}, $ass->{Expression});
        }

    return $res;
    };

no Moose::Role;

1;
__END__

