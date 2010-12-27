package BPM::Engine::Role::LoggerAPI;
BEGIN {
    $BPM::Engine::Role::LoggerAPI::VERSION   = '0.001';
    $BPM::Engine::Role::LoggerAPI::AUTHORITY = 'cpan:SITETECH';
    }

use namespace::autoclean;
use Moose::Role;

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