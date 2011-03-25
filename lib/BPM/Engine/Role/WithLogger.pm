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
    default    => '/etc/bpmengine/logger.conf',
    );

sub _build_logger {
    my $self = shift;
    return BPM::Engine::Logger->new({
        log_dispatch_conf => $self->log_dispatch_conf
        });
    }

no Moose::Role;

1;
__END__

=pod

=head1 NAME

BPM::Engine::Role::WithLogger - Engine and ProcessRunner role providing a logger

=head1 VERSION

version 0.001

=head1 DESCRIPTION

This role provides a logger object to L<BPM::Engine> and 
L<BPM::Engine::ProcessRunner|BPM::Engine::ProcessRunner>.

=head1 ATTRIBUTES

=head2 logger

=head2 log_dispatch_conf

=head1 AUTHOR

Peter de Vos, C<< <sitetech@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2010, 2011 Peter de Vos C<< <sitetech@cpan.org> >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
