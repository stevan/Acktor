
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

use Acktor::IO::Watcher;

class Acktor::IO::Scheduler {
    use Acktor::Logging;

    field @watchers;

    method add_watcher ($watcher) {
        push @watchers => $watcher;
    }

    method remove_watcher ($watcher) {
        @watchers = grep { refaddr $watcher != refaddr $_ } @watchers;
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
            my $fh = $watcher->fh;

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
        # - close all watcher fh
        # - flush any buffers needed?
    }

}
