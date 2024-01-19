
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

class Acktor::Node::BufferedReader {

    field $buffer;
    field @messages;

    method has_messages { !! @messages }
    method fetch_messages {
        my @msgs = @messages;
        @messages = ();
        @msgs;
    }

    method read ($socket) {

        $socket->recv($buffer, 1024);

        if (length $buffer) {
            push @messages => $buffer;
            $buffer = '';
        }

        # returns true if we
        # have read messages
        # and false if not
        return !! scalar @messages;
    }

}
