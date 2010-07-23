use strict;
use warnings;

package Dist::Zilla::Role::Tempdir;
BEGIN {
  $Dist::Zilla::Role::Tempdir::VERSION = '0.01027622';
}

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
      hash => $self->digest_for( \$content ),
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
      name => $_,
      file => $input_files{$_}->{file},
    );
    $output_files{$_}->set_deleted;
  }

  for my $filename (@files) {

    my $shortname = file($filename)->relative($dir)->stringify;
    my $content   = file($filename)->slurp;
    my $hash      = $self->digest_for( \$content );

    if ( exists $input_files{$shortname} ) {

      # FILE NOT MODIFIED, (O)riginal

      if ( $input_files{$shortname}->{hash} eq $hash ) {
        $output_files{$shortname}->set_original;
        $output_files{$shortname}->file( $input_files{$shortname}->{file} );
        next;
      }

      # FILE (M)odified
      $output_files{$shortname}->set_modified;
      $output_files{$shortname}->file(
        Dist::Zilla::File::InMemory->new(
          name    => $shortname,
          content => $content,
        )
      );
      next;
    }

    # FILE (N)ew
    $output_files{$shortname} = Dist::Zilla::Tempdir::Item->new(
      name => $shortname,
      file => Dist::Zilla::File::InMemory->new(
        name    => $shortname,
        content => $content,
      ),
    );
    $output_files{$shortname}->set_new;
  }

  return values %output_files;
}


sub digest_for {
  my ( $self, $data ) = @_;
  $self->_digester->reset;
  $self->_digester->add( ${$data} );
  return $self->_digester->b64digest;
}


has _digester => (
  isa        => 'Digest::base',
  is         => 'rw',
  lazy_build => 1,
);


## no critic ( ProhibitUnusedPrivateSubroutines )
sub _build__digester {
  ## no critic ( ProhibitMagicNumbers )
  return Digest::SHA->new(512);
}


no Moose::Role;
1;


__END__
=pod

=head1 NAME

Dist::Zilla::Role::Tempdir - Shell Out and collect the result in a DZ plug-in.

=head1 VERSION

version 0.01027622

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
      if( $_->is_new && $_->name =~ qr/someregex/ ){
        $self->add_file( $_->file );
      }
    }
  }

This role is a convenience role for factoring into other plug-ins to use the power of Unix
in any plug-in.

If for whatever reason you need to shell out and run your own app that is not Perl ( i.e.: Java )
to go through the code and make modifications, produce documentation, etc, then this role is for you.

Important to note however, this role B<ONLY> deals with getting C<Dist::Zilla>'s state written out to disk,
executing your given arbitrary code, and then collecting the results. At no point does it attempt to re-inject
those changes back into L<< C<Dist::Zilla>|Dist::Zilla >>. That is left as an exercise to the plug-in developer.

=head1 METHODS

=head2 capture_tempdir

Creates a File::Tempdir and dumps the current state of Dist::Zilla's files into it.

Runs the specified code sub C<chdir>'ed into that C<tmpdir>, and captures the changed files.

  my ( @array ) = $self->capture_tempdir(sub{

  });

Response is an array of L<< C<::Tempdir::Item>|Dist::Zilla::Tempdir::Item >>

   [ bless( { name => 'file/Name/Here' ,
      status => 'O' # O = Original, N = New, M = Modified, D = Deleted
      file   => Dist::Zilla::Role::File object
    }, 'Dist::Zilla::Tempdir::Item' ) , bless ( ... ) ..... ]

Make sure to look at L<< C<Dist::Zilla::Tempdir::Item>|Dist::Zilla::Tempdir::Item >> for usage.

=head2 digest_for

  my $hash = $self->digest_for( \$content );

Hashes content and returns the result in b64.

=head1 PRIVATE ATTRIBUTES

=head2 _digester

  isa => Digest::base,
  is  => rw,
  lazy_build => 1

Used for Digesting the contents of files.

=head1 PRIVATE METHODS

=head2 _build__digester

returns an instance of Digest::SHA with 512bit hashes.

=head1 SEE ALSO

=over 4

=item * L<< C<Dist::Zilla::Tempdir::Item>|Dist::Zilla::Tempdir::Item >>

=back

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Kent Fredric.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

