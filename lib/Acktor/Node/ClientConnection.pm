
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

    method to_write ($data) {
        $self->is_writing = true;
        push @output => $data;
    }

    method handle_read ($node) {
        logger->log( DEBUG, "Got read event for ClientConnection: "
                . $self->address
                . " connected to ServerConnection: "
                . $self->peer_address) if DEBUG;

        my $buffer = '';
        $socket->recv($buffer, 1024);
        if (length $buffer) {
            logger->log( INFO, "Got ($buffer) on [$$] Client from Server" ) if INFO;
            push @input => $buffer;
        }
    }

    method handle_write ($node) {
        logger->log( DEBUG, "Got write event for ClientConnection: "
                . $self->address
                . " connected to ServerConnection: "
                . $self->peer_address) if DEBUG;

        # flush them all
        while (@output) {
            my $msg = pop @output;
            logger->log( INFO, "Sending '$msg' message from Client" ) if INFO;
            $socket->send("'$msg' from [$$] Client: ".$self->address);
        }

        $self->is_writing = false;
    }

}
