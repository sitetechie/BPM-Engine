use strict;
use warnings;
use lib './t/lib';
use Test::More;
use Test::Exception;
use Test::Moose;
use XML::LibXML;

use BPM::Engine::TestUtils qw/setup_db teardown_db $dsn/;
BEGIN { setup_db }
END   { teardown_db }

no warnings 'redefine';
sub diag {}
use warnings;

#-- Interface check
#----------------------------------------------------------------------------
use_ok('BPM::Engine');
use_ok('BPM::Engine::Logger');

throws_ok(
    sub { BPM::Engine->new() },
    'BPM::Engine::Exception::Engine',
    'Invalid connection arguments'
    );
throws_ok(
    sub { BPM::Engine->new_with_config(configfile => 'nonexistantfile') },
    qr/Specified configfile 'nonexistantfile' does not exist/,
    'Invalid config file'
    );
unless(-f '/etc/bpmengine.yaml') {
    throws_ok( sub { BPM::Engine->new_with_config }, qr/Specified configfile.*does not exist/);
    }
lives_ok( sub { BPM::Engine->new( connect_info => $dsn ) }, 'Valid connect_info' );
lives_ok( sub { BPM::Engine->new({ connect_info => $dsn }) }, 'Valid connect_info' );

my $e1 = new_ok('BPM::Engine' => [ connect_info => $dsn ]);
meta_ok($e1);

foreach(qw/
    MooseX::SimpleConfig
    BPM::Engine::Role::WithLogger
    BPM::Engine::Role::WithCallback
    BPM::Engine::Role::WithPersistence
    BPM::Engine::Handler::ProcessDefinitionHandler
    BPM::Engine::Handler::ProcessInstanceHandler
    BPM::Engine::Handler::ActivityInstanceHandler
    BPM::Engine::Role::EngineAPI
    /) {
    does_ok($e1, $_);
    }

foreach(qw/logger log_dispatch_conf callback schema connect_info/) {
    has_attribute_ok($e1, $_);
    }

with_immutable { ok(1) } qw/BPM::Engine/;

can_ok($e1, qw/storage log debug info runner/ );

#-- Engine construction
#----------------------------------------------------------------------------

my $engine;

my $callback = sub {
        my($runner, $entity, $event, $node, $instance) = @_;
        #diag('callback...');
        my %dispatcher = (
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
                continue => sub {
                    my ($node, $instance) = @_;
                    diag 'Continuing activity ' . $node->activity_uid;
                    return 1;
                    },
                execute => sub {
                    my ($node, $instance) = @_;
                    diag 'Executing activity ' . $node->activity_uid;
                    return 1;
                    },
                complete => sub {
                    my ($node, $instance) = @_;
                    diag 'Completing activity ' . $node->activity_uid;
                    return 1;
                    },
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
        die("Unknown callback") unless $dispatcher{$entity}{$event};
        return $dispatcher{$entity}{$event}->($node, $instance);

        #is($entity, 'activity');
        #is($event, 'execute');
        #diag('end callback...');
        };

my ($package, $process) = ();

{
package Foo;
use Moose::Role;


before 'start_process_instance' => sub {
    my $self = shift;
    my $pi = shift;
    #warn "STARTING PROCESS INSTANCE " . $pi->process->process_uid;
    };

no Moose::Role;
}

$engine = BPM::Engine->with_traits(qw/Foo/)->new(
    connect_info => { dsn => $dsn },
    callback     => $callback,
    log_dispatch_conf => {
        class     => 'Log::Dispatch::Screen',
        min_level => 'critical',
        stderr    => 1,
        format    => '[%p] %m at %F line %L%n',
        },
    );

isa_ok($engine, 'BPM::Engine');
isa_ok($engine->storage, 'BPM::Engine::Store');
isa_ok($engine->storage->resultset('BPM::Engine::Store::Result::Package')->search, 'BPM::Engine::Store::ResultSet::Package');
ok(!$engine->storage->resultset('BPM::Engine::Store::Result::Package')->search->all);

#- from config file

my $e2 = BPM::Engine->new_with_config(
    configfile => './t/etc/engine.yaml',
    #connect_info => $dsn,
    logger => BPM::Engine::Logger->new(),
    );
isa_ok($e2, 'BPM::Engine');

#-- ProcessDefinition Methods (Handler::ProcessDefinitionHandler)
#----------------------------------------------------------------------------

is($engine->list_packages->count, 0, 'No Packages');
is($engine->list_process_definitions->count, 0, 'No Processes');

#-- create_package

throws_ok( sub { $engine->create_package() }, qr/Validation failed/, 'Validation failed' );

my $str = '';
throws_ok( sub { $engine->create_package(\$str) }, qr/Empty String/, 'Validation failed' );
throws_ok( sub { $engine->create_package(\$str) }, 'BPM::Engine::Exception::Model', 'Validation failed' );
throws_ok( sub { $engine->create_package($str) }, qr/Empty file/, 'Empty String' );
throws_ok( sub { $engine->create_package($str) }, 'BPM::Engine::Exception::Model', 'Validation failed' );

my $doc = XML::LibXML->new->parse_string('<root/>');
throws_ok( sub { $engine->create_package($doc) }, qr/XPDLVersion not defined/, 'Validation failed' );
throws_ok( sub { $engine->create_package($doc) }, 'BPM::Engine::Exception::Model', 'Validation failed' );

is($engine->list_packages->count, 0, 'No Packages');

$package = $engine->create_package('./t/var/samples.xpdl');
isa_ok($package,'BPM::Engine::Store::Result::Package');

is($package->package_uid, 'samples');
is($engine->list_packages->count, 1, 'Package created');
is($engine->list_process_definitions->count, 9, 'Processes created');

#-- list_packages

is($engine->list_packages->count, 1, 'Package created');
$package = $engine->list_packages->first;
isa_ok($package,'BPM::Engine::Store::Result::Package');

#-- list_process_definitions

$process = $engine->list_process_definitions({ process_uid => 'multi-inclusive-split-and-join' })->first;
isa_ok($process, 'BPM::Engine::Store::Result::Process');

#-- get_process_definition

throws_ok( sub { $engine->get_process_definition() },         qr/Validation failed/, 'Validation failed' );
throws_ok( sub { $engine->get_process_definition('string') }, qr/Validation failed/, 'Validation failed' );

$process = $engine->get_process_definition($process->id);
isa_ok($process, 'BPM::Engine::Store::Result::Process');

#-- delete_package

throws_ok( sub { $engine->delete_package() },          qr/Validation failed/, 'Validation failed' );
throws_ok( sub { $engine->delete_package('string') },  qr/Validation failed/, 'Validation failed' );
throws_ok( sub { $engine->delete_package(1) },         qr/Validation failed/, 'Validation failed' );

$engine->delete_package($package->id);
is($engine->list_packages->count, 0, 'Package deleted');
is($engine->list_process_definitions->count, 0, 'Process deleted');

#-- ProcessInstance Methods (Handler::ProcessInstanceHandler)
#----------------------------------------------------------------------------

$engine->create_package('./t/var/samples.xpdl');
my @procs = $engine->list_process_definitions({ process_uid => 'unstructured-inclusive-tasks' })->all;
is(@procs, 1);
$process = shift @procs;
isa_ok($process, 'BPM::Engine::Store::Result::Process');

#-- create_process_instance

throws_ok( sub { $engine->create_process_instance() },          qr/Validation failed/, 'Validation failed' );
throws_ok( sub { $engine->create_process_instance('string') },  qr/Validation failed/, 'Validation failed' );
throws_ok( sub { $engine->create_process_instance(987654321) }, qr/Process '987654321' not found/, 'Validation failed' );
throws_ok( sub { $engine->create_process_instance(987654321) }, 'BPM::Engine::Exception::Database', 'Validation failed' );

ok(my $pi0 = $engine->create_process_instance($process->id));
isa_ok($pi0, 'BPM::Engine::Store::Result::ProcessInstance');

ok(my $pi = $engine->create_process_instance($process));
isa_ok($pi, 'BPM::Engine::Store::Result::ProcessInstance');

#-- list_process_instances

is($engine->list_process_instances->count, 2, 'Two process instances found');
my $first_pi = $engine->list_process_instances->first;
isa_ok($first_pi, 'BPM::Engine::Store::Result::ProcessInstance');
is($pi0->id, $first_pi->id, 'Created process instance found in list');

#-- get_process_instance

throws_ok( sub { $engine->get_process_instance() },          qr/Validation failed/, 'Validation failed' );
throws_ok( sub { $engine->get_process_instance('string') },  qr/Validation failed/, 'Validation failed' );
throws_ok( sub { $engine->get_process_instance(987654321) }, qr/Process instance '987654321' not found/, 'Validation failed' );
throws_ok( sub { $engine->get_process_instance(987654321) }, 'BPM::Engine::Exception::Database', 'Validation failed' );

ok($first_pi = $engine->get_process_instance($first_pi->id));
isa_ok($first_pi, 'BPM::Engine::Store::Result::ProcessInstance');
is($first_pi->workflow_instance->state->name, 'open.not_running.ready');
is($first_pi->state, 'open.not_running.ready');

#-- start_process_instance

throws_ok( sub { $engine->start_process_instance() },          qr/Validation failed/, 'Validation failed' );
throws_ok( sub { $engine->start_process_instance('string') },  qr/Validation failed/, 'Validation failed' );
throws_ok( sub { $engine->start_process_instance(987654321) }, qr/Process instance '987654321' not found/, 'Validation failed' );
throws_ok( sub { $engine->start_process_instance(987654321) }, 'BPM::Engine::Exception::Database', 'Validation failed' );

my $args = { splitA => 'B1', splitB => 'B1' };
$engine->start_process_instance($pi, $args);
#warn "process " . $ai ? 'completed' : 'running';
is($pi->workflow_instance->state->name, 'closed.completed');
is($pi->state, 'closed.completed');

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

#is($engine->list_activity_instances->count, 7);
my $ai = $engine->list_activity_instances->first;
isa_ok($ai, 'BPM::Engine::Store::Result::ActivityInstance');

#-- get_activity_instance

throws_ok( sub { $engine->get_activity_instance() },          qr/Validation failed/, 'Validation failed' );
throws_ok( sub { $engine->get_activity_instance('string') },  qr/Validation failed/, 'Validation failed' );
throws_ok( sub { $engine->get_activity_instance(987654321) }, 'BPM::Engine::Exception::Database', 'Record not found' );

ok($ai = $engine->get_activity_instance($ai->id));
isa_ok($ai, 'BPM::Engine::Store::Result::ActivityInstance');

#-- change_activity_instance_state

#ok($engine->change_activity_instance_state($ai->id, 'finish'));

#-- activity_instance_attribute

throws_ok(
    sub { $engine->activity_instance_attribute($ai->id, 'UnknownVar') },
    qr/Attribute named 'UnknownVar' not found/, 'Validation failed'
    );
throws_ok(
    sub { $engine->activity_instance_attribute($ai->id, 'UnknownVar') },
    'BPM::Engine::Exception::Database', 'Validation failed'
    );

ok($ai->add_to_attributes({
    name => 'SomeVar',
    value => 'SomeVal',
    }));

is($engine->activity_instance_attribute($ai->id, 'SomeVar')->value, 'SomeVal');
ok($engine->activity_instance_attribute($ai->id, 'SomeVar', 'OtherValue'));
is($engine->activity_instance_attribute($ai->id, 'SomeVar')->value, 'OtherValue');

undef $engine;

done_testing();
