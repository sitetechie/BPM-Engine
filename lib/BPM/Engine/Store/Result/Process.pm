
package BPM::Engine::Store::Result::Process;
BEGIN {
    $BPM::Engine::Store::Result::Process::VERSION   = '0.001';
    $BPM::Engine::Store::Result::Process::AUTHORITY = 'cpan:SITETECH';
    }

use Moose;
extends qw(DBIx::Class);
with qw/BPM::Engine::Store::ResultBase::Process
        BPM::Engine::Store::ResultRole::WithAssignments/;

use overload '""' => sub { shift->process_name }, fallback => 1;

__PACKAGE__->load_components(qw/
    UUIDColumns UTF8Columns  InflateColumn::Serializer Core
    /);
__PACKAGE__->table('wfd_process');
__PACKAGE__->add_columns(
    process_id => {
        data_type         => 'CHAR',
        size              => 36,
        is_nullable       => 0,
        default_value     => 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
        },
    package_id => {
        data_type         => 'CHAR',
        size              => 36,
        is_nullable       => 0,
        is_foreign_key    => 1,       
        },
    process_uid => {
        data_type         => 'VARCHAR',
        size              => 64,
        is_nullable       => 1,
        },
    process_name => {
        data_type         => 'VARCHAR',
        size              => 255,
        is_nullable       => 1,
        default_value     => 'SomeProcess',
        },    
    description => {
        data_type         => 'TEXT',
        is_nullable       => 1,
        },    
    priority => {
        data_type         => 'BIGINT',
        default_value     => 0,
        is_nullable       => 0,
        size              => 21
        },
    valid_from => {
        data_type         => 'DATETIME',
        is_nullable       => 1,
        timezone          => 'UTC',
        },
    valid_to => {
        data_type         => 'DATETIME',
        is_nullable       => 1,
        timezone          => 'UTC',
        },
    version => {
        data_type         => 'VARCHAR',
        size              => 8,
        is_nullable       => 0,
        default_value     => '0.01',
        },
    author => {
        data_type         => 'VARCHAR',
        size              => 255,
        is_nullable       => 1,
        },
    codepage => {
        data_type         => 'VARCHAR',
        size              => 255,
        is_nullable       => 1,
        },
    country_geo => {
        data_type         => 'VARCHAR',
        size              => 20,
        is_nullable       => 1,
        },
    publication_status => {
        data_type         => 'VARCHAR',
        size              => 20,
        is_nullable       => 1,
        },
    participant_list_id => {
        data_type         => 'INT',
        is_foreign_key    => 1,
        is_nullable       => 0,
        extras            => { unsigned => 1 }
        },    
    data_fields => {
        data_type         => 'TEXT',
        is_nullable       => 1,
        serializer_class  => 'JSON',
        },
    formal_params => {
        data_type         => 'TEXT',
        is_nullable       => 1,
        serializer_class  => 'JSON',
        },    
    assignments => {
        data_type         => 'TEXT',
        is_nullable       => 1,
        serializer_class  => 'JSON',
        },
    extended_attr => {
        data_type         => 'TEXT',
        is_nullable       => 1,
        serializer_class  => 'JSON',
        },     
    created => {
        data_type         => 'DATETIME',
        is_nullable       => 1,
        #timezone          => 'UTC',
        },    
    );

__PACKAGE__->set_primary_key('process_id');
__PACKAGE__->uuid_columns('process_id');
__PACKAGE__->utf8_columns(qw/process_name description/);
__PACKAGE__->add_unique_constraint( [qw/package_id process_uid version/] );

__PACKAGE__->might_have(
    'package' => 'BPM::Engine::Store::Result::Package',
    { 'foreign.package_id' => 'self.package_id' }
);

__PACKAGE__->has_many(activities => 'BPM::Engine::Store::Result::Activity','process_id');

__PACKAGE__->has_many(transitions => 'BPM::Engine::Store::Result::Transition','process_id');

__PACKAGE__->has_many(instances => 'BPM::Engine::Store::Result::ProcessInstance','process_id');

__PACKAGE__->belongs_to(participant_list => 'BPM::Engine::Store::Result::ParticipantList', 'participant_list_id');

__PACKAGE__->has_many(participants => 'BPM::Engine::Store::Result::Participant','participant_list_id');

sub insert {
    my $self = shift;

    my $plist = $self->result_source->schema->resultset('ParticipantList')->create({});
    $self->participant_list_id($plist->id);

    $self->next::method(@_);
    }

1;
__END__