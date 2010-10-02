
package BPM::Engine::Logger::Default;
BEGIN {
    $BPM::Engine::Logger::Default::VERSION   = '0.001';
    $BPM::Engine::Logger::Default::AUTHORITY = 'cpan:SITETECH';
    }

use Moose;
use MooseX::StrictConstructor;

with qw/
  BPM::Engine::Logger::API
  MooseX::LogDispatch::Levels
  /;

$Log::Dispatch::Config::CallerDepth = 1;

has log_dispatch_conf => (
   is => 'ro',
   lazy => 1,
   default => "etc/logger.conf"
 );

__PACKAGE__->meta->make_immutable;
1;
__END__
