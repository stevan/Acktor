
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

use Acktor::PostOffice::BufferedReader;
use Acktor::PostOffice::BufferedWriter;

class Acktor::PostOffice::Connection :isa(Acktor::PostOffice::Watcher) {
    use Acktor::Logging;

    field $on_messages :param;

    field $reader;
    field $writer;

    ADJUST {
        $reader = Acktor::PostOffice::BufferedReader->new;
        $writer = Acktor::PostOffice::BufferedWriter->new;

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
            my @messages = $reader->fetch_messages;
            logger->log( INFO, "Got (".(join ', ' => @messages).") on Connection from Peer" ) if INFO;
            $self->$on_messages(@messages);
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
