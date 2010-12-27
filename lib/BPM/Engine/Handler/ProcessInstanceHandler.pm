package BPM::Engine::Handler::ProcessInstanceHandler;
BEGIN {
    $BPM::Engine::Handler::ProcessInstanceHandler::VERSION   = '0.001';
    $BPM::Engine::Handler::ProcessInstanceHandler::AUTHORITY = 'cpan:SITETECH';
    }
## no critic (RequireEndWithOne)
use MooseX::Declare;

role BPM::Engine::Handler::ProcessInstanceHandler {

  requires 'runner';

  use Scalar::Util qw/blessed/;
  use BPM::Engine::Exceptions qw/throw_store throw_abstract/;

  requires 'get_process_definition';

  method create_process_instance (Int|Object $process, HashRef $args = {}) {
    
      $process = 
        $self->get_process_definition($process, { prefetch => 'package' })
        unless blessed($process);
    
      return $process->new_instance($args);
      }

  method list_process_instances (@args) {
    
      return $self->storage->resultset('ProcessInstance')->search_rs(@args);
      }

  method get_process_instance (Int|HashRef $id, HashRef $args = {}) {    
    
      return $self->storage->resultset('ProcessInstance')->find($id, $args)
          || throw_store(error => "Process instance '$id' not found");
      }

  method start_process_instance (Int|Object $pi, HashRef $args = {}) {    
    
      $pi = $self->get_process_instance($pi) unless(blessed $pi);
      foreach(keys %{$args}) {
          $pi->attribute($_ => $args->{$_});
          }
    
      my $runner = $self->runner($pi);
      return $runner->start_process();
      }

  method terminate_process_instance (Int|Object $pi) {
    
      $pi = $self->get_process_instance($pi) unless(blessed $pi);    
      throw_abstract(error => 'Method not implemented');
      }

  method abort_process_instance (Int|Object $pi) {
    
      $pi = $self->get_process_instance($pi) unless(blessed $pi);
      throw_abstract(error => 'Method not implemented');    
      }

  method delete_process_instance (Int|Object $pi) {
    
      $pi = $self->get_process_instance($pi) unless(blessed $pi);
      $pi->delete;
      }

  method process_instance_attribute (Int|Object $pi, Str $attr, Str $value?) {
    
      $pi = $self->get_process_instance($pi) unless(blessed $pi);    
      return $value ? 
          $pi->attribute($attr)->update({ value => $value }) : 
          $pi->attribute($attr);
      }

  method change_process_instance_state (Int|Object $pi, Str $state) {
    
      $pi = $self->get_process_instance($pi) unless(blessed $pi);
      $pi->apply_transition($state);
      }

}

1;
__END__
