
use strict;
use warnings;
use lib './t/lib';
use Test::More;
use BPM::Engine::TestUtils qw/$dsn/;

#unlink './t/var/bpmengine.log' if -f './t/var/bpmengine.log';

use_ok('BPM::Engine');
use_ok('BPM::Engine::Logger');

my $engine;

ok($engine = BPM::Engine->new(
  connect_info => $dsn,
  ));

my @methods = qw/
  log
  debug
  info
  notice
  warning
  error
  critical
  alert
  emergency
  /;
can_ok('BPM::Engine::Logger', @methods);
can_ok('BPM::Engine', @methods);
can_ok($engine, @methods);

# default logger

isa_ok($engine->logger, 'BPM::Engine::Logger');
is($engine->log_dispatch_conf, '/etc/bpme_logger.conf');
is($engine->logger->log_dispatch_conf, '/etc/bpme_logger.conf');

#ok(!$engine->warning('a warning'));
#ok(!$engine->error('an error'));

# same, standard logger

ok($engine = BPM::Engine->new(
  logger => BPM::Engine::Logger->new,
  connect_info => $dsn,
  ));
isa_ok($engine->logger, 'BPM::Engine::Logger');
is($engine->log_dispatch_conf, '/etc/bpme_logger.conf');
is($engine->logger->log_dispatch_conf, '/etc/bpme_logger.conf');

#ok(!$engine->warning('a warning'));
#ok(!$engine->error('an error'));

# custom logger object

ok( my $logger = BPM::Engine::Logger->new({
    log_dispatch_conf => './t/etc/logger_file.conf'
    })  );

ok(!$logger->notice("event triggered"));
ok(!$logger->warning("event triggered"));

ok($engine = BPM::Engine->new(
  logger       => $logger,
  connect_info => $dsn,
  ));

my $elogger = $engine->logger;
is($engine->log_dispatch_conf, '/etc/bpme_logger.conf');
is($elogger->log_dispatch_conf, './t/etc/logger_file.conf');
is($logger->log_dispatch_conf, './t/etc/logger_file.conf');

ok(!$engine->warning('a warning'));
ok(!$engine->error('an error'));

# log_dispatch_conf in engine config

ok($engine = BPM::Engine->new_with_config(
  configfile   => './t/etc/engine.yaml',
  connect_info => $dsn,
  ));

is($engine->log_dispatch_conf, 't/etc/logger_file.conf');
is($engine->logger->log_dispatch_conf, 't/etc/logger_file.conf');

ok(!$engine->warning('a warning'));
ok(!$engine->error('an error'));

# unknown config file

ok($engine = BPM::Engine->new(
  log_dispatch_conf => '/somewhere/somefile.conf',
  connect_info => $dsn,
  ));

is($engine->log_dispatch_conf, '/somewhere/somefile.conf');
is($engine->logger->log_dispatch_conf, '/somewhere/somefile.conf');

#ok(!$engine->warning('a warning'));
#ok(!$engine->error('an error'));


# specify config

ok($engine = BPM::Engine->new(
  log_dispatch_conf => {
    class     => 'Log::Dispatch::Screen',
    min_level => 'info',
    stderr    => 1,
    format    => '[%p] %m at %F line %L%n',
    },
  connect_info => $dsn,
  ));

#ok(!$engine->warning('a warning'));
#ok(!$engine->error('an error'));

#unlink './t/var/bpmengine.log' if -f './t/var/bpmengine.log';

done_testing;
