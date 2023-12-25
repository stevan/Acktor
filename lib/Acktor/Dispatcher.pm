
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

use Acktor::Scheduler;
use Acktor::Mailbox;
use Acktor::Mailbox::Remote;
use Acktor::Ref;
use Acktor::Context;
use Acktor::Props;

use Acktor::System::Init;

class Acktor::Dispatcher {
    use Acktor::Logging;

    field $post_office :param;

    field $scheduler;
    field $init_ref;

    field %pid_to_mailbox;

    ADJUST {
        $scheduler = Acktor::Scheduler->new
    }

    method init_ref { $init_ref }

    my sub new_pid ($props) {
        state $PID_SEQ = 0;
        sprintf '%04d:%s' => ++$PID_SEQ, $props->class
    }

    method _build_actor_ref ($props, $parent=undef) {
        return Acktor::Ref->new(
            pid     => new_pid($props),
            context => Acktor::Context->new(
                props      => $props,
                dispatcher => $self,
                ($parent ? (parent  => $parent) :()),
            )
        );
    }

    method spawn_remote_actor ($props) {
        my $actor_ref = $self->_build_actor_ref($props);

        $pid_to_mailbox{ $actor_ref->pid } = Acktor::Mailbox::Remote->new(
            actor_ref   => $actor_ref,
            post_office => $post_office,
        );

        logger->log( DEBUG, "spawn_remote_actor( $props ) => $actor_ref" ) if DEBUG;

        return $actor_ref;
    }

    method spawn_actor ($props, $parent=undef) {
        my $actor_ref = $self->_build_actor_ref($props, $parent);

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

    method loop (%options) {
        logger->line( "dispatcher::loop" ) if DEBUG;

        $init_ref = $self->spawn_actor( Acktor::Props->new( class => 'Acktor::System::Init' ) );

        if (my $init = delete $options{init}) {
            $scheduler->next_tick(sub {
                # start all the mailboxes created prior to start
                $_->start foreach values %pid_to_mailbox;
                $init->( $init_ref->context );
            });
        }

        $scheduler->loop(%options);

        # TODO: despawn $init_ref

        logger->line( "dispatcher::exit" ) if DEBUG;
    }
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Acktor::Dispatcher

=head1 DESCRIPTION

=cut
