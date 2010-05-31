use strict;
use warnings;

package Dist::Zilla::Role::Tempdir;

# ABSTRACT: Shell Out and collect the result in a DZ plug-in.

use Moose::Role;
use Digest::SHA;
use File::Tempdir;
use File::Slurp qw( write_file read_file );
use Path::Class qw( dir file );
use File::chdir;
use File::Find::Rule;
use Dist::Zilla::File::InMemory;
use Dist::Zilla::Tempdir::Item;

use namespace::autoclean;

=head1 SYNOPSIS

  package #
    Dist::Zilla::Plugin::FooBar;

  use Moose;
  with 'Dist::Zilla::Role::Tempdir';
  with 'Dist::Zilla::Role::FileInjector';
  with 'Dist::Zilla::Role::InstallTool';

  sub setup_installer {
    my ( $self, $arg ) = @_ ;

    my ( @generated_files ) = $self->capture_tempdir(sub{
      system( $somecommand );
    });

    for ( @generated_files ) {
      if( $_->{status} eq 'N' && $_->{name} =~ qr/someregex/ ){
        $self->add_file( $_->{file});
      }
    }
  }

=cut

=head1 METHODS

=head2 capture_tempdir

Creates a File::Tempdir and dumps the current state of Dist::Zilla's files into it.

Runs the specified code sub C<chdir>'ed into that C<tmpdir>, and captures the changed files.

  my ( @array ) = $self->capture_tempdir(sub{

  });

Response is an array of hash-ref.

    { name => 'file/Name/Here' ,
      status => 'O' # O = Original, N = New, M = Modified, D = Deleted
      file   => Dist::Zilla::Role::File object ( missing if status => 'D'),
    }

=cut

sub capture_tempdir {
  my ( $self, $code, $args ) = @_;

  $args = {} unless defined $args;
  $code = sub { }
    unless defined $code;

  my ($dzil);

  $dzil = $self->zilla;

  my ( $tempdir, $dir );
  $tempdir = File::Tempdir->new();
  $dir     = dir( $tempdir->name );

  my %input_files;

  for my $file ( @{ $dzil->files } ) {
    my ( $name, $content, ) = ( $file->name, $file->content, );

    $input_files{ $file->name } = {
      hash => $self->_digest_for( \$content ),
      file => $file,
    };

    my ($tmpfile) = $dir->file($name);
    $tmpfile->dir->mkpath(1);
    write_file( $tmpfile->absolute->stringify, \$content );
  }
  {
    ## no critic ( ProhibitLocalVars )
    local $CWD = $dir;
    $code->();
  }
  my (@files) = File::Find::Rule->file->in($dir);

  my %output_files;

  for ( keys %input_files ) {
    $output_files{$_} = Dist::Zilla::Tempdir::Item->new(
      name   => $_,
      file   => $input_files{$_}->{file},
    );
    $output_files{$_}->set_deleted;
  }

  for my $filename (@files) {

    my $shortname = file($filename)->relative($dir)->stringify;
    my $content   = file($filename)->slurp;
    my $hash      = $self->_digest_for( \$content );

    if ( exists $input_files{$shortname} ) {

      # FILE NOT MODIFIED, (O)riginal

      if ( $input_files{$shortname}->{hash} eq $hash ) {
        $output_files{$shortname}->set_original;
        $output_files{$shortname}->file( $input_files{$shortname}->{file} );
        next;
      }

      # FILE (M)odified
      $output_files{$shortname}->set_modified;
      $output_files{$shortname}->file( Dist::Zilla::File::InMemory->new(
        name    => $shortname,
        content => $content,
      ));
      next;
    }

    # FILE (N)ew
    $output_files{$shortname} = Dist::Zilla::Tempdir::Item->new(
      name   => $shortname,
      file   => Dist::Zilla::File::InMemory->new(
        name    => $shortname,
        content => $content,
      ),
    );
    $output_files{$shortname}->set_new;
  }

  return values %output_files;
}

=head1 PRIVATE ATTRIBUTES

=head2 _digester

  isa => Digest::base,
  is  => rw,
  lazy_build => 1

Used for Digesting the contents of files.

=cut

has _digester => (
  isa        => 'Digest::base',
  is         => 'rw',
  lazy_build => 1,
);

=head1 PRIVATE METHODS

=head2 _build__digester

returns an instance of Digest::SHA with 512bit hashes.

=cut

sub _build__digester {
  ## no critic ( ProhibitMagicNumbers )
  return Digest::SHA->new(512);
}

=head2 _digest_for

  my $hash = $self->_digest_for( \$content );

Hashes content and returns the result in b64.

=cut

sub _digest_for {
  my ( $self, $data ) = @_;
  $self->_digester->reset;
  $self->_digester->add( ${$data} );
  return $self->_digester->b64digest;
}

no Moose::Role;
1;

