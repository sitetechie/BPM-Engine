
package BPM::Engine::Types::Internal;
BEGIN {
    $BPM::Engine::Types::Internal::VERSION   = '0.001';
    $BPM::Engine::Types::Internal::AUTHORITY = 'cpan:SITETECH';
    }

use strict;
use warnings;

use Carp qw/croak/;
use Scalar::Util 'reftype';

use MooseX::Types -declare => [qw/
    Exception
    /];

use MooseX::Types::Moose qw/
    Object
    /;

subtype Exception,
    as Object,
    where { $_->isa('BPM::Engine::Exception') },
    message { "Object isn't an Exception" };



1;
__END__