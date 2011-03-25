use strict;
use warnings;
use Test::More;
use Test::Exception;

{
package WCall;
use Moose;
with 'BPM::Engine::Role::WithCallback';
}

package main;

ok(my $wc = WCall->new(callback => sub { $_[0] ? 'welcome' : 'goodbye' }));

is($wc->call_callback(1), 'welcome');
is($wc->call_callback(0), 'goodbye');

###
#$wc->register_callback();
#$wc->reg_cb();
#is(scalar $wc->callbacks(), 1);
#$wc->clear_callbacks();
#is(scalar $wc->callbacks(), 0);
###

done_testing();
