
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr   ];

use Acktor::Dispatcher;

class Acktor::System {
    field $dispatcher;

    ADJUST {
        $dispatcher = Acktor::Dispatcher->new( system => $self );
    }

    method dispatch_message ($message) {
        $dispatcher->dispatch( $message );
    }

    method spawn_actor ($props) {
        return $dispatcher->spawn_actor( $props );
    }

    method tick {
        $dispatcher->tick;
    }
}

__END__
