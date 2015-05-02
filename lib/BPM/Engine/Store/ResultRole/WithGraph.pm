package BPM::Engine::Store::ResultRole::WithGraph;

our $VERSION   = '0.02';
our $AUTHORITY = 'cpan:SITETECH';

use namespace::autoclean;
use Moose::Role;

use Graph::Directed;

requires 'activities';
requires 'transitions';

sub graph {
    my $self = shift;

    my @edges = map { [ $_->from_activity_id, $_->to_activity_id ] }
        $self->transitions->all;

    return Graph::Directed->new( edges => [@edges] );
}

no Moose::Role;

1;
__END__
