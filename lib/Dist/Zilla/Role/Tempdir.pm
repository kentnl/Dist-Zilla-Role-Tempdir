package Dist::Zilla::Role::Tempdir;

# ABSTRACT: Shell Out and collect the result in a DZ plugin.

# $Id:$
use strict;
use warnings;

use Moose::Role;
use Digest::SHA;
use File::Tempdir;
use File::Slurp qw( write_file read_file );
use Path::Class qw( dir file );
use File::chdir;

use namespace::autoclean;

=head1 SYNOPSIS

  package Dist::Zilla::Plugin::FooBar;

  use Moose;
  with 'Dist::Zilla::Role::Tempdir';
  with 'Dist::Zilla::Role::FileInjector';
  with 'Dist::Zilla::Role::InstallTool';

  sub setup_installer {
    my ( $self, $arg ) = @_ ;

    my ( @generated_files ) = $self->capture_tempdir(sub{
      system( $somecommand );
    },{
      ignore_updated => 1,
    });

    for ( @generated_files ) {
      if( $_->name =~ qr/someregex/ ){
        $self->add_file( $file );
      }
    }
  }
=cut

=head1 METHODS

=head2 capture_tempdir

Creates a File::Tempdir and dumps the current state of Dist::Zilla's files into it.

Runs the specified codesub CHDir'ed into that tmpdir, and captures the changed files.

=cut

has _digester => (
  isa        => 'Digest::base',
  is         => 'rw',
  lazy_build => 1,
);

sub _build__digester {
  return Digest::SHA->new(512);
}

sub _digest_for {
  my ( $self, $data ) = @_;
  $self->_digester->reset;
  $self->_digester->add($$data);
  return $self->_digester->b64digest;
}

sub capture_tempdir {
  my ( $self, $code, $args ) = @_;

  $args = {} unless defined $args;
  $code = sub { }
    unless defined $code;

  my ($dzil);

  $dzil = $self->zilla;

  my ( $tempdir, $dir );
  $tempdir = File::Tempdir->new();
  $dir     = $tempdir->name;

  my %input_files;

  for my $file ( @{ $dzil->files } ) {
    my ( $name, $content, ) = ( $file->name, $file->content, );

    $input_files{ $file->name } = { hash => $self->_digest_for( \$content ), };

    my ($tmpfile) = dir($dir)->file($name);
    $tmpfile->dir->mkpath(1);
    write_file( $tmpfile->absolute . "", \$content );
  }
  use Data::Dump qw( dump );
  dump \%input_files;
  {
    local $CWD = $dir;
    $code->();
  }


}

1;

