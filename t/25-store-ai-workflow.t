
use strict;
use warnings;
use lib './t/lib';
use Test::More;
use Test::Exception;

use BPME::TestUtils qw/setup_db rollback_db schema process_wrap schema/;

BEGIN { setup_db }
END   { rollback_db }

my $schema = schema();
my ($e, $process) = process_wrap();

my $activity = $process->add_to_activities({
    activity_uid     => 1,
    activity_name    => 'work item',
    activity_type    => 'Implementation',
    start_mode => 'Manual'
    });
$activity->discard_changes;

ok(!$activity->is_auto_start, 'activity is auto start');
is($activity->finish_mode, 'Automatic', 'finish mode is Automatic');
ok($activity->is_auto_finish, 'activity is auto finish');

$activity->start_mode('Automatic');
$activity->implementation_type('Task');
$activity->update();

my $task = $activity->add_to_tasks({
        task_uid    => 112,
        task_name   => 'user task',
        description => '',
        task_type   => 'UserTask',
        #task_data   => '',
        });
isa_ok($task, 'BPM::Engine::Store::Result::ActivityTask');

ok($activity->is_start_activity, 'is start activity');
ok($activity->is_impl_task, 'is impl task');
ok($activity->is_auto_start, 'is auto start');

$activity->finish_mode('Manual');
$activity->update();

my $pi = $process->new_instance();
isa_ok($pi, 'BPM::Engine::Store::Result::ProcessInstance');

is($schema->resultset('ActivityInstanceState')->search_rs->count, 0);

my $aic = $activity->new_instance({ process_instance_id => $pi->id });
ok($aic->workflow_instance_id);
is($schema->resultset('ActivityInstanceState')->search_rs->count, 1);

is($pi->activity_instances->count, 1);


#-- get ai

my $ai = $pi->activity_instances->first;
isa_ok($ai, 'BPM::Engine::Store::Result::ActivityInstance');

isa_ok($ai->workflow_instance, 'BPM::Engine::Store::Result::ActivityInstanceState');
is($ai->workflow_instance->state, 'open.not_running.ready', 'State set to open.not_running.not_assigned');
is($ai->state, 'open.not_running.ready');

my $rs = $schema->resultset('ActivityInstanceState')->search_rs;
is($rs->count, 1);

$ai->apply_transition('start');
is($ai->workflow_instance->state, 'open.running.not_assigned');
is($rs->count, 2);

$ai->apply_transition('assign');
is($ai->workflow_instance->state, 'open.running.assigned');
is($rs->count, 3);

$ai->apply_transition('suspend');
is($ai->workflow_instance->state, 'open.not_running.suspended', 'suspended');
is($rs->count, 4);

$ai->apply_transition('resume');
is($ai->workflow_instance->state, 'open.running.assigned', 'resumed');

$ai->apply_transition('reassign');
is($ai->workflow_instance->state, 'open.running.assigned', 'reassigned');

my $ai2 = $ai->clone;
is($ai2->workflow_instance->state, 'open.not_running.ready', 'ready');

$ai2->apply_transition('assign');
is($ai2->workflow_instance->state, 'open.running.assigned', 'assigned');

#$ai2->update;
$ai->apply_transition('abort');
is($ai2->workflow_instance->state, 'open.running.assigned', 'open.running.assigned');
is($ai->workflow_instance->state, 'closed.cancelled.aborted');

$ai2->apply_transition('finish');
is($ai2->workflow_instance->state, 'closed.completed');

done_testing();
