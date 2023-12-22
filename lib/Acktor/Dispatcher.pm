
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr   ];

use Acktor::Scheduler;
use Acktor::Mailbox;
use Acktor::Ref;
use Acktor::Context;
use Acktor::Props;

use Acktor::System::Init;

class Acktor::Dispatcher {
    use Acktor::Logging;

    field $scheduler;
    field $init_ref;

    field %pid_to_mailbox;

    ADJUST {
        $scheduler = Acktor::Scheduler->new
    }

    my sub new_pid ($props) {
        state $PID_SEQ = 0;
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

    method loop (%options) {
        logger->line( "dispatcher::loop" ) if DEBUG;

        $init_ref = $self->spawn_actor( Acktor::Props->new( class => 'Acktor::System::Init' ) );

        if (my $init = delete $options{init}) {
            $scheduler->next_tick(sub { $init->( $init_ref->context ) });
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
