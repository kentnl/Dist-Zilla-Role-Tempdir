use 5.008;    # utf8
use strict;
use warnings;
use utf8;

package Dist::Zilla::Tempdir::Dir;
$Dist::Zilla::Tempdir::Dir::VERSION = '1.000000';
# ABSTRACT: A temporary directory with a collection of item states

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moose qw( has );
use File::chdir;
use Dist::Zilla::Tempdir::Item::State;
use Dist::Zilla::Tempdir::Item;
use Path::Iterator::Rule;
use Dist::Zilla::File::InMemory;
use Path::Tiny qw(path);

has '_tempdir' => (
  is         => ro =>,
  lazy_build => 1,
);

sub _build__tempdir {
  return Path::Tiny->tempdir;
}

has '_input_files' => (
  isa     => 'HashRef',
  traits  => [qw( Hash )],
  is      => ro =>,
  lazy    => 1,
  default => sub { {} },
  handles => {
    '_set_input_file'  => 'set',
    '_all_input_files' => 'values',
    '_has_input_file'  => 'exists',
  },
);

has '_output_files' => (
  isa     => 'HashRef',
  traits  => [qw( Hash )],
  is      => ro =>,
  lazy    => 1,
  default => sub { {} },
  handles => {
    '_set_output_file' => 'set',
    'all_output_files' => 'values',
  },
);

sub add_file {
  my ( $self, $file ) = @_;
  my $state = Dist::Zilla::Tempdir::Item::State->new(
    file           => $file,
    storage_prefix => $self->_tempdir,
  );
  $state->write_out;
  $self->_set_input_file( $file->name, $state );
  return;
}

sub update_input_file {
  my ( $self, $file ) = @_;

  my $update_item = Dist::Zilla::Tempdir::Item->new( name => $file->name, file => $file->file, );
  $update_item->set_original;

  if ( not $file->on_disk ) {
    $update_item->set_deleted;
  }
  elsif ( $file->on_disk_changed ) {
    $update_item->set_modified;
    my %params = ( name => $file->name, content => $file->new_content );
    if ( Dist::Zilla::File::InMemory->can('encoded_content') ) {
      $params{encoded_content} = delete $params{content};
    }
    $update_item->file( Dist::Zilla::File::InMemory->new(%params) );
  }
  $self->_set_output_file( $file->name, $update_item );
  return;
}

sub update_disk_file {
  my ( $self, $fullname ) = @_;
  my $fullpath  = path($fullname);
  my $shortname = $fullpath->relative( $self->_tempdir );

  my %params = ( name => "$shortname", content => $fullpath->slurp_raw );
  if ( Dist::Zilla::File::InMemory->can('encoded_content') ) {
    $params{encoded_content} = delete $params{content};
  }
  my $item = Dist::Zilla::Tempdir::Item->new(
    name => "$shortname",
    file => Dist::Zilla::File::InMemory->new(%params)
  );
  $item->set_new;
  $self->_set_output_file( "$shortname", $item );
  return;
}

sub update_input_files {
  my ($self) = @_;
  for my $file ( $self->_all_input_files ) {
    $self->update_input_file($file);
  }
  return;
}

sub update_disk_files {
  my ($self) = @_;
  for my $filename ( Path::Iterator::Rule->new->file->all( $self->_tempdir->stringify ) ) {
    next if $self->_has_input_file( path($filename)->relative( $self->_tempdir ) );
    $self->update_disk_file($filename);
  }
  return;
}

sub run_in {
  my ( $self, $code ) = @_;
  ## no critic ( ProhibitLocalVars )
  local $CWD = $self->_tempdir->stringify;
  return $code->();
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Dist::Zilla::Tempdir::Dir - A temporary directory with a collection of item states

=head1 VERSION

version 1.000000

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Kent Fredric.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
