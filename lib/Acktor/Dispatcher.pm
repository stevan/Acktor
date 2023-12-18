
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr   ];

use Acktor::Mailbox;
use Acktor::Ref;
use Acktor::Context;

class Acktor::Dispatcher {
    use Acktor::Logging;

    field %mailbox_by_actor_ref;
    field %to_be_run;

    method spawn_actor ($props) {
        my $actor_ref = Acktor::Ref->new(
            context => Acktor::Context->new(
                props      => $props,
                dispatcher => $self,
            )
        );

        $mailbox_by_actor_ref{ $actor_ref->pid } = Acktor::Mailbox->new( actor_ref => $actor_ref );

        logger->log( DEBUG, "spawn_actor( $props ) => $actor_ref" ) if DEBUG;

        return $actor_ref;
    }

    method dispatch ($message) {
        logger->log( DEBUG, "dispatch( $message )" ) if DEBUG;
        my $receiver = $message->to;
        $mailbox_by_actor_ref{ $receiver->pid }->enqueue_message( $message );
        $to_be_run{ $receiver->pid }++;
    }

    method tick {
        my %to_run = %to_be_run;
        %to_be_run = ();

        logger->log( DEBUG, scalar keys %to_run ? "tick =>> running( " . (join ', ' => keys %to_run) . " )" : "tick ... nothing to run" ) if DEBUG;
        map { $_->tick }
        map { $mailbox_by_actor_ref{$_} }
        keys %to_run;
    }
}

__END__
