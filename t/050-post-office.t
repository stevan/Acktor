#!perl

use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

use IO::File;
use Data::Dumper;

use Acktor;
use Acktor::Behaviors;

use Acktor::System;
use Acktor::Props;
use Acktor::Logging;

class Echo :isa(Acktor) {
    use Acktor::Logging;

    field $remote :param = undef;

    method Echo :Receive ($body) {
        logger->log( INFO, "Echo >> got ($body)" ) if INFO;

        context->lookup('init@127.0.0.1:3000')->send( event *Acktor::System::Init::Ping );

        await *Acktor::System::Init::Ping => method :Receive  {
            logger->log( WARN, "Got Ping Back") if WARN;
        };
    }

    method End :Receive {
        logger->log( INFO, "Echo >> Goodbye" ) if INFO;
        die;
    }
}

sub init ($ctx) {
    logger->log( INFO, ">> runnning init" ) if INFO;

    my $Echo = spawn( actor_of Echo:: );
    logger->log( INFO, ">> got actor Echo($Echo)" ) if INFO;

    $Echo->send( event *Echo::Echo => "Hello" );

    $ctx->schedule(
        event => event( *Echo::Echo => "Hello Again" ),
        for   => $Echo,
        after => 1,
    );

    $ctx->schedule(
        event => event( *Echo::End ),
        for   => $Echo,
        after => 3,
    );
}

if (my $pid = fork()) {

    my $log = IO::File->new('>parent.log') or die "Could not open log because: $!";
    *STDOUT = $log;
    *STDERR = $log;

    my $system = Acktor::System->new;

    $system->run(
        listen_on  => '127.0.0.1:3000',
        connect_to => [ '127.0.0.1:3001' ],
        init       => sub ($ctx) {
            my $Echo = spawn( actor_of Echo:: );
            $ctx->schedule(
                event => event( *Echo::End ),
                for   => $Echo,
                after => 10,
            );
        },
    );

    waitpid($pid, 0);
} else {

    my $system = Acktor::System->new;

    $system->run(
        init       => \&init,
        listen_on  => '127.0.0.1:3001',
        connect_to => [ '127.0.0.1:3000' ]
    );


    exit();
}
