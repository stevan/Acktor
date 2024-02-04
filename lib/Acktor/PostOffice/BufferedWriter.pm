
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

class Acktor::PostOffice::BufferedWriter {
    use Acktor::Logging;

    field @letters;

    method has_letters { !! @letters }

    method send_letters ($message) {
        logger->log( DEBUG, "letter sent ($message)" ) if DEBUG;
        unshift @letters => length($message).':'.$message;
    }

    method write ($socket) {
        logger->log( DEBUG, "write event for ($socket)" ) if DEBUG;
        while (@letters) {
            my $message = pop @letters;

            logger->log( DEBUG, "Writing letters ...[ $message ]" ) if DEBUG;
            $socket->syswrite( $message, length($message) );
        }

        # returns false if all letters
        # have been sent, true otherwise
        return !! scalar @letters;
    }

}

