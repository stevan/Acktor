
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

class Acktor::PostOffice {
    use Acktor::Logging;

    # TODO:
    # if this delivers messages, it will need mapping of destinations to sockets, etc.

    # Full address:
    # <ID>:<ACTOR>@<PID>:local
    # <ID>:<ACTOR>@<host>:<port>

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
