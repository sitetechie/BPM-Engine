
package BPM::Engine::Handler::ProcessDefinitionHandler;
BEGIN {
    $BPM::Engine::Handler::ProcessDefinitionHandler::VERSION   = '0.001';
    $BPM::Engine::Handler::ProcessDefinitionHandler::AUTHORITY = 'cpan:SITETECH';
    }

use Moose::Role;
use namespace::autoclean;

sub list_packages {
    my ($self, @args) = @_;
    return $self->storage->resultset('Package')->search_rs(@args);
    }

sub create_package {
    my ($self, $args) = @_;

    my $package;
    eval {
        $package = $self->storage->resultset('Package')->create_from_xpdl($args);
        };
    die("Package not created: $@") unless $package;
    return $package;
    }

sub delete_package {
    my ($self, $id) = @_;
    my $package = $self->storage->resultset('Package')->find($id) or die("Package not found");
    return $package->delete;
    }

sub list_process_definitions {
    my ($self, @args) = @_;
    return $self->storage->resultset('Process')->search_rs(@args);
    }

sub get_process_definition {
    my ($self, $id) = @_;
    return $self->storage->resultset('Process')->find($id) or die ("Process not found");
    }

no Moose::Role;

1;
__END__
