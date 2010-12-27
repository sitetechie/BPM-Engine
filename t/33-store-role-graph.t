use strict;
use warnings;
use lib './t/lib';
use Test::More;
use Test::Exception;
use Data::Dumper;

use BPM::Engine::TestUtils qw/setup_db teardown_db schema/;
BEGIN { setup_db }
END   { teardown_db }

use_ok('BPM::Engine');
#use BPM::Engine;
use Graph;
use Graph::Directed;

my $engine = BPM::Engine->new( schema => schema() );
$engine->create_package('./t/var/samples.xpdl');
$engine->create_package('./t/var/02-branching.xpdl');

if(0){
my $g = new Graph::Directed;
$g->add_edge('B', 'C');
$g->add_edge('B', 'D');
$g->add_edge('D', 'E');
$g->add_edge('E', 'C');
#$g->add_edge('E', 'B');
$g->add_edge('A', 'E');
$g->add_edge('A', 'B');
$g->add_edge('C', 'D');
$g->add_edge('D', 'F');

print "The graph is $g\n";

my $tcg = $g->TransitiveClosure_Floyd_Warshall;
warn Dumper $tcg;

ok($g->is_reachable('E', 'D') );
ok($g->is_reachable('A','E') );
ok(!$g->is_reachable('E','A') );
ok($g->is_reachable('A','D') );
ok(!$g->is_reachable('E','B') );
ok($g->is_reachable('B','E') );
}

my ($process, $proc, $g) = ();
my $a = sub {
    my $id = shift;
#warn "$proc $id";
    return $process->activities_rs({ activity_uid => $proc . '.' . $id })->first->id;
    };

$proc = 'wcp37';
$process = $engine->get_process_definition({ process_uid => $proc });
$g = $process->graph;
isa_ok($g, 'Graph');

ok($g->is_reachable(&$a('MC'), &$a('E')) );
ok(!$g->is_reachable(&$a('E'), &$a('MC')) );
ok(!$g->is_reachable(&$a('B'), &$a('E')) );
ok(!$g->is_transitive());

$proc = 'wcp38';
$process = $engine->get_process_definition({ process_uid => $proc });
$g = $process->graph;
ok($g->is_reachable(&$a('MC'), &$a('E')) );
ok(!$g->is_reachable(&$a('E'), &$a('MC')) );
ok(!$g->is_reachable(&$a('B'), &$a('E')) );
ok($g->is_reachable(&$a('C'), &$a('XOR')) );
ok($g->is_reachable(&$a('XOR'), &$a('C')) );
#ok($g->is_transitive());

my $tcg = Graph::TransitiveClosure->new($g, path => 1);
my $u = &$a('MC');
my $v = &$a('SM');

my @v = $tcg->path_vertices($u, $v);
@v = map { $process->activities_rs({ activity_id => $_ })->first->activity_uid } @v;
#warn Dumper \@v;

my @l = $tcg->path_length($u, $v);
#warn Dumper \@l;

is($tcg->is_reachable($u, $v),1);
is($tcg->is_transitive($u, $v),1);
#is($tcg->is_transitive(&$a('B'), &$a('E')),0);

#my $tcm = Graph::TransitiveClosure::Matrix->new($g);
#@v = $tcm->vertices;
#@v = map { $process->activities_rs({ activity_id => $_ })->first->activity_uid } @v;
#warn Dumper \@v;

done_testing;

