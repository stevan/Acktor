
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

use Acktor::IO::BufferedReader;
use Acktor::IO::BufferedWriter;

class Acktor::PostOffice::Connection :isa(Acktor::PostOffice::ConnectionWatcher) {
    use Acktor::Logging;

    field $reader;
    field $writer;

    ADJUST {
        $reader = Acktor::IO::BufferedReader->new;
        $writer = Acktor::IO::BufferedWriter->new;

        $self->is_reading = true;
        $self->is_writing = false;
    }

    method to_write ($data) {
        logger->log( DEBUG, "to_write called with ($data)" ) if DEBUG;
        $self->is_writing = true;
        $writer->send_packets($data);
    }

    method handle_read ($post_office) {
        logger->log( DEBUG, "Got read event for Connection: "
                . $self->_address
                . " connected to PeerConnection: "
                . $self->_peer_address) if DEBUG;

        if ($reader->read( $self->socket )) {
            my @packets = $reader->fetch_packets;
            logger->log( INFO, "Got (".(join ', ' => @packets).") on Connection from Peer" ) if INFO;
            #$self->$on_letters(@packets);
            $post_office->deliver_letters( @packets );
        }

        if ( my $error = $reader->get_error ) {
            if ($error == $reader->EOF) {
                $self->is_reading = false;
                $self->is_writing = false;
                # TODO - do something here ... dunno what yet
            }
        }
    }

    method handle_write ($post_office) {
        logger->log( DEBUG, "Got write event for Connection: "
                . $self->_address
                . " connected to PeerConnection: "
                . $self->_peer_address) if DEBUG;

        $self->is_writing = $writer->write( $self->socket );
    }

}
