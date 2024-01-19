
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

use Acktor::Node::Listener;
use Acktor::Node::ClientConnection;

class Acktor::Node {
    use Acktor::Logging;

    use IO::Select;
    use IO::Socket::INET;

    field $listener;
    field @watchers;

    method listen_on ($host, $port) {

        $listener = Acktor::Node::Listener->new( host => $host, port => $port );
        $listener->init_socket;

        $self->add_watcher( $listener );
    }

    method connect_to ($host, $port) {
        my $conn = Acktor::Node::ClientConnection->new( host => $host, port => $port );
        $conn->init_socket;

        $self->add_watcher( $conn );

        return $conn;
    }

    method add_watcher    ($watcher) { push @watchers => $watcher }
    method remove_watcher ($watcher) {
        @watchers = grep { refaddr $watcher != refaddr $_ } @watchers;
    }

    # TODO: move this to the Scheduler
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
