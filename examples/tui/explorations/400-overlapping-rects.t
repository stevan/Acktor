#!perl

use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ceil ];

$|++;

use Data::Dumper;

use Rect;
use Coords;

my $r1 = Rect->new(
    origin => [0, 0],
    height => 10,
    width  => 20,
    fill   => '░'
);

my $r2 = Rect->new(
    origin => [10, 5],
    height => 10,
    width  => 20,
    fill   => '▒'
);

my $r3 = Rect->new(
    origin => subtract($r2->center, [2,2]),
    height => 4,
    width  => 4,
    fill   => '▓'
);

print $r1->render;
print $r2->render;
print $r3->render;

say'' for 0 .. 20;
#warn "origin: ", join ", " => $r2->origin->@*;
#warn "center: ", join ", " => $r2->center->@*;
#warn "corner: ", join ", " => $r2->corner->@*;
#
#warn "origin: ", join ", " => $r3->origin->@*;
#warn "corner: ", join ", " => $r3->corner->@*;

__END__

░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▓▒▒▒▒▒▒▒▒▒
         ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
         ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
         ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
         ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒


