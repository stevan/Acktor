
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

class Acktor::Mailbox {
    use Acktor::Logging;

    field $actor_ref :param;

    field $actor;
    field @signals;
    field @messages;

    ADJUST {
        $actor = $actor_ref->props->new_actor;
    }

    method owner { $actor_ref }

    method address { $actor_ref->context->dispatcher->address }

    # ... signals

    method all_signals    {           @signals }
    method has_signals    { !! scalar @signals }
    method enqueue_signal ($message) {
        push @signals => $message;
    }

    method drain_signals {
        my @sigs  = @signals;
        @signals = ();
        return @sigs;
    }

    # ... messages

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

    # ... tick

    method tick {
        logger->log( DEBUG, "tick for $actor_ref" ) if DEBUG;

        if (@signals) {
            foreach my $signal ($self->drain_signals) {
                # TODO:
                # this could be much better ...
                if ($signal isa Acktor::System::Signal::PoisonPill) {
                    logger->log( DEBUG, "Got PoisonPill for $actor_ref, despawning" ) if DEBUG;
                    $actor_ref->context->dispatcher->despawn_actor( $actor_ref );
                    return;
                }
            }
        }

        if (@messages) {
            foreach my $message ($self->drain_messages) {
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
}


__END__

=pod

=encoding UTF-8

=head1 NAME

Acktor::Mailbox

=head1 DESCRIPTION

=cut
