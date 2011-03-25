use strict;
use warnings;
use Test::More;
use t::TestUtils;

{
package WAss;
use Moose;
has 'process' => ( is => 'ro' );
has 'process_instance' => ( is => 'ro' );
with 'BPM::Engine::Role::HandlesIO';

sub _execute_implementation {}

}


package main;

my $schema = schema();
my $package = $schema->resultset('Package')->create_from_xpdl('./t/var/09-data.xpdl');

my $process = $package->processes->first; # $schema->resultset('Process')->search->first;
my $pi = $process->new_instance();

ok(my $wa = WAss->new(process => $process, process_instance => $pi));
ok($wa->process->id);
ok($wa->process_instance->id);

my $activity = $process->start_activity;
my $instance = $activity->new_instance({ process_instance_id => $pi->id });

$wa->_execute_implementation($activity, $instance);

ok(1);

done_testing();
