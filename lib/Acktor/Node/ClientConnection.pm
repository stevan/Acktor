
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

use Acktor::Node::BufferedReader;
use Acktor::Node::BufferedWriter;

class Acktor::Node::ClientConnection :isa(Acktor::Node::Watcher) {
    use Acktor::Logging;

    field $host :param;
    field $port :param;

    field $socket;

    field $reader;
    field $writer;

    ADJUST {
        $reader = Acktor::Node::BufferedReader->new;
        $writer = Acktor::Node::BufferedWriter->new;
    }

    method socket { $socket }

    method init_socket {
        $socket = IO::Socket::INET->new(
            PeerHost => $host,
            PeerPort => $port,
            proto    => 'tcp',
        ) or die "Failed to create socket for host($host) port($port): $!";

        $socket->autoflush(1);
        $socket->blocking(0);

        $self->is_reading = true;
        $self->is_writing = false;
    }

    method to_write ($data) {
        $self->is_writing = true;
        $writer->push_messages($data);
    }

    method handle_read ($node) {
        logger->log( DEBUG, "Got read event for ClientConnection: "
                . $self->address
                . " connected to ServerConnection: "
                . $self->peer_address) if DEBUG;

        if ($reader->read( $socket )) {
            my @messages = $reader->fetch_messages;
            logger->log( INFO, "Got (".(join ', ' => @messages).") to Client from Server" ) if INFO;
        }
    }

    method handle_write ($node) {
        logger->log( DEBUG, "Got write event for ClientConnection: "
                . $self->address
                . " connected to ServerConnection: "
                . $self->peer_address) if DEBUG;

        $self->is_writing = $writer->write( $socket );
    }

}
