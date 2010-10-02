
use strict;
use warnings;
use lib './t/lib';
use Test::More;
use Test::Moose;
use DateTime;

use BPME::TestUtils qw/setup_db rollback_db $dsn process_wrap/;

BEGIN { setup_db unless -f './t/var/bpmengine.db'; }
END   { rollback_db }

my ($engine, $process) = process_wrap();
my $pi = $engine->create_process_instance($process);

#-- new activity

my $activity = $process->add_to_activities({
        activity_uid     => 1,
        activity_name    => 'work item',
        activity_type    => 'Implementation',
        start_mode => 'Manual'
        });
$activity->discard_changes;

#-- new activity_instance

my $ai = $activity->add_to_instances({ process_instance_id => $pi->id });
isa_ok($ai, 'BPM::Engine::Store::Result::ActivityInstance');

# the right way to do it
$ai = $activity->new_instance({
    process_instance_id => $pi->id,
    
    });
#$ai->discard_changes;
isa_ok($ai, 'BPM::Engine::Store::Result::ActivityInstance');

is($pi->activity_instances->count, 2, 'AI count matches');

#-- activity_instance interface

is($ai->process_instance->id, $pi->id);
is($ai->activity->id, $activity->id);
ok(!$ai->transition);
ok(!$ai->prev);
ok(!$ai->next);
ok(!$ai->parent);
ok(!$ai->completed);
ok($ai->completed( DateTime->now() ));
ok($ai->completed);

isa_ok($ai->workflow_instance, 'BPM::Engine::Store::Result::ActivityInstanceState');
ok(!$ai->join);
#isa_ok($ai->join, 'BPM::Engine::Store::Result::ActivityInstanceJoin');
isa_ok($ai->attributes, 'DBIx::Class::ResultSet');
can_ok($ai, qw/join_should_fire/);

#-- workflow role

isa_ok($ai->workflow, 'Class::Workflow');
does_ok($ai->workflow_instance, 'Class::Workflow::Instance');
is($ai->workflow_instance->state, 'open.not_running.ready');

done_testing();
