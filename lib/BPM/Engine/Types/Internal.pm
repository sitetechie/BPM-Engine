package BPM::Engine::Types::Internal;
BEGIN {
    $BPM::Engine::Types::Internal::VERSION   = '0.01';
    $BPM::Engine::Types::Internal::AUTHORITY = 'cpan:SITETECH';
    }
## no critic (RequireTidyCode)
use strict;
use warnings;

use Type::Library -base,
  -declare => qw/
    LibXMLDoc
    Exception
    ConnectInfo
    UUID
  /;
use Type::Utils -all;
use Types::Standard qw/
    Str HashRef CodeRef Object StrMatch
    /;

declare LibXMLDoc,
  as      Object,
  where   { $_->isa('XML::LibXML::Document') },
  message { "Object isn't a XML::LibXML::Document" };

declare Exception,
  as      Object,
  where   { $_->isa('BPM::Engine::Exception') },
  message { "Object isn't an Exception" };

declare ConnectInfo,
  as      HashRef,
  where   { exists $_->{dsn} || exists $_->{dbh_maker} },
  message { 'Does not look like a valid connect_info' };


coerce ConnectInfo,
  from Str,      via(\&_coerce_connect_info_from_str),
  from CodeRef,  via { +{ dbh_maker => $_ } };

sub _coerce_connect_info_from_str {
    +{ dsn => $_, user => '', password => '' }
    }

declare UUID,
  as StrMatch[ qr/^[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}$/ ];

__PACKAGE__->meta->make_immutable;

1;
__END__
