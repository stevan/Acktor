
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

use Acktor::Timers;

class Acktor::Scheduler {
    use Acktor::Logging;

    field $post_office :param = undef;

    field $timers;
    field %mailboxes;
    field @deadletters;

    field @to_be_run;
    field %to_be_run;

    ADJUST {
        $timers = Acktor::Timers->new;
    }

    # ...

    method register ($ref, $mailbox) {
        $mailboxes{ refaddr $ref } = $mailbox;
    }

    method deregister ($ref) {
        delete $mailboxes{ refaddr $ref };
    }

    method suspend ($ref) {
        $mailboxes{ refaddr $ref }->stop;
    }

    # ...

    method schedule_message ($to, $event) {
        if ( my $m = $mailboxes{ refaddr $to } ) {
            $m->enqueue_message( $event );
            $to_be_run{ refaddr $m } //= $m;
        } else {
            push @deadletters => [ $to, $event ];
        }
    }

    method schedule_callback ($f) {
        push @to_be_run => $f;
    }

    method schedule_timer ($timer) {
        $timers->schedule_timer($timer);
    }

    # ...

    method tick {

        if ($timers->has_timers) {
            logger->log( DEBUG, "tick =>> running timers" ) if DEBUG;
            $timers->tick;
        }

        my @to_run;
        my %to_run;

        if ( @to_be_run ) {
            @to_run    = @to_be_run;
            @to_be_run = ();
        }

        if ( keys %to_be_run ) {
            %to_run    = %to_be_run;
            %to_be_run = ();
        }

        if ( @to_run ) {
            logger->log( DEBUG, "tick =>> running callbacks( ".(join ', ' => (map "$_", @to_run))." )" ) if DEBUG;

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
        }

        if ( keys %to_run ) {
            logger->log( DEBUG, "tick =>> running mailboxes( ".
                                (join ', ' => (map $_->owner->to_string, values %to_run)).
                                " )" ) if DEBUG;

            # mailboxes handle their own exceptions ...
            $_->tick foreach values %to_run;
        }
    }


    # TODO:
    # I need to take advantage of the %options here to
    # control how much looping is done
    method run (%options) {
        logger->line( "scheduler::start" ) if DEBUG;

        my $run_until_done = !$options{forever};

        my $tick = 0;
        while (1) {
            $tick++;
            logger->line( "scheduler::tick($tick)" ) if DEBUG;

            # FIXME: this logic is confusing
            if ( scalar @to_be_run == 0 && scalar keys %to_be_run == 0 && !$timers->has_timers ) {
                last if $run_until_done;
                logger->log( DEBUG, '=>> nothing to run, ... yet' ) if DEBUG;
            }
            else {
                $self->tick;
            }

            # if there is nothing to be run ...
            if ( scalar @to_be_run == 0 && scalar keys %to_be_run == 0 ) {
                # check timers first ...
                if (my $wait = $timers->should_wait) {
                    logger->log( WARN, "... waiting ($wait)" ) if WARN;
                    if ($post_office->is_listening) {
                        $post_office->tick( $wait );
                    }
                    else {
                        $timers->sleep( $wait );
                    }
                    # if we have waited, proceed to next tick
                    next;
                }
            }

            # unless we have already waited
            # we want to give the watcher a
            # chance to get called here ...
            $post_office->tick( 0 ) if $post_office->is_listening;
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
