
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

class Acktor::PostOffice {
    use Acktor::Logging;

    field %registered;

    method register ($dispatcher) {
        # FIXME: the Dispatcher::address method does not exist anymore
        $registered{ $dispatcher->address } = $dispatcher;
    }

    method post_letters (@letters) {
        logger->log( WARN, "Posting(".(join ", " => @letters)) if WARN;
        # TODO - look through the letters and try to deliver them
        # if letter.destination in %registered
        #   enqueue message to dispatcher
        # else
        #   send to dead letter queue??
    }
}


__END__

=pod

=encoding UTF-8

=head1 NAME

Acktor::PostOffice

=head1 DESCRIPTION

=cut