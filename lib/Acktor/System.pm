
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr   ];

use Acktor::Dispatcher;
use Acktor::Ref;
use Acktor::Context;

class Acktor::System {
    field $dispatcher;

    ADJUST {
        $dispatcher = Acktor::Dispatcher->new;
    }

    method dispatch_message ($message) {
        $dispatcher->dispatch( $message );
    }

    method spawn_actor ($props) {
        my $actor_ref = Acktor::Ref->new(
            context => Acktor::Context->new(
                props  => $props,
                system => $self,
            )
        );

        $dispatcher->attach( $actor_ref );
        return $actor_ref;
    }

    method tick {
        $dispatcher->tick;
    }
}

__END__
