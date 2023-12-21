
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr   ];

use Acktor::Dispatcher;

class Acktor::System {
    use Acktor::Logging;

    field $dispatcher;

    ADJUST {
        $dispatcher = Acktor::Dispatcher->new;
    }

    method loop (%options) {
        logger->line( "system::loop" ) if DEBUG;
        $dispatcher->loop(%options);
        logger->line( "system::exit" ) if DEBUG;
    }
}

__END__
