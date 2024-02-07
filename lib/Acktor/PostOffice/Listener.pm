
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

use Acktor::PostOffice::ServerConnection;

class Acktor::PostOffice::Listener :isa(Acktor::PostOffice::Watcher) {
    use Acktor::Logging;

    ADJUST {
        $self->is_reading = true;
    }

    method handle_read ($post_office) {
        logger->log( DEBUG, "Got read event for Listener: ".$self->_address ) if DEBUG;

        # collect as many as are waiting ...
        while (my $conn = $self->socket->accept) {
            logger->log( INFO, "Adding new ServerConnection" ) if INFO;

            $post_office->add_watcher(
                Acktor::PostOffice::ServerConnection->new(
                    address => $self->address,
                    socket  => $conn,
                )
            );
        }
    }

}
