#!perl

use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

use Data::Dumper;

use Acktor::Node;
use Acktor::Node::ClientConnection;


my $node2 = Acktor::Node->new;
$node2->listen('0.0.0.0', 3000);

my $conn2 = $node2->connect( '0.0.0.0', 3000 );

$conn2->to_write('Hello');

foreach (0 .. 10) {
    say '-('.$$.' = '.$_.')-------------------------------';
    $node2->tick(3);
}


