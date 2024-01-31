
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

use Acktor::Node::Listener;
use Acktor::Node::Connection;

class Acktor::Node {
    use Acktor::Logging;

    use IO::Select;
    use IO::Socket::INET;

    field $host :param;
    field $port :param;

    field $listener;
    field @watchers;

    method start_listening {

        my $socket = IO::Socket::INET->new(
            Listen    => SOMAXCONN,
            LocalAddr => $host,
            LocalPort => $port,
            Proto     => 'tcp',
            ReuseAddr => 1,
        ) or die "Failed to create listen address at ${host}:${port} => $!";

        $listener = Acktor::Node::Listener->new( socket => $socket );
        $self->add_watcher( $listener );
    }

    method connect_to ($host, $port) {

        my $socket = IO::Socket::INET->new(
            PeerHost => $host,
            PeerPort => $port,
            proto    => 'tcp',
        ) or die "Failed to create socket for host($host) port($port): $!";

        my $conn = Acktor::Node::Connection->new( socket => $socket );
        $self->add_watcher( $conn );

        return $conn;
    }

    method add_watcher    ($watcher) { push @watchers => $watcher }
    method remove_watcher ($watcher) {
        @watchers = grep { refaddr $watcher != refaddr $_ } @watchers;
    }

    method tick ($timeout) {
        local $! = 0;

        logger->log( DEBUG, "looping w/ timeout($timeout) ..." ) if DEBUG;

        my $readers = IO::Select->new;
        my $writers = IO::Select->new;

        my %to_read;
        my %to_write;

        foreach my $watcher (@watchers) {
            my $fh = $watcher->socket;

            if ($watcher->is_reading) {
                #say "adding read watcher ($fh) ($watcher)";
                push @{ $to_read{ $fh } //= [] } => $watcher;
                $readers->add( $fh );
            }

            if ($watcher->is_writing) {
                #say "adding write watcher ($fh) ($watcher)";
                push @{ $to_write{ $fh } //= [] } => $watcher;
                $writers->add( $fh );
            }
        }

        my @handles = IO::Select::select(
            $readers,
            $writers,
            undef, # TODO: fix me when I know when I am doing
            $timeout
        );

        my ($r, $w, undef) = @handles;

        if (!defined $r && !defined $w) {
            logger->log( DEBUG, "... no events to see, looping" ) if DEBUG;
            return;
        }

        foreach my $fh (@{ $r // [] }) {
            foreach my $watcher ( $to_read{$fh}->@* ) {
                $watcher->handle_read( $self );
            }
        }
        foreach my $fh (@{ $w // [] }) {
            foreach my $watcher ( $to_write{$fh}->@* ) {
                $watcher->handle_write( $self );
            }
        }
    }

}

=pod

Node handles creating the sockets, where needed. It then passes them to a Watcher,
which will allow for buffered reading/writing of messages.

- Listener is a special case of Watcher that accepts new connections.
- Server/Client Connections can always read, and will write when needed.
- There is no request/response, just message transfer back and forth.

# How to make Remote Actors visible to another Node

Upon connection, client should send Register message to introduce itself
to the node it just connected to. It does this by supply it's host and port
as well as a list of actor aliases it has.

It can assume there is an `init` actor, or some other kind of entry point
that messages can be sent to.

    { to => <init@0:3000>,
    from => <init@0:4000>,
    event => {
        symbol  => 'Register',
        payload => {
            host: 0,
            port: 4000,
            aliases: [
                init   // can be assumed
                echo
                lookup
            ]
        }
    }}

The receiveing node, will create new remote actors for each of the aliases. Then
it will then respond to the remote <init> actor with a `Register` message of it's
own.

=cut
