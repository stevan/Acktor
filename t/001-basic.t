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
    use Test::More;

    our $GREETED = 0;
    our $GOODBYE = 0;

    method Greet ($body) {
        logger->log( INFO, ">> Hello $body" ) if INFO;
        is($body, 'World', '... got the expected greeting');
        $GREETED++;
    }

    method Goodbye ($body) {
        logger->log( INFO, ">> Goodbye $body" ) if INFO;
        is($body, 'Cruel World', '... got the expected greeting');
        $GOODBYE++;
    }
}

sub init ($ctx) {
    my $hello = spawn( actor_of *Hello:: );
    isa_ok($hello, 'Acktor::Ref');
    is($hello->props->class, 'Hello', '... the Actor is of the expected class');

    $hello->send( event *Hello::Greet => "World" );

    $ctx->schedule( 1, $hello, event *Hello::Goodbye => "Cruel World" );
}

my $system = Acktor::System->new;
isa_ok($system, 'Acktor::System');

$system->run( init => \&init );

is($Hello::GREETED, 1, '... Hello::Greet was called once');
is($Hello::GOODBYE, 1, '... Hello::Goodbye was called once');

done_testing;
