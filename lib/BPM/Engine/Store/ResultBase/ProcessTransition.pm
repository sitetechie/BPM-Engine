
package BPM::Engine::Store::ResultBase::ProcessTransition;
BEGIN {
    $BPM::Engine::Store::ResultBase::ProcessTransition::VERSION   = '0.001';
    $BPM::Engine::Store::ResultBase::ProcessTransition::AUTHORITY = 'cpan:SITETECH';
    }

use Moose::Role;
use BPM::Engine::Util::ExpressionEvaluator;
use namespace::autoclean -also => [qr/^_/];

with 'Class::Workflow::Transition::Validate::Simple' => {
      '-excludes' => 'derive_and_accept_instance',
      };

has to_activity => (
    does => "Class::Workflow::State",
    is   => "rw",
    required => 0,
    );

before apply => sub {
    my ($self, $instance, @args) = @_;
    my $state = $instance->activity;

    unless ($state->has_transition($self)) {
        die($self->transition_uid . ' is not in ' . $instance->activity->activity_uid . '\'s current state (' . $state->activity_uid . ')"');
        }

    $self->clear_validators;    
    
    # set validators
    if($self->condition_type eq 'CONDITION') {
        $self->add_validators( sub { 
            my ($transition, $activity_instance, @args) = @_;
            my $evaluator = BPM::Engine::Util::ExpressionEvaluator->load(
                activity_instance => $activity_instance,
                transition        => $transition,
                args              => [@args],
                );
            my $res = $evaluator->evaluate($transition->condition_expr);
            undef $evaluator;
            return $res;
            } );

        }
    };

sub apply {
    my ($self, $instance, @args) = @_;

    my ($set_instance_attrs, @rv) = $self->_apply_body( $instance, @args );
    $set_instance_attrs ||= {}; # should really die if it's bad

    my $new_instance = $self->derive_and_accept_instance($instance, {
            activity => ( $self->to_activity || die "$self has no 'to_activity'" ),
            %{$set_instance_attrs},
            },
        @args,
        );
    
    return wantarray ? ($new_instance, @rv) : $new_instance;
    }

sub _apply_body {
    my ($self, $instance, @args) = @_;
    
    return {}, (); # no fields, no additional values
    }


sub derive_and_accept_instance {
    my ($self, $proto_instance, $attrs, @args) = @_;

    my $activity = delete $attrs->{activity} 
        or die "You must specify the next activity of the instance";
    
    my $from_activity = $self->from_activity;    
    if($from_activity->split_type =~ /^(OR|Inclusive)$/) {
        # set transition 'taken' if coming from a split
        my $join = $proto_instance->join 
            or die("No join found for split activity " . $from_activity->activity_uid);
        $join->set_transition($self->id, 'taken');
        # set new instances' parent to the split-ai if coming from a split
        $attrs->{parent_token_id} = $proto_instance->id;
        }
    elsif($proto_instance->parent_token_id) {
        $attrs->{parent_token_id} = $proto_instance->parent_token_id;
        }

    my $instance = $proto_instance->derive(
        transition_id => $self->id,
        activity_id => $activity->id,
        %$attrs,
        );
   
    $instance->update();

    # create future join on arrival in a split
    if($activity->split_type =~ /^(OR|Inclusive)$/) { # && !$instance->join) {
        $instance->create_related('join', { states => {} });
        }
    
    return $instance;
    }

sub validation_error {
    my ( $self, $error, $instance, @args ) = @_;
    die $error;
    }

1;
__END__