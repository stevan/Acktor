#!perl

use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr   ];

use Data::Dumper;
use Test::More;

class Props {
    field $class :param;
    field $args  :param = undef;

    method new_actor {
        return $class->new( $args ? %$args : () )
    }
}

class Message {
    field $to   :param;
    field $from :param;
    field $body :param;

    method to   { $to   }
    method from { $from }
    method body { $body }
}

class Mailbox {
    field @messages;

    method messages { @messages }

    method has_messages    { !! scalar @messages }
    method dequeue_message {     shift @messages }
    method enqueue_message ($message) {
        push @messages => $message;
    }
}

class Scheduler {
    field %activations;
    field %scheduled;

    method enqueue_message ($message) {
        if ( my $activation = $activations{ $message->to } ) {
            $activation->context
                       ->mailbox
                       ->enqueue_message( $message );
            $scheduled{ $activation }++;
        }
    }

    method spawn_activation ($props, $parent) {
        my $activation = Activation->new(
            props  => $props,
            parent => $parent,
        );

        $activations{ $activation } = $activation;

        $activation->START(
            Context->new(
                activation => $activation,
                scheduler  => $self,
                mailbox    => Mailbox->new,
            )
        );

        return $activation;
    }

    method TICK {
        foreach my $activation (map $activations{ $_ }, keys %scheduled) {
            $activation->RUN;
            $scheduled{ $activation }--;
        }
    }
}

class Context {
    field $activation :param;
    field $scheduler  :param;
    field $mailbox    :param;

    field $current_message;

    method self    { $activation }
    method mailbox { $mailbox    }

    # scheduler ...

    method send ($to, $body, $from=undef) {
        $scheduler->enqueue_message(
            Message->new( to => $to, from => $from, body => $body )
        );
    }

    method spawn ($props, $parent=undef) {
        return $scheduler->spawn_activation($props, $parent);
    }

    # mailbox ...

    method has_messages { $mailbox->has_messages }
    method next_message {
        $current_message = $mailbox->dequeue_message;
        return $current_message;
    }

    method has_current_message { !! $current_message }
    method current_message     {    $current_message }
}

class Activation {
    field $props  :param;
    field $parent :param = undef;
    field @children;

    field $context;
    field $actor;

    method START ($ctx) {
        $context = $ctx;
        $actor   = $props->new_actor;
    }

    method RUN {
        while ($context->has_messages) {
            $actor->receive($self, $context->next_message);
        }
    }

    method STOP {
        $context = undef;
        $actor   = undef;
    }

    method is_started {     defined $context &&     defined $actor }
    method is_stopped { not defined $context && not defined $actor }

    method context  { $context  }
    method id       { refaddr $self }
    method parent   { $parent   }
    method children { @children }

    method is_root      { not defined $parent }
    method has_children { !! scalar @children }

    method spawn_child ($props) {
        $context // die 'Cannot spawn a child on a stopped actor';
        my $child = $context->spawn($props, $self);
        push @children => $child;
        return $child;
    }

    method send ($body, $from=undef) {
        $context // die 'Cannot send a message to a stopped actor';
        $context->send( $self, $body, $from );
    }
}

class Hello {
    method receive ($this, $message) {
        say $this->context->has_messages ? '...' : 'last message';
        say "Hello ".$message->body;
    }
}

my $scheduler = Scheduler->new;
my $props     = Props->new( class => 'Hello' );
my $activation = $scheduler->spawn_activation($props, undef);

$activation->send("World $_") foreach 0 .. 5;
diag "TICK";
$scheduler->TICK;

$activation->send("World $_") foreach 6 .. 10;
diag "TICK";
$scheduler->TICK;

done_testing;
