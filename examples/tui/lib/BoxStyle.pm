
use v5.38;
use utf8;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

class BoxStyle {
    method top_left;
    method bottom_left;
    method top_right;
    method bottom_right;
    method top_horz_line;
    method bottom_horz_line;
    method left_vert_line;
    method right_vert_line;
}

# ...

class RoundedBoxStyle :isa(BoxStyle) {
    use constant top_left         => '╭';
    use constant bottom_left      => '╰';
    use constant top_right        => '╮';
    use constant bottom_right     => '╯';
    use constant top_horz_line    => '─';
    use constant bottom_horz_line => '─';
    use constant left_vert_line   => '│';
    use constant right_vert_line  => '│';
}

class RoundedTopOpenTabStyle :isa(RoundedBoxStyle) {
    use constant bottom_left         => '╯';
    use constant bottom_right        => '╰';
    use constant bottom_horz_line    => ' ';
}

class RoundedTopClosedTabStyle :isa(RoundedBoxStyle) {
    use constant bottom_left         => '┴';
    use constant bottom_right        => '┴';
}

class RoundedBottomOpenTabStyle :isa(RoundedBoxStyle) {
    use constant top_left         => '╮';
    use constant top_right        => '╭';
    use constant top_horz_line    => ' ';
}

class RoundedBottomClosedTabStyle :isa(RoundedBoxStyle) {
    use constant top_left         => '┬';
    use constant top_right        => '┬';
}

# ...

class SquareBoxStyle :isa(BoxStyle) {
    use constant top_left         => '┌';
    use constant bottom_left      => '└';
    use constant top_right        => '┐';
    use constant bottom_right     => '┘';
    use constant top_horz_line    => '─';
    use constant bottom_horz_line => '─';
    use constant left_vert_line   => '│';
    use constant right_vert_line  => '│';
}

# ...

class SolidBoxStyle :isa(BoxStyle) {
    use constant top_left         => '▁';
    use constant bottom_left      => '▔';
    use constant top_right        => '▁';
    use constant bottom_right     => '▔';
    use constant top_horz_line    => '▁';
    use constant bottom_horz_line => '▔';
    use constant left_vert_line   => '▏';
    use constant right_vert_line  => '▕';
}

class SolidBoxStyle2 :isa(BoxStyle) {
    use constant top_left         => ' ';
    use constant bottom_left      => ' ';
    use constant top_right        => ' ';
    use constant bottom_right     => ' ';
    use constant top_horz_line    => '▁';
    use constant bottom_horz_line => '▔';
    use constant left_vert_line   => '▕';
    use constant right_vert_line  => '▏';
}
