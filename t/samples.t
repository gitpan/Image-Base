#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde

# This file is part of Image-Base.
#
# Image-Base is free software; you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Image-Base is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with Image-Base.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use Test::More tests => 70;

{
  package MyGrid;
  use Image::Base;
  use vars '@ISA';
  @ISA = ('Image::Base');
  sub new {
    my $class = shift;
    my $self = bless { @_}, $class;
    my $horiz = '+' . ('-' x $self->{'-width'}) . "+\n";
    $self->{'str'} = $horiz
      . (('|' . (' ' x $self->{'-width'}) . "|\n") x $self->{'-height'})
        . $horiz;
    return $self;
  }
  sub xy {
    my ($self, $x, $y, $colour) = @_;
    my $pos = $x+1 + ($y+1)*($self->{'-width'}+3);

    if (substr ($self->{'str'}, $pos, 1) ne ' ') {
      # doubled up pixel, undesirable, treated as an error
      $colour = 'X';
    }
    substr ($self->{'str'}, $pos, 1) = $colour;
  }
}

foreach my $elem (

                  # one pixel
                  [0,0, 0,0, <<'HERE'],
+--------------------+
|*                   |
|                    |
|                    |
|                    |
|                    |
|                    |
|                    |
|                    |
|                    |
|                    |
+--------------------+
HERE

                  # horizontal
                  [3,3, 13,3, <<'HERE'],
+--------------------+
|                    |
|                    |
|                    |
|   ***********      |
|                    |
|                    |
|                    |
|                    |
|                    |
|                    |
+--------------------+
HERE

                  # vertical
                  [3,3, 3,9, <<'HERE'],
+--------------------+
|                    |
|                    |
|                    |
|   *                |
|   *                |
|   *                |
|   *                |
|   *                |
|   *                |
|   *                |
+--------------------+
HERE

                  # two pixels
                  [1,3, 2,4, <<'HERE'],
+--------------------+
|                    |
|                    |
|                    |
| *                  |
|  *                 |
|                    |
|                    |
|                    |
|                    |
|                    |
+--------------------+
HERE

                  # shallow rounding step in middle
                  [1,3, 4,4, <<'HERE'],
+--------------------+
|                    |
|                    |
|                    |
| **                 |
|   **               |
|                    |
|                    |
|                    |
|                    |
|                    |
+--------------------+
HERE

                  # steep rounding step in middle
                  [1,3, 2,6, <<'HERE'],
+--------------------+
|                    |
|                    |
|                    |
| *                  |
| *                  |
|  *                 |
|  *                 |
|                    |
|                    |
|                    |
+--------------------+
HERE

                  [0,0, 19,9, <<'HERE'],
+--------------------+
|**                  |
|  **                |
|    **              |
|      **            |
|        **          |
|          **        |
|            **      |
|              **    |
|                **  |
|                  **|
+--------------------+
HERE
                 ) {
  my ($x0,$y0, $x1,$y1, $want) = @$elem;
  foreach ('', 'swap') {

    my $image = MyGrid->new (-width => 20, -height => 10);
    $image->line ($x0,$y0, $x1,$y1, '*');
    my $got = $image->{'str'};
    is ("\n$got", "\n$want", "line $x0,$y0, $x1,$y1");

    ($x0,$y0, $x1,$y1) = ($x1,$y1, $x0,$y0);
  }
}

foreach my $elem (

                  # one pixel
                  [0,0, 0,0, 0, <<'HERE'],
+--------------------+
|*                   |
|                    |
|                    |
|                    |
|                    |
|                    |
|                    |
|                    |
|                    |
|                    |
+--------------------+
HERE

                  # horizontal
                  [3,3, 13,3, 0, <<'HERE'],
+--------------------+
|                    |
|                    |
|                    |
|   ***********      |
|                    |
|                    |
|                    |
|                    |
|                    |
|                    |
+--------------------+
HERE

                  # vertical
                  [3,3, 3,9, 0, <<'HERE'],
+--------------------+
|                    |
|                    |
|                    |
|   *                |
|   *                |
|   *                |
|   *                |
|   *                |
|   *                |
|   *                |
+--------------------+
HERE

                  # two pixels
                  [1,3, 2,4, 0, <<'HERE'],
+--------------------+
|                    |
|                    |
|                    |
| **                 |
| **                 |
|                    |
|                    |
|                    |
|                    |
|                    |
+--------------------+
HERE

                  [1,3, 4,4, 0, <<'HERE'],
+--------------------+
|                    |
|                    |
|                    |
| ****               |
| ****               |
|                    |
|                    |
|                    |
|                    |
|                    |
+--------------------+
HERE

                  [1,3, 2,6, 0, <<'HERE'],
+--------------------+
|                    |
|                    |
|                    |
| **                 |
| **                 |
| **                 |
| **                 |
|                    |
|                    |
|                    |
+--------------------+
HERE

                  # three pixels, unfilled
                  [1,3, 3,5, 0, <<'HERE'],
+--------------------+
|                    |
|                    |
|                    |
| ***                |
| * *                |
| ***                |
|                    |
|                    |
|                    |
|                    |
+--------------------+
HERE

                  # three pixels, filled
                  [1,3, 3,5, 1, <<'HERE'],
+--------------------+
|                    |
|                    |
|                    |
| ***                |
| ***                |
| ***                |
|                    |
|                    |
|                    |
|                    |
+--------------------+
HERE

                  [1,3, 4,5, 0, <<'HERE'],
+--------------------+
|                    |
|                    |
|                    |
| ****               |
| *  *               |
| ****               |
|                    |
|                    |
|                    |
|                    |
+--------------------+
HERE

                  [1,3, 4,5, 1, <<'HERE'],
+--------------------+
|                    |
|                    |
|                    |
| ****               |
| ****               |
| ****               |
|                    |
|                    |
|                    |
|                    |
+--------------------+
HERE

                  [2,3, 4,6, 0, <<'HERE'],
+--------------------+
|                    |
|                    |
|                    |
|  ***               |
|  * *               |
|  * *               |
|  ***               |
|                    |
|                    |
|                    |
+--------------------+
HERE

                  [2,3, 4,6, 1, <<'HERE'],
+--------------------+
|                    |
|                    |
|                    |
|  ***               |
|  ***               |
|  ***               |
|  ***               |
|                    |
|                    |
|                    |
+--------------------+
HERE

                  [0,0, 19,9, 0, <<'HERE'],
+--------------------+
|********************|
|*                  *|
|*                  *|
|*                  *|
|*                  *|
|*                  *|
|*                  *|
|*                  *|
|*                  *|
|********************|
+--------------------+
HERE

                  [0,0, 19,9, 1, <<'HERE'],
+--------------------+
|********************|
|********************|
|********************|
|********************|
|********************|
|********************|
|********************|
|********************|
|********************|
|********************|
+--------------------+
HERE
                 ) {
  foreach my $swap_x (0, 1) {
    foreach my $swap_y (0, 1) {

      my ($x0,$y0, $x1,$y1, $fill, $want) = @$elem;
      if ($swap_x) { ($x0,$x1) = ($x1,$x0) }
      if ($swap_y) { ($y0,$y1) = ($y1,$y0) }

      my $image = MyGrid->new (-width => 20, -height => 10);
      $image->rectangle ($x0,$y0, $x1,$y1, '*', $fill);
      my $got = $image->{'str'};
      is ("\n$got", "\n$want", "rectangle $x0,$y0, $x1,$y1, fill=$fill");
    }
  }
}

exit 0;
