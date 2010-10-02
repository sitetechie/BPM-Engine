use strict;
use warnings;
use lib './t/lib';
use Test::More;
use Test::Exception;

use BPME::TestUtils qw/setup_db rollback_db $dsn/;

BEGIN { setup_db }
END   { rollback_db }


my $con0 = {
  connect_info => {
    user => 'postgres',
    password => ''
  }
};


my $con1 = {
  connect_info => {
    dsn => 'dbi:Pg:dbname=mypgdb',
    user => 'postgres',
    password => ''
  }
};

my $con2 = {
  connect_info => {
    dsn => 'dbi:SQLite:dbname=foo.db',
    on_connect_do => [
      'PRAGMA synchronous = OFF',
    ]
  }
};

my $con3 = {
  connect_info => {
    dsn => 'dbi:Pg:dbname=mypgdb',
    user => 'postgres',
    password => '',
    pg_enable_utf8 => 1,
    on_connect_do => [
      'some SQL statement',
      'another SQL statement',
    ],
  }
};

my $con4 = {
  connect_info => 'dbi:SQLite:dbname=var/bpmengine.sqlite'
};

my $con5 = {
  connect_info => {
    dsn => 'dbi:SQLite:dbname=var/bpmengine.sqlite',
    user => 'root',
    password => '',
    pg_enable_utf8 => 1,
    on_connect_do => [
      'some SQL statement',
      'another SQL statement',
    ],
  }
};
my $con6 = {
  connect_info => ['dbi:SQLite:dbname=var/bpmengine.sqlite','root','',{}]
};

my($db1,$db2,$db3,$db4);

use_ok('BPM::Engine');
use BPM::Engine::Store;

lives_ok { $db1 = BPM::Engine::Store->connect($con1->{connect_info}); }  'expecting to live';
lives_ok { $db2 = BPM::Engine::Store->connect($con2->{connect_info}); }  'expecting to live';
lives_ok { $db3 = BPM::Engine::Store->connect($con3->{connect_info}); }  'expecting to live';
lives_ok { $db4 = BPM::Engine::Store->connect($con4->{connect_info}); }  'expecting to live';

#-- engine construction

my($e0,$e1,$e2,$e3,$e4,$e5);

lives_ok { $e0 = BPM::Engine->new($con1); } 'expecting to live';
lives_ok { $e1 = BPM::Engine->new($con1); } 'expecting to live';
lives_ok { $e2 = BPM::Engine->new($con2); } 'expecting to live';
lives_ok { $e3 = BPM::Engine->new($con3); } 'expecting to live';
lives_ok { $e4 = BPM::Engine->new($con4); } 'expecting to live';
lives_ok { $e5 = BPM::Engine->new($con5); } 'expecting to live';

lives_and { isa_ok(BPM::Engine->new($con4)->schema, 'BPM::Engine::Store') } 'method is 42';

isa_ok($e1->schema, 'BPM::Engine::Store');
isa_ok($e2->storage, 'BPM::Engine::Store');

#$e3->schema->storage->debug(1);

lives_ok { $e4->list_process_definitions } 'existing db';
lives_ok { $e5->list_process_definitions } 'existing db';

done_testing();
