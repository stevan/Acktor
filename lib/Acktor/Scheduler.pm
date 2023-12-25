
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

class Acktor::Scheduler {
    use Acktor::Logging;

    field @to_be_run;
    field %to_be_run;

    method schedule ($mailbox) {
        $to_be_run{ refaddr $mailbox } = $mailbox;
    }

    method next_tick ($f) { push @to_be_run => $f }

    method tick {
        if ( scalar @to_be_run == 0 && scalar keys %to_be_run == 0 ) {
            logger->log( DEBUG, 'tick =>> nothing to run' ) if DEBUG;
            return;
        }

        my @to_run = @to_be_run;
        @to_be_run = ();

        my %to_run = %to_be_run;
        %to_be_run = ();

        logger->log( DEBUG, "tick =>> running( ".
                            (join ', ' => (map "$_",                        @to_run),
                                          (map $_->owner->to_string, values %to_run)).
                            " )" ) if DEBUG;

        map $_->(),          @to_run;
        map $_->tick, values %to_run;
    }

    method loop (%options) {
        logger->line( "scheduler::init" ) if DEBUG;

        my $tick = 0;
        while (1) {
            $tick++;
            logger->line( "scheduler::tick($tick)" ) if DEBUG;

            $self->tick;

            last if $options{max_ticks} && $options{max_ticks} <= $tick;
        }

        logger->line( "scheduler::exit" ) if DEBUG;
    }
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Acktor::Scheduler

=head1 DESCRIPTION

=cut
