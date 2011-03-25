package BPM::Engine::Handler::ActivityInstanceHandler;
BEGIN {
    $BPM::Engine::Handler::ActivityInstanceHandler::VERSION   = '0.001';
    $BPM::Engine::Handler::ActivityInstanceHandler::AUTHORITY = 'cpan:SITETECH';
    }
## no critic (RequireEndWithOne)
use MooseX::Declare;

role BPM::Engine::Handler::ActivityInstanceHandler {

  requires 'runner';

  use Scalar::Util qw/blessed/;
  use BPM::Engine::Exceptions qw/throw_store/;
  use aliased 'BPM::Engine::Store::Result::ActivityInstance';

  method get_activity_instances (@args) {

      return $self->schema->resultset('ActivityInstance')->search_rs(@args);
      }

  method get_activity_instance (Int|HashRef $id, HashRef $args = {}) {

      return $self->schema->resultset('ActivityInstance')->find($id, $args)
          || throw_store(error => "ActivityInstance '$id' not found");
      }

  method change_activity_instance_state (Int|ActivityInstance $ai, Str $state) {

      $ai = $self->get_activity_instance(
          $ai, { prefetch => ['process_instance', 'activity'] }
          ) unless(blessed $ai);

      if ($state eq 'assign' || $state eq 'finish') {
          my $activity         = $ai->activity;
          my $process_instance = $ai->process_instance;
          my $runner           = $self->runner($process_instance);
          if($state eq 'assign') { # open.running
              # Execute the activity if it is now open.running.
              $runner->start_activity($activity, $ai, 1);
              }
          elsif($state eq 'finish') { # closed.completed
              # Fire the activity's efferent transitions if it is
              # now closed.complete.
              $runner->complete_activity($activity, $ai, 1);
              }
          }
      else {
          $ai->apply_transition($state);
          }

      return;
      }

  method activity_instance_attribute (Int|ActivityInstance $ai, @args) {

      $ai = $self->get_activity_instance($ai) unless(blessed $ai);
      return $ai->attribute(@args);
      }

}

1;
__END__
