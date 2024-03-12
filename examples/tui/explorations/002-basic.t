#!perl

use v5.38;
use utf8;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];
use open         qw[ :std :encoding(UTF-8) ];

use Data::Dumper;
use Time::HiRes   qw[ sleep ];
use Term::ReadKey qw[ ReadKey ReadMode ];

use Coords;
use ANSI;

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

class Box {
    field $origin :param;
    field $height :param;
    field $width  :param;
    field $style  :param;
    field $color  :param = undef;

    field $fill   :param = undef;

    field $overlap;

    method overlaps ($box) { $overlap = $box }

    method color { $color }

    method draw {
        my $spacer = $fill
            ? join('' => ($fill x ($width + 1)))
            : format_move_right($width + 1);
        my $break  = format_line_break( $width + 1 + 2 );
        return (
            format_move_cursor( reverse map $_|| 1, @$origin ),
            join('' => $style->top_left, format_repeat_char($style->top_horz_line, $width), $style->top_right, $break),
            (map {
                join('' =>
                    $style->left_vert_line,
                    ($color ? format_fg_color($color) : ()),
                    $spacer,
                    ($color ? format_reset() : ()),
                    $style->right_vert_line,
                    $break)
            } (1 .. $height)),
            join('' => $style->bottom_left, format_repeat_char($style->bottom_horz_line, $width), $style->bottom_right, $break),
        )
    }

}


my $b1 = Box->new(
    origin => [1, 1],
    height => 5,
    width  => 20,
    fill   => '▓',
    style  => SolidBoxStyle2::,
    color  => [ 100, 100, 255 ]
);

my $b2 = Box->new(
    origin => [10, 5],
    height => 10,
    width  => 20,
    fill   => '▒',
    style  => SolidBoxStyle2::,
    color  => [ 255, 100, 0 ]
);

my $b3 = Box->new(
    origin => [22, 10],
    height => 2,
    width  => 4,
    fill   => '░',
    style  => SolidBoxStyle2::,
    color  => [ 0, 255, 100 ]
);

$b3->overlaps($b2);
$b2->overlaps($b1);


my @one   = $b1->draw;
my @two   = $b2->draw;
my @three = $b3->draw;

print @one, @two, @three;

say '' for 0 .. 20;
