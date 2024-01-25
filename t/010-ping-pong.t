#!perl

use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

use Data::Dumper;
use Test::More;

use Acktor;
use Acktor::Behaviors;

use Acktor::System;
use Acktor::Props;
use Acktor::Logging;

class Pong :isa(Acktor) {
    use Test::More;

    our $BOUNCES = 0;

    field $ping;

    method Start :Receive {
        $ping = sender;
        isa_ok($ping, 'Acktor::Ref');
        is($ping->props->class, 'Ping', '... the Actor is of the expected class');

        $ping->send( event *Ping::Ping, 0 );
    }

    method Pong :Receive ($count) {
        $ping->send( event *Ping::Ping, $count );
        $BOUNCES++;
    }
}

class Ping :isa(Acktor) {
    use Test::More;

    field $max_bounce :param;
    field $pong;

    our $BOUNCES = 0;

    method Start :Receive {
        $pong = spawn( actor_of Pong:: );
        isa_ok($pong, 'Acktor::Ref');
        is($pong->props->class, 'Pong', '... the Actor is of the expected class');

        $pong->send( event *Pong::Start );
    }

    method Ping :Receive ($count) {
        $count++;

        if ( $count <= $max_bounce ) {
            $BOUNCES++;
            $pong->send( event *Pong::Pong, $count );
        } else {
            context->stop(context->self); # will stop $pong as well
        }
    }
}

sub init ($ctx) {
    my $Ping = spawn( actor_of *Ping::, ( max_bounce => 5 ) );
    isa_ok($Ping, 'Acktor::Ref');
    is($Ping->props->class, 'Ping', '... the Actor is of the expected class');

    $Ping->send( event *Ping::Start );
}

my $system = Acktor::System->new;
isa_ok($system, 'Acktor::System');

$system->run( init => \&init );

is($Ping::BOUNCES, 5, '... Ping::Ping was called the expected number of times');
is($Pong::BOUNCES, 5, '... Pong::Pong was called the expected number of times');

done_testing;
