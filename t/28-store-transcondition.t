
use strict;
use warnings;
use lib './t/lib';
use Test::More;
use Test::Exception;
use BPM::Engine::TestUtils qw/setup_db teardown_db process_wrap schema runner/;

use BPM::Engine;
use BPM::Engine::Store;
use DateTime;
use Data::Dumper;

BEGIN { setup_db; }
END   { teardown_db; }

my ($engine, $process);


#-- OR inclusive join
# after all valid transitions join fires
if(1) {
    my $x = '<Activities>
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

# before apply
$tAB->clear_validators();
$tAB->add_validator(sub {
    my ($transition, $activity_instance, $cmd) = @_;
    die("No command") unless $cmd;
    die("Something wrong") if $cmd eq 'die';
    return 0 if $cmd eq 'false';
    return 1 if $cmd eq 'true';
    die("Wrong command $cmd");
    });
# around apply
ok($tAB->validate($aiA, 'true')); # condition true
throws_ok(sub { $tAB->validate($aiA, 'false') }, 'BPM::Engine::Exception::Condition', 'condition false');
throws_ok(sub { $tAB->validate($aiA, 'false') }, qr/Condition\s+\(boolean\)\s+false/, 'condition false');
throws_ok(sub { $tAB->validate($aiA, 'die') }, qr/wrong/, 'dies ok');
throws_ok(sub { $tAB->validate($aiA, 'die') }, 'BPM::Engine::Exception', 'dies ok');
throws_ok(sub { $tAB->validate($aiA) }, qr/No command/, 'dies ok');
throws_ok(sub { $tAB->validate($aiA) }, 'BPM::Engine::Exception', 'dies ok');
$tAB->clear_validators();

# apply with false condition
$tAB->update({
    condition_expr => '1 + 2 - 3',
    condition_type => 'CONDITION',
    });
ok(!eval { $tAB->apply($aiA); });
throws_ok(sub { $tAB->apply($aiA) }, qr/Condition\s+\(boolean\)\s+false/);
throws_ok(sub { $tAB->apply($aiA) }, 'BPM::Engine::Exception::Condition');

$tAB->update({ condition_expr => '3' });
throws_ok(sub { $tAB->apply($aiA) }, qr/Condition evalutation did not result in a true boolean/);
throws_ok(sub { $tAB->apply($aiA) }, 'BPM::Engine::Exception::Expression');

$tAB->update({ condition_expr => 'Some string' });
throws_ok(sub { $tAB->apply($aiA) }, qr/parse error.*unexpected token/);
throws_ok(sub { $tAB->apply($aiA) }, 'BPM::Engine::Exception::Expression');

$tAB->update({ condition_expr => '"Some string"' });
throws_ok(sub { $tAB->apply($aiA) }, qr/Condition evalutation did not result in a boolean/);
throws_ok(sub { $tAB->apply($aiA) }, 'BPM::Engine::Exception::Expression');

$tAB->update({ condition_type => 'NONE' });

    my $aiB = eval { $tAB->apply($aiA); };
    ok($aiB);

    my $aiC = eval { $tAC->apply($aiA); };

    $aiC = eval { $tBC->apply($aiB); };
    ok($aiC);
    ok(!$aiC->is_enabled);

    my $aiD = eval { $tBD->apply($aiB); };
   #ok($aiC->is_enabled);

    $aiD = eval { $tCD->apply($aiC); };
    ok($aiD);
    ok(!$aiD->is_enabled);    
}

done_testing();
