
package BPM::Engine::Store::Result::ProcessInstance;
BEGIN {
    $BPM::Engine::Store::Result::ProcessInstance::VERSION   = '0.001';
    $BPM::Engine::Store::Result::ProcessInstance::AUTHORITY = 'cpan:SITETECH';
    }

use Moose;

extends qw/DBIx::Class Moose::Object/;
with    qw/BPM::Engine::Store::ResultBase::ProcessInstance 
           BPM::Engine::Store::ResultRole::WithAttributes/;

__PACKAGE__->load_components(qw/TimeStamp InflateColumn::DateTime Core /);
__PACKAGE__->table('wfe_process_instance');
__PACKAGE__->add_columns(
    instance_id => {
        data_type         => 'INT',
        is_auto_increment => 1,
        is_nullable       => 0,
        extras            => { unsigned => 1 }
        },
    process_id => {
        data_type         => 'CHAR',
        size              => 36,
        is_nullable       => 0,
        },
    parent_ai_id => {     # parent blockactivity
        data_type         => 'INT',
        is_nullable       => 1,
        },
    instance_name => {
        data_type         => 'VARCHAR',
        size              => 64,
        is_nullable       => 1,
        default_value     => 'SomeProcessInstance',        
        },
    workflow_instance_id => { # state machine
        data_type         => 'INT',
        is_nullable       => 1,
        #accessor => '_workflow_instance',
        },
    created => {
        data_type         => 'DATETIME',
        is_nullable       => 0,
        set_on_create     => 1,
        timezone          => 'UTC',
        },    
    completed => {
        data_type         => 'DATETIME',
        is_nullable       => 1,
        timezone          => 'UTC',
        },
    );

__PACKAGE__->set_primary_key(qw/ instance_id /);

__PACKAGE__->belongs_to(
    process => 'BPM::Engine::Store::Result::Process','process_id'
    );

__PACKAGE__->has_many(
    attributes => 'BPM::Engine::Store::Result::ProcessInstanceAttribute',
    { 'foreign.process_instance_id' => 'self.instance_id' }
    );

__PACKAGE__->has_many(
    activity_instances => 'BPM::Engine::Store::Result::ActivityInstance',
    { 'foreign.process_instance_id' => 'self.instance_id' }, { order_by => 'prev' }
    );

__PACKAGE__->might_have(
    parent_activity_instance => 'BPM::Engine::Store::Result::ActivityInstance', 
    { 'foreign.token_id' => 'self.parent_ai_id' }
    );

__PACKAGE__->belongs_to(
    workflow_instance => 'BPM::Engine::Store::Result::ProcessInstanceState',
    { 'foreign.event_id' => 'self.workflow_instance_id' }
    );

sub insert {
    my $self = shift;

    my $guard = $self->result_source->schema->txn_scope_guard;

    $self->next::method(@_);
    $self->discard_changes;
    my $rel = $self->create_related('workflow_instance', {
        process_instance_id => $self->id,
        state => $self->workflow->initial_state,
        });
    $self->update({ workflow_instance_id => $rel->id });
    
    $guard->commit;

    return $self;
    }

1;
__END__