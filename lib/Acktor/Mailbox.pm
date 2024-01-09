
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

class Acktor::Mailbox {
    use Acktor::Logging;

    my $WAITING = 0;
    my $STOPPED = 1;

    field $actor_ref :param;

    field $state;
    field $actor;
    field @messages;
    field @deadletters;

    ADJUST {
        $state = $WAITING;
        $actor = $actor_ref->props->new_actor;
    }

    method owner { $actor_ref }

    # ...

    method resume { $state = $WAITING }
    method stop   { $state = $STOPPED }

    method is_stopped { $state == $STOPPED }
    method is_waiting { $state == $WAITING }

    # ... messages

    method deadletters { @deadletters }

    method all_messages    {           @messages }
    method has_messages    { !! scalar @messages }
    method enqueue_message ($message) {
        if ($self->is_stopped) {
            push @deadletters => $message;
        } else {
            push @messages => $message;
        }
    }

    method drain_messages {
        my @msgs  = @messages;
        @messages = ();
        return @msgs;
    }

    # ... tick

    method tick {
        logger->log( DEBUG, "tick for $actor_ref" ) if DEBUG;

        if (@messages) {
            my @msgs = $self->drain_messages;
            while (@msgs) {
                my $message = shift @msgs;
                try {
                    $actor->receive($actor_ref->context, $message);
                } catch ($e) {
                    logger->log( ERROR, "actor::receive($message) failed with ($e)" ) if ERROR;
                    # TODO: decide how to handle this:
                    #       - resume
                    #       - restart
                    #       - stop permanently (ctx->exit/despawn)
                }
                if ($self->is_stopped) {
                    push @deadletters => @msgs;
                    # TODO : run POST_STOP on the actor
                    return;
                }
            }
        }
    }
}


__END__

=pod

=encoding UTF-8

=head1 NAME

Acktor::Mailbox

=head1 DESCRIPTION

=cut
