package BPM::Engine::Store::ResultRole::WithGraph;
BEGIN {
    $BPM::Engine::Store::ResultRole::WithGraph::VERSION   = '0.001';
    $BPM::Engine::Store::ResultRole::WithGraph::AUTHORITY = 'cpan:SITETECH';
    }

use namespace::autoclean;
use Moose::Role;

use Graph::Directed;
use GraphViz;
use Graph::Writer::GraphViz;

requires 'activities';
requires 'transitions';

sub graph {
    my $self = shift;

    my @edges = map { [
        $_->from_activity_id, $_->to_activity_id
        ] } $self->transitions->all;

    return Graph::Directed->new(edges => [ @edges ]);
    }

sub as_png {
    my ($self, $file) = @_;

    my $g = $self->graph;

    my $wr_png = Graph::Writer::GraphViz->new(-format => 'png');
    $file .= '.png' unless($file =~ /\.png$/);
    $wr_png->write_graph($g, $file);
    }

sub graphviz2 {
    my ($self) = @_;
    my $wr = Graph::Writer::GraphViz->new(-format => 'png');
    return $wr->graph2graphviz($self->graph);
    }

sub graphviz {
    my ($self) = @_;

    my $graphViz = GraphViz->new(
        overlap => 'compress',
        rankdir => 1, # left-right
        directed => 1,
        node => {
            fontname => "Verdana",
            name => "graph",
            shape => 'box',
            style => 'filled',
            fillcolor => '#EFEFEF',
            },
        );

    foreach my $activity($self->activities->all) {
        my %args = ();
        $args{style} = $activity->is_implementation_type ? 
            'filled,rounded' : 'filled';
        $graphViz->add_node(
            $activity->activity_uid,
            label => $activity->activity_name || $activity->activity_uid,
            #URL => "javascript:alert('node')",
            fillcolor =>
                $activity->is_implementation_type ? '#EFEFEF' :
                ($activity->is_event_type ? '#ABABAB' : '#BCBCBC'),
            shape =>
                $activity->is_route_type ? 'diamond' :
                ($activity->is_event_type ? 
                    ($activity->is_end_activity ? 'doublecircle' : 'circle')
                 : 'box'),
            %args,
            );
        }
    foreach my $transition($self->transitions(
        {},{ prefetch => ['from_activity', 'to_activity'] }
        )->all) {
        $graphViz->add_edge(
            $transition->from_activity->activity_uid,
            $transition->to_activity->activity_uid,
            #URL => "javascript:alert('edge')",
            );
        }

    return $graphViz;
    }

1;
__END__

# ABSTRACT: Role for Process