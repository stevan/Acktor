#!perl

use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ceil ];

class Stage {
    use Coords;
    use ANSI;

    field $origin :param;
    field $height :param;
    field $width  :param;
    field $corner;

    ADJUST {
        $corner = add( $origin, [ $width, $height ] );
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

    method place_box_randomly ($b) {
        $b->set_origin([
            int(rand( $width  - $b->width  )),
            int(rand( $height - $b->height )),
        ]);
    }
}

__END__
