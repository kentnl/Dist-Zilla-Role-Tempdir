
use strict;
use warnings;

use Test::More tests => 1;                      # last test to print

use Dist::Zilla;
use Dist::Zilla::Role::Tempdir;

{
  package Dist::Zilla::Plugin::TestTempDir;
  use Moose;
  with 'Dist::Zilla::Role::Tempdir';
  with 'Dist::Zilla::Role::FileInjector';
  with 'Dist::Zilla::Role::InstallTool';


  sub setup_installer {
    my ( $self, $arg ) = @_ ;

  }

  __PACKAGE__->meta->make_immutable;
}


my $dz = Dist::Zilla->new(
  root => 't/fake/' ,
  name => 'Test-DZRTd',
  copyright_holder => 'Kent Fredric',
  main_module => 't/fake/dist.pm',
  abstract => "A Fake Dist",
  license => "Perl_5",
  plugins => [],
);

for ( qw( AllFiles ) ) {
  my $full = 'Dist::Zilla::Plugin::' . $_;
  eval "use $full; 1" or die( "Cant load plugin >$full<" );
  my $plug = $full->new( zilla => $dz, plugin_name => $_ );

  push @{$dz->plugins}, $plug;
}

$_->gather_files for @{$dz->plugins_with(-FileGatherer)};

my $plug = Dist::Zilla::Plugin::TestTempDir->new(
  zilla => $dz,
  plugin_name => 'TestTempDir',
);


$plug->capture_tempdir(sub{
  system( 'find ./' );
});
