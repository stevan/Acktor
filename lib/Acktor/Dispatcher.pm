
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr   ];

use Acktor::Mailbox;
use Acktor::Ref;
use Acktor::Context;

class Acktor::Dispatcher {
    use Acktor::Logging;

    field $scheduler :param;

    field %pid_to_mailbox;

    our $PID_SEQ = 0;

    my sub new_pid ($props) {
        sprintf '%04d:%s' => ++$PID_SEQ, $props->class
    }

    method spawn_actor ($props) {
        my $actor_ref = Acktor::Ref->new(
            pid     => new_pid($props),
            context => Acktor::Context->new(
                props      => $props,
                dispatcher => $self,
            )
        );

        $pid_to_mailbox{ $actor_ref->pid } = Acktor::Mailbox->new( actor_ref => $actor_ref );

        logger->log( DEBUG, "spawn_actor( $props ) => $actor_ref" ) if DEBUG;

        return $actor_ref;
    }

    method dispatch ($message) {
        logger->log( DEBUG, "dispatch( $message )" ) if DEBUG;
        my $mailbox = $pid_to_mailbox{ $message->to->pid };
        $mailbox->enqueue_message( $message );
        $scheduler->schedule( $mailbox );
    }

    method tick {
        $scheduler->tick;
    }

    method loop (%options) {
        $scheduler->loop(%options);
    }
}

__END__
