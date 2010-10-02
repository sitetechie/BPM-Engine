
use strict;
use warnings;
use lib './t/lib';
use Test::More;
use Test::Exception;

use BPME::TestUtils qw/setup_db rollback_db process_wrap schema runner/;

BEGIN { setup_db; }
END   { rollback_db; }

use BPM::Engine;
my ($engine, $process);

#-- OR inclusive join
# after all valid transitions join fires
{
    my $x = '
            <Activities>
                <Activity Id="A">
                    <TransitionRestrictions>
                        <TransitionRestriction>
                            <Split Type="Inclusive">
                                <TransitionRefs>
                                    <TransitionRef Id="A-B"/>
                                    <TransitionRef Id="A-C"/>
                                </TransitionRefs>
                            </Split>
                        </TransitionRestriction>
                    </TransitionRestrictions>
                </Activity>
                <Activity Id="B" StartMode="Manual" FinishMode="Manual">
                    <TransitionRestrictions>
                        <TransitionRestriction>
                            <Split Type="Inclusive">
                                <TransitionRefs>
                                    <TransitionRef Id="B-C"/>
                                    <TransitionRef Id="B-D"/>
                                </TransitionRefs>
                            </Split>
                        </TransitionRestriction>
                    </TransitionRestrictions>
                </Activity>
                <Activity Id="C" StartMode="Manual" FinishMode="Manual">
                    <TransitionRestrictions>
                        <TransitionRestriction>
                            <Join Type="Inclusive"/>
                        </TransitionRestriction>
                    </TransitionRestrictions>
                </Activity>
                <Activity Id="D" StartMode="Manual" FinishMode="Manual">
                    <TransitionRestrictions>
                        <TransitionRestriction>
                            <Join Type="Inclusive"/>
                        </TransitionRestriction>
                    </TransitionRestrictions>
                </Activity>
            </Activities>
            <Transitions>
                <Transition Id="A-B" From="A" To="B"/>
                <Transition Id="A-C" From="A" To="C"/>
                <Transition Id="B-C" From="B" To="C"/>
                <Transition Id="B-D" From="B" To="D"/>
                <Transition Id="C-D" From="C" To="D"/>
            </Transitions>
    ';

    #$x =~ s/StartMode="Manual" FinishMode="Manual"//g;
    ($engine, $process) = process_wrap($x);
    ok($process);

    #-- step through the process

    my $aiA = $process->start_activities->[0]->new_instance({
        process_instance_id => $process->new_instance->id
        });

    my $tAB = $process->transitions->find({ transition_uid => 'A-B' });
    my $tAC = $process->transitions->find({ transition_uid => 'A-C' });
    my $tBC = $process->transitions->find({ transition_uid => 'B-C' });
    my $tBD = $process->transitions->find({ transition_uid => 'B-D' });
    my $tCD = $process->transitions->find({ transition_uid => 'C-D' });

    my $aiB = eval { $tAB->apply($aiA); };
    ok($aiB);
    #ok($aiB->join_should_fire);

    my $aiC = eval { $tAC->apply($aiA); };
   # ok(!$aiC);
    #ok($aiB->join_should_fire);

    $aiC = eval { $tBC->apply($aiB); };
    ok($aiC);
    ok(!$aiC->join_should_fire);

    my $aiD = eval { $tBD->apply($aiB); };
   # ok(!$aiD);
   # ok($aiC->join_should_fire);

    $aiD = eval { $tCD->apply($aiC); };
    ok($aiD);
    ok(!$aiD->join_should_fire);    
}

# OR split/join
{
    $engine = BPM::Engine->new(schema => schema());
    $engine->create_package('./t/var/or.xpdl');

    my ($r,$p,$i) = runner($engine, 'multi-inclusive-split-and-join', { splitA => 'B1', splitB => undef });

    #my $tAB = $p->transitions->find({ transition_uid => 'A-B' });
    #my $tAC = $p->transitions->find({ transition_uid => 'A-C' });
    #my $tBC = $p->transitions->find({ transition_uid => 'B-C' });
    #my $tBD = $p->transitions->find({ transition_uid => 'B-D' });
    #my $tCD = $p->transitions->find({ transition_uid => 'C-D' });

    my $activity = $p->start_activities->[0];
    my $ai_A = #$r->_create_activity_instance($activity);
        $activity->new_instance({ 
                process_instance_id => $i->id 
                });
    # main path (before splitted or after joined) doesn't have a parent_token
    # OR any ai not directly after a split doesn't have a parent_token, use ->prev instead ??
    ok(!$ai_A->parent_token_id, 'A has no parent');
    ok(!$ai_A->prev, 'A has no previous');

# B1-JOIN

    #- follow transition A-B1 (split->join)
    #-----------------------------------------
    my $t_A_B1 = $activity->transitions->find({ transition_uid => 'A-B1'});    
    my $a_B1 = $t_A_B1->to_activity;
    my $attrs = { activity => $a_B1,  };
    my @args = ();

    my $ai_B1 = $t_A_B1->derive_and_accept_instance($ai_A, $attrs, @args);
    is($ai_B1->activity->activity_uid, 'B1','derive_and_accept results in B1');

    # transition in joinA set to 'taken' since we're coming from a split    
    is($ai_A->join->states->{$t_A_B1->id}, 'taken', "Transition A-B1 state is 'taken'");

    # after a split, the parent_token of the new ai is set to the split-ai
    is($ai_B1->parent_token_id, $ai_A->id, 'Parent matches');
    is($ai_B1->parent->id, $ai_A->id, 'Parent matches');
    is($ai_B1->prev->id, $ai_A->id, 'Prev matches');

    # join B1 should fire, since we didn't follow the path from A to B
    ok($ai_B1->join_should_fire(), 'Join B1 should fire');
    $ai_A->join->discard_changes();
    is($ai_A->join->states->{$t_A_B1->id}, 'joined', "Transition A-B1 state is 'joined'");
    is($ai_B1->prev->join->states->{$t_A_B1->id}, 'joined', "Transition A-B1 state is 'joined'");


    #- follow transition A-B (split->split)
    #-----------------------------------------
    my $t_A_B = $activity->transitions->find({ transition_uid => 'A-B'});
    my $a_B = $t_A_B->to_activity;
    $attrs = { activity => $a_B  };
    @args = ();

    my $ai_B = $t_A_B->derive_and_accept_instance($ai_A, $attrs, @args);
    is($ai_B->activity->activity_uid, 'B','derive_and_accept results in B');

    # transition in joinA set to 'taken' since we're coming from a split    
    $ai_A->join->discard_changes();
    is($ai_A->join->states->{$t_A_B->id}, 'taken', "Transition A-B state is 'taken'");
    is($ai_A->join->states->{$t_A_B1->id}, 'joined', "Transition A-B1 state is still 'joined'");

    # now join B1 should NOT fire, since the path from A to B didn't come in yet
    ok(!$ai_B1->join_should_fire(), 'Join B1 should not fire anymore');

    #- follow transition B-B1 (split->join)
    #-----------------------------------------
    my $t_B_B1 = $a_B->transitions->find({ transition_uid => 'B-B1'});
    $attrs = { activity => $a_B1 }; # $t_B_B1->to_activity
    @args = ();

    my $ai_B1b = $t_B_B1->derive_and_accept_instance($ai_B, $attrs, @args);
    is($ai_B1b->activity->activity_uid, 'B1','derive_and_accept results in B1');

    # transition in join-for-split set to 'taken'
    is($ai_B->join->states->{$t_B_B1->id}, 'taken');

    # join B1 should now fire, as seen from all sides
    ok($ai_B1b->join_should_fire(), 'Join B1b should also fire');
    ok($ai_B1->join_should_fire(), 'Join B1 should now fire again');

# C-JOIN

    #- follow transition B1-B2 (join->split)
    #-----------------------------------------
    my $t_B1_B2 = $a_B1->transitions->find({ transition_uid => 'B1-B2'});
    my $a_B2 = $t_B1_B2->to_activity;
    $attrs = { activity => $a_B2  };

    my $ai_B2 = $t_B1_B2->derive_and_accept_instance($ai_B1, $attrs, @args);
    is($ai_B2->activity->activity_uid, 'B2','derive_and_accept results in B2');

    #- follow transition B-C (split->join)
    #-----------------------------------------
    my $t_B_C = $a_B->transitions->find({ transition_uid => 'B-C'});
    my $a_C = $t_B_C->to_activity;
    $attrs = { activity => $a_C  };

    my $ai_C = $t_B_C->derive_and_accept_instance($ai_B, $attrs, @args);
    is($ai_C->activity->activity_uid, 'C','derive_and_accept results in C');    

    ok(!$ai_C->join_should_fire(), 'Join C should not fire yet');

    #- follow transition B2-C (split->join)
    #-----------------------------------------
    my $t_B2_C = $a_B2->transitions->find({ transition_uid => 'B2-C'});
    $attrs = { activity => $t_B2_C->to_activity,  };

    my $ai_Cb = $t_B2_C->derive_and_accept_instance($ai_B2, $attrs, @args);
    is($ai_Cb->activity->activity_uid, 'C','derive_and_accept results in C');

    # join C should now fire from either B or B2
    ok($ai_Cb->join_should_fire(), 'Join C should now fire');
#  ok($ai_C->join_should_fire(), 'Join C should now fire');

# D-JOIN

    #- follow transition B2-D (split->join)
    #-----------------------------------------
    my $t_B2_D = $a_B2->transitions->find({ transition_uid => 'B2-D'});
    my $a_D = $t_B2_D->to_activity;
    $attrs = { activity => $a_D  };

    # join D should not fire, path C-D hasn't come in yet
    #ok(!$a_D->should_join_fire($t_B2_D, $ai_B2), 'Join should not fire from B2');
    
    my $ai_D = $t_B2_D->derive_and_accept_instance($ai_B2, $attrs, @args);
    is($ai_D->activity->activity_uid, 'D','derive_and_accept results in D');

#  ok(!$ai_D->join_should_fire(), 'Join D should not fire yet');

    #- follow transition C-D (join->join)
    #-----------------------------------------
    my $t_C_D = $a_C->transitions->find({ transition_uid => 'C-D'});
    $attrs = { activity => $a_D,  };

    # join D should now fire
    #ok($a_D->should_join_fire($t_C_D, $ai_C), 'Join D should fire from C');
    # and also from B2, now
    #ok($a_D->should_join_fire($t_B2_D, $ai_B2), 'Join D should fire from B2'); # SHOULD DIE DOUBLE DIP

    my $ai_Db = $t_C_D->derive_and_accept_instance($ai_C, $attrs, @args);
    is($ai_Db->activity->activity_uid, 'D','derive_and_accept results in D');

#  ok($ai_Db->join_should_fire(), 'Join D should now fire');

}

done_testing();
