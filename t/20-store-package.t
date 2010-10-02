
use strict;
use warnings;
use lib './t/lib';
use Test::More qw/no_plan/;

use BPME::TestUtils qw/setup_db rollback_db schema $dsn/;

BEGIN { setup_db }
END   { rollback_db }

my $schema = schema();
my $rs = $schema->resultset('Package');

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

{
my $package = $rs->create_from_xml($xml);
isa_ok($package, 'BPM::Engine::Store::Result::Package');

my $process = $package->processes->first;
isa_ok($process, 'BPM::Engine::Store::Result::Process');
is($process->process_uid, 'OrderPizza', 'Process id matches');
}

{
my $package = $rs->create_from_xpdl('./t/var/or.xpdl');
isa_ok($package, 'BPM::Engine::Store::Result::Package');

my $process = $package->processes->first;
isa_ok($process, 'BPM::Engine::Store::Result::Process');
is($process->process_uid, 'multi-inclusive-split-and-join', 'Process id matches');

my @res = $package->processes->all;
is(@res, 1, 'process stored');
$process = $res[0];
isa_ok($process, 'BPM::Engine::Store::Result::Process');
}

