#!perl

use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

use Data::Dumper;

use Acktor::PostOffice;
use Acktor::PostOffice::ClientConnection;

if (my $pid = fork()) {
    say "FORKED $pid";
    my $node1 = Acktor::Node->new;
    $node1->listen_on('0.0.0.0', 3000);

    my $conn1 = $node1->connect_to('0.0.0.0', 3001);

    $conn1->to_write('Hello1');

    foreach (0 .. 10) {
        say '-('.$$.' = '.$_.')-------------------------------';
        $node1->tick(1);
    }

    waitpid($pid, 0);
}
else {
    say "FORKED Child";
    my $node2 = Acktor::Node->new;
    $node2->listen_on('0.0.0.0', 3001);

    my $conn2 = $node2->connect_to( '0.0.0.0', 3000 );

    $conn2->to_write('Hello2');

    foreach (0 .. 10) {
        say '-('.$$.' = '.$_.')-------------------------------';
        sleep(1);
        $node2->tick(1);
    }
    exit();
}

