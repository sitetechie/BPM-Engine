
use strict;
use warnings;
use lib './t/lib';
use Test::More;
use DateTime;
use BPM::Engine::TestUtils qw/setup_db teardown_db $dsn schema/;

BEGIN { setup_db }
END   { teardown_db }

my $schema = schema();
my $rs = $schema->resultset('ActivityInstance');
for(1..5) {
  my $params = {
    process_instance_id => $_ < 3 ? 1 : 2,
    activity_id => 1,
    transition_id => 1,
    prev => 1,
    };
  $params->{deferred} = DateTime->now() if($_ < 3);
  if($_ == 5) {
    $params->{completed} = DateTime->now();
    }
  $rs->create($params);
  }

is($rs->count(), 5);
is($rs->active->count(), 2);
is($rs->active_or_deferred->count(), 4);
is($rs->active_or_completed->count(), 3);
is($rs->deferred->count(), 2);
is($rs->completed->count(), 1);

is($rs->completed->count({ process_instance_id => 1 }), 0);
is($rs->completed({ process_instance_id => 1 })->count, 0);

is($rs->completed->count({ process_instance_id => 2 }), 1);
is($rs->completed({ process_instance_id => 2 })->count, 1);

ok($rs->find(5)->is_completed);
ok($rs->find(3)->is_active);
ok($rs->find(1)->is_deferred);

$rs->find(1)->update({ deferred => \'NULL' });
$rs->find(2)->update({ deferred => undef });
is($rs->deferred->count(), 0);

done_testing;
