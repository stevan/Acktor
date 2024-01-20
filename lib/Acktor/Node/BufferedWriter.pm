
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

class Acktor::Node::BufferedWriter {

    field @messages;

    method has_messages { !! @messages }

    method push_messages ($message) {
        push @messages => $message;
    }

    method write ($socket) {
        while (@messages) {
            my $message = pop @messages;
            $socket->syswrite( $message, length($message) );
        }

        # returns false if all messages
        # have been sent, true otherwise
        return !! scalar @messages;
    }

}
