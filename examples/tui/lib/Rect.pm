#!perl

use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ceil ];

class Rect {
    use Coords;
    use ANSI;

    field $origin :param;
    field $height :param;
    field $width  :param;
    field $fill   :param = ' ';
    field $nested :param = [];

    field $corner;
    field $dirty = true;

    ADJUST {
        $corner = add( $origin, [ $width, $height ] );

        # nest children accordingly ...
        foreach my $child ( @$nested ) {
            $child->set_origin( add( $child->origin, $origin ) );
            $child->set_corner( add( $child->corner, $origin ) );
        }
    }

    method origin { $origin }
    method corner { $corner }

    method height { $height }
    method width  { $width  }

    method extent { subtract( $corner, $origin ) }
    method center { add( $origin, scale_by_factor( $self->extent, 0.5 ) ) }

    method top_left     { $origin }
    method top_right    { [ $corner->[X], $origin->[Y] ] }
    method bottom_left  { [ $origin->[X], $corner->[Y] ] }
    method bottom_right { $corner }

    # mutators

    method set_origin ($o) {
        $dirty  = true;
        $origin = $o;
    }

    method set_corner ($c) {
        $dirty  = true;
        $corner = $c;
    }

    method set_height ($h) {
        $dirty       = true;
        $height      = $h;
        $corner->[Y] = $origin->[Y] + $h;
    }

    method set_width ($w) {
        $dirty       = true;
        $width       = $w;
        $corner->[X] = $origin->[X] + $w;
    }

    method set_fill ($f) {
        $dirty = true;
        $fill  = $f;
    }

    # rendering

    method needs_refresh { $dirty }

    method render {
        my $height     = $height;
        my $width      = $width;
        my $line_break = format_line_break( $width );

        my @out;

        push @out => format_move_cursor( map ($_ || 1), reverse @$origin );

        if (ref $fill) {
            push @out => map { @$_, $line_break } @$fill;
        } else {
            push @out => map { ($fill x $width), $line_break } (1 .. $height);
        }

        if (@$nested) {
            push @out => $_->render foreach @$nested;
        }

        $dirty = false;
        return @out;
    }
}

__END__
