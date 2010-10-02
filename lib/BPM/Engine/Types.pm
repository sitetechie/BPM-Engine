
package BPM::Engine::Types;
BEGIN {
    $BPM::Engine::Types::VERSION   = '0.001';
    $BPM::Engine::Types::AUTHORITY = 'cpan:SITETECH';
    }

use strict;
use warnings;

use base 'MooseX::Types::Combine';

__PACKAGE__->provide_types_from(qw/
    BPM::Engine::Types::Internal
    MooseX::Types::Moose
    /);

1;
__END__
