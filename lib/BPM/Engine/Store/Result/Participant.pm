
package BPM::Engine::Store::Result::Participant;
BEGIN {
    $BPM::Engine::Store::Result::Participant::VERSION   = '0.001';
    $BPM::Engine::Store::Result::Participant::AUTHORITY = 'cpan:SITETECH';
    }

use strict;
use warnings;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/InflateColumn::Serializer Core /);
__PACKAGE__->table('wfd_participant');
__PACKAGE__->add_columns(
    participant_id => {
        data_type         => 'INT',
        is_auto_increment => 1,
        is_nullable       => 0,
        extras            => { unsigned => 1 }
        },    
    participant_uid => {
        data_type         => 'VARCHAR',
        size              => 64,
        is_nullable       => 0,
        },
    participant_name => {
        data_type         => 'VARCHAR',
        size              => 255,
        is_nullable       => 1,
        },
    description => {
        data_type         => 'VARCHAR',
        size              => 255,
        is_nullable       => 1,
        },
    participant_type => {
        data_type         => 'ENUM',
        is_nullable       => 1,
        default           => 'SYSTEM',
        default_value     => 'SYSTEM',
        extra             => { list => [qw/
            RESOURCE_SET RESOURCE ROLE ORGANIZATIONAL_UNIT HUMAN SYSTEM /] },
        },
    participant_list_id => {
        data_type         => 'INT',
        is_foreign_key    => 1,
        is_nullable       => 0,
        extras            => { unsigned => 1 }
        },    
    participant_list_index => {
        data_type         => 'BIGINT',
        default_value     => 0,
        is_nullable       => 0,
        size              => 21
        },    
    attributes => {
        data_type         => 'TEXT',
        is_nullable       => 1,
        serializer_class  => 'JSON',
        },    
    );

__PACKAGE__->set_primary_key(qw/participant_id/);

__PACKAGE__->add_unique_constraint( [qw/participant_uid participant_list_id/] );

__PACKAGE__->belongs_to(
    participant_list => 'BPM::Engine::Store::Result::ParticipantList', 
    'participant_list_id'
    );

1;
__END__