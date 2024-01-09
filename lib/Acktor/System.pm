
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

use Acktor::Dispatcher;

class Acktor::System {
    use Acktor::Logging;

    field $dispatcher;

    ADJUST {
        $dispatcher  = Acktor::Dispatcher->new;
    }

    method loop (%options) {
        logger->line( "system::loop" ) if DEBUG;
        try {
            $dispatcher->loop(%options);
        } catch ($e) {
            logger->log( ERROR, "dispatcher::loop failed with ($e)" ) if ERROR;
        }
        logger->line( "system::exit" ) if DEBUG;
    }
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Acktor::System

=head1 DESCRIPTION

=cut
