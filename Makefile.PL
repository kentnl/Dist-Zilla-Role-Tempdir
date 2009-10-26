
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'Dist-Zilla-Role-Tempdir',
  NAME      => 'Dist::Zilla::Role::Tempdir',
  AUTHOR    => "Kent\ Fredric\ \<kentnl\@cpan\.org\>",
  ABSTRACT  => "Shell\ Out\ and\ collect\ the\ result\ in\ a\ DZ\ plug\-in\.",
  VERSION   => '0.01000003',
  EXE_FILES => [ qw() ],
  (eval { ExtUtils::MakeMaker->VERSION(6.31) } ? (LICENSE => 'perl') : ()),
  PREREQ_PM    => {
    "File::Find::Rule" => '0.30',
    "namespace::autoclean" => '0.09',
    "File::Tempdir" => '0.02',
    "Digest::base" => '1.16',
    "File::chdir" => '0.1002',
    "Digest::SHA" => '5.47',
    "Dist::Zilla" => '1.092930',
    "Path::Class" => '0.17',
    "File::Slurp" => '9999.13',
    "Moose" => '0.92',
  },
  test => {TESTS => 't/*.t'}
);

