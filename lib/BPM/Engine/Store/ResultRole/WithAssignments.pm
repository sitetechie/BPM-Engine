
package BPM::Engine::Store::ResultRole::WithAssignments;
BEGIN {
    $BPM::Engine::Store::ResultRole::WithAssignments::VERSION   = '0.001';
    $BPM::Engine::Store::ResultRole::WithAssignments::AUTHORITY = 'cpan:SITETECH';
    }

use Moose::Role;
use namespace::autoclean;

sub start_assignments {
    my $self = shift;
    my $assignments = $self->assignments || [];
    return grep { !$_->{AssignTime} || $_->{AssignTime} eq 'Start' } @$assignments;
    }

sub end_assignments {
    my $self = shift;
    my $assignments = $self->assignments || [];
    return grep { $_->{AssignTime} eq 'End' } @$assignments;
    }

# ABSTRACT: Role for Process, Transition and Activity

1;
__END__
