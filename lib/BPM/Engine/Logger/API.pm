
package BPM::Engine::Logger::API;
BEGIN {
    $BPM::Engine::Logger::API::VERSION   = '0.001';
    $BPM::Engine::Logger::API::AUTHORITY = 'cpan:SITETECH';
    }

use Moose::Role;
use namespace::autoclean;

requires qw(
  log
  debug
  info
  notice
  warning
  error
  critical
  alert
  emergency
);

no Moose::Role;

1;
__END__