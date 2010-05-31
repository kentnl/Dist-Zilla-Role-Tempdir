use strict;
use warnings;

package Dist::Zilla::Tempdir::Item;

# ABSTRACT: A result object for things that DO() DZ::R::Tempdir; 

use Moose;
use Carp qw( croak );
use Scalar::Util qw( blessed );

use namespace::autoclean;

use Data::Dump qw( dump );

has 'status' => ( 
  isa        => 'Str',
#  required   => 1,
  is         => 'rw',
);

has 'file' => (
  isa      => 'Dist::Zilla::Role::File',
  required => 1,
  is       => 'rw',
);

has 'name' => (
  isa      => 'Str',
  required => 1,
  is       => 'rw',
);

sub _mk_status {
  my $name = shift;
  my $value = shift;

  my $setter = sub { 
    my $self = shift;
    croak $name . "is an instance method, not a class method" 
      unless blessed($self);
    croak "too many arguments ( 0 expected ) to ->" . $name 
      if @_ ;
  #  dump { "set_${name}($value)" => $self };
    $self->status($value);
  };

  my $getter = sub {
    my $self = shift;
    croak $name . "is an instance method, not a class method" 
      unless blessed($self);
    croak "too many arguments ( 0 expected ) to ->" . $name 
      if @_ ;
 #   dump { "is_${name}(${value})" => $self };
    $self->status() eq $value;
  };

  { 
    no strict 'refs';
    *{__PACKAGE__ . "::set_" . $name } = $setter;
    *{__PACKAGE__ . "::is_" . $name } = $getter;
  }
}

_mk_status('modified', 'M');
_mk_status('original', 'O');
_mk_status('new',      'N' );
_mk_status('deleted',  'D' );


__PACKAGE__->meta->make_immutable;

no Moose;

1;
