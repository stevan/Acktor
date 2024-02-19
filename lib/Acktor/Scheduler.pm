
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

use Acktor::Event;
use Acktor::Timers;
use Acktor::System::Init;

class Acktor::Scheduler {
    use Acktor::Logging;

    field $post_office :param = undef;

    field $timers;
    field %mailboxes;
    field @deadletters;

    field %msg_buffer;
    field @to_be_run;

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
        push @{ $msg_buffer{ refaddr $to } //= [ $to ] } => $event;
    }

    method schedule_callback ($f) {
        push @to_be_run => $f;
    }

    method schedule_timer (%options) {

        my $timeout = $options{after};
        my $for     = $options{for};
        my $event   = $options{event};

        logger->log( DEBUG, "schedule( $timeout, $for, $event )" ) if DEBUG;

        my $timer = Acktor::Timer->new(
            timeout  => $timeout,
            callback => sub {
                $self->schedule_message( $for, $event );
            }
        );

        $timers->schedule_timer($timer);

        return $timer;
    }

    # ...

    method tick {

        if ($timers->has_timers) {
            logger->log( DEBUG, "tick =>> running timers" ) if DEBUG;
            $timers->tick;
        }

        if ( @to_be_run ) {
            logger->log( DEBUG, "tick =>> running callbacks( ".(join ', ' => (map "$_", @to_be_run))." )" ) if DEBUG;

            my @to_run = @to_be_run;
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

            @to_be_run = ();
        }

        if ( keys %msg_buffer ) {
            logger->log( DEBUG, "tick =>> running mailboxes" ) if DEBUG;
            $_->tick foreach $self->flush_buffered_mailboxes;
        }
    }

    method flush_buffered_mailboxes {
        return unless %msg_buffer;
        my @mailboxes = values %msg_buffer;
        %msg_buffer = ();
        return map {
            my ($to, @msgs) = @$_;
            if ( my $m = $mailboxes{ refaddr $to } ) {
                $m->enqueue_messages( @msgs );
                $m;
            } else {
                push @deadletters => [ $to, [ @msgs ] ];
                ();
            }
        } @mailboxes;
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
            if ( scalar @to_be_run == 0 && scalar keys %msg_buffer == 0 && !$timers->has_timers ) {
                last if $run_until_done;
                logger->log( DEBUG, '=>> nothing to run, ... yet' ) if DEBUG;
            }
            else {
                $self->tick;
            }

            # if there is nothing to be run ...
            if ( scalar @to_be_run == 0 && scalar keys %msg_buffer == 0 ) {
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
