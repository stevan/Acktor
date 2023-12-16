
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr   ];

use Acktor::Mailbox;

class Acktor::Dispatcher {
    field %mailbox_by_actor_ref;
    field %to_be_run;

    method attach ($actor_ref) {
        $mailbox_by_actor_ref{ $actor_ref } = Acktor::Mailbox->new( actor_ref => $actor_ref );
    }

    method detach ($actor_ref) {
        delete $mailbox_by_actor_ref{ $actor_ref };
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
