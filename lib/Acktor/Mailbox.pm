
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr   ];

class Acktor::Mailbox {
    field $actor_ref :param;

    field $actor;
    field @messages;

    ADJUST {
        $actor = $actor_ref->context->props->new_actor;
    }

    method all_messages    {           @messages }
    method has_messages    { !! scalar @messages }
    method enqueue_message ($message) {
        push @messages => $message;
    }

    method tick {
        while (@messages) {
            $actor->receive($actor_ref->context, shift @messages);
        }
    }
}


__END__
