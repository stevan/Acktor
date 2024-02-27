
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

class Acktor::Scheduler::Timer {
    our $TIMER_PRECISION_DECIMAL = 0.001;
    our $TIMER_PRECISION_INT     = 1000;

    field $timeout  :param;
    field $callback :param;

    field $cancelled = false;

    method timeout  { $timeout  }
    method callback { $callback }

    method cancel    { $cancelled = true }
    method cancelled { $cancelled }

    method calculate_end_time ($now) {
        my $end_time = $now + $timeout;
           $end_time = int($end_time * $TIMER_PRECISION_INT) * $TIMER_PRECISION_DECIMAL;

        return $end_time;
    }
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Acktor::Scheduler::Timer

=head1 DESCRIPTION

=cut
