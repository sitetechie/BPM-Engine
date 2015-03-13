package BPM::Engine::Types;
use strict;
use warnings;

use namespace::autoclean;
use Type::Library -base;
use Type::Utils 'extends';

BEGIN {
  $BPM::Engine::Types::VERSION   = '0.01';
  $BPM::Engine::Types::AUTHORITY = 'cpan:SITETECH';

  extends 'Types::Standard';
#  extends 'MooseX::Types::Moose';
  extends 'MooseX::Types::UUID';
  extends 'MooseX::Types::DBIx::Class';
  extends 'BPM::Engine::Types::Internal';
}

1;
__END__

=pod

=head1 NAME

BPM::Engine::Types - Exports BPM::Engine internal types as well as Moose types

=head1 VERSION

version 0.01

=head1 AUTHOR

Peter de Vos, C<< <sitetech@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2010, 2011 Peter de Vos C<< <sitetech@cpan.org> >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
