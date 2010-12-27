use strict;
use warnings;
use lib './t/lib';
use Test::More;
use BPM::Engine::TestUtils qw/setup_db teardown_db process_wrap schema runner/;

BEGIN { setup_db; }
END   { teardown_db; }

no warnings 'redefine';
sub diag {}
use warnings;

use_ok('BPM::Engine');

my $DEBUG = 0;

can_ok('BPM::Engine::ProcessRunner', qw/
    start_process
    complete_process
    start_activity
    continue_activity
    complete_activity
    /);

my $engine = BPM::Engine->new(
    log_dispatch_conf => {
        class     => 'Log::Dispatch::Screen',
        min_level => $DEBUG ? 'debug' : 'warning',
        stderr    => 1,
        format    => '[%p] %m at %F line %L%n',
        },
    schema => schema(),
    callback => sub {
        my($runner, $entity, $event, $node, $instance) = @_;
#        return 1 if ($entity eq 'activity' || $event ne 'execute');
        my $act = $entity eq 'process' ? $node->process_uid :
            ($entity eq 'transition' ? $node->transition_uid : $instance->activity->activity_uid);
        diag "$event $entity $act"; # unless $entity eq 'task';
        #return 0 if (($entity eq 'route' || $entity eq 'task') && $event eq 'execute'); # halts execution
        return 0 if ($entity eq 'activity' && $event eq 'execute'); # halts execution
        return 1;    
        },
    );

my ($runner, $process, $pi) = ();

my $complete_active = sub {
  #warn "\n\n--- Completing active instances ---";
  my @ais = $engine->list_activity_instances({
    process_instance_id => $pi->id
    })->active->all;
  #is(scalar @ais, 1, 'just one active instance'); # just B
  foreach my $ai(@ais) {
    diag "--- Completing active " . $ai->activity->activity_uid;
    $runner->complete_activity($ai->activity, $ai, 1);
    }
  };

sub test_state {
    my (%args) = @_;
    
    my $rs_def = $engine->list_activity_instances->deferred({
        process_instance_id => $pi->id,
        });

    my $rs_act = $engine->list_activity_instances({
        process_instance_id => $pi->id
        #parent_token_id => $ai->parent_token_id,
        })->active;

    my $rs_cmp = $engine->list_activity_instances({
        process_instance_id => $pi->id
        })->completed;

    $args{active} ||= [];
    $args{deferred} ||= [];
    $args{completed} ||= [];

    my $cmp = [ sort map { /^(.*)-X?OR/ ? $1 : $_ } map { /\.(.*)/ ? $1 : $_ } map { $_->activity->activity_uid } $rs_cmp->all ];
    is_deeply( $cmp, [ sort @{$args{completed}} ], 'completed - expecting ' . join(', ',@{$args{completed}}) . ', got ' . join(', ', @{$cmp}));

    my $act = [ sort map { /^(.*)-X?OR/ ? $1 : $_ } map { /\.(.*)/ ? $1 : $_ } map { $_->activity->activity_uid } $rs_act->all ];
    is_deeply( $act, [ sort @{$args{active}} ],    'active - expecting ' . join(', ',@{$args{active}}) . ', got ' . join(', ', @{$act}));

    my $def = [ sort map { /^(.*)-X?OR/ ? $1 : $_ } map { /\.(.*)/ ? $1 : $_ } map { $_->activity->activity_uid } $rs_def->all ];
    is_deeply( $def, [ sort @{$args{deferred}} ],  'deferred - expecting ' . join(', ',@{$args{deferred}}) . ', got ' . join(', ', @{$def}));
    }

$engine->create_package('./t/var/samples.xpdl');
$engine->create_package('./t/var/02-branching.xpdl');
$engine->create_package('./t/var/06-iteration.xpdl');

diag('inclusive-tasks');
if(1) {
  my $params = { splitA => undef, splitB => undef, splitB2 => 'C' };
  ($runner, $process, $pi) = runner($engine, 'unstructured-inclusive-tasks', $params);
  $pi->apply_transition('start');

  my $act = $process->start_activities->[0];
  my $aiA = $act->new_instance({
    process_instance_id => $pi->id
    });
  is($aiA->workflow_instance->state->name, 'open.not_running.ready');
  $runner->start_activity($act, $aiA, 1);
  is($aiA->workflow_instance->state->name, 'open.running.assigned');

  #$runner->complete_activity($act, $aiA, 1);
  &$complete_active;  # complete A

  $aiA->discard_changes();
  is($aiA->workflow_instance->state->name, 'closed.completed');

  diag "--- A completed, B active, B1 deferred";
  test_state(completed => ['A'], active => ['B'], deferred => ['B1']);

  &$complete_active;  # complete B
  diag "--- A+B+B1 completed, B1 active, C deferred";
  test_state(completed => ['A','B','B1'], active => ['B1'], deferred => ['C']);

  &$complete_active;  # complete B1
  diag "--- B2 active";
  test_state(completed => ['A','B','B1','B1'], active => ['B2'], deferred => ['C']);

  &$complete_active;  # complete B2
  diag "--- C active";
  test_state(completed => ['A','B','B1','B1','B2','C'], active => ['C'], deferred => ['D']);

  &$complete_active;  # complete C
  diag "--- D active";
  test_state(completed => ['A','B','B1','B1','B2','C','C','D'], active => ['D'], deferred => []);

  &$complete_active;  # complete D
  diag "--- D completed"; 
  test_state(completed => ['A','B','B1','B1','B2','C','C','D','D'], active => [], deferred => []);

  is($pi->workflow_instance->state->name, 'closed.completed');
}

diag('inclusive-tasks 2');
if(1){
  my $params = { splitA => 'B', splitB => 'C', splitB2 => 'D' };
#'inclusive-splits-and-joins'
  ($runner, $process, $pi) = runner($engine, 'unstructured-inclusive-tasks', $params);
  $pi->apply_transition('start');

  my $act = $process->start_activities->[0];
  my $aiA = $act->new_instance({
    process_instance_id => $pi->id
    });
  $runner->start_activity($act, $aiA, 1);
  &$complete_active;
  diag "--- A completed, B active, no deferred";
  test_state(completed => ['A'], active => ['B'], deferred => []);

  &$complete_active; # complete B
  diag "--- A+B completed, C active, no deferred";
  test_state(completed => ['A','B'], active => ['C'], deferred => []);

  &$complete_active;
  diag "--- A+B+C completed, D active, no deferred";
  test_state(completed => ['A','B','C'], active => ['D'], deferred => []);

  &$complete_active;
  diag "--- A+B+C+D completed";
  test_state(completed => ['A','B','C','D'], active => [], deferred => []);

  is($pi->workflow_instance->state->name, 'closed.completed');
}

# scenario:
# - take paths B and C
# - SM from B not is_enabled(), gets deferred
# - take path DC-E, block DC-D
# - find deferred SM, now is_enabled() so fire_join() and follow transition SM-End

diag('Local Synchronizing Merge');
if(1){
  my $params = { multi_choice => 'B,C', deferred_choice => undef };
  ($runner, $process, $pi) = runner($engine, 'wcp37', $params);
  $pi->apply_transition('start');

  my $act = $process->start_activities->[0];
  my $aiMC = $act->new_instance({
    process_instance_id => $pi->id
    });
  is($aiMC->workflow_instance->state->name, 'open.not_running.ready');

  $runner->start_activity($act, $aiMC, 1);
  is($aiMC->workflow_instance->state->name, 'open.running.assigned');

  &$complete_active; # complete MC
  test_state(completed => ['MC'], active => ['B','C'], deferred => []);

  &$complete_active; # complete B+C
  test_state(completed => [qw/B C MC/], active => [qw/DC/], deferred => [qw/SM/]);

  &$complete_active; # complete DC
  test_state(completed => [qw/B C DC MC/], active => [qw/E SM/], deferred => [qw//]);
  # when activating deferreds from processrunner, active contains SM
  # (preferred strategy), otherwise End has to take care of executing SM (bad)

  &$complete_active; # complete E+SM, which sets first End from deferred to completed when enabling second End
  test_state(completed => [qw/B C DC E End MC SM/], active => [qw/End/], deferred => []);

  &$complete_active; # complete End
  test_state(completed => [qw/B C DC E End End MC SM/], active => [qw//], deferred => [qw//]);
  is($pi->workflow_instance->state->name, 'closed.completed');  
}


# scenario: 

diag('General Synchronizing Merge');
if(1) {

  my $params = { multi_choice => 'B,XOR', deferred_choice => undef };
  ($runner, $process, $pi) = runner($engine, 'wcp38', $params);
  $pi->apply_transition('start');

  my $act = $process->start_activities->[0];
  my $aiMC = $act->new_instance({
    process_instance_id => $pi->id
    });
  is($aiMC->workflow_instance->state->name, 'open.not_running.ready');

  $runner->start_activity($act, $aiMC, 1);
  is($aiMC->workflow_instance->state->name, 'open.running.assigned');

  &$complete_active;  # complete MC
  $aiMC->discard_changes();
  is($aiMC->workflow_instance->state->name, 'closed.completed');
  is($aiMC->state, 'closed.completed');
  test_state(completed => ['MC'], active => ['B','XOR'], deferred => []);

  &$complete_active;  # complete XOR + B
  test_state(completed => ['MC','B','XOR'], active => ['C'], deferred => ['SM']);

  &$complete_active;  # complete C
  test_state(completed => ['MC','B','XOR','C'], active => ['DC'], deferred => ['SM']);

  &$complete_active;  # complete DC, back to XOR
  test_state(completed => ['MC','B','XOR','C','DC'], active => ['XOR'], deferred => ['SM']);

  &$complete_active;  # complete XOR2
  test_state(completed => ['B','C','DC','MC','XOR','XOR'], active => ['C'], deferred => ['SM']);

  &$complete_active;  # complete C
  test_state(completed => ['B','C','C','DC','MC','XOR','XOR'], active => ['DC'], deferred => ['SM']);

 if(1) {
  $pi->attribute(deferred_choice => 'D');

  &$complete_active;  # complete DC, follow to D
  test_state(completed => ['B','C','C','DC','DC','MC','XOR','XOR'], active => ['D'], deferred => ['SM']);

  &$complete_active;  # complete D
  test_state(completed => [qw/B C C D DC DC MC SM XOR XOR/], active => ['SM'], deferred => []);

  &$complete_active;  # complete SM
  test_state(completed => [qw/B C C D DC DC MC SM SM XOR XOR/], active => ['End'], deferred => []);
 }
 else {
  $pi->attribute(deferred_choice => 'E');
  &$complete_active;  # complete DC, follow DC-E
  # path D was blocked, deferred SM now enabled (path D blocked in MC-localJoin), so should fire and execute
  test_state(completed => [qw/B C C DC DC MC XOR XOR/], active => ['E','SM'], deferred => []);

  &$complete_active;  # complete E+SM
  test_state(completed => [qw/B C C DC DC E End MC SM XOR XOR/], active => ['End'], deferred => []);

  &$complete_active;  # complete End
  test_state(completed => [qw/B C C DC DC E End End MC SM XOR XOR/], active => [], deferred => []);

 }
}

diag('Nested Loops');
if(1) {
#dc->join->states
#C-DC closes cycle, sets prev DC.join(XOR) to 'joined'
  my $params = { inner_loop => 1, outer_loop => 1 };
  ($runner, $process, $pi) = runner($engine, 'wcp10b2', $params);

  $pi->apply_transition('start');

  my $act = $process->start_activities->[0];
  my $ai = $act->new_instance({
    process_instance_id => $pi->id
    });
  is($ai->workflow_instance->state->name, 'open.not_running.ready');
  $runner->start_activity($act, $ai, 1);
  is($ai->workflow_instance->state->name, 'open.running.assigned');

  &$complete_active;  # complete Start
  test_state(completed => [qw/Start/], active => [qw/A/], deferred => []);

  &$complete_active;  # complete A-Join1
  test_state(completed => [qw/Start A/], active => [qw/B/], deferred => []);

  &$complete_active;  # complete B-Join2
  test_state(completed => [qw/Start A B/], active => [qw/C/], deferred => []);

 if(1) {
  &$complete_active;  # complete C-Split2, back to B-Join2 AND forward to D-Split1
  test_state(completed => [qw/Start A B C/], active => [qw/B D/], deferred => []);

  &$complete_active;  # complete B+D
  test_state(completed => [qw/Start A B C B D/], active => [qw/A C/], deferred => []);

  $pi->attribute(inner_loop => 0);

  &$complete_active;  # complete A+C
  test_state(completed => [qw/Start A B C B D A C/], active => [qw/B D/], deferred => []);

  &$complete_active;  # complete B+D
  test_state(completed => [qw/Start A B C B D A C B D/], active => [qw/C A/], deferred => []);

  &$complete_active;  # complete C+A
  test_state(completed => [qw/Start A B C B D A C B D C A/], active => [qw/D B/], deferred => []);

  $pi->attribute(outer_loop => 0);

  &$complete_active;  # complete B+D
  test_state(completed => [qw/Start A B C B D A C B D C A B D/], active => [qw/C End/], deferred => []);

  &$complete_active;  # complete C+End
  test_state(completed => [qw/Start A B C B D A C B D C A B D C End/], active => [qw/D/], deferred => []);

  &$complete_active;  # complete D
  test_state(completed => [qw/Start A B C B D A C B D C A B D C End D/], active => [qw/End/], deferred => []);

  &$complete_active;  # complete End
  test_state(completed => [qw/Start A B C B D A C B D C A B D C End D End/], active => [], deferred => []);
 }
 else {
  $pi->attribute(inner_loop => 0);

  &$complete_active;  # complete C, forward to D only
  test_state(completed => [qw/A B C Start/], active => [qw/D/], deferred => []);

  &$complete_active;  # complete D, outer-loop back-edge to A
  test_state(completed => [qw/A B D C Start/], active => [qw/A/], deferred => []);

  &$complete_active;  # complete A, follow to B (second instance)
  test_state(completed => [qw/A A B D C Start/], active => [qw/B/], deferred => []);

  &$complete_active;  # complete B (second instance), follow to C
  test_state(completed => [qw/A A B B D C Start/], active => [qw/C/], deferred => []);

  $pi->attribute(inner_loop => 1);

  &$complete_active;  # complete C, back to B AND forward to D
  test_state(completed => [qw/A A B B D C C Start/], active => [qw/B D/], deferred => []);

  $pi->attribute(outer_loop => 0);
  }
}
 



done_testing;
