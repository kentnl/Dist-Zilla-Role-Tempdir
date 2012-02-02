
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Dist::Zilla" => 0,
    "Dist::Zilla::Role::FileInjector" => 0,
    "Dist::Zilla::Role::InstallTool" => 0,
    "Dist::Zilla::Tester" => 0,
    "File::Find" => 0,
    "File::Temp" => 0,
    "Module::Build" => "0.3601",
    "Test::More" => "0.88"
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Shell Out and collect the result in a DZ plug-in.",
  "dist_author" => [
    "Kent Fredric <kentnl\@cpan.org>"
  ],
  "dist_name" => "Dist-Zilla-Role-Tempdir",
  "dist_version" => "0.01053721",
  "license" => "perl",
  "module_name" => "Dist::Zilla::Role::Tempdir",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Carp" => 0,
    "Digest::SHA" => "5.47",
    "Dist::Zilla" => "2.0",
    "Dist::Zilla::File::InMemory" => 0,
    "File::Find::Rule" => "0.30",
    "File::Slurp" => "9999.13",
    "File::Tempdir" => "0.02",
    "File::chdir" => "0.1002",
    "Moose" => "0.92",
    "Moose::Role" => 0,
    "Path::Class" => "0.17",
    "Scalar::Util" => 0,
    "namespace::autoclean" => "0.09",
    "perl" => "5.006",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
