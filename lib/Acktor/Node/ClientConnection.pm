
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

class Acktor::Node::ClientConnection :isa(Acktor::Node::Watcher) {
    use Acktor::Logging;

    field @input;
    field @output;

    field $host :param;
    field $port :param;

    field $socket;

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

    method input  { @input  }
    method output { @output }

    method to_write ($data) {
        $self->is_writing = true;
        push @output => $data;
    }

    method get_input {
        return unless @input;
        pop @input;
    }

    method handle_read ($node) {
        logger->log( DEBUG, "Got read event for ClientConnection: "
                . (join ":" => $socket->sockhost, $socket->sockport)
                . " connected to ServerConnection: "
                . (join ":" => $socket->peerhost, $socket->peerport)) if DEBUG;

        my $buffer = '';
        $socket->recv($buffer, 1024);
        if (length $buffer) {
            logger->log( INFO, "Got ($buffer) on [$$] Client from Server" ) if INFO;
            push @input => $buffer;
        }
    }

    method handle_write ($node) {
        logger->log( DEBUG, "Got write event for ClientConnection: "
                . (join ":" => $socket->sockhost, $socket->sockport)
                . " connected to ServerConnection: "
                . (join ":" => $socket->peerhost, $socket->peerport)) if DEBUG;

        if (@output) {
            my $msg = pop @output;
            logger->log( INFO, "Sending '$msg' message from Client" ) if INFO;
            $socket->send("'$msg' from [$$] Client: ".(join ":" => $socket->sockhost, $socket->sockport));
        }
        unless (@output) {
            $self->is_writing = false;
        }
    }

}
