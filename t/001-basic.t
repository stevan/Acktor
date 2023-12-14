#!perl

use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr   ];

use Data::Dumper;
use Test::More;

## ------------------------------------------------------------------
## Actors
## ------------------------------------------------------------------
## This defines the base Actor interface and the Props which is
## basically a simple Actor factory.
## ------------------------------------------------------------------

class Props {
    field $class :param;
    field $args  :param = undef;

    method new_actor {
        return $class->new( $args ? %$args : () )
    }
}

class Actor {
    method receive;
}

## ------------------------------------------------------------------
## Mailbox & Message
## ------------------------------------------------------------------
## Message definition and Mailbox to hold/distribute messages
## ------------------------------------------------------------------

class Message {
    field $to   :param;
    field $from :param;
    field $body :param;

    method to   { $to   }
    method from { $from }
    method body { $body }
}

class Mailbox {
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

## ------------------------------------------------------------------
## Dispatcher
## ------------------------------------------------------------------
## Manages mailboxes and dispatching of messages
## ------------------------------------------------------------------

class Dispatcher {
    field %mailbox_by_actor_ref;
    field %to_be_run;

    method attach ($actor_ref) {
        $mailbox_by_actor_ref{ $actor_ref } = Mailbox->new( actor_ref => $actor_ref );
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

## ------------------------------------------------------------------
## Actor System
## ------------------------------------------------------------------

# TODO:
# - Scheduler   ... for timers & intervals

class System {
    field $dispatcher;

    ADJUST {
        $dispatcher = Dispatcher->new;
    }

    method dispatch_message ($message) {
        $dispatcher->dispatch( $message );
    }

    method spawn_actor ($props) {
        my $actor_ref = ActorRef->new(
            context => Context->new(
                props  => $props,
                system => $self,
            )
        );

        $dispatcher->attach( $actor_ref );
        return $actor_ref;
    }

    method tick {
        $dispatcher->tick;
    }

}

## ------------------------------------------------------------------
## Actor Context
## ------------------------------------------------------------------

class Context {
    field $props  :param;
    field $system :param;

    field $actor_ref;
    field @children;

    method props  { $props  }
    method system { $system }

    method self               { $actor_ref }
    method assign_self ($ref) { $actor_ref = $ref }

    method all_children {           @children }
    method has_children { !! scalar @children }

    # ...

    method spawn ($props) {
        my $child = $system->spawn_actor($props);
        push @children => $child;
        return $child;
    }

    method send ($message) {
        $system->dispatch_message($message);
    }
}

## ------------------------------------------------------------------
## Actor ActorRef
## ------------------------------------------------------------------

class ActorRef {
    field $context :param;

    ADJUST {
        $context->assign_self($self);
    }

    method pid     { refaddr $self }
    method context { $context      }

    method send ($body, $from=undef) {
        $context->send(Message->new( to => $self, from => $from, body => $body ));
    }
}

## ------------------------------------------------------------------

class Hello :isa(Actor) {
    method receive ($ctx, $message) {
        say "Hello ".$message->body;
    }
}

my $system    = System->new;
my $props     = Props->new( class => 'Hello' );
my $actor_ref = $system->spawn_actor($props);

$actor_ref->send("World $_") foreach 0 .. 5;
diag "TICK";
$system->tick;

$actor_ref->send("World $_") foreach 6 .. 10;
diag "TICK";
$system->tick;

done_testing;
