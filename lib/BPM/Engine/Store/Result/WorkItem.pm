package BPM::Engine::Store::Result::WorkItem;
BEGIN {
    $BPM::Engine::Store::Result::WorkItem::VERSION   = '0.001';
    $BPM::Engine::Store::Result::WorkItem::AUTHORITY = 'cpan:SITETECH';
    }

use namespace::autoclean;
use Moose;
extends 'DBIx::Class';

__PACKAGE__->load_components(qw/ Core /);
__PACKAGE__->table('wfe_workitem');
__PACKAGE__->add_columns(
    workitem_id => {
        data_type         => 'INT',
        is_auto_increment => 1,
        is_nullable       => 0,
        extras            => { unsigned => 1 },
        size              => 11,
        },
    name => {
        data_type         => 'VARCHAR',
        size              => 64,
        is_nullable       => 1,
        },    
    parent_id => {
        data_type         => 'INT',
        extras            => { unsigned => 1 },
        is_foreign_key    => 1,
        is_nullable       => 1,
        },
    process_id => {
        data_type         => 'INT',
        is_foreign_key    => 1,
        is_nullable       => 0,
        extras            => { unsigned => 1 },
        },    
    process_instance_id => {
        data_type         => 'INT',
        is_foreign_key    => 1,
        is_nullable       => 0,
        extras            => { unsigned => 1 },
        },    
    activity_id => {
        data_type         => 'INT',
        extras            => { unsigned => 1 },
        is_foreign_key    => 1,
        is_nullable       => 0,
        },    
    token_id => {
        data_type         => 'INT',
        extras            => { unsigned => 1 },
        is_foreign_key    => 1,
        is_nullable       => 0,
        },    
    participant_id => {
        data_type         => 'INT',
        extras            => { unsigned => 1 },
        is_foreign_key    => 1,
        is_nullable       => 0,
        },    
    status => {
        data_type         => 'VARCHAR',
        size              => 20,
        is_nullable       => 1,
        },
    workitem_type => {
        data_type         => 'VARCHAR',
        size              => 20,
        is_nullable       => 1,
        },
    last_status_update => {
        data_type         => 'timestamp',
        is_nullable       => 1,
        },
    purpose_id => {
        data_type         => 'VARCHAR',
        size              => 20,
        is_nullable       => 1,
        },
    );

__PACKAGE__->set_primary_key(qw/ workitem_id /);
__PACKAGE__->belongs_to(
    process => 'BPM::Engine::Store::Result::Process', 'process_id'
    );
__PACKAGE__->belongs_to(
    process_instance => 'BPM::Engine::Store::Result::ProcessInstance', 
    { 'foreign.instance_id' => 'self.process_instance_id' }
    );
__PACKAGE__->belongs_to(
    activity => 'BPM::Engine::Store::Result::Activity', 'activity_id'
    );
__PACKAGE__->belongs_to(
    activity_instance => 'BPM::Engine::Store::Result::ActivityInstance', 'token_id'
    );
__PACKAGE__->belongs_to(
    participant => 'BPM::Engine::Store::Result::Participant', 'participant_id'
    );
__PACKAGE__->might_have(
    parent => __PACKAGE__, 'parent_id'
    );

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );

1;
__END__

=pod

=head1 NAME

BPM::Engine::Store::Result::WorkItem - DBIC schema class for WorkItem data

=head1 SYNOPSIS

    use BPM::Engine::Store;
    my $schema = BPM::Engine::Store->connect;
    my $items  = $schema->resultset('WorkItem')->search;

=head1 DESCRIPTION

This module is loaded by BPM::Engine::Store to read/write WorkItem data.

=head1 COLUMNS

  XXX TBD

=head1 RELATIONS

  XXX TBD

=head1 AUTHOR

Peter de Vos <sitetech@cpan.org>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

