
use strict;
use warnings;
use lib './t/lib';
use Test::More;

use_ok('BPM::Engine::Service::ProcessRunner');
foreach(qw/
    start_process
    complete_process
    start_activity
    continue_activity
    complete_activity/) {
  can_ok('BPM::Engine::Service::ProcessRunner', $_);
  }



done_testing();
