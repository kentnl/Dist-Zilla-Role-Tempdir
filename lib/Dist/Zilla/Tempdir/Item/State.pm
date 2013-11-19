use strict;
use warnings;

package Dist::Zilla::Tempdir::Item::State;

# ABSTRACT: Intermediate state for a file

use Moose;

has 'hash' => ( is => ro =>, lazy_build => 1 );

has 'file' => (
  is       => ro =>,
  required => 1,
  handles => { name => name => },
);

has 'new_content' => ( is => ro =>, lazy_build => 1 );
has 'new_hash'    => ( is => ro =>, lazy_build => 1 );

has 'storage_prefix' => ( is => ro =>, required => 1 );

has '_digester' => ( is => ro =>, lazy_build => 1 );

sub _build__digester {
  require Digest::SHA;
  ## no critic ( ProhibitMagicNumbers )
  return Digest::SHA->new(512);
}

sub _digest_for {
  my ( $self, $content ) = @_;
  $self->_digester->reset();
  $self->_digester->add($content);
  return $self->_digester->b64digest;
}

sub _build_hash {
  my ($self) = @_;
  return $self->_digest_for( $self->_encoded_content );
}

sub _build_new_content {
  my ($self) = @_;
  return unless $self->on_disk;
  $self->_relpath->slurp_raw();
}

sub _build_new_hash {
  my ($self) = @_;
  return unless $self->on_disk;
  return $self->_digest_for( $self->new_content );
}

sub _encoded_content {
  my ($self) = @_;
  return $self->file->encoded_content if $self->file->can('encoded_content');
  return $self->content;
}

sub _relpath {
  my ($self) = @_;
  require Path::Tiny;
  my $d        = Path::Tiny->new( $self->storage_prefix );
  my $out_path = $d->child( $self->file->name );
  return $out_path;
}

sub write_out {
  my ($self) = @_;
  my $out_path = $self->_relpath();
  $out_path->parent->mkpath(1);
  $out_path->spew_raw( $self->_encoded_content );
}

sub on_disk {
  my ($self) = @_;
  my $out_path = $self->_relpath();
  return -e $out_path;
}

sub on_disk_changed {
  my ($self) = @_;
  return unless $self->on_disk;
  return $self->hash ne $self->new_hash;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
