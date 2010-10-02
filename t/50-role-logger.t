#!/usr/bin/perl -w

use strict;
use warnings;
use lib './t/lib';
use Test::More;
use Test::Exception;
use BPM::Engine::Logger::Default;

ok( my $logger = BPM::Engine::Logger::Default->new({
    log_dispatch_conf => 't/var/log_file.conf'
    })  );

ok(!$logger->notice("event triggered"));

done_testing();
