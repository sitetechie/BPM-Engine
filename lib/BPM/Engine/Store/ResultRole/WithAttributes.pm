package BPM::Engine::Store::ResultRole::WithAttributes;
BEGIN {
    $BPM::Engine::Store::ResultRole::WithAttributes::VERSION   = '0.001';
    $BPM::Engine::Store::ResultRole::WithAttributes::AUTHORITY = 'cpan:SITETECH';
    }

use namespace::autoclean;
use Moose::Role;
use BPM::Engine::Exceptions qw/throw_store/;

sub attribute {
    my ($self, $name, $value) = @_;
    
    my $attr = $self->attributes->find({ name => $name }) 
        or throw_store error => "Attribute named '$name' not found";
    if(defined $value) {
        $attr->update({ value => $value });
        }
    return $attr;
    }

sub create_attributes {
    my ($self, $scope, $data_fields) = @_;

    foreach my $param(@{$data_fields}) {
        $self->add_to_attributes({
            name => $param->{Id},
          mode => $param->{Mode}, #IsArray
            scope => $scope,
            type => $param->{DataType}->{BasicType}->{Type},
            value => $param->{InitialValue},
            });
        }
    }

# ABSTRACT: attribute creator and accessor role for ProcessInstance and ActivityInstance

1;
__END__