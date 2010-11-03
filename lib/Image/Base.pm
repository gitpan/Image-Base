package Image::Base ;    # Documented at the __END__

use strict ;

use vars qw( $VERSION ) ;

$VERSION = '1.11' ;

use Carp qw( croak ) ;
use Symbol () ;

# uncomment this to run the ### lines
#use Smart::Comments '###';

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


sub new   { croak __PACKAGE__ .  "::new() must be overridden" }
sub xy    { croak __PACKAGE__ .   "::xy() must be overridden" }
sub load  { croak __PACKAGE__ . "::load() must be overridden" }
sub save  { croak __PACKAGE__ . "::save() must be overridden" }
sub set   { croak __PACKAGE__ .  "::set() must be overridden" }


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
    my $obj = $newclass->new( @_, -width => $width, -height => $height ) ;

    croak "new_from_image() cannot convert to " . ref $obj unless $obj->can( 'xy' ) ;

    for( my $x = 0 ; $x < $width ; $x++ ) {
        for( my $y = 0 ; $y < $height ; $y++ ) {
            $obj->xy( $x, $y, $self->xy( $x, $y ) ) ;
        }
    }

    $obj ;
}


sub line { # Object method
    my( $self, $x0, $y0, $x1, $y1, $colour ) = @_ ;

    # basic Bressenham line drawing

    my $dy = abs ($y1 - $y0);
    my $dx = abs ($x1 - $x0);
    #### $dy
    #### $dx

    if ($dx >= $dy) {
        # shallow slope

        ( $x0, $y0, $x1, $y1 ) = ( $x1, $y1, $x0, $y0 ) if $x0 > $x1 ;

        my $y = $y0 ;
        my $ystep = ($y1 > $y0 ? 1 : -1);
        my $rem = int($dx/2) - $dx;
        for( my $x = $x0 ; $x <= $x1 ; $x++ ) {
            #### $rem
            $self->xy( $x, $y, $colour ) ;
            if (($rem += $dy) >= 0) {
                $rem -= $dx;
                $y += $ystep;
            }
        }
    } else {
        # steep slope

        ( $x0, $y0, $x1, $y1 ) = ( $x1, $y1, $x0, $y0 ) if $y0 > $y1 ;

        my $x = $x0 ;
        my $xstep = ($x1 > $x0 ? 1 : -1);
        my $rem = int($dy/2) - $dy;
        for( my $y = $y0 ; $y <= $y1 ; $y++ ) {
            #### $rem
            $self->xy( $x, $y, $colour ) ;
            if (($rem += $dx) >= 0) {
                $rem -= $dy;
                $x += $xstep;
            }
        }
    }
}


# Midpoint ellipse algorithm from Computer Graphics Principles and Practice.
#
# The points of the ellipse are
#     (x/a)^2 + (y/b)^2 == 1
# or expand out to
#     x^2*b^2 + y^2*a^2 == a^2*b^2
#
# The x,y coordinates are taken relative to the centre $ox,$oy, with radials
# $a and $b half the width $x1-x0 and height $y1-$y0.  If $x1-$x0 is odd,
# then $ox and $a are not integers but have 0.5 parts.  Starting from $x=0.5
# and keeping that 0.5 means the final _ellipse_point() drawn xy() pixels
# are integers.  Similarly in y.
#
# Only a few lucky pixels exactly satisfy the ellipse equation above.  For
# the rest there's an error amount expressed as
#
#     E(x,y) = x^2*b^2 + y^2*a^2 - a^2*b^2
#
# The first loop maintains a "discriminator" d1 in $d
#
#     d1 = (x+1)^2*b^2 + (y-1/2)^2*a^2 - a^2*b^2
#
# which is E(x+1,y-1/2), being the error amount for the next x+1 position,
# taken at y-1/2 which is the midpoint between the possible next y or y-1
# pixels.  When d1 > 0 it means that the y-1/2 position is outside the
# ellipse and the y-1 pixel is taken to be the better approximation to the
# ellipse than y.
#
# The first loop does the four octants near the Y axis, ie. the nearly
# horizontal parts.  The second loop does the four octants near the X axis,
# ie. the nearly vertical parts.  For the second loop the discriminator in
# $d is instead at the next y-1 position and between x and x+1,
#
#     d2 = E(x+1/2,y-1) = (x+1/2)^2*b^2 + (y-1)^2*a^2 - a^2*b^2
#
# The difference between d1 and d2 for the changeover is as follows and is
# used to step across to the new position rather than a full recalculation.
# Not much difference in speed, but less code.
#
#     E(x+1/2,y-1) - E(x+1,y-1/2)
#            = -b^2 * (x + 3/4) + a^2 * (3/4 - y)
#
#     since (x+1/2)^2 - (x+1)^2 = -x - 3/4
#           (y-1)^2 - (y-1/2)^2 = -y + 3/4
#
#
# The calculations could be made all-integer by counting $x and $y from 0 at
# the bounding box edges directed inwards, rather than outwards from a
# fractional centre.  E(x,y) could have a factor of 2 or 4 put through as
# necessary (the discriminating >0 or <0 staying the same).  Rumour has it
# E() can grow to roughly max(a^3, b^3), which fits a 32-bit signed integer
# for up to 800 pixels or so radius, or 1600 for unsigned 32-bit, and of
# course Perl switches to 53-bit floats automatically, which is then still
# an exact integer up to about 200,000 pixels radius.
#
# It'd be possible to draw runs of horizontal pixels with line() instead of
# individual xy() calls.  That might help subclasses doing a block-fill for
# a horizontal line segment.  Except only big or flat ellipses have more
# than a few adjacent horizontal pixels.
#
# It's possible to calculate (with a sqrt) where d1 goes positive and thus
# the horizontal ends, if that seemed better than watching $aa*($y-0.5) vs
# $bb *($x+1) for the end of the first loop.
#


sub ellipse { # Object method
    my $self  = shift ;
    #    my $class = ref( $self ) || $self ;

    my( $x0, $y0, $x1, $y1, $colour ) = @_ ;

    my $a  = abs( $x1 - $x0 ) / 2 ;
    my $b  = abs( $y1 - $y0 ) / 2 ;
    if ($a <= .5 || $b <= .5) {
        # one or two pixels high or wide, treat as rectangle
        $self->rectangle ($x0, $y0, $x1, $y1, $colour );
        return;
    }
    my $aa = $a ** 2 ;
    my $bb = $b ** 2 ;
    my $ox = ($x0 + $x1) / 2;
    my $oy = ($y0 + $y1) / 2;

    my $x  = $a - int($a) ;  # 0 or 0.5
    my $y  = $b ;
    ### initial: "origin $ox,$oy  start xy $x,$y"

    # d1 = E(x+1,y-1/2) = (x+1)^2*b^2 + (y-1/2)^2*a^2 - a^2*b^2
    # which for x=0,y=b is b^2 - a^2*b + a^2/4
    # or for x=0.5,y=b  is 9/4*b^2 - ...
    #
    my $d = ($x ? 2.25*$bb : $bb) - ( $aa * $b ) + ( $aa / 4 ) ;

    $self->_ellipse_point( $ox, $oy, $x, $y, $colour ) ;

    while( ( $aa * ( $y - 0.5 ) ) > ( $bb * ( $x + 1 ) ) ) {
        ### assert: $d == ($x+1)**2 * $bb + ($y-.5)**2 * $aa - $aa * $bb
        if( $d < 0 ) {
            $d += ( $bb * ( ( 2 * $x ) + 3 ) ) ;
            ++$x ;
        }
        else {
            $d += ( ( $bb * ( (  2 * $x ) + 3 ) ) +
                    ( $aa * ( ( -2 * $y ) + 2 ) ) ) ;
            ++$x ;
            --$y ;
        }
        $self->_ellipse_point( $ox, $oy, $x, $y, $colour ) ;
    }

    # switch to d2 = E(x+1/2,y-1) by adding E(x+1/2,y-1) - E(x+1,y-1/2)
    $d += $aa*(.75-$y) - $bb*($x+.75);
    ### assert: $d == $bb*($x+0.5)**2 + $aa*($y-1)**2 - $aa*$bb

    ### second loop at: "$x, $y"

    while( $y >= 1 ) {
        if( $d < 0 ) {
            $d += ( $bb * ( (  2 * $x ) + 2 ) ) +
              ( $aa * ( ( -2 * $y ) + 3 ) ) ;
            ++$x ;
            --$y ;
        }
        else {
            $d += ( $aa * ( ( -2 * $y ) + 3 ) ) ;
            --$y ;
        }
        $self->_ellipse_point( $ox, $oy, $x, $y, $colour ) ;

        ### assert: $d == $bb*($x+0.5)**2 + $aa*($y-1)**2 - $aa*$bb
    }
    # loop stops after drawing an _ellipse_point() at $y==0 or $y==0.5, the
    # latter if $b has a .5 fraction
    ### assert: $y == $b - int($b)

    # tail if small height large width
    while( ++$x <= $a ) {
        $self->_ellipse_point( $ox, $oy, $x, $y, $colour ) ;
    }
    # $x started from the possible 0.5 fraction part of $a, so having
    # stepped up by 1s it will reach $a exactly
    ### assert: $x == $a+1
}


sub _ellipse_point { # Object method 
    my $self  = shift ; 
#    my $class = ref( $self ) || $self ;

    my( $ox, $oy, $rx, $ry, $colour ) = @_ ;
    ### _ellipse_point: "$rx,$ry"

    $self->xy( $ox + $rx, $oy + $ry, $colour ) ;
    $self->xy( $ox - $rx, $oy - $ry, $colour ) ;
    $self->xy( $ox + $rx, $oy - $ry, $colour ) ;
    $self->xy( $ox - $rx, $oy + $ry, $colour ) ;
}


sub rectangle { # Object method
  my ($self, $x0, $y0, $x1, $y1, $colour, $fill) = @_;

  if ($x0 == $x1) {
    # vertical line only
    $self->line( $x0, $y0, $x1, $y1, $colour ) ;

  } else {
    ( $y0, $y1 ) = ( $y1, $y0 ) if $y0 > $y1 ;

    if ($fill) {
      for( my $y = $y0 ; $y <= $y1 ; $y++ ) {
        $self->line( $x0, $y, $x1, $y, $colour ) ;
      }

    } else { # unfilled

      $self->line( $x0, $y0,
                   $x1, $y0, $colour ) ;   # top
      if (++$y0 <= $y1) {
        # height >= 2
        if ($y0 < $y1) {
          # height >= 3, verticals
          $self->line( $x0, $y0,
                       $x0, $y1-1, $colour ) ;  # left
          $self->line( $x1, $y0,
                       $x1, $y1-1, $colour ) ;  # right
        }
        $self->line( $x1, $y1,
                     $x0, $y1, $colour ) ;  # bottom
      }
    }
  }
}

1 ;


__END__

=head1 NAME

Image::Base - base class for loading, manipulating and saving images.

=head1 SYNOPSIS

This class should not be used directly.  Known inheritors are Image::Xbm and
Image::Xpm (and see L</SEE ALSO> below).

    use Image::Xpm ;

    my $i = Image::Xpm->new( -file => 'test.xpm' ) ;
    $i->line( 1, 1, 3, 7, 'red' ) ;
    $i->ellipse( 3, 3, 6, 7, '#ff00cc' ) ;
    $i->rectangle( 4, 2, 9, 8, 'blue' ) ;

If you want to create your own algorithms to manipulate images in terms of
(x,y,colour) then you could extend this class (without changing the file),
like this:

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

=head2 line()

    $i->line( $x0, $y0, $x1, $y1, $colour ) ;

Draw a line from point ($x0,$y0) to point ($x1,$y1) in colour $colour.

=head2 ellipse()

    $i->ellipse( $x0, $y0, $x1, $y1, $colour ) ;

Draw an oval enclosed by the rectangle whose top left is ($x0,$y0) and bottom
right is ($x1,$y1) using a line colour of $colour.

=head2 rectangle()

    $i->rectangle( $x0, $y0, $x1, $y1, $colour, $fill ) ;

Draw a rectangle whose top left is ($x0,$y0) and bottom right is ($x1,$y1)
using a line colour of $colour. If C<$fill> is true then the rectangle will be
filled.

=head2 new()

Virtual - must be overridden.

Recommend that it at least supports C<-file> (filename), C<-width> and
C<-height>.

=head2 new_from_serialised()

Not implemented. Recommended for inheritors. Should accept a string serialised
using serialise() and return an object (reference).

=head2 serialise()

Not implemented. Recommended for inheritors. Should return a string
representation (ideally compressed).

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

=head1 SEE ALSO

L<Image::Xpm>,
L<Image::Xbm>,
L<Image::Pbm>,
L<Image::Base::GD>,
L<Image::Base::PNGwriter>,
L<Image::Base::Multiplex>,
L<Image::Base::Text>

L<Image::Base::Gtk2::Gdk::Drawable>,
L<Image::Base::Gtk2::Gdk::Pixbuf>,
L<Image::Base::Gtk2::Gdk::Pixmap>,
L<Image::Base::Gtk2::Gdk::Window>,
L<Image::Base::X11::Protocol::Drawable>,
L<Image::Base::X11::Protocol::Pixmap>,
L<Image::Base::X11::Protocol::Window>

=head1 AUTHOR

Mark Summerfield. I can be contacted as <summer@perlpress.com> -
please include the word 'imagebase' in the subject line.

=head1 COPYRIGHT

Copyright (c) Mark Summerfield 2000. All Rights Reserved.

Copyright (c) Kevin Ryde 2010.

This module may be used/distributed/modified under the LGPL. 

=cut

# Local variables:
# cperl-indent-level: 4
# End:
