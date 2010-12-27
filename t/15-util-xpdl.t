
use strict;
use warnings;
use lib './t/lib';
use Test::More;
use BPM::Engine::Util::XPDL;

foreach my $version(qw/1_0 2_0 2_1 2_2/) {
    ok(-e BPM::Engine::Util::XPDL::_xpdl_spec($version));
    }

done_testing;
