
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

class Acktor::Mailbox {
    use Acktor::Logging;

    use constant STOPPED => \'STOP';
    use constant PAUSED  => \'PAUSE';
    use constant RUNNING => \'RUN';

    field $actor_ref :param;

    field $actor;

    field @messages;
    field @buffer;
    field @deadletters;

    field $queue;

    field $status;

    ADJUST {
        $actor_ref->context->mailbox = $self;

        $queue  = \@messages;
        $actor  = $actor_ref->props->new_actor;
        $status = RUNNING;
    }

    method origin { $actor_ref->context->dispatcher->address }
    method owner  { $actor_ref }

    method status { $status }

    # ...

    method stop   { $queue = \@deadletters; $status = STOPPED; $self; }
    method pause  { $queue = \@buffer;      $status = PAUSED;  $self; }
    method resume {
        push @messages => @buffer;
        @buffer = ();
        $queue  = \@messages;
        $status = RUNNING;
        $self;
    }

    # ... messages

    method deadletters { @deadletters }

    method all_messages    {           @messages }
    method has_messages    { !! scalar @messages }
    method enqueue_message ($message) {
        push @$queue => $message;
    }

    method drain_messages {
        my @msgs = @messages;
        @messages = ();
        return @msgs;
    }

    # ... tick

    method tick {
        logger->log( DEBUG, "tick for $actor_ref" ) if DEBUG;

        if (@messages) {
            my @msgs  = @messages;
            @messages = ();

            my $context = $actor_ref->context;
            while (@msgs) {
                my $message = shift @msgs;
                try {
                    unless ($actor->accept($context, $message)) {
                        logger->log( ERROR, "actor::accept($message) sent to dead letter" ) if ERROR;
                        push @deadletters => $message;
                    }
                } catch ($e) {
                    logger->log( ERROR, "actor::accept($message) failed with ($e)" ) if ERROR;
                    # TODO: decide how to handle this:
                    #       - resume
                    #       - restart
                    #       - stop permanently (ctx->exit/despawn)
                }
            }
        }

        $self;
    }
}


__END__

=pod

=encoding UTF-8

=head1 NAME

Acktor::Mailbox

=head1 DESCRIPTION

=cut
