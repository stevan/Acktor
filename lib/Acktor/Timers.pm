
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

use Time::HiRes;

use Acktor::Timer;

class Acktor::Timers {
    use Acktor::Logging;

    field $time;
    field @timers;

    method has_timers { !! @timers }

    method now  {
        state $MONOTONIC = Time::HiRes::CLOCK_MONOTONIC();
        # always stay up to date ...
        $time = Time::HiRes::clock_gettime( $MONOTONIC );
    }

    method sleep ($duration) {
        Time::HiRes::sleep( $duration );
    }

    method schedule_timer ($timer) {

        # XXX - should this use $time, or should it call ->now to update?
        my $end_time = $timer->calculate_end_time($self->now);

        if ( scalar @timers == 0 ) {
            # fast track the first one ...
            push @timers => [ $end_time, [ $timer ] ];
        }
        # if the last one is the same time as this one
        elsif ( $timers[-1]->[0] == $end_time ) {
            # then push it onto the same timer slot ...
            push $timers[-1]->[1]->@* => $timer;
        }
        # if the last one is less than this one, we add a new one
        elsif ( $timers[-1]->[0] < $end_time ) {
            push @timers => [ $end_time, [ $timer ] ];
        }
        elsif ( $timers[-1]->[0] > $end_time ) {
            # and only sort when we absolutely have to
            @timers = sort { $a->[0] <=> $b->[0] } @timers, [ $end_time, [ $timer ] ];
            # TODO: since we are sorting we might
            # as well also prune the cancelled ones
        }
        else {
            # NOTE:
            # we could add some more cases here, for instance
            # if the new time is before the last timer, we could
            # also check the begining of the list and `unshift`
            # it there if it made sense, but that is likely
            # micro optimizing this.
            die "This should never happen";
        }
    }

    method get_next_timer () {
        while (my $next_timer = $timers[0]) {
            # if we have any timers
            if ( $next_timer->[1]->@* ) {
                # if all of them are cancelled
                if ( 0 == scalar grep !$_->cancelled, $next_timer->[1]->@* ) {
                    # drop this set of timers
                    shift @timers;
                    # try again ...
                    next;
                }
                else {
                    last;
                }
            }
            else {
                shift @timers;
            }
        }

        return $timers[0];
    }

    method should_wait {
        my $wait = 0;

        if (my $next_timer = $self->get_next_timer) {
            $wait = $next_timer->[0] - $time
        }

        # do not wait for negative values ...
        if ($wait < $Acktor::Timer::TIMER_PRECISION_DECIMAL) {
            $wait = 0;
        }

        return $wait;
    }

    method tick {
        logger->log( DEBUG, "tick for Timers" ) if DEBUG;

        return unless @timers;

        my $now = $self->now;

        logger->log( DEBUG, "Got timers ...") if DEBUG;
        while (@timers && $timers[0]->[0] <= $now) {
            logger->log( DEBUG, "Running timers ($now) ...") if DEBUG;
            my $timer = shift @timers;
            while ( $timer->[1]->@* ) {
                my $t = shift $timer->[1]->@*;
                next if $t->cancelled; # skip if the timer has been cancelled
                try {
                    $t->callback->();
                } catch ($e) {
                    die "Timer callback failed ($timer) because: $e";
                }
            }
        }
    }

}


__END__

=pod

=encoding UTF-8

=head1 NAME

Acktor::Timers

=head1 DESCRIPTION

=cut
