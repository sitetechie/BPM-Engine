
package BPM::Engine::Store::Result::ActivityTask;
BEGIN {
    $BPM::Engine::Store::Result::ActivityTask::VERSION   = '0.001';
    $BPM::Engine::Store::Result::ActivityTask::AUTHORITY = 'cpan:SITETECH';
    }

use Moose;
extends qw(DBIx::Class Moose::Object);
#with 'BPM::Engine::Store::ResultBase::ActivityTask';

__PACKAGE__->load_components(qw/ InflateColumn::Serializer Core /);
__PACKAGE__->table('wfd_activity_task');
__PACKAGE__->add_columns(
    task_id => {
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
    application_id => {
        data_type         => 'INT',
        is_foreign_key    => 1,
        is_nullable       => 1,
        extras            => { unsigned => 1 }
        },    
    task_uid => {
        data_type         => 'VARCHAR',
        size              => 64,
        is_nullable       => 1,
        },
    task_name => {
        data_type         => 'VARCHAR',
        size              => 64,
        is_nullable       => 1,
        },    
    description => {
        data_type         => 'VARCHAR',
        size              => 255,
        is_nullable       => 1,
        },    
    task_type => {
        data_type         => 'ENUM',
        is_nullable       => 1,
        default           => 'Tool',
        default_value     => 'Tool',
        extra             => { list => [qw/
            Tool Application Send Receive Script Service User Manual Reference/] },
        },
    task_data => {
        data_type         => 'TEXT',
        is_nullable       => 1,
        serializer_class  => 'JSON',
        },     
    actual_params => {
        data_type         => 'TEXT',
        is_nullable       => 1,
        serializer_class  => 'JSON',        
        },
    data_maps => {
        data_type         => 'TEXT',
        is_nullable       => 1,
        serializer_class  => 'JSON',
        },    
    extended_attr => {
        data_type         => 'TEXT',
        is_nullable       => 1,
        serializer_class  => 'JSON',        
        },
    );
__PACKAGE__->set_primary_key(qw/ task_id /);

__PACKAGE__->has_one(
    activity => 'BPM::Engine::Store::Result::Activity', 'activity_id'
    );

__PACKAGE__->belongs_to( # might_have?
    application => 'BPM::Engine::Store::Result::Application', 'application_id'
    );

1;
__END__