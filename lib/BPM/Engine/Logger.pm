package BPM::Engine::Logger;
BEGIN {
    $BPM::Engine::Logger::VERSION   = '0.001';
    $BPM::Engine::Logger::AUTHORITY = 'cpan:SITETECH';
    }

use namespace::autoclean;
use Moose;
use MooseX::StrictConstructor;

with qw/MooseX::LogDispatch::Levels MooseX::LogDispatch::Interface/;

$Log::Dispatch::Config::CallerDepth = 1;

has log_dispatch_conf => (
    is      => 'ro',
    lazy    => 1,
    default => '/etc/bpmengine/logger.conf'
    );

__PACKAGE__->meta->make_immutable;

1;
__END__
