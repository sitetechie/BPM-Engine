
package BPM::Engine::Store::ResultRole::WithAttributes;
#ABSTRACT: attribute accessor role for ProcessInstance and ActivityInstance
BEGIN {
    $BPM::Engine::Store::ResultRole::WithAttributes::VERSION   = '0.001';
    $BPM::Engine::Store::ResultRole::WithAttributes::AUTHORITY = 'cpan:SITETECH';
    }

use Moose::Role;
use namespace::autoclean;

sub attribute {
    my ($self, $name, $value) = @_;
    
    my $attr = $self->attributes->find({ name => $name }) 
        or return undef; #die("Attribute named '$name' not found");
    if($value) {
        $attr->update({ value => $value });
        }
    return $attr;
    }

1;
__END__