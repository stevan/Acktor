
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

use Acktor::Node::BufferedReader;
use Acktor::Node::BufferedWriter;

class Acktor::Node::Connection :isa(Acktor::Node::Watcher) {
    use Acktor::Logging;

    field $on_message :param;

    field $reader;
    field $writer;

    ADJUST {
        $reader = Acktor::Node::BufferedReader->new;
        $writer = Acktor::Node::BufferedWriter->new;

        $self->is_reading = true;
        $self->is_writing = false;
    }

    method to_write ($data) {
        $self->is_writing = true;
        $writer->push_messages($data);
    }

    method handle_read ($node) {
        logger->log( DEBUG, "Got read event for Connection: "
                . $self->address
                . " connected to PeerConnection: "
                . $self->peer_address) if DEBUG;

        if ($reader->read( $self->socket )) {
            my ($message) = $reader->fetch_messages;
            logger->log( INFO, "Got ($message) on Connection from Peer" ) if INFO;
            $self->$on_message($message);
        }
    }

    method handle_write ($node) {
        logger->log( DEBUG, "Got write event for Connection: "
                . $self->address
                . " connected to PeerConnection: "
                . $self->peer_address) if DEBUG;

        $self->is_writing = $writer->write( $self->socket );
    }

}
