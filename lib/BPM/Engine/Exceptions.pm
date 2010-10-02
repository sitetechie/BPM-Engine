
package BPM::Engine::Exceptions;
BEGIN {
    $BPM::Engine::Exceptions::VERSION   = '0.001';
    $BPM::Engine::Exceptions::AUTHORITY = 'cpan:SITETECH';    
    }
use strict;
use warnings;

BEGIN {
    my %classes = (
        'BPM::Engine::Exception' => {
            description => 'Generic BPM::Engine exception',
            alias       => 'throw'
        },
        'BPM::Engine::Exception::Engine' => {
            isa         => 'BPM::Engine::Exception',
            description => 'Engine exception',
            alias       => 'throw_engine'
        },
        'BPM::Engine::Exception::Runner' => {
            isa         => 'BPM::Engine::Exception',
            description => 'Dispatcher exception',
            alias       => 'throw_runner'
        },        
        'BPM::Engine::Exception::Database' => {
            isa         => 'BPM::Engine::Exception',
            description => 'Datastore exception',
            alias       => 'throw_store'
        },        
        'BPM::Engine::Exception::IO' => {
            isa         => 'BPM::Engine::Exception',
            description => 'IO exception',
            alias       => 'throw_io'
        },
        'BPM::Engine::Exception::Parameter' => {
            isa         => 'BPM::Engine::Exception',
            description => 'Invalid parameters was given to method/function',
            alias       => 'throw_param'
        },
        'BPM::Engine::Exception::Expression' => {
            isa         => 'BPM::Engine::Exception',
            description => 'Exception evaluator error',
            alias       => 'throw_expression'
        },        
        'BPM::Engine::Exception::Plugin' => {
            isa         => 'BPM::Engine::Exception',
            fields      => 'plugin',
            description => 'Plugin exception',
            alias       => 'throw_plugin'
        },
        'BPM::Engine::Exception::Model' => {
            isa         => 'BPM::Engine::Exception',
            description => 'Model exception',
            alias       => 'throw_model'
        },
        'BPM::Engine::Exception::Install' => {
            isa         => 'BPM::Engine::Exception',
            description => 'Installation/configuration exception',
            alias       => 'throw_install'
        },
        'BPM::Engine::Exception::NotImplemented' => {
            isa         => 'BPM::Engine::Exception',
            description => 'Abstract method',
            alias       => 'throw_abstract'
        },    
    );

    my @exports = map { $classes{ $_ }->{ alias } } keys %classes;

    require Exception::Class;
    require Sub::Exporter;

    Exception::Class->import(%classes);
    Sub::Exporter->import( -setup => { exports => \@exports  } );
}

1;
__END__
