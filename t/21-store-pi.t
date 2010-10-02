
use strict;
use warnings;
use lib './t/lib';
use Test::More;

use BPME::TestUtils qw/setup_db rollback_db schema $dsn/;

BEGIN { setup_db }
END   { rollback_db }

my $schema = schema();
$schema->resultset('Package')->create_from_xpdl('./t/var/or.xpdl');

#-- get the first process definition
my $process = $schema->resultset('Process')->search->first;
my $p_meta = $process->meta;
ok($p_meta->does_role('BPM::Engine::Store::ResultBase::Process'), '... Process->meta does_role Store::ResultBase::Process');

#- create a new process instance
my $pi = $process->new_instance();
my $pi_meta = $pi->meta;
ok($pi_meta->does_role('BPM::Engine::Store::ResultBase::ProcessInstance'), '... ProcessInstance->meta does_role Store::ResultBase::ProcessInstance');

#- get the first activity
my $from_act = $pi->process->start_activities->[0];
my $act_meta = $from_act->meta;
isa_ok($act_meta, 'Moose::Meta::Class');
ok($act_meta->does_role('BPM::Engine::Store::ResultBase::Activity'), '... Activity->meta does_role Store::ResultBase::Activity');
ok($act_meta->does_role('Class::Workflow::State'), '... Activity->meta does_role Class::Workflow::State');
ok($act_meta->does_role('Class::Workflow::State::TransitionHash'), '... Activity->meta does_role Class::Workflow::State::TransitionHash');
ok($act_meta->does_role('Class::Workflow::State::AcceptHooks'), '... Activity->meta does_role Class::Workflow::State::AcceptHooks');
ok($act_meta->does_role('Class::Workflow::State::AutoApply'), '... Activity->meta does_role Class::Workflow::State::AutoApply');

#- create a new activity instance
#my $from_instance = $pi->add_to_activity_instances({
#        activity_id => $from_act->id,
#        workflow_instance_id => $schema->resultset('ActivityInstanceState')->create({ state => 'open.not_running.not_assigned' })->id,
#        });
my $from_instance = $from_act->new_instance({
    process_instance_id => $pi->id,
    });
my $ai_meta = $from_instance->meta;

#- get the first transition
my $transition = $from_act->transitions->first;
my $t_meta = $transition->meta;
ok($t_meta->does_role('BPM::Engine::Store::ResultBase::ProcessTransition'), '... Transition->meta does_role Store::ResultBase::ProcessTransition');
ok($t_meta->does_role('Class::Workflow::Transition'), '... Transition->meta does_role Class::Workflow::Transition');
ok($t_meta->does_role('Class::Workflow::Transition::Validate::Simple'), '... Transition->meta does_role Class::Workflow::Transition::Validate::Simple');
ok(!$t_meta->does_role('Class::Workflow::Transition::Deterministic'), '... Transition->meta does not do role Class::Workflow::Transition::Deterministic');
ok(!$t_meta->does_role('Class::Workflow::Transition::Strict'), '... Transition->meta does not do role Class::Workflow::Transition::Strict');

$transition->ignore_validator_rv(1);
$transition->no_die(1);
$transition->clear_validators;
#$transition->add_validators( sub { die('invalid') } );
#$transition->add_validators( sub { 1 == 0 } );
$transition->add_validators( sub { 1 == 1 } );

#- apply the transition
my $instance = $transition->apply($from_instance);
my $ni_meta = $instance->meta;
ok($ni_meta->does_role('BPM::Engine::Store::ResultBase::ActivityInstance'), '... ActivityInstance->meta does_role Store::ResultBase::ActivityInstance');
ok(!$ni_meta->does_role('Class::Workflow::Instance'), '... ActivityInstance->meta does not do role Class::Workflow::Instance');

#- get the next activity
my $activity = $instance->activity;
isa_ok($activity, 'BPM::Engine::Store::Result::Activity');

done_testing();
