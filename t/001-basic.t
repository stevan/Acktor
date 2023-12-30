#!perl

use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

use Data::Dumper;
use Test::More;

use Acktor;
use Acktor::System;
use Acktor::Props;
use Acktor::Logging;

class Hello :isa(Acktor) {
    use Acktor::Logging;

    method receive ($ctx, $message) {
        logger($ctx)->log( INFO, ">> Hello ".$message->body ) if INFO;

        my $remote = $ctx->lookup('RemoteHello') // die 'Unable to find RemoteHello actor';

        $remote->send( "FORWARD => ".$message->body, $ctx->self );
    }
}

sub init ($ctx) {
    logger($ctx)->log( INFO, ">> runnning init" ) if INFO;

    my $hello = $ctx->spawn(Acktor::Props->new( class => 'Hello' ));
    logger($ctx)->log( INFO, ">> got actor Hello($hello)" ) if INFO;

    foreach (0 .. 5) {
        $hello->send("World $_", $ctx->self );
        logger($ctx)->log( INFO, ">> sent Hello($hello) $_ message(s)" ) if INFO;
    }

    # we can do this last, because nothing will happen until next tick
    my $remote = $ctx->dispatcher->spawn_remote_actor(
        Acktor::Props->new( class => 'Hello', alias => 'RemoteHello' ),
        origin => '001@remote'
    );
    logger($ctx)->log( INFO, ">> got remote actor RemoteHello($hello)" ) if INFO;
}

my $system = Acktor::System->new;

$system->loop( init => \&init );

done_testing;
