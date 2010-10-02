
package BPM::Engine::Store::Result::ActivityInstance;
BEGIN {
    $BPM::Engine::Store::Result::ActivityInstance::VERSION   = '0.001';
    $BPM::Engine::Store::Result::ActivityInstance::AUTHORITY = 'cpan:SITETECH';
    }

use Moose;

BEGIN {
  extends qw/DBIx::Class Moose::Object/;
  with    qw/BPM::Engine::Store::ResultBase::ActivityInstance
             BPM::Engine::Store::ResultRole::WithAttributes/;
  }

__PACKAGE__->load_components(qw/ TimeStamp InflateColumn::DateTime Core /);
__PACKAGE__->table('wfe_activity_instance'); #process_token
__PACKAGE__->add_columns(
    token_id => {
        data_type         => 'INT',
        is_auto_increment => 1,
        is_nullable       => 0,
        extras            => { unsigned => 1 },
        size              => 11,
        },
    parent_token_id => {  # upstream split, of which this is a branch
        data_type         => 'INT',
        is_nullable       => 1,
        extras            => { unsigned => 1 },
        size              => 11,
        },    
    process_instance_id => {
        data_type         => 'INT',
        extras            => { unsigned => 1 },
        is_foreign_key    => 1,        
        is_nullable       => 0,
        },
    activity_id => {      # process state
        data_type         => 'INT',
        is_foreign_key    => 1,        
        is_nullable       => 0,
        extras            => { unsigned => 1 },
        },
    transition_id => {    # the transition this instance is a result of
        data_type         => 'INT',
        is_foreign_key    => 1,        
        is_nullable       => 1,
        },
    prev => {             # the activity instance this instance was derived from
        data_type         => 'INT',
        is_foreign_key    => 1,
        is_nullable       => 1,
        },
    workflow_instance_id => {         # (internal) state machine
        data_type         => 'INT',
        extras            => { unsigned => 1 },
        is_foreign_key    => 1,
        is_nullable       => 1,
        size              => 11,
        },
    created => {
        data_type         => 'DATETIME',
        is_nullable       => 1,
        set_on_create     => 1,
        timezone          => 'UTC',
        },
    deferred => {
        data_type         => 'DATETIME',
        is_nullable       => 1,
        timezone          => 'UTC',
        },
    completed => {
        data_type         => 'DATETIME',
        is_nullable       => 1,
        timezone          => 'UTC',
        },    
    );


__PACKAGE__->set_primary_key(qw/ token_id /);

__PACKAGE__->belongs_to(
    process_instance => 'BPM::Engine::Store::Result::ProcessInstance','process_instance_id'
    );

# state
__PACKAGE__->belongs_to(
    activity => 'BPM::Engine::Store::Result::Activity', 'activity_id' 
    );

# the transition this instance is a result of
__PACKAGE__->belongs_to(
    transition => 'BPM::Engine::Store::Result::Transition', 'transition_id'
    );

# history, the instance this instance was derived from
__PACKAGE__->belongs_to(
    prev => __PACKAGE__
    );

__PACKAGE__->might_have(
    next => __PACKAGE__,   { 'foreign.prev' => 'self.token_id' }
    );

__PACKAGE__->might_have(
    parent => __PACKAGE__, { 'foreign.token_id' => 'self.parent_token_id' }
    );

__PACKAGE__->belongs_to(
    workflow_instance => 'BPM::Engine::Store::Result::ActivityInstanceState', 
                       { 'foreign.event_id' => 'self.workflow_instance_id' }  
    );

__PACKAGE__->might_have(
    'join' => 'BPM::Engine::Store::Result::ActivityInstanceJoin', 
            { 'foreign.token_id' => 'self.token_id' }
    );

__PACKAGE__->has_many(
    attributes => 'BPM::Engine::Store::Result::ActivityInstanceAttribute',
                { 'foreign.activity_instance_id' => 'self.token_id' }
    );

sub insert {
    my $self = shift;
    
    my $guard = $self->result_source->schema->txn_scope_guard;
    
    $self->next::method(@_);
    $self->discard_changes;
    my $state = $self->result_source->schema
        ->resultset('ActivityInstanceState')->create({
          token_id => $self->id,
          state => $self->workflow->initial_state,
          });
    #$self->store_column('workflow_instance_id', $state->id);    
    $self->update({ workflow_instance_id => $state->id });    
    
    $guard->commit;

    return $self;
    }

sub join_should_fire {
    my $self = shift;

    die("Not an OR join") unless $self->activity->join_type =~ /^(OR|Inclusive)$/;
    my $upstream_ai = undef;
    my $transition = $self->transition;

    while($upstream_ai = $self->prev) {
        if($upstream_ai->activity->split_type =~ /^(OR|Inclusive)$/) {
            if($upstream_ai->activity->id != $transition->from_activity->id) {
                die("ShouldFire: Illegal transition for JoinActivity '" .
                    $upstream_ai->activity->activity_uid .
                    "' doesn't match transition " . $transition->transition_uid .
                    " activity '" . $transition->from_activity->activity_uid . "'");
                }
            
            my $join = $upstream_ai->join || die("Inclusive split has no join attached");            
            $join->discard_changes;            
            
            # mark transition from split as 'fired' in join from this downstream branch            
            my $should_fire = $join->should_fire($transition);
            return 0 unless $should_fire;
            }
        $self = $upstream_ai;
        $transition = $upstream_ai->transition;
        return 1 unless $transition;
        }
    return 1;
    }

sub deferred :ResultSet {
    my $self = shift;
    $self->search({ deferred => \'IS NOT NULL' },
                  { order_by => \'deferred ASC' });
}

1;
__END__