
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr   ];

class Acktor::Scheduler {
    use Acktor::Logging;

    field %to_be_run;

    method schedule ($mailbox) {
        $to_be_run{ refaddr $mailbox } = $mailbox;
    }

    method tick {
        unless ( keys %to_be_run ) {
            logger->log( DEBUG, 'tick =>> nothing to run' ) if DEBUG;
            return;
        }

        my %to_run = %to_be_run;
        %to_be_run = ();

        logger->log( DEBUG, "tick =>> running( ".
                            (join ', ' => map $_->owner->to_string, values %to_run).
                            " )" ) if DEBUG;
        map { $_->tick } values %to_run;
    }

    method loop (%options) {
        logger->line( "init" ) if DEBUG;

        my $tick = 0;
        while (1) {
            $tick++;
            logger->line( "tick($tick)" ) if DEBUG;

            $self->tick;

            last if $options{max_ticks} && $options{max_ticks} <= $tick;
        }

        logger->line( "exit" ) if DEBUG;
    }
}

__END__
