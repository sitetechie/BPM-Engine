
package BPME::TestUtils;

use strict;
use warnings;

use File::Copy ();
use File::Spec;
use Cwd qw/abs_path/;

use base 'Exporter';
use vars qw/@EXPORT_OK/;
@EXPORT_OK = qw/
    setup_db
    seed_db
    rollback_db
    schema
    $dsn
    process_wrap
    runner
    /;

my (undef, $path) = File::Spec->splitpath(__FILE__);
$path = abs_path($path);

my $db_file = './t/var/bpmengine.db'; # File::Spec->catfile( $path, 'bpmengine.test.db' );
our $dsn = 'dbi:SQLite:dbname=t/var/bpmengine.db';
my $schema;

sub setup_db {
    unlink $db_file if -f $db_file;
    die("Temp db locked") if -f $db_file;
    File::Copy::copy(
        File::Spec->catfile($path, 'bpmengine.test.db'),
        $db_file
        );
    }

# populate with fixtures
sub seed_db {
    my @files = @_;
    foreach(@files) {
        schema()->resultset('Package')->create_from_xpdl('./t/var/' . $_ . '.xml');
        }
    }

sub rollback_db {
    schema()->storage->disconnect if $schema;
    unlink $db_file if -f $db_file;
    warn("db $db_file not deleted") if -f $db_file;
    }

sub schema {
    require BPM::Engine::Store;
    $schema ||= BPM::Engine::Store->connect($dsn);
    return $schema;
    }

sub process_wrap {
    my ($xml, $v) = @_;
    $xml ||= '';
    $v ||= 2.1;
    $xml = q|<?xml version="1.0" encoding="UTF-8"?>
        <Package xmlns="http://www.wfmc.org/2008/XPDL2.1" Id="TestPackage">
        <PackageHeader><XPDLVersion>| . $v . q|</XPDLVersion><Vendor/><Created/></PackageHeader>
        <WorkflowProcesses><WorkflowProcess Id="TestProcess"><ProcessHeader/>
        | . $xml . '</WorkflowProcess></WorkflowProcesses></Package>';
    
    require BPM::Engine;
    my $engine = BPM::Engine->new(schema => schema());
    my $process = $engine->create_package(\$xml)->processes->first;
    return ($engine, $process);
    }

sub runner {
    my ($engine, $id, $args) = @_;
    
    require BPM::Engine::Service::ProcessRunner;

    my $p = $engine->list_process_definitions({ process_uid => $id })->first or die("Process $id not found");
    my $i = $engine->create_process_instance($p, undef, $args);
    my $r = BPM::Engine::Service::ProcessRunner->new(
        process => $p,
        process_instance => $i,
        );
    
    return ($r,$p,$i);
    }


1;
__END__
