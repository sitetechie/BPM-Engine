
package BPM::Engine::Handler::ProcessInstanceHandler;
BEGIN {
    $BPM::Engine::Handler::ProcessInstanceHandler::VERSION   = '0.001';
    $BPM::Engine::Handler::ProcessInstanceHandler::AUTHORITY = 'cpan:SITETECH';
    }

use Moose::Role;
use Silly::Werder;
use BPM::Engine::Exceptions qw/throw throw_param/;
use namespace::autoclean -also => [qr/^_/];

my $WORDGEN = new Silly::Werder;

sub create_process_instance {
    my ($self, $process_id, $name, $args) = @_;

    my $process = (ref($process_id) ? 
        $process_id : $self->schema->resultset('Process')->find($process_id))
        or throw("Process $process_id not found");
    
    my $guard = $self->schema->storage->txn_scope_guard;

    $name ||= $WORDGEN->get_werd;    
    my $pi = $process->new_instance({
        instance_name => $name
        }) or throw("No ProcessInstance created");

    my $fp = $process->formal_params || [];
    if(scalar @$fp) {
        foreach my $param(@$fp) {
            if($param->{Mode} =~ /^(IN|INOUT)$/ && !exists($args->{$param->{Id}})) {
                throw_param("Invalid params: process instance attribute '" . $param->{Id} . "' is required");
                }
            $pi->add_to_attributes({
                name => $param->{Id},
                mode => $param->{Mode},
                type => $param->{DataType}->{BasicType}->{Type},
                value => $param->{Mode} =~ /^(IN|INOUT)$/ ? $args->{$param->{Id}} : undef,
                });
            }
        }
    
    # Create workflow relevant data from data fields
    $self->_create_process_attributes($pi, $process->package->data_fields);
    $self->_create_process_attributes($pi, $process->data_fields);

    $guard->commit;
    
    return $pi;
    }

sub _create_process_attributes {
    my ($self, $pi, $data_fields) = @_;
    
    foreach my $param(@{$data_fields}) {
        $pi->add_to_attributes({
            name => $param->{Id},
            #mode => $param->{Mode}, #IsArray
            type => $param->{DataType}->{BasicType}->{Type},
            value => $param->{InitialValue},
            });
        # Notify attribute instance listeners
        }
    }

sub list_process_instances {
    my ($self, @args) = @_;
    return $self->storage->resultset('ProcessInstance')->search_rs(@args);
    }

sub get_process_instance {
    my ($self, $id) = @_;
    return $self->storage->resultset('ProcessInstance')->find($id);
    }

sub start_process_instance {
    my ($self, $process_instance) = @_;
    my $runner = $self->_runner($process_instance);
    return $runner->start_process();
    }

sub terminate_process_instance {
    my ($self, $pi) = @_;
    }

sub abort_process_instance {
    my ($self, $pi) = @_;
    }

sub delete_process_instance {
    my ($self, $pi) = @_;
    $pi->delete;
    }

sub process_instance_attribute {
    my ($self, $pi, $attr, $value) = @_;    
    
    return $value ? 
        $pi->attribute($attr)->update({ value => $value }) : 
        $pi->attribute($attr);
    }

sub change_process_instance_state {
    my ($self, $id, $state) = @_;
    
    my $instance = $self->get_process_instance($id);
    $instance->apply_transition($state);
    }

no Moose::Role;

1;
__END__
