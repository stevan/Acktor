
use v5.38;
use utf8;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

use BoxStyle;

class Box {
    use Coords;
    use ANSI;

    field $origin  :param;
    field $height  :param;
    field $width   :param;
    field $style   :param;
    field $color   :param = undef;
    field $fill    :param = undef;
    field $content :param = undef;

    field $dirty = true;

    field $stage;

    method is_staged         { !! $stage }
    method add_to_stage ($s) { $dirty = true; $stage = $s }

    method is_dirty { $dirty }
    method clean    { $dirty = false; }

    method origin  { $origin  }
    method height  { $height  }
    method width   { $width   }
    method style   { $style   }
    method color   { $color   }
    method fill    { $fill    }
    method content { $content }

    method set_origin  ($o) { $dirty = true; $origin  = $o }
    method set_height  ($h) { $dirty = true; $height  = $h }
    method set_width   ($w) { $dirty = true; $width   = $w }
    method set_style   ($s) { $dirty = true; $style   = $s }
    method set_color   ($c) { $dirty = true; $color   = $c }
    method set_fill    ($f) { $dirty = true; $fill    = $f }
    method set_content ($c) { $dirty = true; $content = $c }

    method draw {
        my $spacer = defined $fill
            ? join('' => ($fill x ($width + 1)))
            : $content
                ? sprintf("%-".($width + 1)."s" => $content)
                : format_move_right($width + 1);

        my $break  = format_line_break( $width + 1 + 2 );
        my $pos    = $stage ? add( $stage->origin, $origin ) : $origin;
        return (
            format_move_cursor( reverse map $_+1, @$pos ),
            join('' => $style->top_left,
                       format_repeat_char($style->top_horz_line, $width),
                       $style->top_right,
                       $break),
            (map {
                join('' =>
                    $style->left_vert_line,
                    ($color ? format_fg_color($color) : ()),
                    $spacer,
                    ($color ? format_reset() : ()),
                    $style->right_vert_line,
                    $break)
            } (1 .. $height)),
            join('' => $style->bottom_left,
                       format_repeat_char($style->bottom_horz_line, $width),
                       $style->bottom_right,
                       $break),
        )
    }

}
