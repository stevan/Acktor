
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

use Acktor::Node::Listener;

class Acktor::Node {
    use Acktor::Logging;

    use IO::Select;
    use IO::Socket::INET;

    field $select;

    field $listener;
    field %readers;
    field %writers;

    ADJUST {
        $select = IO::Select->new;
    }

    method listen ($host, $port) {
        $listener = IO::Socket::INET->new(
            Listen    => SOMAXCONN,
            LocalPort => $port,
            LocalAddr => $host,
            Proto     => 'tcp',
            ReuseAddr => 1,
        ) or die "Failed to create listen port at $port: $!";

        $listener->autoflush(1);
        $listener->blocking(0);

        $self->add_watcher(
            $listener, 'r',
            Acktor::Node::Listener->new
        );
    }

    method connect ($host, $port, $handler) {
        my $conn = IO::Socket::INET->new(
            PeerHost => $host,
            PeerPort => $port,
            proto    => 'tcp',
        ) or die "Failed to create socket for host($host) port($port): $!";

        $conn->autoflush(1);
        $conn->blocking(0);

        $self->add_watcher( $conn, 'rw', $handler );

        return $conn;
    }

    method add_watcher ($fh, $mode, $handler) {
        push @{$readers{$fh} //= []} => $handler if $mode =~ /^r/;
        push @{$writers{$fh} //= []} => $handler if $mode =~ /^r?w$/;

        $select->add($fh) unless $select->exists($fh);
    }

    method remove_watcher ($fh, $mode, $handler) {
        # remove the handler
        @{$readers{$fh}} = grep { refaddr $handler != refaddr $_ } @{$readers{$fh}}  if $mode =~ /^r/;
        @{$writers{$fh}} = grep { refaddr $handler != refaddr $_ } @{$writers{$fh}} if $mode =~ /^r?w$/;

        # remove the $fh from readers/writers if they are empty
        delete $readers{$fh} unless $readers{$fh}->@*;
        delete $writers{$fh} unless $writers{$fh}->@*;

        # and remove the $fh if not one needs it anymore
        $select->remove($fh) unless $readers{$fh}->@* && $writers{$fh}->@*;
    }

    method tick ($timeout) {
        local $! = 0;

        logger->log( DEBUG, "looping w/ timeout($timeout) ..." ) if DEBUG;

        my @handles = IO::Select::select(
            (keys %readers ? $select : undef),
            (keys %writers ? $select : undef),
            $select,
            $timeout
        );

        my ($r, $w, $e) = @handles;

        unless (@$r || @$w) {
            logger->log( DEBUG, "... no events to see, looping" ) if DEBUG;
            next;
        }

        if ( keys %readers ) {
            foreach my $fh (@$r) {
                foreach my $handler ( $readers{$fh}->@* ) {
                    $handler->handle( $fh, 'r', $self );
                }
            }
        }

        if ( keys %writers ) {
            foreach my $fh (@$w) {
                foreach my $handler ( $writers{$fh}->@* ) {
                    $handler->handle( $fh, 'w', $self );
                }
            }

        }
    }

}
