use strict;
use warnings;

sub author_requires     {}
sub author_tests        {}
sub readme_from         {}
sub auto_set_repository {}
sub version_check       {}
sub manifest_skip       {}
sub auto_manifest       {}
sub auto_license        {}
sub auto_include        {}
sub auto_include_deps   {}

use inc::Module::Install;

name            'BPM-Engine';
all_from        'lib/BPM/Engine.pm';
readme_from;
homepage        'http://bpmengine.org/';

author_requires 'Module::Install::AuthorRequires';
author_requires 'Module::Install::AutoManifest';
author_requires 'Module::Install::AutoLicense';
author_requires 'Module::Install::AuthorTests';
author_requires 'Module::Install::ReadmeFromPod';
author_requires 'Module::Install::ExtraTests';
author_requires 'Module::Install::ManifestSkip';
author_requires 'Module::Install::GithubMeta';
author_requires 'Module::Install::Repository';
author_requires 'Module::Install::VersionCheck';

author_requires 'Test::Pod'                  => '1.14';
author_requires 'Test::Pod::Coverage';
author_requires 'Pod::Coverage::Moose';
author_requires 'Test::Perl::Critic'         => '1.02';
author_requires 'Perl::Critic'               => '1.11';

build_requires  'Test::More'                 => '0.92';
build_requires  'Test::Exception'            => '0.29';
build_requires  'Test::Moose'                => '1.17';

requires        'namespace::clean'           => '0.18';
requires        'namespace::autoclean'       => '0.11';
requires        'Class::MOP'                 => '1.1';
requires        'Moose'                      => '0.57';
requires        'MooseX::StrictConstructor'  => '0.07';
requires        'MooseX::Types'              => '0.23';
requires        'MooseX::Types::UUID'        => '0.02';
requires        'MooseX::Declare'            => '0.34';
requires        'MooseX::LogDispatch'        => '1.20';
requires        'MooseX::Traits'             => '0.11';
requires        'Exception::Class'           => '1.29';
requires        'Sub::Exporter'              => '0.98';
requires        'Class::Workflow'            => '0.11';
requires        'DBIx::Class'                => '0.08';
requires        'DBIx::Class::InflateColumn::Serializer' => '0.02';
requires        'DBIx::Class::Helpers'       => '2.005';
requires        'Template'                   => '2.20';
requires        'Silly::Werder'              => '0.90';
requires        'XML::LibXML'                => '1.70';
requires        'XML::LibXML::Simple'        => '0.13';
requires        'File::ShareDir'             => '1.02';
requires        'BPM::XPDL'                  => '0.04';
requires        'File::ShareDir'             => '1.00';
requires        'Path::Class'                => '0.21';
requires        'DateTime'                   => '0.53';
requires        'Graph'                      => '0.94';

feature          'Graphviz rendering'        => -default => 1,
                 'GraphViz'                  => '2.04',
                 'Graph::Writer::GraphViz'   => '0.10';

tests           't/*.t';
author_tests    'xt';

manifest_skip;
auto_set_repository;
auto_manifest;
auto_license;
auto_include;
version_check;

auto_include_deps;
install_share 'share';
auto_install;
WriteAll;
