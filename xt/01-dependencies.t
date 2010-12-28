#!/usr/bin/env perl

# Makes sure that all of the modules that are 'use'd are listed in the Makefile.PL as dependencies.

use warnings;
use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

my @MODULES = (
	'Module::CoreList 2.42',
);

# Don't run tests during end-user installs
use Test::More;
use File::Find;
unless ( $ENV{AUTOMATED_TESTING} or $ENV{RELEASE_TESTING} ) {
	plan( skip_all => "Author tests not required for installation" );
}

# Load the testing modules
foreach my $MODULE ( @MODULES ) {
	eval "use $MODULE";
	if ( $@ ) {
		$ENV{RELEASE_TESTING}
		? die( "Failed to load required release-testing module $MODULE" )
		: plan( skip_all => "$MODULE not available for testing" );
	}
}

plan 'no_plan';

my %used;
find( \&wanted, qw/ lib bin t / );

sub wanted {
    return unless -f $_;
    return if $File::Find::dir  =~ m!/.svn($|/)!;
    return if $File::Find::name =~ /~$/;
    return if $File::Find::name =~ /\.(pod|html)$/;

    # read in the file from disk
    my $filename = $_;
    local $/;
    open( FILE, $filename ) or return;
    my $data = <FILE>;
    close(FILE);

    # strip pod, in a really idiotic way.  Good enough though
    $data =~ s/^=head.+?(^=cut|\Z)//gms;

    # look for use and use base statements
    $used{$1}{$File::Find::name}++ while $data =~ /^\s*(?:use|require)\s+([\w:]+)/gm;
    while ( $data =~ m|^\s*use base qw.([\w\s:]+)|gm ) {
        $used{$_}{$File::Find::name}++ for split ' ', $1;
    }
}

my %required;
{
    local $/;
    ok( open( MAKEFILE, "Makefile.PL" ), "Opened Makefile" );
    my $data = <MAKEFILE>;
    close(FILE);
    while ( $data =~ /^\s*?(?:requires|recommends|).*?([\w:]+)'(?:\s*=>\s*['"]?([\d\.]+)['"]?)?.*?(?:#(.*))?$/gm ) {
        $required{$1} = $2;
        if ( defined $3 and length $3 ) {
            $required{$_} = undef for split ' ', $3;
        }
    }
}

for ( sort keys %used ) {
    next if /^(Graph::Directed|DBIx::Class::Schema|Moose::Role|MooseX::Types::Moose|Template::Stash|XML::LibXML::XPathContext|BPM::Engine|inc|t)(::|$)/;
    next if /^5/;
    my $first_in = Module::CoreList->first_release($_);
    #next if defined $first_in and $first_in <= 5.00803;
    next if defined $first_in and $first_in <= 5.010;

    #warn $_;
    ok( exists $required{$_}, "$_ in Makefile.PL" )
        or diag( "used in ", join ", ", sort keys %{ $used{$_} } );
    delete $used{$_};
    delete $required{$_};
}

for ( sort keys %required ) {
    my $first_in = Module::CoreList->first_release( $_, $required{$_} );
    my $v  = $required{$_} || '0';
    fail("Required module $_ (v. $v) is in core since $first_in")
        if defined $first_in and $first_in <= 5.010;
}

1;
