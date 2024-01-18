
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

class Acktor::Node::ClientConnection {
    use Acktor::Logging;

    field @input;
    field @output;

    ADJUST {
        push @output => 'Hello';
    }

    method input  { @input  }
    method output { @output }

    method to_write ($data) {
        push @output => $data;
    }

    method get_input {
        return unless @input;
        pop @input;
    }

    method handle ($socket, $mode, $node) {
        logger->log( DEBUG, "Got ($mode) event for ClientConnection: "
                . (join ":" => $socket->sockhost, $socket->sockport)
                . " connected to ServerConnection: "
                . (join ":" => $socket->peerhost, $socket->peerport)) if DEBUG;

        if ($mode eq 'r') {
            my $buffer = '';
            $socket->recv($buffer, 1024);
            if (length $buffer) {
                logger->log( INFO, "Got ($buffer) on [$$] Client from Server" ) if INFO;
                push @input => $buffer;
            }
        }
        elsif ($mode eq 'w') {
            if (@output) {
                my $msg = pop @output;
                logger->log( INFO, "Sending '$msg' message from Client" ) if INFO;
                $socket->send("'$msg' from [$$] Client: ".(join ":" => $socket->sockhost, $socket->sockport));
            }
        }
    }

}
