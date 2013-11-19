use strict;
use warnings;

package Dist::Zilla::Tempdir::Item::State;
BEGIN {
  $Dist::Zilla::Tempdir::Item::State::AUTHORITY = 'cpan:KENTNL';
}
{
  $Dist::Zilla::Tempdir::Item::State::VERSION = '0.01053723';
}

# ABSTRACT: Intermediate state for a file

use Moose;
use Path::Tiny qw(path);

has 'hash' => ( is => ro =>, lazy_build => 1 );

has 'file' => (
  is       => ro =>,
  required => 1,
  handles => { name => name => },
);

has 'new_content' => ( is => ro =>, lazy_build => 1 );
has 'new_hash'    => ( is => ro =>, lazy_build => 1 );

has 'storage_prefix' => ( is => ro =>, required => 1 );

has '_digester' => ( is => ro =>, required => 1 );

sub name {
  my ($self) = @_;
  return $self->file->name;
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
  my ( $self ) = @_;
  return unless $self->on_disk;
  $self->_relpath->slurp_raw();
}
sub _build_new_hash { 
    my ( $self ) = @_;
    return unless $self->on_disk;
    return $self->_digest_for( $self->new_content );
}

sub _encoded_content {
  my ($self) = @_;
  return $self->file->encoded_content if $self->file->can('encoded_content');
  return $self->content;
}

sub _relpath {
  my ( $self ) = @_;
  my $d        = path($self->storage_prefix);
  my $out_path = $d->child( $self->file->name );
  return $out_path;
}

sub write_out {
  my ( $self ) = @_;
  my $out_path = $self->_relpath();
  $out_path->parent->mkpath(1);
  $out_path->spew_raw( $self->_encoded_content );
}

sub on_disk {
  my ( $self ) = @_;
  my $out_path = $self->_relpath();
  return -e $out_path;
}

sub on_disk_changed {
  my ( $self ) = @_;
  return unless $self->on_disk;
  return $self->hash ne $self->new_hash;
}

__END__

=pod

=head1 NAME

Dist::Zilla::Tempdir::Item::State - Intermediate state for a file

=head1 VERSION

version 0.01053723

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Kent Fredric.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
