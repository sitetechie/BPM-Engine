use strict;
use warnings;
use Test::More;

use t::TestUtils;

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
  08-samples.xpdl
  09-data.xpdl
  10-tasks.xpdl
  /){
#warn "Package $_";
    my $package = $rs->create_from_xpdl('./t/var/' . $_);
    isa_ok($package, 'BPM::Engine::Store::Result::Package');
    my $process = $package->processes->first;
    isa_ok($process, 'BPM::Engine::Store::Result::Process');

    my @res = $package->processes->all;
    $process = $res[0];
    isa_ok($process, 'BPM::Engine::Store::Result::Process');
    }
}

my $pack1 = q|
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<Package xmlns="http://www.wfmc.org/2008/XPDL2.1"
  xmlns:deprecated="http://www.wfmc.org/2004/XPDL2.0alpha http://www.wfmc.org/2002/XPDL1.0"
  xmlns:sitecorp="http://schemas.sitecorporation.com/bpm"
  xmlns:tns="http://schemas.xmlsoap.org/tns/"
  xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/"
  xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xmlns:xdt="http://www.w3.org/2004/07/xpath-datatypes"
  xmlns:fn="http://www.w3.org/2004/07/xpath-functions"
  xmlns:xs="http://www.w3.org/2001/XMLSchema" Id="1" Name="1">
</Package>
|;
my $pack2 = q|
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<Package xmlns="http://www.wfmc.org/2008/XPDL2.1"
         xmlns:deprecated="http://www.wfmc.org/2004/XPDL2.0alpha http://www.wfmc.org/2002/XPDL1.0"
         xmlns:sitecorp="http://schemas.sitecorporation.com/bpm"
         xmlns:tns="http://schemas.xmlsoap.org/tns/"
         xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/"
         xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xmlns:xdt="http://www.w3.org/2004/07/xpath-datatypes"
         xmlns:fn="http://www.w3.org/2004/07/xpath-functions"
         xmlns:xs="http://www.w3.org/2001/XMLSchema"
         Id="[% id %]" Name="[% title %]">
    <PackageHeader>
        <XPDLVersion>2.1</XPDLVersion>
        <Vendor>BPM::Engine</Vendor>
        <Created>2010-09-07 04:04:45</Created>
    </PackageHeader>
|;

done_testing;
