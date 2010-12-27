package BPM::Engine::Role::WithLogger;
BEGIN {
    $BPM::Engine::Role::WithLogger::VERSION   = '0.001';
    $BPM::Engine::Role::WithLogger::AUTHORITY = 'cpan:SITETECH';
    }

use namespace::autoclean;
use Moose::Role;
use BPM::Engine::Logger;

has 'logger' => (
    does       => 'BPM::Engine::Role::LoggerAPI',
    is         => 'ro',
    lazy_build => 1,
    handles    => 'BPM::Engine::Role::LoggerAPI',
    );

has 'log_dispatch_conf' => (
    is         => 'ro',
    lazy       => 1,
    default    => '/etc/bpme_logger.conf',
    );

sub _build_logger { 
    my $self = shift;
    BPM::Engine::Logger->new({
        log_dispatch_conf => $self->log_dispatch_conf
        });
    }

no Moose::Role;

1;
__END__