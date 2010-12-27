package BPM::Engine::Store::Result::ParticipantList;
BEGIN {
    $BPM::Engine::Store::Result::ParticipantList::VERSION   = '0.001';
    $BPM::Engine::Store::Result::ParticipantList::AUTHORITY = 'cpan:SITETECH';
    }

use strict;
use warnings;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/ Core /);
__PACKAGE__->table('wfd_participant_list');
__PACKAGE__->add_columns(
    participant_list_id => {
        data_type         => 'INT',
        is_auto_increment => 1,
        is_nullable       => 0,
        extras            => { unsigned => 1 }
        },
    );

__PACKAGE__->set_primary_key(qw/ participant_list_id /);

__PACKAGE__->might_have(
    'package' => 'BPM::Engine::Store::Result::Package', 'participant_list_id');

__PACKAGE__->might_have(
    'process' => 'BPM::Engine::Store::Result::Process', 'participant_list_id');

__PACKAGE__->has_many(
    participants => 'BPM::Engine::Store::Result::Participant',
    'participant_list_id'
    );

1;
__END__