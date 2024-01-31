#!perl

use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

use Data::Dumper;

use Acktor::PostOffice;

my $node2 = Acktor::PostOffice->new;
$node2->listen_on('0.0.0.0', 3000);

my $conn2a = $node2->connect_to(
    '0.0.0.0', 3000,
    sub ($w, @msgs) {
        my ($msg) = @msgs;
        say "CLIENT GOT $msg";
    }
);

$conn2a->to_write('Hello');

foreach (0 .. 10) {
    say '-('.$$.' = '.$_.')-------------------------------';
    $node2->tick(1);
}


