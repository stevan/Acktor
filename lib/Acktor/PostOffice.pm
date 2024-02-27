
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

use JSON::XS;

use Acktor::PostOffice::Listener;
use Acktor::PostOffice::ClientConnection;
use Acktor::Remote::Address;

class Acktor::PostOffice {
    use Acktor::Logging;

    use IO::Select;
    use IO::Socket::INET;

    field $dispatcher :param = undef;

    field $listener;
    field @watchers;
    field @deadletters;

    field %lookup;


    method dispatcher { $dispatcher }

    ## ----------------------------------------------------

    method listen_on ($address) {

        my $addr = Acktor::Remote::Address->new( address => $address );

        my $socket = IO::Socket::INET->new(
            Listen    => SOMAXCONN,
            LocalAddr => $addr->host,
            LocalPort => $addr->port,
            Proto     => 'tcp',
            ReuseAddr => 1,
        ) or die "Failed to create listen address at $address => $!";

        $listener = Acktor::PostOffice::Listener->new(
            address => $addr,
            socket  => $socket,
        );

        $self->add_listener( $listener );

        return $addr;
    }

    method connect_to ($address) {

        my $addr = Acktor::Remote::Address->new( address => $address );

        my $socket = IO::Socket::INET->new(
            PeerHost => $addr->host,
            PeerPort => $addr->port,
            proto    => 'tcp',
        ) or die "Failed to create socket for $address => $!";

        my $conn = Acktor::PostOffice::ClientConnection->new(
            address => $addr,
            socket  => $socket,
        );

        $self->add_watcher( $conn );

        return $addr;
    }

    # TODO: check the connections for these too

    method is_listening { !! $listener }
    method is_connected_to ($address) { exists $lookup{ $address->hostname } }

    ## ----------------------------------------------------

    method post_letters (@letters) {
        logger->log( DEBUG, "Posting(".(join ", " => @letters)) if DEBUG;
        foreach my $letter (@letters) {
            if (my $watcher = $lookup{ $letter->to->hostname }) {
                #say $watcher->peer_address;
                #say $letter->destination;
                #say JSON::XS->new->encode( $letter->pack );
                $watcher->to_write( JSON::XS->new->encode( $letter->pack ) );
            }
            else {
                logger->log( ERROR, "Cannot find destination: ". $letter->to->hostname) if ERROR;
                logger->log( ERROR, "DeadLetters(".(join ", " => @letters)) if ERROR;
                use Data::Dumper;
                logger->log( ERROR, join "\n" => map { $_ .' => '.$lookup{$_} } keys %lookup) if ERROR;
                push @deadletters => $letter;
            }
        }
    }

    method deliver_letters (@letters) {
        logger->log( WARN, "Delivering(".(join ", " => @letters)) if WARN;
        foreach my $letter (@letters) {
            my $data = JSON::XS->new->decode( $letter );

            my $to   = Acktor::Remote::Address->new( address => $data->{to} );
            my $from = Acktor::Remote::Address->new( address => $data->{from} );

            my $recipient = $dispatcher->lookup( $to->pid ) // die 'Could not find to: actor('.$to->pack.')';
            my $sender    = $dispatcher->spawn_remote_actor( $from );

            $dispatcher->dispatch(
                $recipient,
                Acktor::Event->new(
                    symbol  => $data->{event}->{symbol},
                    payload => $data->{event}->{payload},
                    context => $sender->context, # XXX - this should be a remote context??
                )
            );
        }
    }

    ## ----------------------------------------------------

    method add_listener ($listener) {
        push @watchers => $listener;
    }

    method add_watcher ($watcher) {
        push @watchers => $watcher;
        $lookup{ $watcher->address->hostname } = $watcher;
        #warn join ', ' => map { $_ .' => '.$lookup{$_} } keys %lookup;
    }

    method remove_watcher ($watcher) {
        @watchers = grep { refaddr $watcher != refaddr $_ } @watchers;
        delete $lookup{ $watcher->address->hostname };
    }

    ## ...

    method tick ($timeout) {
        local $! = 0;

        logger->log( DEBUG, "tick w/ timeout($timeout) ..." ) if DEBUG;

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


    method shutdown {
        # TODO - implement me ...
        # - unbind listener
        # - close all watcher sockets
        # - flush any buffers needed?
    }

}


=pod

Wire Format?
    - netstring JSON?

-----------------------------------------------------------

- System owns PostOffice
    - will pass arguments such as:
        - listen <host>:<port>
        - connect <host>:<port>

- PostOffice owns Node
    - constructs Node from arguments (listen, connect)

- Dispatcher gets PostOffice
    - registers PostOffice->Node with Scheduler
    - if PostOffice
        - use that for address, not the `local` one

- Scheduler has Node
    - handles wait with `select`
    - calls Node->tick

- PostOffice
    - post_letters
        - loops over letters in outbox
            - add letters to connection outbox
    - deliver_letters
        - loop over letters in inbox
            - dispatch messages locally

    - register watchers for:
        - reading
            - for all watched connections
                - read letters and add to inbox
            - call deliver_letters
        - writing
            - for all watched connections
                - write letters from connection outbox

-----------------------------------------------------------

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
