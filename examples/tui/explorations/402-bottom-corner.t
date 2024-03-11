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
    corner => [20, 10],
    fill   => '░'
);

my $r2 = Rect->new(
    origin => subtract($r1->corner, [2, 2]),
    corner => add($r1->corner, [1, 1]), # add 1 because this point is exclusive
    fill   => '▒'
);

print $r1->render;
print $r2->render;

say'' for 0 .. 20;

__END__

░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░▒▒▒
░░░░░░░░░░░░░░░░░▒▒▒
░░░░░░░░░░░░░░░░░▒▒▒


