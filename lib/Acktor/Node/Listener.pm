
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

use Acktor::Node::ServerConnection;

class Acktor::Node::Listener {
    use Acktor::Logging;

    method handle ($socket, $mode, $node) {
        logger->log( DEBUG, "Got ($mode) event for Listener: "
                . join ":" => $socket->sockhost, $socket->sockport ) if DEBUG;

        my $conn = $socket->accept;

        $conn->autoflush(1);
        $conn->blocking(0);

        logger->log( INFO, "Adding new ServerConnection" ) if INFO;

        $node->add_watcher(
            $conn, 'rw',
            Acktor::Node::ServerConnection->new
        );
    }

}
