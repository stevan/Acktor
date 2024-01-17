
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

class Acktor::Node::ClientConnection {
    use Acktor::Logging;

    field $waiting = true;

    method handle ($socket, $mode, $node) {
        logger->log( DEBUG, "Got ($mode) event for ClientConnection: "
                . (join ":" => $socket->sockhost, $socket->sockport)
                . " connected to ServerConnection: "
                . (join ":" => $socket->peerhost, $socket->peerport)) if DEBUG;

        if ($mode eq 'r') {
            if ($waiting) {
                my $buffer = '';
                $socket->recv($buffer, 1024);
                if (length $buffer) {
                    logger->log( INFO, "Got ($buffer) on [$$] Client from Server" ) if INFO;
                    $waiting = false;
                }
            }
        }
        elsif ($mode eq 'w') {
            unless ($waiting) {
                logger->log( INFO, "Sending message from Client" ) if INFO;
                $socket->send("Hello from [$$] Client: ".(join ":" => $socket->sockhost, $socket->sockport));
                $waiting = true;
            }
        }
    }

}
