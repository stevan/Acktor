
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

class Acktor::Node::BufferedWriter {
    use Acktor::Logging;

    field @messages;

    method has_messages { !! @messages }

    method push_messages ($message) {
        push @messages => (length($message).':'.$message);
    }

    method write ($socket) {

        while (@messages) {
            my $message = pop @messages;

            logger->log( DEBUG, "Writing messages ...[ $message ]" ) if DEBUG;
            $socket->syswrite( $message, length($message) );
        }

        # returns false if all messages
        # have been sent, true otherwise
        return !! scalar @messages;
    }

}

