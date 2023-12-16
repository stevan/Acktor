
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr   ];

use Acktor::Mailbox;
use Acktor::Ref;
use Acktor::Context;

class Acktor::Dispatcher {
    field $system :param;

    field %mailbox_by_actor_ref;
    field %to_be_run;

    method spawn_actor ($props) {
        my $actor_ref = Acktor::Ref->new(
            context => Acktor::Context->new(
                props  => $props,
                system => $self,
            )
        );

        $mailbox_by_actor_ref{ $actor_ref } = Acktor::Mailbox->new( actor_ref => $actor_ref );

        return $actor_ref;
    }

    method dispatch ($message) {
        my $receiver = $message->to;
        $mailbox_by_actor_ref{ $receiver }->enqueue_message( $message );
        $to_be_run{ $receiver }++;
    }

    method tick {
        map { $_->tick }
        map { $mailbox_by_actor_ref{$_} }
        keys %to_be_run;

        %to_be_run = ();
    }
}

__END__
