#!perl

use warnings;
use strict;

use Test::More;
use File::Find;

my @modules;
find( sub { push @modules, $File::Find::name if /\.pm$/ }, './lib' );
@modules = grep { !/ShipIt/} @modules;

plan tests => (2 * scalar @modules) + 1;

# Check the perl version
ok( $] >= 5.005, "Your perl is new enough" );

use_ok($_) for sort map { s!/!::!g; s/\.pm$//; s/\.:://; s/^lib:://; $_ } @modules; ## no critic (MutatingListFunctions)

is($_->VERSION, $BPM::Engine::VERSION, "Version $_ matches") for sort map { s!/!::!g; s/\.pm$//; s/\.:://; s/^lib:://; $_ } @modules; ## no critic (MutatingListFunctions)
