use strict;
use warnings;
use Test::More;
use Test::Exception;

use BPM::Engine::Exceptions;
use BPM::Engine::Types qw/+Exception UUID Row ResultSource Schema/;

eval { BPM::Engine::Exception->throw(error => 'I feel funny.') };
my $e = $@;
ok(is_Exception($e),'Got exception type');
is(UUID->validate('12345678-90ab-CDEF-0000-FeedBeefAbba'),undef,
   'UUID validates');
like(UUID->validate('1234567890abCDEF0000FeedBeefAbba'),qr/./,
     'UUID without dashes fails');

done_testing;
