
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

class Acktor::IO::BufferedWriter {
    use Acktor::Logging;

    field @packets;

    method has_packets { !! @packets }

    method send_packets ($message) {
        logger->log( DEBUG, "letter sent ($message)" ) if DEBUG;
        unshift @packets => length($message).':'.$message;
    }

    method write ($socket) {
        logger->log( DEBUG, "write event for ($socket)" ) if DEBUG;
        while (@packets) {
            my $message = pop @packets;

            logger->log( DEBUG, "Writing packets ...[ $message ]" ) if DEBUG;
            $socket->syswrite( $message, length($message) );
        }

        # returns false if all packets
        # have been sent, true otherwise
        return !! scalar @packets;
    }

}

