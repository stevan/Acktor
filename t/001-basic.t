#!perl

use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr   ];

use Data::Dumper;
use Test::More;

use Acktor;
use Acktor::System;
use Acktor::Props;
use Acktor::Logging;

class Hello :isa(Acktor) {
    use Acktor::Logging;

    field $remote :param = undef;

    method receive ($ctx, $message) {
        logger($ctx)->log( INFO, ">> Hello ".$message->body ) if INFO;
        $remote->send( "FORWARD => ".$message->body ) if $remote;
    }
}

sub init ($ctx) {

    my $remote = $ctx->dispatcher->spawn_remote_actor(Acktor::Props->new( class => 'Hello' ) );

    logger($ctx)->log( INFO, ">> runnning init" ) if INFO;
    my $hello = $ctx->spawn(Acktor::Props->new( class => 'Hello', args => { remote => $remote } ));
    logger($ctx)->log( INFO, ">> got actor Hello($hello)" ) if INFO;
    foreach (0 .. 5) {
        $hello->send("World $_");
        logger($ctx)->log( INFO, ">> sent Hello($hello) $_ message(s)" ) if INFO;
    }
}

my $system = Acktor::System->new;

$system->loop(
    init      => \&init,
    max_ticks => 4
);

done_testing;
