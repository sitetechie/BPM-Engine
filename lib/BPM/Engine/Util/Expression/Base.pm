
package BPM::Engine::Util::Expression::Base;
BEGIN {
    $BPM::Engine::Util::Expression::Base::VERSION   = '0.001';
    $BPM::Engine::Util::Expression::Base::AUTHORITY = 'cpan:SITETECH';
    }

use Moose;
use MooseX::StrictConstructor;
use namespace::autoclean;

has 'params' => (
    traits    => [ 'Hash' ],
    isa => 'HashRef',
    is => 'rw',
    default => sub { {} },
    handles => {
        get_param => 'get',        
        set_param => 'set',
        variables => 'keys',
        set_activity => [ set => 'activity' ],    
        },
    );

sub type {
    my ($self) = @_;

    my $type = ref $self;
    $type =~ s/Expression:://xms;
    $type =~ tr/A-Z/a-z/;

    return $type;
    }

__PACKAGE__->meta->make_immutable;

1;
__END__