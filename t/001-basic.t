#!perl

use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr   ];

use Data::Dumper;
use Test::More;

use Acktor;
use Acktor::System;
use Acktor::Props;

class Hello :isa(Acktor) {
    method receive ($ctx, $message) {
        say ">> Hello ".$message->body;
    }
}

sub init ($ctx) {
    say ">> runnning init";
    my $hello = $ctx->spawn(Acktor::Props->new( class => 'Hello' ));
    say ">> got actor Hello($hello)";
    foreach (0 .. 5) {
        $hello->send("World $_");
        say ">> sent Hello($hello) $_ message(s) ";
    }
}

my $system = Acktor::System->new( init => \&init );

for (0 .. 10) {
    diag "-- TICK($_)";
    $system->tick;
}


done_testing;
