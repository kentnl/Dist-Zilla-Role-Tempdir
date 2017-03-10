use 5.006;    #06 -> [pragmas, our]
use strict;
use warnings;

package Dist::Zilla::Tempdir::Item;

our $VERSION = '1.001004';

# ABSTRACT: A result object for things that DO() DZ::R::Tempdir;

# AUTHORITY

use Moose qw( has );
use MooseX::LazyRequire;
use namespace::autoclean;

use Carp qw(croak);
use Scalar::Util qw( blessed );

=attr status

  isa => Str,
  is  => rw,

The internal status character. You can mangle this yourself if you want, and for compatibility with older versions
of this dist, you may even have to, but try not to, if it breaks, something something something pieces.

Using the is_* and set_* accessors is a I<much> smarter idea.

At present, the characters M, O, N and D have defined meanings, but this could change. ( Its not even unforeseeable expanding it to
be 2 characters to represent different parts of state, I probably will not do that, but do not pretend I will not ;) )

=cut

has 'status' => (
  isa           => 'Str',
  lazy_required => 1,
  is            => 'rw',
);

=attr file

  isa      => Dist::Zilla::Role::File,
  required => 1,
  is       => rw

This is the Dist::Zilla::File::* item which we refer to. For items that C<is_deleted>, C<file> is likely to be the file before it got deleted.

For C<is_new> and C<is_original> files, the item is the file itself, and for C<is_modified>, its the modified version of the file.

=cut

has 'file' => (
  isa      => 'Dist::Zilla::Role::File',
  required => 1,
  is       => 'rw',
  handles  => { name => 'name' },
);

=method name

Proxy for C<< $item->file->name >>

This is the path to the file relative to the dist root.

=cut

sub _mk_status {
  my $name  = shift;
  my $value = shift;

  my $setter = sub {
    my $self = shift;
    return croak( $name . 'is an instance method, not a class method' ) unless blessed($self);
    return croak( 'too many arguments ( 0 expected ) to ->' . $name ) if @_;
    $self->status($value);
  };

  my $getter = sub {
    my $self = shift;
    return croak( $name . 'is an instance method, not a class method' ) unless blessed($self);
    return croak( 'too many arguments ( 0 expected ) to ->' . $name ) if @_;
    $self->status() eq $value;
  };

  {
    ## no critic ( ProhibitNoStrict )
    no strict 'refs';
    *{ __PACKAGE__ . q[::set_] . $name } = $setter;
    *{ __PACKAGE__ . q[::is_] . $name }  = $getter;
  }
  return 1;
}

=method is_modified

returns if the file is modified or not.

=method set_modified

sets the state to 'modified'

=cut

_mk_status( 'modified', 'M' );

=method is_original

returns if the file is the original file or not.

=method set_original

sets the state to 'original'

=cut

_mk_status( 'original', 'O' );

=method is_new

returns if the file is new or not ( that is, if it wasn't in the dist prior to executing
the given code ).

=method set_new

sets the state to 'new'

=cut

_mk_status( 'new', 'N' );

=method is_deleted

returns if the file is deleted or not ( that is, if it were deleted during the execution phase )

=method set_deleted

sets the state to 'deleted'

=cut

_mk_status( 'deleted', 'D' );

__PACKAGE__->meta->make_immutable;

no Moose;

1;

=head1 SYNOPSIS

  my $foo = Dist::Zilla::Tempdir::Item->new(
    name => 'Path/To/File.txt',
    file => $dzilfile,
  );
  $foo->set_new;
  $foo->is_new; # true
  $foo->is_deleted; # false
  $foo->set_deleted;
  $foo->is_new; # false
  $foo->is_deleted; # true.

Ultimately, I figured using a character with "C<eq>" every where in extending code
was a way to extra bugs that were hard to detect. Going via all the Object-Oriented niceness
you'll probably incur* a small performance penalty,  but things going B<Bang> when you
make a typo or add invisible white-space is a Good Thing.

* albeit immeasurably insignificant in size, especially for something that will only take
15 seconds of run-time every once in a while, not to mention the overhead is drowned by the
fact we're doing file-system IO and running many of the files through a complete hashing
algorithm to test for modification.

=cut
