
package BPM::Engine::Store::Result::Transition;
BEGIN {
    $BPM::Engine::Store::Result::Transition::VERSION   = '0.001';
    $BPM::Engine::Store::Result::Transition::AUTHORITY = 'cpan:SITETECH';
    }

use Moose;
extends qw(DBIx::Class Moose::Object);
with qw/
    BPM::Engine::Store::ResultBase::ProcessTransition
    BPM::Engine::Store::ResultRole::WithAssignments
    /;

__PACKAGE__->load_components(qw/ Core /);
__PACKAGE__->table('wfd_transition');
__PACKAGE__->add_columns(
    transition_id => {
        data_type         => 'INT',
        is_auto_increment => 1,
        is_nullable       => 0,
        extras            => { unsigned => 1 }
        },    
    process_id => {
        data_type         => 'CHAR',
        size              => 36,
        is_nullable       => 0,
        is_foreign_key    => 1,
        },    
    from_activity_id => { # state
        data_type         => 'INT',
        is_nullable       => 0,
        is_foreign_key    => 1,
        },
    to_activity_id => {   # to_state
        data_type         => 'INT',
        is_nullable       => 0,
        is_foreign_key    => 1,
        },    
    transition_uid => {
        data_type         => 'VARCHAR',
        size              => 64,
        is_nullable       => 1,
        },
    transition_name => {
        data_type         => 'VARCHAR',
        size              => 255,
        is_nullable       => 1,
        },
    description => {
        data_type         => 'VARCHAR',
        size              => 255,
        is_nullable       => 1,
        },
    condition_type => {
        data_type         => 'ENUM',
        is_nullable       => 0,
        default           => 'NONE',
        default_value     => 'NONE',        
        extra             => { list => [qw/
            NONE CONDITION OTHERWISE EXCEPTION DEFAULTEXCEPTION
            /] },
        },    
    condition_expr => {
        data_type         => 'TEXT',
        #size              => 255,
        is_nullable       => 1,
        },
    assignments => {
        data_type         => 'TEXT',
        #size              => 255,
        is_nullable       => 1,
        serializer_class  => 'JSON',
        },    
    class => {
        data_type         => 'VARCHAR',
        size              => 255,
        is_nullable       => 1,
        },    
    );

__PACKAGE__->set_primary_key('transition_id');

__PACKAGE__->belongs_to( process => 'BPM::Engine::Store::Result::Process', 'process_id' );

__PACKAGE__->belongs_to( from_activity => 'BPM::Engine::Store::Result::Activity',
    { 'foreign.activity_id' => 'self.from_activity_id' } );

__PACKAGE__->belongs_to( to_activity => 'BPM::Engine::Store::Result::Activity', 
    { 'foreign.activity_id' => 'self.to_activity_id' } );

__PACKAGE__->might_have( from_split => 'BPM::Engine::Store::Result::TransitionRef',
    { 'foreign.activity_id' => 'self.from_activity_id', 'foreign.transition_id' => 'self.transition_id' } );

__PACKAGE__->might_have( to_join => 'BPM::Engine::Store::Result::TransitionRef',
    { 'foreign.activity_id' => 'self.to_activity_id', 'foreign.transition_id' => 'self.transition_id' } );

__PACKAGE__->has_many(
    transition_refs => 'BPM::Engine::Store::Result::TransitionRef', 'transition_id'
    );

__PACKAGE__->might_have(
    deadline => 'BPM::Engine::Store::Result::ActivityDeadline',
    { 'foreign.exception_id' => 'self.transition_id' } 
    );

1;
__END__