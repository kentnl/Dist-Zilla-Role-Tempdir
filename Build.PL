
use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
  module_name   => 'Dist::Zilla::Role::Tempdir',
  license       => 'perl',
  dist_abstract => "Shell\ Out\ and\ collect\ the\ result\ in\ a\ DZ\ plug\-in\.",
  dist_name     => "Dist\-Zilla\-Role\-Tempdir",
  dist_author   => [
"Kent\ Fredric\ \<kentnl\@cpan\.org\>",
  ],
  requires      => {
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
  script_files => [ qw() ],
);

$build->create_build_script;
