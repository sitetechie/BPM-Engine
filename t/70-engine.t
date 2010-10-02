use strict;
use warnings;
use lib './t/lib';
use Test::More;
use Test::Exception;
use Test::Moose;

use BPME::TestUtils qw/setup_db rollback_db $dsn/;
BEGIN { setup_db }
END   { rollback_db }

no warnings 'redefine';
*diag  = sub {};
use warnings;

#-- Interface check
#----------------------------------------------------------------------------
use_ok('BPM::Engine');
ok(my $e1 = BPM::Engine->new(connect_info => $dsn));

meta_ok($e1);

foreach(qw/
    MooseX::SimpleConfig
    BPM::Engine::Role::WithLogger
    BPM::Engine::Role::WithCallback
    BPM::Engine::Role::WithPersistence
    BPM::Engine::Handler::ProcessDefinitionHandler
    BPM::Engine::Handler::ProcessInstanceHandler
    BPM::Engine::Handler::ActivityInstanceHandler
    BPM::Engine::API
    /) {
    does_ok($e1, $_);
    }

foreach(qw/logger log_dispatch_conf callback schema connect_info/) {
    has_attribute_ok($e1, $_);
    }

with_immutable { ok(1) } qw/BPM::Engine/;

can_ok($e1, qw/storage log debug info _runner/ );

#-- Engine construction
#----------------------------------------------------------------------------

my $engine;

my $callback = sub {
        my($entity, $event, $node, $instance) = @_;
        #diag('callback...');
        my %dispatch = (
            process => {
                start => sub {
                    my ($node, $instance) = @_;
                    diag 'Starting process ' . $node->process_uid;
                    isa_ok($node, 'BPM::Engine::Store::Result::Process');
                    isa_ok($instance, 'BPM::Engine::Store::Result::ProcessInstance');
                    return 1;
                    },
                complete => sub {
                    my ($node, $instance) = @_;
                    diag 'Completing process' . $node->process_uid;
                    return 1;
                    },
                },
            activity => {
                start   => sub {
                    my ($node, $instance) = @_;
                    diag 'Starting activity ' . $node->activity_uid;
                    isa_ok($node, 'BPM::Engine::Store::Result::Activity');
                    isa_ok($instance, 'BPM::Engine::Store::Result::ActivityInstance');
                    return 1;
                    },
                continue => sub { my ($node, $instance) = @_; diag 'Continuing activity ' . $node->activity_uid; return 1; },
                execute => sub { my ($node, $instance) = @_; diag 'Executing activity ' . $node->activity_uid; return 1; },
                complete => sub { my ($node, $instance) = @_; diag 'Completing activity ' . $node->activity_uid; return 1; },
                },
            task => {
                execute => sub {
                    my ($node, $instance) = @_;
                    diag 'Executing task ' . $node->activity->activity_uid;
                    isa_ok($node, 'BPM::Engine::Store::Result::ActivityTask');
                    isa_ok($instance, 'BPM::Engine::Store::Result::ActivityInstance');
                    return 1;
                    },
                },
            transition => {
                execute => sub {
                    my ($node, $instance) = @_;
                    diag 'Executing transition' . $node->transition_uid;
                    isa_ok($node, 'BPM::Engine::Store::Result::Transition');
                    isa_ok($instance, 'BPM::Engine::Store::Result::ActivityInstance');
                    return 1;
                    },
                },
            );
        die("Unknown callback") unless $dispatch{$entity}{$event};
        return $dispatch{$entity}{$event}->($node, $instance);

        #is($entity, 'activity');
        #is($event, 'execute');
        #diag('end callback...');
        };

$engine = BPM::Engine->new(
    connect_info => $dsn,
    callback     => $callback,
    );

isa_ok($engine, 'BPM::Engine');
isa_ok($engine->storage, 'BPM::Engine::Store');
isa_ok($engine->storage->resultset('BPM::Engine::Store::Result::Package')->search, 'BPM::Engine::Store::ResultSet::Package');
ok(!$engine->storage->resultset('BPM::Engine::Store::Result::Package')->search->all);


#- from config file
my $e2 = BPM::Engine->new_with_config(
    configfile => './etc/engine.yaml',
    #connect_info => $dsn,
    logger => BPM::Engine::Logger::Default->new(),
    );
isa_ok($e2, 'BPM::Engine');

#-- ProcessDefinition Methods (Handler::ProcessDefinitionHandler)
#----------------------------------------------------------------------------

is($engine->list_packages->count, 0, 'No Packages');
is($engine->list_process_definitions->count, 0, 'No Processes');

#-- create_package

my $package = $engine->create_package('./t/var/or.xpdl');
isa_ok($package,'BPM::Engine::Store::Result::Package');
is($package->package_uid, 'Example1');
is($engine->list_packages->count, 1, 'Package created');
is($engine->list_process_definitions->count, 1, 'Process created');

#-- list_packages

is($engine->list_packages->count, 1, 'Package created');
$package = $engine->list_packages->first;
isa_ok($package,'BPM::Engine::Store::Result::Package');

#-- list_process_definitions

my $process = $engine->list_process_definitions({ process_uid => 'multi-inclusive-split-and-join' })->first;
isa_ok($process, 'BPM::Engine::Store::Result::Process');

#-- get_process_definition

$process = $engine->get_process_definition($process->id);
isa_ok($process, 'BPM::Engine::Store::Result::Process');

#-- delete_package

$engine->delete_package($package->id);
is($engine->list_packages->count, 0, 'Package deleted');
is($engine->list_process_definitions->count, 0, 'Process deleted');

#-- ProcessInstance Methods (Handler::ProcessInstanceHandler)
#----------------------------------------------------------------------------

$engine->create_package('./t/var/or.xpdl');
my @procs = $engine->list_process_definitions->all;
$process = shift @procs;
isa_ok($process, 'BPM::Engine::Store::Result::Process');

#-- create_process_instance

my $args = { splitA => 'B1', splitB => 'B1' };
my $pi0 = $engine->create_process_instance($process->id, undef, $args);
isa_ok($pi0, 'BPM::Engine::Store::Result::ProcessInstance');

my $pi = $engine->create_process_instance($process, undef, $args);
isa_ok($pi, 'BPM::Engine::Store::Result::ProcessInstance');

#-- list_process_instances

is($engine->list_process_instances->count, 2, 'Two process instances found');
my $first_pi = $engine->list_process_instances->first;
isa_ok($first_pi, 'BPM::Engine::Store::Result::ProcessInstance');
#is($pi->id, $first_pi->id, 'Created process instance found in list');

#-- get_process_instance

$first_pi = $engine->get_process_instance($first_pi->id);
isa_ok($first_pi, 'BPM::Engine::Store::Result::ProcessInstance');
is($first_pi->workflow_instance->state, 'open.not_running.ready');

#-- start_process_instance

$engine->start_process_instance($pi);
#warn "process " . $ai ? 'completed' : 'running';
is($pi->workflow_instance->state, 'closed.completed');

#-- terminate_process_instance
#-- abort_process_instance

#-- process_instance_attribute
#-- change_process_instance_state

#-- delete_process_instance
is($engine->list_process_instances->count, 2, 'First process instance found');
ok($engine->delete_process_instance($pi));
is($engine->list_process_instances->count, 1, 'First process instance deleted');


#-- Activity Methods (Handler::ActivityInstanceHandler)
#----------------------------------------------------------------------------

$engine->start_process_instance($pi0);

#-- list_activity_instances

is($engine->list_activity_instances->count, 7);
my $ai = $engine->list_activity_instances->first;
isa_ok($ai, 'BPM::Engine::Store::Result::ActivityInstance');

#-- get_activity_instance

$ai = $engine->get_activity_instance($ai->id);
isa_ok($ai, 'BPM::Engine::Store::Result::ActivityInstance');

#-- change_activity_instance_state

#ok($engine->change_activity_instance_state($ai->id, 'finish'));

#-- activity_instance_attribute

ok($ai->add_to_attributes({
    name => 'SomeVar',
    value => 'SomeVal',
    }));
is($engine->activity_instance_attribute($ai->id, 'SomeVar')->value, 'SomeVal');
ok($engine->activity_instance_attribute($ai->id, 'SomeVar', 'OtherValue'));
is($engine->activity_instance_attribute($ai->id, 'SomeVar')->value, 'OtherValue');

done_testing();
