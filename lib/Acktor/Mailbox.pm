
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

class Acktor::Mailbox {
    use Acktor::Logging;

    field $actor_ref :param;

    field $actor;
    field @messages;
    field @deadletters;
    field $stopped = false;

    ADJUST {
        $actor = $actor_ref->props->new_actor;
    }

    method owner { $actor_ref }

    # ...

    method resume { $stopped = false }
    method stop   { $stopped = true  }

    method is_stopped {  $stopped }
    method is_waiting { !$stopped }

    # ... messages

    method deadletters { @deadletters }

    method all_messages    {           @messages }
    method has_messages    { !! scalar @messages }
    method enqueue_message ($message) {
        if ($stopped) {
            push @deadletters => $message;
            return;
        }
        push @messages => $message;
    }

    # ... tick

    method tick {
        logger->log( DEBUG, "tick for $actor_ref" ) if DEBUG;

        if (@messages) {
            my @msgs  = @messages;
            @messages = ();

            my $context = $actor_ref->context;
            while (@msgs) {
                if ($stopped) {
                    push @deadletters => @msgs;
                    return;
                }

                my $message = shift @msgs;
                try {
                    $actor->apply($context, $message);
                } catch ($e) {
                    logger->log( ERROR, "actor::apply($message) failed with ($e)" ) if ERROR;
                    # TODO: decide how to handle this:
                    #       - resume
                    #       - restart
                    #       - stop permanently (ctx->exit/despawn)
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
