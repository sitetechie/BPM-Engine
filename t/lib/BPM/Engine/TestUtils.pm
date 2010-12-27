
package 
  BPM::Engine::TestUtils;

use strict;
use warnings;

use File::Copy ();
use File::Spec ();
use File::Temp;
use Cwd qw/abs_path/;

use base 'Exporter';
use vars qw/@EXPORT_OK/;
@EXPORT_OK = qw/
    setup_db seed_db teardown_db 
    schema $dsn process_wrap runner
    /;

my (undef, $path) = File::Spec->splitpath(__FILE__);
$path = abs_path($path);

my $DEBUG = $ENV{BPME_DEBUG};
our($db_file, $dsn) = ();

if($DEBUG) {
    $db_file = './t/var/bpmengine.db';
    $dsn = 'dbi:SQLite:dbname=t/var/bpmengine.db';
    }
else {
    $db_file = File::Temp->new(TMPDIR => 1);
    $dsn = 'dbi:SQLite:dbname='.$db_file->filename;
    }

my $schema;

sub setup_db {
    unlink $db_file if $DEBUG && -f $db_file;
    die("Temp db locked") if $DEBUG && -f $db_file;
    File::Copy::copy(
        File::Spec->catfile($path, 'bpmengine.test.db'),
        $DEBUG ? $db_file : $db_file->filename
        );
    }

# populate with fixtures
sub seed_db {
    my @files = @_ ||
        (qw/samples.xpdl 01-basic.xpdl 02-branching.xpdl 
            06-iteration.xpdl 07-termination.xpdl
           /);
    foreach(@files) {
        schema()->resultset('Package')->create_from_xpdl('./t/var/' . $_ . '.xml');
        }
    }

sub teardown_db {
    schema()->storage->disconnect if $schema;
    unlink $db_file if $DEBUG && -f $db_file;
    warn("db $db_file not deleted: " . $@) if $DEBUG && -f $db_file;
    undef $db_file unless $DEBUG;
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
    
    #my $p = $engine->list_process_definitions({ process_uid => $id })->first 
    my $p = $engine->get_process_definition({ process_uid => $id })
        or die("Process $id not found");
    my $i = $engine->create_process_instance($p);
    
    foreach(keys %{$args}) {
        $i->attribute($_ => $args->{$_});
        }
    
    return ($engine->runner($i), $p, $i);
    }


1;
__END__
