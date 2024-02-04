#!perl

use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

use Data::Dumper;
use Test::More;

use Acktor;
use Acktor::System;
use Acktor::Behaviors;

class Pinger :isa(Acktor) {
    use Acktor::Logging;
    use Test::More;

    method Call :Receive {

        context->lookup('init')->send( event *Acktor::System::Init::Ping );

        await *Acktor::System::Init::Ping => method :Receive  {
            logger->log( INFO, "Got Ping Back") if INFO;
        };

        logger->log( INFO, "Awaiting response ...") if INFO;
    }
}

sub init ($ctx) {
    my $Pinger = spawn( actor_of( Pinger:: ) );

    $Pinger->send( event *Pinger::Call );
}

my $system = Acktor::System->new;
isa_ok($system, 'Acktor::System');

$system->run( init => \&init );

done_testing;


