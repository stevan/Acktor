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

class Echo :isa(Acktor) {
    use Acktor::Logging;

    method receive ($ctx, $msg) {
        logger($ctx)->log( INFO, $msg->body ) if INFO;
    }
}

sub init ($ctx) {
    logger($ctx)->log( INFO, ">> runnning init" ) if INFO;

    $ctx->send(Acktor::Message->new(
        to   => $ctx->dispatcher->init_ref,
        from => $ctx->spawn( Acktor::Props->new( class => 'Echo' ) ),
        body => [ 'get_actor_tree' ]
    ));

}

my $system = Acktor::System->new;

$system->loop( init => \&init );

done_testing;
