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
    my $height = int(rand(10)) + 1;
    my $width  = int(rand(20)) + 1;

    my $b = Box->new(
        origin => [ 0, 0 ],
        height => $height,
        width  => $width,
        style  => RoundedBoxStyle::,
        fill   => /^(\d)/
    );

    $card->add_element( $b );
    $card->stage->place_box_randomly($b);

    $b;
} 0 .. 20;


$card->setup;
while (1) {
    $card->render;

    map { rand() < 0.3 ? $_->set_color([
        map int(rand(255)), qw[ r g b ]
    ]) : () } @boxes;

    map { rand() < 0.3 ? $card->stage->place_box_randomly($_) : () } @boxes;

}
$card->teardown;










