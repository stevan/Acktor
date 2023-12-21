
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr   ];

use Acktor::Dispatcher;
use Acktor::Scheduler;
use Acktor::Props;

use Acktor::System::Init;

class Acktor::System {
    use Acktor::Logging;

    field $init :param;

    field $dispatcher;

    ADJUST {
        $self->build_dispatcher()
    }

    method build_dispatcher () {
        $dispatcher  = Acktor::Dispatcher->new(
            scheduler => Acktor::Scheduler->new
        );

        my $init_ref = $dispatcher->spawn_actor(
            Acktor::Props->new(
                class => 'Acktor::System::Init',
                args  => { init => $init },
            )
        );

        $init_ref->send( 'init' );
    }

    method tick {
        logger->log( DEBUG, "tick" ) if DEBUG;
        $dispatcher->tick;
    }

    method loop (%options) {
        $dispatcher->loop(%options);
    }
}

__END__
