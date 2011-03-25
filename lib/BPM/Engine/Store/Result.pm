package BPM::Engine::Store::Result;
BEGIN {
    $BPM::Engine::Store::Result::VERSION   = '0.001';
    $BPM::Engine::Store::Result::AUTHORITY = 'cpan:SITETECH';
    }

use namespace::autoclean;
use Moose;
extends qw/DBIx::Class/;

__PACKAGE__->load_components(qw/
    UUIDColumns TimeStamp InflateColumn::DateTime
    InflateColumn::Serializer Core
    /);

sub _inflate_to_datetime {
    my $self = shift;
    my $val = $self->next::method(@_);

    return bless $val, 'BPM::Engine::DateTime';
    }

sub TO_JSON {
    my($self, $level) = @_;

    my %parms = map { $_ => $self->$_ } grep { $self->$_ }
        $self->result_source->columns; # $self->columns;

    return \%parms;
    }

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );

package BPM::Engine::DateTime;

use strict;
use warnings;
use parent 'DateTime';

sub TO_JSON {
    my $dt = shift; 
    return "$dt";
    }

1;
__END__