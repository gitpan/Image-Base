package Image::Base ;    # Documented at the __END__

# $Id: Base.pm,v 1.2 2000/05/04 20:12:49 root Exp $

use strict ;

use vars qw( $VERSION ) ;
$VERSION = '1.00' ;

use Carp qw( croak ) ;
use Symbol () ;

# All the supplied methods are expected to be inherited by subclasses; some
# will be adequate, some will need to be overridden and some *must* be
# overridden.

### Private methods 
#
# _get          object
# _set          object

sub _get { # Object method
    my $self  = shift ;
#    my $class = ref( $self ) || $self ;
   
    $self->{shift()} ;
}


sub _set { # Object method
    my $self  = shift ;
#    my $class = ref( $self ) || $self ;
    
    my $field = shift ;

    $self->{$field} = shift ;
}


sub DESTROY {
    ; # Save's time
}


### Public methods


sub new   { croak __PACKAGE__ .   "::new() must be overridden" }
sub xy    { croak __PACKAGE__ .    "::xy() must be overridden" }
sub load  { croak __PACKAGE__ .  "::load() must be overridden" }
sub save  { croak __PACKAGE__ .  "::save() must be overridden" }
sub set   { croak __PACKAGE__ .   "::set() must be overridden" }


sub get { # Object method 
    my $self  = shift ;
#    my $class = ref( $self ) || $self ;
  
    my @result ;

    push @result, $self->_get( shift() ) while @_ ;

    wantarray ? @result : shift @result ;
}


sub new_from_image { # Object method 
    my $self     = shift ; # Must be an image to copy
    my $class    = ref( $self ) || $self ;
    my $newclass = shift ; # Class of target taken from class or object

    croak "new_from_image() cannot read $class" unless $self->can( 'xy' ) ;

    my( $width, $height ) = $self->get( -width, -height ) ;

    # If $newclass was an object reference we inherit its characteristics
    # except for width/height and any arguments we've supplied.
    my $obj = $newclass->new( -width => $width, -height => $height, @_ ) ;

    croak "new_from_image() cannot convert to " . ref $obj unless $obj->can( 'xy' ) ;

    for( my $x = 0 ; $x < $width ; $x++ ) {
        for( my $y = 0 ; $y < $height ; $y++ ) {
            $obj->xy( $x, $y, $self->xy( $x, $y ) ) ;
        }
    }

    $obj ;
}


1 ;


__END__

=head1 NAME

Image::Base - base class for loading, manipulating and saving images.

=head1 SYNOPSIS

This class should not be used directly. Known inheritors are Image::Xbm and
Image::Xpm.

An example of the generalised functionality that this class could provide is
the C<new_from_image()> method (described later) which can be used to copy an
image of one type to an image of another type.

If you want to create algorithms which manipulate 2D images in terms of
(x,y,colour) then you could extend this class (without changing the file), like
this:

    # Filename: mylibrary.pl
    package Image::Base ; # Switch to this class to build on it.
    
    sub mytransform {
        my $self  = shift ;
        my $class = ref( $self ) || $self ;

        # Perform your transformation here; might be drawing a line or filling
        # a rectangle or whatever... getting/setting pixels using $self->xy().
    }

    package main ; # Switch back to the default package.

Now if you C<require> mylibrary.pl after you've C<use>d Image::Xpm or any
other Image::Base inheriting classes then all these classes will inherit your
C<mytransform()> method.

=head1 DESCRIPTION

=head2 new_from_image()

    my $bitmap = Image::Xbm->new( -file => 'bitmap.xbm' ) ;
    my $pixmap = $bitmap->new_from_image( 'Image::Xpm', -cpp => 1 ) ;
    $pixmap->save( 'pixmap.xpm' ) ;

Note that the above will only work if you've installed Image::Xbm and
Image::Xpm, but will work correctly for any image object that inherits from
Image::Base and respects its API.

You can use this method to transform an image to another image of the same
type but with some different characteristics, e.g.

    my $p = Image::Xpm->new( -file => 'test1.xpm' ) ;
    my $q = $p->new_from_image( ref $p, -cpp => 2, -file => 'test2.xpm' ) ;
    $q->save ;

=head2 new()

Virtual - must be overridden.

Recommend that it at least supports C<-file> (filename), C<-width> and
C<-height>.

=head2 get()
     
    my $width = $i->get( -width ) ;
    my( $hotx, $hoty ) = $i->get( -hotx, -hoty ) ;

Get any of the object's attributes. Multiple attributes may be requested in a
single call.

See C<xy> get/set colours of the image itself.

=head2 set()

Virtual - must be overridden.

Set any of the object's attributes. Multiple attributes may be set in a single
call; some attributes are read-only.

See C<xy> get/set colours of the image itself.

=head2 xy()

Virtual - must be overridden. Expected to provide the following functionality:

    $i->xy( 4, 11, '#123454' ) ;    # Set the colour at point 4,11
    my $v = $i->xy( 9, 17 ) ;       # Get the colour at point 9,17

Get/set colours using x, y coordinates; coordinates start at 0. 

When called to set the colour the value returned is class specific; when
called to get the colour the value returned is the colour name, e.g. 'blue' or
'#f0f0f0', etc, e.g.

    $colour = xy( $x, $y ) ;  # e.g. #123456 
    xy( $x, $y, $colour ) ;   # Return value is class specific

We don't normally pick up the return value when setting the colour.

=head2 load()

Virtual - must be overridden. Expected to provide the following functionality:

    $i->load ;
    $i->load( 'test.xpm' ) ;

Load the image whose name is given, or if none is given load the image whose
name is in the C<-file> attribute.

=head2 save()

Virtual - must be overridden. Expected to provide the following functionality:

    $i->save ;
    $i->save( 'test.xpm' ) ;

Save the image using the name given, or if none is given save the image using
the name in the C<-file> attribute. The image is saved in xpm format.

=head1 CHANGES

2000/05/04

Created. 

=head1 AUTHOR

Mark Summerfield. I can be contacted as <summer@perlpress.com> -
please include the word 'imagebase' in the subject line.

=head1 COPYRIGHT

Copyright (c) Mark Summerfield 2000. All Rights Reserved.

This module may be used/distributed/modified under the LGPL. 

=cut

