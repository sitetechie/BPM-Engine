package BPM::Engine::Util::ExpressionEvaluator;
BEGIN {
    $BPM::Engine::Util::ExpressionEvaluator::VERSION   = '0.001';
    $BPM::Engine::Util::ExpressionEvaluator::AUTHORITY = 'cpan:SITETECH';
    }

use strict;
use warnings;
use Class::MOP ();
use BPM::Engine::Util::Expression::TT;

sub load {
    my ($class, @args) = @_;
    return BPM::Engine::Util::Expression::TT->new(params => { @args });
    }

1;
__END__