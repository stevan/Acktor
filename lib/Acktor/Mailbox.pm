
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

class Acktor::Mailbox {
    use Acktor::Logging;

    field $origin    :param;
    field $actor_ref :param;

    field $actor;

    field @messages;
    field @deadletters;

    field $queue;

    ADJUST {
        $actor_ref->context->mailbox = $self;

        $queue = \@messages;
        $actor = $actor_ref->props->new_actor;
    }

    method origin { $origin    }
    method owner  { $actor_ref }

    # ...

    method resume { $queue = \@messages     }
    method stop   { $queue = \@deadletters  }

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
    }
}


__END__

=pod

=encoding UTF-8

=head1 NAME

Acktor::Mailbox

=head1 DESCRIPTION

=cut
