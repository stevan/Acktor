
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
        my @to_run = @to_be_run;
        @to_be_run = ();

        my %to_run = %to_be_run;
        %to_be_run = ();

        logger->log( DEBUG, "tick =>> running( ".
                            (join ', ' => (map "$_",                        @to_run),
                                          (map $_->owner->to_string, values %to_run)).
                            " )" ) if DEBUG;

        # we need to be careful with running these
        # as they are arbitrary callbacks ...
        foreach my $f (@to_run) {
            try {
                $f->();
            } catch ($e) {
                logger->log( ERROR, "scheduler::tick->callback($f) failed with ($e)" ) if ERROR;
                # for the most part we can ignore these, unless they are critical
                # which will need to be signified by the error object
            }
        }

        # mailboxes handle their own exceptions ...
        $_->tick foreach values %to_run;
    }


    # TODO:
    # I need to take advantage of the %options here to
    # control how much looping is done
    method loop (%options) {
        logger->line( "scheduler::init" ) if DEBUG;

        my $run_until_done = !$options{forever};

        my $tick = 0;
        while (1) {
            $tick++;
            logger->line( "scheduler::tick($tick)" ) if DEBUG;
            if ( scalar @to_be_run == 0 && scalar keys %to_be_run == 0 ) {
                last if $run_until_done;
                logger->log( DEBUG, '=>> nothing to run, ... yet' ) if DEBUG;
            }
            else {
                $self->tick;
            }
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
