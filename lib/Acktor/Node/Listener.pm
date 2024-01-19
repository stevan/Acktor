
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

use Acktor::Node::ServerConnection;

class Acktor::Node::Listener :isa(Acktor::Node::Watcher) {
    use Acktor::Logging;

    use IO::Socket;
    use IO::Socket::INET;

    field $host :param;
    field $port :param;

    field $socket;

    method socket { $socket }

    method init_socket {
        die 'Cannot call create_socket once' if $socket;

        $socket = IO::Socket::INET->new(
            Listen    => SOMAXCONN,
            LocalAddr => $host,
            LocalPort => $port,
            Proto     => 'tcp',
            ReuseAddr => 1,
        ) or die "Failed to create listen port at $port: $!";

        $socket->autoflush(1);
        $socket->blocking(0);

        $self->is_reading = true;
    }

    method handle_read ($node) {
        logger->log( DEBUG, "Got read event for Listener: "
                . join ":" => $socket->sockhost, $socket->sockport ) if DEBUG;

        my $conn = $socket->accept;

        logger->log( INFO, "Adding new ServerConnection" ) if INFO;
        my $server = Acktor::Node::ServerConnection->new( socket => $conn );
        $server->init_socket;
        $node->add_watcher( $server );
    }

}
