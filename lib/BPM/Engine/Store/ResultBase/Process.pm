
package BPM::Engine::Store::ResultBase::Process;
BEGIN {
    $BPM::Engine::Store::ResultBase::Process::VERSION   = '0.001';
    $BPM::Engine::Store::ResultBase::Process::AUTHORITY = 'cpan:SITETECH';
    }

use Moose::Role;
use namespace::autoclean;

sub new_instance {
    my ($self, $attrs) = @_;
    $attrs ||= {};
    return $self->add_to_instances($attrs);
    }

sub start_activities {
    my $self = shift;
    my @start = grep { $_->is_start_activity } $self->activities->all
        or die('No start activities, invalid definition');
    return \@start;
    }

1;
__END__