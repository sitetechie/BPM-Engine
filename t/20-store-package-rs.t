
use strict;
use warnings;
use lib './t/lib';
use Test::More;

use BPM::Engine::TestUtils qw/setup_db teardown_db schema $dsn/;

BEGIN { setup_db }
END   { teardown_db }

my $xml = qq!
<Package>
    <WorkflowProcesses>
        <WorkflowProcess Id="OrderPizza" Name="Order Pizza">
            <Activities>
                <Activity Id="PlaceOrder" />
                <Activity Id="WaitForDelivery" />
                <Activity Id="PayPizzaGuy" />
            </Activities>
            <Transitions>
                <Transition Id="1" From="PlaceOrder" To="WaitForDelivery"/>
                <Transition Id="2" From="WaitForDelivery" To="PayPizzaGuy"/>
            </Transitions>
        </WorkflowProcess>
    </WorkflowProcesses>
</Package>
!;

my $schema = schema();
my $rs = $schema->resultset('Package');

my $package = $rs->create_from_xml($xml);
isa_ok($package, 'BPM::Engine::Store::Result::Package');

my $process = $package->processes->first;
isa_ok($process, 'BPM::Engine::Store::Result::Process');
is($process->process_uid, 'OrderPizza', 'Process id matches');

is($rs->count, 1);
is($schema->resultset('Process')->count, 1);

$package->delete();
is($rs->count, 0);
is($schema->resultset('Process')->count, 0);

{
foreach(qw/
  01-basic.xpdl
  02-branching.xpdl
  06-iteration.xpdl
  07-termination.xpdl
  samples.xpdl
  /){
    my $package = $rs->create_from_xpdl('./t/var/' . $_);
    isa_ok($package, 'BPM::Engine::Store::Result::Package');
    my $process = $package->processes->first;
    isa_ok($process, 'BPM::Engine::Store::Result::Process');
    #is($process->process_uid, 'multi-inclusive-split-and-join', 'Process id matches');

    my @res = $package->processes->all;
    ok(@res > 1, 'processes stored');
    $process = $res[0];
    isa_ok($process, 'BPM::Engine::Store::Result::Process');
    }
}

done_testing;
