#!perl

use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

use Data::Dumper;
use Time::HiRes 'time';

use Acktor;
use Acktor::System;
use Acktor::Behaviors;

our $NUM_PROCESSES = $ARGV[0] // 10;
our $NUM_MESSAGES  = $ARGV[1] // 10;

our $START = time;
our $MSG_START;


class ErlangTest :isa(Acktor) {

    field $id   :param;
    field $next :param = undef;

    method Ping ($count) {
        if (defined $next) {
            $next->send( event *Ping => $count + 1 );
        }
    }
}

sub init ($ctx) {
    my $start = spawn( actor_of *ErlangTest:: => (id => 0) );

    my $t = $start;
    foreach my $id ( 1 .. $NUM_PROCESSES ) {
        $t = spawn( actor_of *ErlangTest:: => (
            id   => $id,
            next => $t,
        ));
    }

    $MSG_START = time();
    say "Process: ".($MSG_START - $START);

    my $first = event *ErlangTest::Ping => 0;
    $t->send( $first ) foreach 1 .. $NUM_MESSAGES;
}

my $system = Acktor::System->new;

$system->run( init => \&init );

say "Message: ".(time() - $MSG_START);
say "Runtime: ".(time() - $START);



