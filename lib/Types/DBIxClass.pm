package Types::DBIxClass;
BEGIN {
  $Types::DBIxClass::VERSION = '0.01';
}
# ABSTRACT: Type::Library for DBIx::Class objects

use strict;
use warnings;
use Carp;

use Type::Library -base,
  -declare => qw(
    BaseResultSet
    BaseResultSource
    BaseRow
    BaseSchema
);
use Type::Utils -all;
use Type::Params;
use Types::Standard qw(Maybe Str RegexpRef ArrayRef Ref);

class_type BaseResultSet, { class => 'DBIx::Class::ResultSet' };

class_type BaseResultSource, { class => 'DBIx::Class::ResultSource' };

class_type BaseRow, { class => 'DBIx::Class::Row' };

class_type BaseSchema, { class => 'DBIx::Class::Schema' };

sub _eq_scalar_or_array {
    my($value, $other) = @_;
    return 1 if ! defined $other;
    return 1 if ! ref $other && $value eq $other;
    return 1 if ref($other) eq 'ARRAY' && grep { $value eq $_ } @$other;
    return 0;
}


my $check_param = Type::Params::compile(ArrayRef|Str);
my $check_param_reg = Type::Params::compile(RegexpRef|Str);

my %param_types=(ResultSet => BaseResultSet,
		 Row => BaseRow);

while (my ($type, $parent) = each %param_types) {
  declare $type,
  parent => $parent,
  constraint_generator => sub
  {
    return $parent unless @_;
    my ($source_name) = $check_param->(@_);
    return sub {
      if ($parent->check($_[0]) && _eq_scalar_or_array($_[0]->result_source->source_name, $source_name)) {
	return 1
      }
      else {
	my $r = $_[0] // '';
	carp sprintf(
            '%s is not a '.$type.'%s',
            ( $parent->check($r) ? $type.'[' . $r->result_source->source_name . ']' : qq('$r') ),
            ( defined $source_name ? qq([$source_name]) : '' )
	);
	return
      }
    }
  };
}

declare 'ResultSource',
  parent => BaseResultSource,
  constraint_generator => sub
  {
    return BaseResultSource unless @_;
    my ($source_name) = $check_param->(@_);
    return sub {
      if (is_BaseResultSource($_[0]) && _eq_scalar_or_array($_[0]->source_name, $source_name)) {
	return 1
      }
      else {
	my $r = $_[0] // '';
	carp sprintf(
            '%s is not a ResultSource%s',
            ( is_BaseResultSource($r) ? 'ResultSource[' . $r->source_name . ']' : qq('$r') ),
            ( defined $source_name ? qq([$source_name]) : '' )
	);
	return
      }
    }
  };


declare 'Schema',
  parent => BaseSchema,
  constraint_generator => sub
  {
    return BaseSchema unless @_;
    my ($pattern) = $check_param_reg->(@_);
    return sub {
      if (is_BaseSchema($_[0]) &&(!$pattern || ref($_[0]) =~ m/$pattern/)) {
	return 1
      }
      else {
	my $s = $_[0] // '';
	carp sprintf(
            '%s is not a Schema%s',
	    qq('$s'), $pattern ? qq([$pattern]) : '');
	return
      }
    }
  };

__PACKAGE__->meta->make_immutable;
1;


__END__
