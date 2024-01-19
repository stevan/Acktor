
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

class Acktor::Node::ServerConnection :isa(Acktor::Node::Watcher) {
    use Acktor::Logging;

    field @input;
    field @output;

    field $socket :param;

    method socket { $socket }

    method init_socket {
        $socket->autoflush(1);
        $socket->blocking(0);

        $self->is_reading = true;
        $self->is_writing = false;
    }

    method to_write ($data) {
        $self->is_writing = true;
        push @output => $data;
    }

    method handle_read ($node) {
        logger->log( DEBUG, "Got read event for ServerConnection: "
                . $self->address
                . " connected to ClientConnection: "
                . $self->peer_address) if DEBUG;

        my $buffer = '';
        $socket->recv($buffer, 1024);
        if (length $buffer) {
            logger->log( INFO, "Got ($buffer) on Server from Client" ) if INFO;
            push @input => $buffer;
            logger->log( INFO, "Responding from Server to Client" ) if INFO;
            $self->to_write('Hello');
        }
    }

    method handle_write ($node) {
        logger->log( DEBUG, "Got write event for ServerConnection: "
                . $self->address
                . " connected to ClientConnection: "
                . $self->peer_address) if DEBUG;

        # flush them all
        while (@output) {
            my $msg = pop @output;
            logger->log( INFO, "Sending '$msg' message from Server" ) if INFO;
            $socket->send("'$msg' from Server: ".$self->address);
        }

        $self->is_writing = false;
    }

}
