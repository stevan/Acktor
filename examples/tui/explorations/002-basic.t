#!perl

use v5.38;
use utf8;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];
use open         qw[ :std :encoding(UTF-8) ];

use Data::Dumper;

$|++;

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

class RoundedBottomTabStyle :isa(RoundedBoxStyle) {
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
        return (
            format_move_cursor( reverse map $_+1, @$origin ),
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

class Card {
    use Time::HiRes   qw[ sleep time ];
    use Term::ReadKey qw[ GetTerminalSize ];

    use Coords;
    use ANSI;

    field $tty :param = \*STDOUT;

    field $height;
    field $width;

    field $frame = 1;
    field $start;

    field $status_bar;

    field @elements;

    ADJUST {
        ($width, $height) = GetTerminalSize();

        push @elements => Box->new(
            origin => [0, 0],
            height => $height - 4,
            width  => $width  - 4,
            style  => RoundedBoxStyle::,
        );

        $status_bar = Box->new(
            origin  => [ 4, $height - 3 ],
            height  => 1,
            width   => $width - 12,
            style   => RoundedBottomTabStyle::,
            content => '...',
            color   => [ 0x33, 0x66, 0x99 ]
        );

        push @elements => $status_bar;
    }

    method height { $height }
    method width  { $width  }

    method add_element ($e) {
        push @elements => $e;
    }


    method setup {
        $tty->print(
            clear_screen(),
            home_cursor(),
            hide_cursor(),
            enable_alt_buf(),
        );

        $SIG{INT} = sub {
            $self->teardown;
            exit;
        };

        $start = time;
    }

    method render {
        my $t = time;

        my @dirty = grep $_->is_dirty, @elements;
        map { $tty->print( $_->draw ) && $_->clean } @dirty;

        sleep 0.016;

        my $d = (time() - $t);
        $status_bar->set_content(
            sprintf(('%-'.$status_bar->width.'s') => join '',
                sprintf(' dirty: %06d ' => scalar(@dirty)),
                sprintf(' frame: %06d ' => $frame++),
                sprintf(' fps: %.03f '  => $frame / (($t - $start) || 1)),
            )
        );
    }

    method teardown {
        $tty->print(
            disable_alt_buf(),
            show_cursor()
        );
    }

}


my $card = Card->new;

my @boxes = map {
    my $height = int(rand(10)) + 1;
    my $width  = int(rand(20)) + 1;

    my $b = Box->new(
        origin => [
            int(rand( $card->width  - ($width  + 6) )) + 1,
            int(rand( $card->height - ($height + 5) )) + 1,
        ],
        height => $height,
        width  => $width,
        style  => RoundedBoxStyle::,
        fill   => $_
    );

    $card->add_element( $b );

    $b;
} 0 .. 9;


$card->setup;
while (1) {
    $card->render;

    map { rand() < 0.01 ? $_->set_color([
        map int(rand(255)), qw[ r g b ]
    ]) : () } @boxes;

    map { rand() < 0.01 ? $_->set_origin([
        int(rand( $card->width  - ($_->width  + 6) )) + 1,
        int(rand( $card->height - ($_->height + 5) )) + 1,
    ]) : () } @boxes;

}
$card->teardown;










