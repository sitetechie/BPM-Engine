package BPM::Engine::Handler::ProcessDefinitionHandler;
BEGIN {
    $BPM::Engine::Handler::ProcessDefinitionHandler::VERSION   = '0.001';
    $BPM::Engine::Handler::ProcessDefinitionHandler::AUTHORITY = 'cpan:SITETECH';
    }
## no critic (RequireEndWithOne)
use MooseX::Declare;

role BPM::Engine::Handler::ProcessDefinitionHandler {

  use BPM::Engine::Types qw/Exception LibXMLDoc UUID/;
  use BPM::Engine::Exceptions qw/throw_engine throw_model throw_store/;

  method get_packages (@args) {

      return $self->schema->resultset('Package')->search_rs(@args);
      }

  method create_package (Str|ScalarRef|LibXMLDoc $args) {

      my $package = eval {
          $self->schema->resultset('Package')->create_from_xpdl($args);
          };
      if(my $err = $@) {
          $self->error($err);
          is_Exception($err) ? $err->rethrow() : throw_model(error => $err);
          }

      return $package;
      }

  method delete_package (UUID $id) {

      my $package = $self->schema->resultset('Package')->find($id)
          or do {
            $self->error("Package '$id' not found");
            throw_store(error => "Package '$id' not found")
            };

      return $package->delete;
      }

  method get_process_definitions (@args) {

      return $self->schema->resultset('Process')->search_rs(@args);
      }

  method get_process_definition (Int|HashRef $id, HashRef $args = {}) {

      my $pid = ref($id) ? $id : { process_id => $id };

      return $self->schema->resultset('Process')->find($pid, $args)
          || do {
            my $proc = $pid->{process_id} || $pid->{process_uid} || '';
            my $error = "Process $proc not found";
            $self->error($error);
            throw_store(error => $error);
            };
      }

}

1;
__END__
