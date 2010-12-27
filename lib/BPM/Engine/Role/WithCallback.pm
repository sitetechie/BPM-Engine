package BPM::Engine::Role::WithCallback;
BEGIN {
    $BPM::Engine::Role::WithCallback::VERSION   = '0.001';
    $BPM::Engine::Role::WithCallback::AUTHORITY = 'cpan:SITETECH';
    }

use Moose::Role;
use BPM::Engine::Types qw/CodeRef Str/;
use namespace::autoclean;

has 'callback' => (
    traits     => ['Code'],
    is         => 'ro',
    isa        => CodeRef|Str,
    required   => 0,
    predicate  => 'has_callback',
    handles    => {
        call_callback => 'execute',
        },
    );

no Moose::Role;

1;
__END__
