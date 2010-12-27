package BPM::Engine::Store::Result;
BEGIN {
    $BPM::Engine::Store::Result::VERSION   = '0.001';
    $BPM::Engine::Store::Result::AUTHORITY = 'cpan:SITETECH';
    }

use namespace::autoclean;
use Moose;
extends qw/DBIx::Class/;

__PACKAGE__->load_components(qw/
    UUIDColumns InflateColumn::Serializer Core
    /);

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );

1;
__END__