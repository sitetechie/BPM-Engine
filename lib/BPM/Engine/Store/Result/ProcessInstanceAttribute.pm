package BPM::Engine::Store::Result::ProcessInstanceAttribute;
BEGIN {
    $BPM::Engine::Store::Result::ProcessInstanceAttribute::VERSION   = '0.001';
    $BPM::Engine::Store::Result::ProcessInstanceAttribute::AUTHORITY = 'cpan:SITETECH';
    }

use strict;
use warnings;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/ Core /);
__PACKAGE__->table('wfe_process_instance_attr');
__PACKAGE__->add_columns(
    process_instance_id => {
        data_type         => 'INT',
        is_nullable       => 0,
        size              => 11,
        is_foreign_key    => 1,
        extras            => { unsigned => 1 },
        },    
    name => {
        data_type         => 'VARCHAR',
        size              => 64,
        is_nullable       => 0,
        },
    scope => {
        data_type         => 'VARCHAR',
        size              => 64,
        is_nullable       => 1,
        },    
    type => {
        data_type         => 'VARCHAR',
        size              => 20,
        is_nullable       => 1,
        },     
    mode => {
        data_type         => 'VARCHAR',
        size              => 20,
        is_nullable       => 1,
        },    
    value => {
        data_type         => 'TEXT',
        is_nullable       => 1,
        },
    );

__PACKAGE__->set_primary_key(qw/ process_instance_id name /);

__PACKAGE__->belongs_to(
    process_instance => 'BPM::Engine::Store::Result::ProcessInstance', 
    'process_instance_id'
    );

1;
__END__