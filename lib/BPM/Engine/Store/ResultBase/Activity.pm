
package BPM::Engine::Store::ResultBase::Activity;
BEGIN {
    $BPM::Engine::Store::ResultBase::Activity::VERSION   = '0.001';
    $BPM::Engine::Store::ResultBase::Activity::AUTHORITY = 'cpan:SITETECH';
    }

use Moose::Role;
use namespace::autoclean -also => [qr/^_/];
with qw/
    Class::Workflow::State
    Class::Workflow::State::TransitionHash
    Class::Workflow::State::AcceptHooks
    Class::Workflow::State::AutoApply
    /;

sub new_instance {
    my ($self, $args) = @_;
    
    my $ai = $self->add_to_instances($args);
    if($self->split_type =~ /^(OR|Inclusive)$/ && !$ai->join) {
        $ai->create_related('join', { states => {} });
        }
    #$ai->discard_changes;
    return $ai;
    }

1;
__END__