
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

    method address { $actor_ref->context->dispatcher->address }

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

            # TODO:
            # this could be much better ...
            if ($message isa Acktor::System::Signal::PoisonPill) {
                logger->log( DEBUG, "Got PoisonPill for $actor_ref, despawning" ) if DEBUG;
                $actor_ref->context->dispatcher->despawn_actor( $actor_ref );
                last;
            }

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
