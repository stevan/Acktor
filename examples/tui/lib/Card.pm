
use v5.38;
use utf8;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

use Stage;
use Box;

class Card {
    use Time::HiRes   qw[ sleep time ];
    use Term::ReadKey qw[ GetTerminalSize ];

    use Coords;
    use ANSI;

    field $tty          :param = \*STDOUT;
    field $refresh_rate :param = 0.016;

    field $height;
    field $width;

    field $start_time;
    field $frame = 1;

    field $stage;

    field $status_bar;

    field @elements;

    ADJUST {
        ($width, $height) = GetTerminalSize();

        $stage = Stage->new(
            origin => [1, 1],
            height => $height - 6,
            width  => $width  - 6,
        );

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
            style   => RoundedBottomClosedTabStyle::,
            content => '...',
            color   => [ 0x33, 0x66, 0x99 ]
        );

        push @elements => $status_bar;
    }

    method height { $height }
    method width  { $width  }

    method stage { $stage }

    method add_element ($e) {
        $e->add_to_stage( $stage );
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

        $start_time = time;
    }

    method render {
        my $t = time;

        my @dirty = grep $_->is_dirty, @elements;
        map { $tty->print( $_->draw ) && $_->clean } @dirty;

        sleep $refresh_rate;

        $status_bar->set_content(
            sprintf(('%-'.$status_bar->width.'s') => join '',
                sprintf(' dirty: %06d ' => scalar(@dirty)),
                sprintf(' frame: %06d ' => $frame++),
                sprintf(' fps: %.03f '  => $frame / (($t - $start_time) || 1)),
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
