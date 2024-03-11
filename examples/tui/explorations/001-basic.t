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

# https://github.com/tinmarino/mouse_xterm

$|++;

my $LIGHT  = "\e[38;5;2;m▓\e[0m";
my $MIDDLE = "\e[38;5;3;m▒\e[0m";
my $DARK   = "\e[38;5;4;m░\e[0m";

sub term_open {
    #print "\e[?1049h";
    print "\e[0m";
    print "\e[2J";
    print "\e[?1003h";
    print "\e[?1015h";
    print "\e[?1006h";
    print "\e[?25l";

    ReadMode 'cbreak';
}

sub term_close {
    ReadMode 'restore';

    #print "\e[?1049l";
    print "\e[?1003l";
    print "\e[?1015l";
    print "\e[?1006l";
    print"\e[?25h";
}


$SIG{INT} = sub {
    term_close();
    die "Ended early!";
};

term_open();

my $x = '';
while (read( STDIN, $x, 24 )) {
    if ($x) {
        my $pos = $x;
        if ( my ($x, $y) = ($pos =~ m/\e\[\<\d+\;(\d+)\;(\d+)M/) ) {
            #print join ', ' => $pos, $x, $y;
            print format_move_cursor($y, $x), "($x, $y)";
        }
    }
    $x = '';
    sleep 0.016;
}

term_close();


=pod

class Scene {
    use Coords;

    field $origin :param;

    field @elements;

    method add_element ($e) {
        $e->set_position( add( $origin, $e->origin ) );
        push @elements => $e;
    }

    method update ($fh=*STDOUT) {
        foreach my $e ( @elements ) {
            $e->render( $fh ) if $e->is_dirty;
        }
    }
}

class Element {
    use Coords;
    use ANSI;

    field $origin :param;
    field $height :param;
    field $width  :param;
    field $fill   :param;

    field $position;
    field $dirty = false;

    ADJUST {
        $position = $origin;
    }

    method origin { $origin }
    method height { $height }
    method width  { $width  }

    method set_position ($p) {
        $position = $p;
        $dirty = true;
    }

    method is_dirty { $dirty }

    method render ($fh=*STDOUT) {
        my $line_break = format_line_break( $width );
        my @out;
        push @out => format_move_cursor( map ($_ || 1), reverse @$position );
        push @out => map { $_, $line_break } $self->draw;
        $fh->print( @out );
        $dirty = false;
    }

    method draw {
        map { ($fill x $width) } (1 .. $height)
    }
}


my $s = Scene->new(
    origin => [1,2]
);

my $x = 0;
while ($x < 100) {
    $s->add_element(
        Element->new(
            origin => [int(rand(60)),int(rand(30))],
            height => 2,
            width  => 2,
            fill   => "\e[38;5;".(1+int(rand(8))).";m░\e[0m"
        )
    );
    $s->update;
    #say '';
    sleep 0.2;
    $x++;
}

say'' foreach 0 .. 20;

=cut
