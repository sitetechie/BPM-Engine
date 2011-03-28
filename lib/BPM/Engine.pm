package BPM::Engine;

BEGIN {
    $BPM::Engine::VERSION   = '0.001';
    $BPM::Engine::AUTHORITY = 'cpan:SITETECH';
    }

use 5.010;
use namespace::autoclean;
use Moose;
use MooseX::StrictConstructor;
use Scalar::Util ();
use BPM::Engine::Exceptions qw/throw_engine/;
use BPM::Engine::Store;
use BPM::Engine::ProcessRunner;
use BPM::Engine::Types qw/ArrayRef/;

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

#has '+configfile'       => ( default => '/etc/bpmengine/engine.yaml' );

has '+_trait_namespace' => (default => 'BPM::Engine::Trait');

has 'runner_traits' => (
    isa       => ArrayRef,
    is        => 'rw',
    default   => sub { [] },
    predicate => 'has_runner_traits'
    );

sub runner {
    my ($self, $pi) = @_;

    Scalar::Util::weaken($self);

    my $args = {
        process_instance => $pi,
        engine           => $self,
        logger           => $self->logger,
        };
    $args->{callback} = $self->callback      if $self->has_callback;
    $args->{traits}   = $self->runner_traits if $self->has_runner_traits;

    return BPM::Engine::ProcessRunner->new_with_traits($args);
    }

__PACKAGE__->meta->make_immutable;

1;
__END__

=pod

=encoding utf-8

=head1 NAME

BPM::Engine - Business Process Execution Engine

=head1 VERSION

0.001

=head1 SYNOPSIS

Create a new bpm engine  
  
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

Save an XPDL file with workflow process definitions, and retrieve the process 
definitions
  
  my $package = $engine->create_package('/path/to/model.xpdl');

  my @processes = $engine->get_process_definitions->all;

Create and run a process instance  
  
  my $instance = $engine->create_process_instance(
      $process, 'Client xyz', { param1 => 'value1' }
      );

  $engine->start_process_instance($instance);

=head1 DISCLAIMER

This is ALPHA SOFTWARE. Use at your own risk. Features may change.

=head1 DESCRIPTION

BPM::Engine is an embeddable workflow process engine with persistence. It
handles saving and loading XPDL packages in a database, and running workflow
processes.

=head1 INTERFACE

=head2 Constructors

=head3 B<< BPM::Engine->new(%options) >>

Creates a new bpm engine.

    $engine = BPM::Engine->new(
      connect_info => {
        dsn      => $dsn,
        user     => $user,
        password => $pass,
        %dbi_attributes,
        %extra_attributes,
        });

Possible options are:

=over

=item C<< schema => $schema // BpmEngineStore >>

L<BPM::Engine::Store> connected schema object. If not provided, one will be 
created using the C<connect_info> option.

Either C<schema> or C<connect_info> is required on object construction.

=item C<< connect_info => $dsn // ConnectInfo >>

DBIx::Class::Schema connection arguments that get passed to the C<connect()>
call to BPM::Engine::Store, as specified by the C<ConnectInfo> type in
L<BPM::Engine::Types::Internal>.

Usually a single hashref with dsn/user/password and attributes.

This attribute is only used to build the C<schema> attribute if not provided
already.

=item C<< logger => $logger // BpmEngineLogger >>

A logger object that implements the L<BPM::Engine::Role::LoggerAPI> role,
defaults to a L<BPM::Engine::Logger> instance constructed with
C<log_dispatch_conf>.

=item C<< log_dispatch_conf => $file | $hashref >>

Optional constructor argument for L<BPM::Engine::Logger> to build the default
C<logger>, if a logger was not provided.

=item C<< callback => \&cb >>

Optional callback I<&cb> which is called on all process instance events. This 
option is passed to any C<BPM::Engine::ProcessRunner> constructor.

=item C<< runner_traits => [qw/TraitA TraitB/] // [] >>

Optional traits to be supplied to all C<BPM::Engine::ProcessRunner> objects used.

=back

=head3 B<< BPM::Engine->new_with_config(%options) >>

    $engine = BPM::Engine->new_with_config(
      configfile => "/etc/bpmengine/engine.conf"
      );

Provided by the base role L<MooseX::SimpleConfig>.  Acts just like
regular C<new()>, but also accepts an argument C<configfile> to specify
the configfile from which to load other attributes. 

=over

=item C<< configfile => $file // $ENV{HOME}/bpmengine/engine.conf >>

A file that, when passed to C<new_with_config>, is parsed using
L<Config::Any> to support any of a variety of different config formats,
detected by the file extension.  See L<Config::Any> for more details
about supported formats.

=back

Explicit arguments to C<new_with_config> will override anything loaded from the 
configfile.

=head3 B<< BPM::Engine->new_with_traits(%options) >>

Just like C<new()>, but also accepts a C<traits> argument with a list of trait 
names to apply to the engine object.

    $engine = BPM::Engine->new_with_traits(
        traits => [qw/Foo Bar/],
        schema => $schema
        );

Options, in addition to those to C<new()>:

=over

=item C<< traits => \@traitnames // [] >>

Traits live under the C<BPM::Engine::Trait> namespace by default, prefix full 
class names with a C<+>.

=back

=head3 B<< BPM::Engine->with_traits(@traits)->new(%options) >>
    
You can use the C<with_traits> class method to use traits in combination
with a configuration file. Example:

    $engine = BPM::Engine->with_traits(qw/Foo Bar/)->new_with_config(
      configfile => '/home/user/bpmengine.conf'
      );

=head2 PROCESS DEFINITION METHODS

=head3 get_packages

    $rs = $engine->get_packages();

=head3 get_package

    $package = $engine->get_package($package_id);

=head3 create_package

    $package = $engine->create_package($file);

=head3 delete_package

    $engine->delete_package($package_id);

=head3 get_process_definitions

    $rs = $engine->get_process_definitions();

=head3 get_process_definition

    $process = $engine->get_process_definition

=head2 PROCESS INSTANCE METHODS

=head3 get_process_instances

    $rs = $engine->get_process_instances();

=head3 get_process_instance

    $process_instance = $engine->get_process_instance($pi_id);

=head3 create_process_instance

    $process_instance = $engine->create_process_instance($process_id);

=head3 start_process_instance

    $engine->start_process_instance($pi_id);

=head3 terminate_process_instance

=head3 abort_process_instance

=head3 delete_process_instance

=head3 process_instance_attribute

=head3 change_process_instance_state

=head2 ACTIVITY INSTANCE METHODS

=head3 get_activity_instances

=head3 get_activity_instance

=head3 change_activity_instance_state

=head3 activity_instance_attribute

=head2 LOGGING METHODS

log, debug, info, notice, warning, error, critical, alert, emergency

=head2 INTERNAL METHODS

=head3 runner

Returns a new L<BPM::Engine::ProcessRunner> instance with the C<runner_traits>
and C<callback> attribute applied for the specified process instance.
Internal method, used by C<start_process_instance()> and
C<change_activity_instance_state()> to advance a process instance.

=head1 DIAGNOSTICS

=head2 Exception Handling

When C<BPM::Engine> encounters an API error, it throws a
C<BPM::Engine::Exception> object.  You can catch and process these exceptions,
see L<BPM::Engine::Exception> for more information.

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

=item * Text::Xslate

=item * XML::LibXML

=item * Graph

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

Plenty. Along with error conditions not being handled gracefully etc.

They will be fixed in due course as I start using this more seriously,
however in the meantime, patches are welcome :)

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

Copyright (c) 2010, 2011 Peter de Vos.

This module is free software; you can redistribute it and/or modify it under the 
same terms as Perl itself. See L<perlartistic>.

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
