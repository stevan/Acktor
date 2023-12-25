
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

class Acktor::Mailbox {
    use Acktor::Logging;

    field $actor_ref :param;

    field $actor;
    field @messages;

    ADJUST {
        $actor_ref->context->set_mailbox( $self );
    }

    method is_started { !! $actor }

    method start {
        logger->log( DEBUG, "start for $actor_ref" ) if DEBUG;
        $actor = $actor_ref->context->props->new_actor
    }

    method stop  {
        logger->log( DEBUG, "start for $actor_ref" ) if DEBUG;
        # XXX - should this trigger anything?
        $actor = undef;
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
        # TODO: throw an error if there is no actor ... i.e. not started
        while (@messages) {
            $actor->receive($actor_ref->context, shift @messages);
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
