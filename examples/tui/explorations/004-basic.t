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
use Box;
use Card;

my $card = Card->new;

my @boxes = map {
    my $b = Box->new( height => 5, width => 10, style => RoundedBoxStyle::, fill => '▒', color => [ map int(rand(255)), qw[ r g b ] ] );
    $card->add_element( $b );
    $card->stage->place_box_randomly( $b );
    $b;
} 0 .. 30;


$card->setup;
while (1) {
    $card->render;

    map {
        my $b = $_;
        my $x = 1;
        my $y = 1;
        if ( $b->origin->[Y] > $card->stage->height - $b->height - 1 ) {
            $y = 0;
        }
        if ( $b->origin->[X] > $card->stage->width - $b->width - 2 ) {
            $x = 0;
        }
        $b->move_by([$x, $y]) if $x || $y;
    }
    grep {
        1; #rand() < 0.3
    }
    @boxes;

}
$card->teardown;










