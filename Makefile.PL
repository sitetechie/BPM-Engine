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

build_requires  'Test::More'                => '0.92';
build_requires  'Test::Exception';
build_requires  'File::Find';
build_requires  'File::Copy';
build_requires  'File::Spec';

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

author_requires 'Test::Pod'                 => '1.14';
author_requires 'Test::Pod::Coverage';
author_requires 'Pod::Coverage::Moose';
#author_requires 'Test::Kwalitee';

requires        'Moose'                     => '0.57';
requires        'MooseX::StrictConstructor' => '0.07';
requires        'MooseX::Types'             => '0.23';
requires        'MooseX::LogDispatch'       => '1.20';
requires        'Exception::Class'          => '1.29';
requires        'Class::Workflow'           => '0.11';
requires        'DBIx::Class';
requires        'Template'                  => '2.20';
requires        'Silly::Werder';
requires        'XML::LibXML';
requires        'File::ShareDir';
requires        'XML::LibXML::Simple';
requires        'BPM::XPDL';
requires        'Try::Tiny';
requires        'File::ShareDir'            => '1.00';
requires        'Path::Class'               => '0.21';

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
