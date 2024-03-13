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

