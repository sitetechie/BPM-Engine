package BPM::Engine::Util::Expression::TT;
BEGIN {
    $BPM::Engine::Util::Expression::TT::VERSION   = '0.001';
    $BPM::Engine::Util::Expression::TT::AUTHORITY = 'cpan:SITETECH';
    }

use Moose;
use MooseX::StrictConstructor;
use Template::Stash;
use Template;
use List::Util ();
use BPM::Engine::Exceptions qw/throw_expression throw_abstract/;
use namespace::autoclean -also => [qr/^_/];
extends 'BPM::Engine::Util::Expression::Base';

# list.contains(string) to assess membership for a scalar
$Template::Stash::LIST_OPS->{contains} = sub {
    my $array = shift;
    my $item = shift;
    return grep { $_ eq $item } @$array ? 1 : 0;
    };

$Template::Stash::LIST_OPS->{sum} = sub {
    my $array = shift;
    return [ List::Util::sum(@$array) ];
    };

my $TT = Template->new(
    INTERPOLATE => 1,
    TRIM        => 1,
    PRE_CHOMP   => 1,
    POST_CHOMP  => 1,
    AUTO_RESET  => 1,
    EVAL_PERL   => 1,
    ENCODING    => 'utf8'
    ) or die $Template::ERROR;

sub parse {
    my ($self, $expr) = @_;
    return _render_template($self, $expr, $self->params);
    }

sub evaluate {
    my ($self, $expr) = @_;
    return 0 unless $expr;

    my $boolean = $self->parse($expr) || 0; # tt returns undef
    #warn "EVAL $expr - $boolean";       
    
    throw_expression("Condition evalutation did not result in a boolean") unless $boolean =~ /^\d$/;
    throw_expression("Condition evalutation did not result in a true boolean, but $boolean") unless ($boolean == 0 || $boolean == 1);
    
    return $boolean;
    }

sub assign {
    my ($self, $var, $val) = @_;
    throw_abstract("Assignments not implemented yet (assigning $val to $var)");
    }

sub _render_template {
    my ($self, $template, $args) = @_;

    $template = '[% ' . $template . ' %]' unless $template =~ /^\[%/;
    #$template = '[% USE ListMoreUtilsVMethods %]' . $template;

    my $output = '';
    unless($TT->process(\$template, $args, \$output, { binmode => ':utf8'} ) ) {
        throw_expression($TT->error);
        }
    $output =~ s/\s+$//xmsg;
    return $output;
    }

__PACKAGE__->meta->make_immutable;

1;
__END__
