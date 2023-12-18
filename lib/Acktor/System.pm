
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr   ];

use Acktor::Dispatcher;
use Acktor::Props;
use Acktor::Message;
use Acktor::System::Init;

class Acktor::System {
    use Acktor::Logging;

    field $init :param;

    field $dispatcher;

    ADJUST {
        $self->build_dispatcher()
    }

    method build_dispatcher () {
        $dispatcher  = Acktor::Dispatcher->new;

        my $init_ref = $dispatcher->spawn_actor(
            # Props[Acktor::System::Init => (init => $init)];
            Acktor::Props->new(
                class => 'Acktor::System::Init',
                args  => { init => $init },
            )
        );

        $dispatcher->dispatch(
            # Msg[ $init_ref, body => undef ];
            Acktor::Message->new(
                to   => $init_ref,
                from => $init_ref,
                body => 'init'
            )
        );
    }

    method tick {
        logger->log( DEBUG, "tick" ) if DEBUG;
        $dispatcher->tick;
    }
}

__END__
