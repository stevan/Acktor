#!perl

use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

use Data::Dumper;

use Acktor::Node;
use Acktor::Node::ClientConnection;


my $node2 = Acktor::Node->new;
$node2->listen('0.0.0.0', 3000);

my $conn2 = $node2->connect(
    '0.0.0.0', 3000,
    Acktor::Node::ClientConnection->new
);

my $conn2b = $node2->connect(
    '0.0.0.0', 3000,
    Acktor::Node::ClientConnection->new
);

foreach (0 .. 10) {
    say '-('.$$.' = '.$_.')-------------------------------';
    $node2->tick(3);
}


