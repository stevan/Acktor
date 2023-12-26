
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

class Acktor::Mailbox {
    use Acktor::Logging;

    field $actor_ref :param;

    field $actor;
    field @messages;

    ADJUST {
        $actor = $actor_ref->context->props->new_actor;
    }

    method owner { $actor_ref }

    method all_messages    {           @messages }
    method has_messages    { !! scalar @messages }
    method enqueue_message ($message) {
        push @messages => $message;
    }

    method drain_messages {
        my @msgs  = @messages;
        @messages = ();
        return @msgs;
    }

    method tick {
        logger->log( DEBUG, "tick for $actor_ref" ) if DEBUG;
        while (@messages) {
            my $message = shift @messages;
            try {
                $actor->receive($actor_ref->context, $message);
            } catch ($e) {
                logger->log( ERROR, "actor::receive($message) failed with ($e)" ) if ERROR;
                # TODO: decide how to handle this:
                #       - resume
                #       - restart
                #       - stop permanently (ctx->exit/despawn)
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
