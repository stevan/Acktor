#!perl

use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr   ];

use Data::Dumper;
use Test::More;

use Acktor;
use Acktor::System;
use Acktor::Props;

## ------------------------------------------------------------------

class Hello :isa(Acktor) {
    method receive ($ctx, $message) {
        say "Hello ".$message->body;
    }
}

my $system    = Acktor::System->new;
my $props     = Acktor::Props->new( class => 'Hello' );
my $actor_ref = $system->spawn_actor($props);

$actor_ref->send("World $_") foreach 0 .. 5;
diag "TICK";
$system->tick;

$actor_ref->send("World $_") foreach 6 .. 10;
diag "TICK";
$system->tick;

done_testing;
