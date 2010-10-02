
package BPM::Engine::Store;
BEGIN {
    $BPM::Engine::Store::VERSION   = '0.001';
    $BPM::Engine::Store::AUTHORITY = 'cpan:SITETECH';
    }

use strict;
use warnings;
use base qw/DBIx::Class::Schema/;

__PACKAGE__->load_namespaces();

1;
__END__
