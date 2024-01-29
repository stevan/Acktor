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

class Hello :isa(Acktor) {
    use Acktor::Logging;

    method ForwardMessage :Receive ($body) {
        logger->log( INFO, ">> got ($body)" ) if INFO;

        my $remote = context->lookup('RemoteHello')
            // die 'Unable to find RemoteHello actor';

        $remote->send( event *Hello::ForwardMessage => "FORWARD => $body" );
    }
}

sub init ($ctx) {
    logger->log( INFO, ">> runnning init" ) if INFO;

    my $hello = spawn( actor_of *Hello:: );
    logger->log( INFO, ">> got actor Hello($hello)" ) if INFO;

    foreach (0 .. 5) {

        $hello->send( event *Hello::ForwardMessage => "World $_" );

        logger->log( INFO, ">> sent Hello($hello) $_ message(s)" ) if INFO;
    }

    # we can do this last, because nothing will happen until next tick
    my $remote = $ctx->dispatcher->spawn_actor(
        Acktor::Props->new( class => 'Hello', alias => 'RemoteHello' ),
        remote      => true,
        destination => '001:remote'
    );
    logger->log( INFO, ">> got remote actor RemoteHello($hello)" ) if INFO;
}

my $system = Acktor::System->new;
isa_ok($system, 'Acktor::System');

$system->run( init => \&init );

done_testing;
