
package BPM::Engine::Service::ProcessRunnerRole::API;
BEGIN {
    $BPM::Engine::Service::ProcessRunnerRole::API::VERSION   = '0.001';
    $BPM::Engine::Service::ProcessRunnerRole::API::AUTHORITY = 'cpan:SITETECH';
    }

use Moose::Role;
use namespace::autoclean;

requires qw(
  log
  debug
  info
  notice
  warning
  error
  critical
  alert
  emergency

  cb_start_process
  cb_start_activity
  cb_start_transition
  cb_start_task
  cb_continue_process
  cb_continue_activity
  cb_continue_transition
  cb_continue_task
  cb_complete_process
  cb_complete_activity
  cb_complete_transition
  cb_complete_task
  cb_execute_process
  cb_execute_activity
  cb_execute_transition
  cb_execute_task
  
  process
  process_instance
  callback

  start_process
  complete_process

  start_activity
  continue_activity
  complete_activity
);

no Moose::Role;

1;
__END__



