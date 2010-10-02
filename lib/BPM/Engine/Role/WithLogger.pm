
package BPM::Engine::Role::WithLogger;
BEGIN {
    $BPM::Engine::Role::WithLogger::VERSION   = '0.001';
    $BPM::Engine::Role::WithLogger::AUTHORITY = 'cpan:SITETECH';
    }

use Moose::Role;
use BPM::Engine::Logger::Default;
use namespace::autoclean -also => [qr/^_/];

has 'logger' => (
    does       => 'BPM::Engine::Logger::API',
    is         => 'ro',
    lazy_build => 1,
    handles    => 'BPM::Engine::Logger::API',
    );

has 'log_dispatch_conf' => (
    is => 'ro',
    lazy => 1,
    default => "etc/logger.conf"
    );

sub _build_logger { 
    my $self = shift;
    BPM::Engine::Logger::Default->new({
        log_dispatch_conf => $self->log_dispatch_conf
        });
    }

no Moose::Role;

1;
__END__