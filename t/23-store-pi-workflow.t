use strict;
use warnings;
use lib './t/lib';
use Test::More;

use BPM::Engine::TestUtils qw/setup_db teardown_db schema/;

BEGIN { setup_db }
END   { teardown_db }

my $schema = schema();
my $process = $schema->resultset('Process')->create({ package_id => 1 });
isa_ok($process, 'BPM::Engine::Store::Result::Process');

is($schema->resultset('ProcessInstanceState')->search_rs->count, 0);

my $pi = $process->new_instance();
isa_ok($pi, 'BPM::Engine::Store::Result::ProcessInstance');

isa_ok($pi->workflow_instance, 'BPM::Engine::Store::Result::ProcessInstanceState');
is($pi->workflow_instance->state->name, 'open.not_running.ready');
is($pi->state, 'open.not_running.ready');
is($schema->resultset('ProcessInstanceState')->search_rs->count, 1);

$pi->apply_transition('start');
is($pi->workflow_instance->state->name, 'open.running');
is($pi->state, 'open.running');
is($schema->resultset('ProcessInstanceState')->search_rs->count, 2);

$pi->apply_transition('suspend');
is($pi->workflow_instance->state->name, 'open.not_running.suspended');
is($schema->resultset('ProcessInstanceState')->search_rs->count, 3);

$pi->apply_transition('resume');
is($pi->workflow_instance->state->name, 'open.running');

$pi->apply_transition('finish');
is($pi->workflow_instance->state->name, 'closed.completed');

$pi = $process->new_instance;
$pi->apply_transition('terminate');
is($pi->workflow_instance->state->name, 'closed.cancelled.terminated');

$pi = $process->new_instance;
$pi->apply_transition('abort');
is($pi->workflow_instance->state->name, 'closed.cancelled.aborted');

done_testing();
