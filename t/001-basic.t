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

    method receive ($ctx, $message) {
        logger($ctx)->log( INFO, ">> Hello ".$message->body ) if INFO;
    }
}

sub init ($ctx) {
    logger($ctx)->log( INFO, ">> runnning init" ) if INFO;
    my $hello = $ctx->spawn(Acktor::Props->new( class => 'Hello' ));
    logger($ctx)->log( INFO, ">> got actor Hello($hello)" ) if INFO;
    foreach (0 .. 5) {
        $hello->send("World $_");
        logger($ctx)->log( INFO, ">> sent Hello($hello) $_ message(s)" ) if INFO;
    }
}

my $system = Acktor::System->new( init => \&init );

for (0 .. 10) {
    diag "-- TICK($_)";
    $system->tick;
}


done_testing;
