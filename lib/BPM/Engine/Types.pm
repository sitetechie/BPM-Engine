package BPM::Engine::Types;

our $VERSION   = '0.02';
our $AUTHORITY = 'cpan:SITETECH';

use strict;
use warnings;

use Type::Library -base;
use Type::Utils 'extends';

BEGIN {
    extends 'Types::Standard';
    extends 'Types::DBIx::Class';
    extends 'BPM::Engine::Types::Internal';
}

__PACKAGE__->meta->make_immutable;

1;
__END__

=pod

=head1 NAME

BPM::Engine::Types - Exports BPM::Engine internal types as well as Moose types

=head1 AUTHOR

Peter de Vos, C<< <sitetech@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2010, 2011 Peter de Vos C<< <sitetech@cpan.org> >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
