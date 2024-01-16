
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

class Acktor::Node::ServerConnection {
    use Acktor::Logging;

    field $waiting = false;

    method handle ($socket, $mode, $node) {
        logger->log( DEBUG, "Got ($mode) event for ServerConnection: "
                . (join ":" => $socket->sockhost, $socket->sockport)
                . " connected to ClientConnection: "
                . (join ":" => $socket->peerhost, $socket->peerport)) if DEBUG;

        if ($mode eq 'w') {
            unless ($waiting) {
                logger->log( INFO, "Sending message from server") if INFO;
                $socket->send('Hello from Server: '.(join ":" => $socket->sockhost, $socket->sockport));
                $waiting = true;
            }
        }
        elsif ($mode eq 'r') {
            if ($waiting) {
                my $buffer = '';
                $socket->recv($buffer, 1024);
                if (length $buffer) {
                    logger->log( INFO, "Got ($buffer) from Client" ) if INFO;
                    $waiting = false;
                }
            }
        }

    }

}
