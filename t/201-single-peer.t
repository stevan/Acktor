#!perl

use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

use Data::Dumper;

use Acktor::Node;
use Acktor::Node::ClientConnection;


my $node2 = Acktor::Node->new;
$node2->listen_on('0.0.0.0', 3000);

my $conn2a = $node2->connect_to( '0.0.0.0', 3000 );
my $conn2b = $node2->connect_to( '0.0.0.0', 3000 );

$conn2a->to_write('Hello1');
$conn2b->to_write('Hello2');

foreach (0 .. 10) {
    say '-('.$$.' = '.$_.')-------------------------------';
    $node2->tick(1);
}


