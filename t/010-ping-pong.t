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

class Ping :isa(Acktor) {
    field $max_bounce :param;
    field $pong;

    method Start {
        $pong = spawn( Acktor::Props->new( class => 'Pong' ) );
        $pong >>= event *Pong::Start;
    }

    method Ping ($count) {
        $count++;

        if ( $count <= $max_bounce ) {
            $pong >>= event *Pong::Pong, $count;
        } else {
            # FIXME: make this actually do something ...
            context->stop( $pong );
            context->exit;
        }
    }
}

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

sub init ($ctx) {
    my $Ping = spawn( Acktor::Props->new( class => 'Ping', args => { max_bounce => 5 } ) );

    $Ping >>= event *Ping::Start;
}

my $system = Acktor::System->new;

$system->loop( init => \&init );

done_testing;
