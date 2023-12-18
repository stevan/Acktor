
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr   ];

use Acktor::Dispatcher;
use Acktor::Props;
use Acktor::Message;
use Acktor::System::Init;

class Acktor::System {
    field $init :param;

    field $dispatcher;

    ADJUST {
        $dispatcher  = Acktor::Dispatcher->new;
        my $init_ref = $dispatcher->spawn_actor(
            Acktor::Props->new(
                class => 'Acktor::System::Init',
                args  => { init => $init },
            )
        );
        $dispatcher->dispatch(
            Acktor::Message->new(
                to   => $init_ref,
                from => $init_ref,
                body => 'init'
            )
        );
    }

    method tick {
        say "$self tick" if $ENV{DEBUG};
        $dispatcher->tick;
    }
}

__END__
