
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr   ];

use Acktor::Mailbox;
use Acktor::Ref;
use Acktor::Context;

class Acktor::Dispatcher {

    field %mailbox_by_actor_ref;
    field %to_be_run;

    method spawn_actor ($props) {
        say "$self spawn_actor $props" if $ENV{DEBUG};
        my $actor_ref = Acktor::Ref->new(
            context => Acktor::Context->new(
                props  => $props,
                system => $self,
            )
        );

        $mailbox_by_actor_ref{ $actor_ref } = Acktor::Mailbox->new( actor_ref => $actor_ref );

        say "... new_actor_ref $actor_ref" if $ENV{DEBUG};

        return $actor_ref;
    }

    method dispatch ($message) {
        say "$self dispatch $message to ".$message->to if $ENV{DEBUG};
        my $receiver = $message->to;
        $mailbox_by_actor_ref{ $receiver }->enqueue_message( $message );
        $to_be_run{ $receiver }++;
    }

    method tick {
        my %to_run = %to_be_run;
        %to_be_run = ();

        say "$self tick -> running(" . (join ', ' => keys %to_run) . ")" if $ENV{DEBUG};
        map { $_->tick }
        map { $mailbox_by_actor_ref{$_} }
        keys %to_run;
    }
}

__END__
