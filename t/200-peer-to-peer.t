#!perl

use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

use Data::Dumper;

=pod

Node1 = perl start-note.pl --at 3000
Node2 = perl start-node.pl --at 3001 --connect 3000

Node2
    - connects to Node1

Node1
    - accepts connection from Node2
        - sends WelcomeMessage to Node2

Node2
    - reads WelcomeMessage
        - sends WelcomeResponse to Node1

Node1
    - reach WelcomeResponse
        - sends WelcomeRepsonse to Node2

WelcomeMessage
    - container sender for response

WelcomeResponse
    - contains list of important PIDs and their addresses


-----


Node
    - listen
        - $socket (r)
    - connect
        - new ClientConnection with connecte Server
    - loop
        - accept
            - new ServerConnection with connected Client
        - read && write to/from *Connections

ServerConnection
    - $socket (rw)
    - prints to connected Client
    - reads from connected Client

ClientConnection
    - $socket (rw)
    - prints to the connected Server
    - reads from the connected Server


=cut



class Node {
    use Time::HiRes 'time';

    use IO::Select;
    use IO::Socket::INET;

    field $timeout :param = 0;

    field $listen;
    field $select;

    field @connections;

    ADJUST {
        $select = IO::Select->new;
    }

    method listener { $listen }

    method listen ($host, $port) {
        say "listening ...";
        $listen = IO::Socket::INET->new(
            Listen    => SOMAXCONN,
            LocalPort => $port,
            LocalAddr => $host,
            Proto     => 'tcp',
            ReuseAddr => 1,
        ) or die "Failed to create listen port at $port: $!";

        say "got listen socket($listen)";
        $listen->autoflush(1);
        $listen->blocking(0);

        $select->add( $listen );
    }

    method connect ($host, $port) {
        my $conn = IO::Socket::INET->new(
            PeerHost => $host,
            PeerPort => $port,
            proto    => 'tcp',
        ) or die "Failed to create socket for host($host) port($port): $!";


        say "got connection socket($conn)";
        $conn->autoflush(1);
        $conn->blocking(0);

        $select->add( $conn );

        return $conn;
    }

    method loop ($handlers) {
        say "starting loop ... ";

        local $! = 0;

        while (1) {
            say "looping ($select) waiting for read event w/ timeout($timeout) ...";

            my @handles = IO::Select::select(
                (keys %{$handlers->{on_read}}  ? $select : undef),
                (keys %{$handlers->{on_write}} ? $select : undef),
                $select,
                $timeout
            );

            unless (@handles) {
                say "... no events to see, looping";
                next;
            }

            my ($r, $w, $e) = @handles;

            if ( keys %{$handlers->{on_read}} ) {
                foreach my $fh (@$r) {
                    if ( $fh == $listen ) {
                        say "got accept event from listener($fh)";
                        my $c = $fh->accept;

                        $c->autoflush(1);
                        $c->blocking(0);

                        $select->add( $c );

                        say "got accept event from ($fh) with ($c) calling handlers";
                        $handlers->{on_accept}->{$fh}->( $c ) if $handlers->{on_accept}->{$fh};
                    }
                    else {
                        say "got read event from ($fh) calling handlers";
                        $handlers->{on_read}->{$fh}->( $fh ) if $handlers->{on_read}->{$fh};
                    }
                }
            }

            if ( keys %{$handlers->{on_write}} ) {
                foreach my $fh (@$w) {
                    say "got write event from ($fh) calling handlers";
                    $handlers->{on_write}->{$fh}->( $fh ) if $handlers->{on_write}->{$fh};
                }
            }
        }
    }
}


my $peer = Node->new( timeout => 3 );

$peer->listen('0.0.0.0', 3000);

my $conn = $peer->connect('0.0.0.0', 3000);

my $output;

say "Listening ...." . join ":" => $peer->listener->sockhost, $peer->listener->sockport;
say "Connected to ...." . join ":" => $conn->peerhost, $conn->peerport;

my $spec;

my sub bar ($fh) {
    my $input = <$fh>;
    if (length $input) {
        say "*** On Read " . join ":" => $fh->sockhost, $fh->sockport;
        say "***    Peer " . join ":" => $fh->peerhost, $fh->peerport;
        if ( $input eq 'World' ) {
            say "!!!!!!!!!! got input($input) for Listener";
        }
        else {
            say "!!!!!!!!!! got BAD input($input)";
        }
    }
}

$spec = {
    on_accept => +{
        # (1)
        $peer->listener => sub ($fh) {
            warn $peer->listener . ", " . $fh;
            say "*** On Accept " . join ":" => $fh->sockhost, $fh->sockport;
            say "***      Peer " . join ":" => $fh->peerhost, $fh->peerport;
            $spec->{on_write}->{$fh} = sub ($) {
                say ">>>> printing the initial Hello";
                $fh->print("Hello");
                delete $spec->{on_write}->{$fh};
            };
            $spec->{on_read}->{$fh} = \&bar;
        }
    },
    on_read   => +{
        $conn => sub ($fh) {
            my $input = <$fh>;
            if (length $input) {
                say "*** On Read " . join ":" => $fh->sockhost, $fh->sockport;
                say "***    Peer " . join ":" => $fh->peerhost, $fh->peerport;
                if ( $input eq 'Hello' ) {
                    say "!!!!!!!!!! got input($input) for Conn";
                    $output = 'World';
                    #$spec->{on_write}->{$conn} = \&foo;
                }
                else {
                    say "!!!!!!!!!! got BAD input($input)";
                }
            }
        }
    },
    on_write  => +{
        $conn => sub ($fh) {
            # if client has output
            if ( $output ) {
                say "*** On Write " . join ":" => $fh->sockhost, $fh->sockport;
                say "***     Peer " . join ":" => $fh->peerhost, $fh->peerport;
                say "Printing output($output) on Conn";
                $fh->print($output); # Client writes back to server
                undef $output;
                delete $spec->{on_write}->{$conn};
            }
            else {
                say "... nothing to write";
            }
        }
    },
};

$peer->loop($spec);

