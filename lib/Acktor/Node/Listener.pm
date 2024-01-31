
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

use Acktor::Node::Connection;

class Acktor::Node::Listener :isa(Acktor::Node::Watcher) {
    use Acktor::Logging;

    ADJUST {
        $self->is_reading = true;
    }

    method handle_read ($node) {
        logger->log( DEBUG, "Got read event for Listener: ".$self->address ) if DEBUG;

        # collect as many as are waiting ...
        while (my $conn = $self->socket->accept) {
            logger->log( INFO, "Adding new ServerConnection" ) if INFO;
            $node->add_watcher(
                Acktor::Node::Connection->new(
                    socket      => $conn,
                    on_messages => sub ($w, @msgs) {
                        my ($msg) = @msgs;
                        say "SERVER GOT $msg";
                        $w->to_write("Goodbye ($msg)");
                    }
                )
            );
        }
    }

}
