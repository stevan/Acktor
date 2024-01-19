
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

use Acktor::Node::BufferedReader;
use Acktor::Node::BufferedWriter;

class Acktor::Node::ServerConnection :isa(Acktor::Node::Watcher) {
    use Acktor::Logging;

    field $socket :param;

    field $reader;
    field $writer;

    ADJUST {
        $reader = Acktor::Node::BufferedReader->new;
        $writer = Acktor::Node::BufferedWriter->new;
    }

    method socket { $socket }

    method init_socket {
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
        logger->log( DEBUG, "Got read event for ServerConnection: "
                . $self->address
                . " connected to ClientConnection: "
                . $self->peer_address) if DEBUG;

        if ($reader->read( $socket )) {
            my ($message) = $reader->fetch_messages;
            logger->log( INFO, "Got ($message) on Server from Client" ) if INFO;
            logger->log( INFO, "Responding from Server to Client" ) if INFO;
            $self->to_write($message);
        }
    }

    method handle_write ($node) {
        logger->log( DEBUG, "Got write event for ServerConnection: "
                . $self->address
                . " connected to ClientConnection: "
                . $self->peer_address) if DEBUG;

        $self->is_writing = $writer->write( $socket );
    }

}
