use strict;
use warnings;
use Test::More;
use t::TestUtils;

my $schema = schema();
my $package = $schema->resultset('Package')->create({});
my $process = $package->add_to_processes({});

my %undefs = map { $_ => undef } qw/
    performer_participant_id activity_uid activity_name
    documentation_url icon_url
    event_attr data_fields input_sets output_sets assignments extended_attr
    /;
my %defaults = (
    activity_type => 'Implementation',
    implementation_type => 'No',
    event_type => 'No',
    description => undef,
    start_mode => 'Automatic',
    finish_mode => 'Automatic',
    priority => 0,
    start_quantity => 1,
    completion_quantity => 1,
    join_type => 'NONE',
    join_type_exclusive => 'Data',
    split_type => 'NONE',
    split_type_exclusive => 'Data',
    %undefs,
    );

my $activity = $process->add_to_activities({})->discard_changes;

foreach my $col(keys %defaults) {
    is($activity->$col, $defaults{$col}, "default $col matches");
    }

can_ok($activity, qw/
    process transitions_in prev_activities transitions next_activities transition_refs
    deadlines performers participants tasks instances
    has_transition has_transitions transitions_in_by_ref transitions_by_ref
    /);

my %false = map { $_ => 0 } qw/
    route_type block_type event_type
    split or_split xor_split and_split complex_split
    join or_join xor_join and_join complex_join
    impl_task impl_subflow impl_reference
	/;

my %bools = (%false, map { $_ => 1 } qw/
	start_activity end_activity auto_start auto_finish
	implementation_type impl_no
	/);

foreach my $col(keys %bools) {
    my $meth = "is_$col";
    is($activity->$meth, $bools{$col}, "$meth returns $bools{$col}");
    }

my $task = $activity->add_to_tasks({
    task_uid    => 112,
    task_name   => 'user task',
    description => '',
    task_type   => 'User',
    #task_data   => '',
    });
isa_ok($task, 'BPM::Engine::Store::Result::ActivityTask');
is($task->id, $activity->tasks->first->id);

done_testing;

__END__

use Data::Dumper;
#warn Dumper \%undefs;
warn Dumper \%defaults;


#foreach my $col(keys %true) {
#    my $meth = "is_$col";
#    is($activity->$col, $false{$col});
#    }

if(0){
$activity = $process->add_to_activities({
    activity_uid     => 1,
    activity_name    => 'work item',
    activity_type    => 'Implementation',
    start_mode => 'Manual'
    });
$activity->discard_changes;

ok(!$activity->is_auto_start, 'activity is auto start');
is($activity->finish_mode, 'Automatic', 'finish mode is Automatic');
ok($activity->is_auto_finish, 'activity is auto finish');

ok(!$activity->is_split, 'activity is not a split');
ok(!$activity->is_join, 'activity is not a join');

$activity->start_mode('Automatic');
}


$activity->implementation_type('Task');
$activity->update();



ok($activity->is_start_activity, 'is start activity');
ok($activity->is_impl_task, 'is impl task');
ok($activity->is_auto_start, 'is auto start');

$activity->finish_mode('Manual');
$activity->update();

###

$activity = $schema->resultset('Activity')->create({
    process_id    => $process->id,
    activity_uid  => 1,
    activity_name => 'work item1',
    activity_type => 'Implementation',
    start_mode    => 'Manual',
    });

isa_ok($activity, 'BPM::Engine::Store::Result::Activity');

is($activity->activity_name, 'work item1');
$activity->update({ activity_name    => 'work item2' });
is($activity->activity_name, 'work item2');

done_testing;

__END__

activity_id process_id performer_participant_id activity_uid activity_name
activity_type implementation_type event_type description start_mode finish_mode
priority start_quantity completion_quantity documentation_url icon_url
join_type join_type_exclusive split_type split_type_exclusive event_attr
data_fields input_sets output_sets assignments extended_attr

process transitions_in prev_activities transitions next_activities transition_refs
deadlines performers participants tasks instances

has_transition has_transitions transitions_in_by_ref transitions_by_ref

is_start_activity
is_end_activity
is_auto_start
is_auto_finish
is_implementation_type
is_route_type
is_block_type
is_event_type
is_split
is_or_split
is_xor_split
is_and_split
is_complex_split
is_join
is_or_join
is_xor_join
is_and_join
is_complex_join
is_impl_no 
is_impl_task
is_impl_subflow
is_impl_reference

