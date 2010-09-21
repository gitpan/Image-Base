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
use Test::More tests => 14;

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
    if ($colour eq 'black') {
      $colour = ' ';
    } else {
      $colour = '*';
    }
    substr ($self->{'str'}, $x+1 + ($y+1)*($self->{'-width'}+3), 1) = $colour;
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

exit 0;
