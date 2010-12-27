use strict;
use warnings;
use lib './t/lib';
use Test::More;
use BPM::Engine::TestUtils qw/setup_db teardown_db process_wrap/;

BEGIN { setup_db }
END   { teardown_db }

my ($e,$process) = process_wrap();
my $pi = $process->new_instance();

my $formals = [
    {"Id"=>"counter","Mode"=>"OUT","DataType"=>{"BasicType"=>{"Type"=>"INTEGER"}}}
    ];
my $actuals = ['openedBranchesFromA'];
my $param = $formals->[0];

eval {
    $pi->add_to_attributes({
                name => $param->{Id},
                mode => $param->{Mode},
                type => $param->{DataType}->{BasicType}->{Type},
                value => 55,
                });
    };
is($pi->attribute('counter')->value,55);
my $attr = $pi->attribute('counter');
isa_ok($attr,'BPM::Engine::Store::Result::ProcessInstanceAttribute');

$attr->value('56');
$attr->update;
#$pi->attribute('counter')->update();
is($attr->value,'56');
is($pi->attribute('counter')->value,'56');

#$attr->value('55');
#$attr->update;

$attr->update({ value => 55 });
is($attr->value,'55');
is($pi->attribute('counter')->value,'55');

$pi->attribute('counter')->update({ value => '57' });
is($pi->attribute('counter')->value,'57');

done_testing;
