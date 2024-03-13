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

my $top_left      = Box->new( height => int($card->stage->height / 3) - 1, width => int($card->stage->width / 3) - 2, style => RoundedBoxStyle::, content => 'Top Left' );
my $top_center    = Box->new( height => int($card->stage->height / 3) - 1, width => int($card->stage->width / 3) - 2, style => RoundedBoxStyle::, content => 'Top Center' );
my $top_right     = Box->new( height => int($card->stage->height / 3) - 1, width => int($card->stage->width / 3) - 2, style => RoundedBoxStyle::, content => 'Top Right' );
my $middle_left   = Box->new( height => int($card->stage->height / 3) - 1, width => int($card->stage->width / 3) - 2, style => RoundedBoxStyle::, content => 'Middle Left' );
my $middle_center = Box->new( height => int($card->stage->height / 3) - 1, width => int($card->stage->width / 3) - 2, style => RoundedBoxStyle::, content => 'Middle Center' );
my $middle_right  = Box->new( height => int($card->stage->height / 3) - 1, width => int($card->stage->width / 3) - 2, style => RoundedBoxStyle::, content => 'Middle Right' );
my $bottom_left   = Box->new( height => int($card->stage->height / 3) - 1, width => int($card->stage->width / 3) - 2, style => RoundedBoxStyle::, content => 'Bottom Left' );
my $bottom_center = Box->new( height => int($card->stage->height / 3) - 1, width => int($card->stage->width / 3) - 2, style => RoundedBoxStyle::, content => 'Bottom Center' );
my $bottom_right  = Box->new( height => int($card->stage->height / 3) - 1, width => int($card->stage->width / 3) - 2, style => RoundedBoxStyle::, content => 'Bottom Right' );

$card->add_element( $top_left   );
$card->add_element( $top_center );
$card->add_element( $top_right  );
$card->stage->align_box( top_left   => $top_left   );
$card->stage->align_box( top_center => $top_center );
$card->stage->align_box( top_right  => $top_right  );

$card->add_element( $middle_left   );
$card->add_element( $middle_center );
$card->add_element( $middle_right  );
$card->stage->align_box( middle_left   => $middle_left   );
$card->stage->align_box( middle_center => $middle_center );
$card->stage->align_box( middle_right  => $middle_right  );

$card->add_element( $bottom_left   );
$card->add_element( $bottom_center );
$card->add_element( $bottom_right  );
$card->stage->align_box( bottom_left   => $bottom_left   );
$card->stage->align_box( bottom_center => $bottom_center );
$card->stage->align_box( bottom_right  => $bottom_right  );


my @boxes = (
    $top_left,
    $top_center,
    $top_right,
    $middle_left,
    $middle_center,
    $middle_right,
    $bottom_left,
    $bottom_center,
    $bottom_right,
);

$card->setup;
while (1) {
    $card->render;

    map { rand() < 0.03 ? $_->set_color([
        map int(rand(255)), qw[ r g b ]
    ]) : () } @boxes;

}
$card->teardown;










