#!perl

use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

use Data::Dumper;
use Test::More;
use Test::Differences;

use Acktor;
use Acktor::Behaviors;

use Acktor::System;
use Acktor::Logging;
use Acktor::Streams;


sub init ($ctx) {

    my $p = spawn Props[ Acktor::Streams::Publisher:: ];
    my $f = spawn Props[
        Acktor::Streams::Processor:: => (
            request_size => 10,
            map          => sub ($x) {  $x * 2 },
            filter       => sub ($x) { ($x % 2) == 0 },
        )
    ];
    my $s = spawn Props[ Acktor::Streams::Subscriber:: => ( request_size => 10 ) ];

    $p->send( event *Acktor::Streams::Publisher::Subscribe => $f );
    $f->send( event *Acktor::Streams::Publisher::Subscribe => $s );

    my $x = 1;
    foreach my $j (1 .. 50) {
        $p->send( event *Acktor::Streams::Publisher::Submit => $x++ );
    }

    context->schedule(
        after => 2,
        for   => $p,
        event => event *Acktor::Streams::Publisher::Close
    );
}

my $system = Acktor::System->new;
isa_ok($system, 'Acktor::System');

$system->run( init => \&init );

done_testing;
