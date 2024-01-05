#!perl

use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

use Data::Dumper;
use Test::More;

use Acktor;
use Acktor::Tools;

use Acktor::System;
use Acktor::Props;
use Acktor::Logging;

class Pong :isa(Acktor) {
    field $ping;

    method Start {
        $ping = sender;
        $ping >>= event *Ping::Ping, 0;
    }

    method Pong ($count) {
        $ping >>= event *Ping::Ping, $count;
    }
}

class Ping :isa(Acktor) {
    field $max_bounce :param;
    field $pong;

    method Start {
        $pong = spawn( actor_of Pong:: );
        $pong >>= event *Pong::Start;
    }

    method Ping ($count) {
        $count++;

        if ( $count <= $max_bounce ) {
            $pong >>= event *Pong::Pong, $count;
        } else {
            context->exit; # will stop $pong as well
        }
    }
}

sub init ($ctx) {
    my $Ping = spawn( actor_of Ping::, ( max_bounce => 5 ) );

    $Ping >>= event *Ping::Start;
}

my $system = Acktor::System->new;

$system->loop( init => \&init );

done_testing;
