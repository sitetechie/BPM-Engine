
package BPM::Engine::Util::YAMLWorkflowLoader;
BEGIN {
    $BPM::Engine::Util::YAMLWorkflowLoader::VERSION   = '0.001';
    $BPM::Engine::Util::YAMLWorkflowLoader::AUTHORITY = 'cpan:SITETECH';
    }

use strict;
use warnings;

use Class::Workflow;
use base qw(Class::Workflow::YAML);
use Exporter qw(import);

use vars qw(@EXPORT);
@EXPORT = qw(load_workflow_from_yaml);

sub empty_workflow {
    my $w = Class::Workflow->new;
    $w->instance_class('Class::Workflow::Instance::Simple');
    $w->state_class('Class::Workflow::Transition::Simple');
    $w->state_class('Class::Workflow::State::Simple');
    return $w;
    }

sub load_workflow_from_yaml {
    my ($yaml) = @_;
    my $y = __PACKAGE__->new;
    $y->load_string($yaml);
    }

1;
__END__
