package BPM::Engine;
BEGIN {
    $BPM::Engine::VERSION   = '0.001';
    $BPM::Engine::AUTHORITY = 'cpan:SITETECH';
    }

use 5.010;
use Moose;
use MooseX::StrictConstructor;
use BPM::Engine::Exceptions qw/throw_engine/;
use BPM::Engine::Store;
use BPM::Engine::ProcessRunner;
use namespace::autoclean;

with qw/
    MooseX::SimpleConfig
    MooseX::Traits    
    BPM::Engine::Role::WithCallback
    BPM::Engine::Role::WithPersistence
    BPM::Engine::Role::WithLogger    
    BPM::Engine::Handler::ProcessDefinitionHandler
    BPM::Engine::Handler::ProcessInstanceHandler
    BPM::Engine::Handler::ActivityInstanceHandler
    /;
with 'BPM::Engine::Role::EngineAPI';

has '+configfile' => ( default => '/etc/bpmengine.yaml' );

around BUILDARGS => sub {
    my $orig = shift;
    my $args = $orig->(@_);

    throw_engine("Invalid connection arguments") 
        unless $args->{connect_info} || $args->{schema};

    return $args;
    };

sub runner {
    my ($self, $pi) = @_;
    
    my $args = {
        process_instance => $pi,
        engine           => $self,
        logger           => $self->logger,
        };
    $args->{callback} = $self->callback if $self->has_callback;
    
    return BPM::Engine::ProcessRunner->new($args);
    }

__PACKAGE__->meta->make_immutable;

1;
__END__

=pod

=encoding utf-8

=head1 NAME

BPM::Engine - Business process execution engine

=head1 VERSION

0.001

=head1 SYNOPSIS

  use BPM::Engine;
  
  my $callback = sub {
        my($runner, $entity, $event, $node, $instance) = @_;
        ...
        };
  
  my $engine = BPM::Engine->new(
      log_dispatch_conf => 'log.conf',
      connect_info      => { dsn => $dsn, user => $user, password => $password },
      callback          => $callback
      );
  
  my $package = $engine->create_package('/path/to/model.xpdl');

  my @workflows = $engine->list_process_definitions->all;
  
  my $instance = $engine->create_process_instance(
      $process, 'Client xyz', { param1 => 'value1' }
      );
  
  $engine->start_process_instance($instance);

=head1 DESCRIPTION

BPM::Engine is an embeddable workflow process engine with persistence. It
handles saving and loading XPDL packages in a database, and running workflow
processes.

=head1 WARNING

Currently this is B<alpha code> and should be considered B<HIGHLY
EXPERIMENTAL>. This module is still in heavy flux, and will change. I welcome 
any opinions, ideas for extensions, etc. However, tests are incomplete, 
documentation is nonexistent, and interfaces are subject to change. 
B<Don't use this in production>.

Please review the test files and source code to see how it works.

=head1 INTERFACE

=head2 CONSTRUCTORS

=head2 new

=head2 new_with_config

=head2 ATTRIBUTES

=head2 connect_info

=head2 schema

=head2 storage

=head2 logger

=head2 log_dispatch_conf

=head2 callback

=head2 PROCESS DEFINITION METHODS

=head2 list_packages

=head2 create_package

=head2 delete_package

=head2 list_process_definitions

=head2 get_process_definition

=head2 PROCESS INSTANCE METHODS

=head2 list_process_instances

=head2 create_process_instance

=head2 get_process_instance

=head2 start_process_instance

=head2 terminate_process_instance

=head2 abort_process_instance

=head2 delete_process_instance

=head2 process_instance_attribute

=head2 change_process_instance_state

=head2 ACTIVITY INSTANCE METHODS

=head2 list_activity_instances

=head2 get_activity_instance

=head2 change_activity_instance_state

=head2 activity_instance_attribute

=head2 LOGGING

log, debug, info, notice, warning, error, critical, alert, emergency

=head1 CONFIGURATION AND ENVIRONMENT

BPM::Engine may optionally be configured with a configuration file when
constructed using the C<new_with_config> method. See F<etc/engine.yaml> for an
example.

=head1 MAJOR DEPENDENCIES

=over 4

=item * Moose

=item * Class::Workflow

=item * BPM::XPDL

=item * DBIx::Class

=item * Template Toolkit

=item * XML::LibXML

=back

See the included F<Makefile.PL> for a list of all dependencies.

=head1 INCOMPATIBILITIES

None reported.

=head1 AUTHOR

Peter de Vos, C<< <sitetech@cpan.org> >>

=head1 SOURCE

You can contribute or fork this project via GitHub:

  git clone git://github.com/sitetechie/BPM-Engine.git

=head1 BUGS

Please report any bugs or feature requests to C<bug-bpm-engine@rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=BPM-Engine>. I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc BPM::Engine

You can also look for information at:

=over 4

=item * Homepage

L<http://bpmengine.org/>

=item * Github Repository

L<http://github.com/sitetechie/BPM-Engine>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2010, Peter de Vos C<< <sitetech@cpan.org> >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
