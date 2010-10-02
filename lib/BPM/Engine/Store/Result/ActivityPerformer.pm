
package BPM::Engine::Store::Result::ActivityPerformer;
BEGIN {
    $BPM::Engine::Store::Result::ActivityPerformer::VERSION   = '0.001';
    $BPM::Engine::Store::Result::ActivityPerformer::AUTHORITY = 'cpan:SITETECH';
    }

use strict;
use warnings;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/Core/);
__PACKAGE__->table('wfd_activity_performer');
__PACKAGE__->add_columns(
    performer_id => {
        data_type         => 'INT',
        is_auto_increment => 1,
        is_nullable       => 0,
        extras            => { unsigned => 1 }
        },    
    activity_id => {
        data_type         => 'INT',
        is_foreign_key    => 1,
        is_nullable       => 0,
        extras            => { unsigned => 1 }
        },
    participant_id => {
        data_type         => 'INT',
        is_foreign_key    => 1,
        is_nullable       => 0,
        extras            => { unsigned => 1 }
        },
    performer_index => {
        data_type         => 'TINYINT',
        default_value     => 0,
        is_nullable       => 0,
        size              => 1,
        extras            => { unsigned => 1 }
        },    
    );
__PACKAGE__->set_primary_key('performer_id');

__PACKAGE__->belongs_to(
    activity => 'BPM::Engine::Store::Result::Activity', 'activity_id'
    );
__PACKAGE__->belongs_to(
    participant => 'BPM::Engine::Store::Result::Participant', 'participant_id'
    );

1;
__END__