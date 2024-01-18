#!perl

use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

use Data::Dumper;

use Acktor::Node;
use Acktor::Node::ClientConnection;

if (my $pid = fork()) {
    say "FORKED $pid";
    my $node1 = Acktor::Node->new;
    $node1->listen('0.0.0.0', 3000);

    my $conn1 = $node1->connect(
        '0.0.0.0', 3001,
        Acktor::Node::ClientConnection->new
    );

    foreach (0 .. 10) {
        say '-('.$$.' = '.$_.')-------------------------------';
        $node1->tick(3);
    }

    waitpid($pid, 0);
}
else {
    say "FORKED Child";
    my $node2 = Acktor::Node->new;
    $node2->listen('0.0.0.0', 3001);

    my $conn2 = $node2->connect(
        '0.0.0.0', 3000,
        Acktor::Node::ClientConnection->new
    );

    foreach (0 .. 10) {
        say '-('.$$.' = '.$_.')-------------------------------';
        $node2->tick(3);
    }
    exit();
}

