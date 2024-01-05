
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

    field $address;
    field $scheduler;

    field %pid_to_mailbox;
    field %aliases;

    ADJUST {
        $scheduler = Acktor::Scheduler->new;
        $post_office->register( $self );
    }

    ## ----------------------------------------------------

    method address {
        state $ADDR_SEQ = 0;
        $address //= sprintf '%04d@%s' => ++$ADDR_SEQ, 'local';
    }

    ## ----------------------------------------------------

    method init_ref { $aliases{init} }

    method lookup ($alias) { $aliases{ $alias } }

    ## ----------------------------------------------------
    ## Spawn
    ## ----------------------------------------------------

    my sub new_pid ($props) {
        state $PID_SEQ = 0;
        sprintf '%04d:%s' => ++$PID_SEQ, $props->class
    }

    method _build_actor_ref ($props, %options) {
        my $parent = $options{parent};

        return Acktor::Ref->new(
            pid     => new_pid($props),
            context => Acktor::Context->new(
                props      => $props,
                dispatcher => $self,
                ($parent ? (parent  => $parent) :()),
            )
        );
    }

    # ...

    method spawn_remote_actor ($props, %options) {
        my $origin = $options{origin} // die 'You must specify the `origin` address for the remote actor';

        my $actor_ref = $self->_build_actor_ref($props);

        # TODO: this won't throw anything, but maybe we should still check??
        $pid_to_mailbox{ $actor_ref->pid } = Acktor::Mailbox::Remote->new(
            origin      => $origin,
            actor_ref   => $actor_ref,
            post_office => $post_office,
        );

        if ( my $alias = $props->alias ) {
            $aliases{ $alias } = $actor_ref;
        }

        logger->log( DEBUG, "spawn_remote_actor( $props ) => $actor_ref" ) if DEBUG;

        return $actor_ref;
    }

    method spawn_actor ($props, %options) {
        my $actor_ref = $self->_build_actor_ref($props, %options);

        # TODO: add try/catch to catch anything throwm by Mailbox::new and rethrow a reasonable error
        $pid_to_mailbox{ $actor_ref->pid } = Acktor::Mailbox->new( actor_ref => $actor_ref );

        if ( my $alias = $props->alias ) {
            $aliases{ $alias } = $actor_ref;
        }

        logger->log( DEBUG, "spawn_actor( $props ) => $actor_ref" ) if DEBUG;

        return $actor_ref;
    }

    method despawn_actor ($actor_ref, %options) {
        my $pid = $actor_ref->pid;

        if (exists $pid_to_mailbox{ $pid }) {
            my $mailbox = delete $pid_to_mailbox{ $pid };

            logger->log( DEBUG, "despawn_actor( $pid ) => $actor_ref" ) if DEBUG;

            # FIXME:
            # this need to call stop on the Mailbox and
            # it's internally held Actor instance. But
            # for now we just let it get DESTROY-ed by
            # Perl (hopefully) and worry about this later.

            if ( my $alias = $actor_ref->context->props->alias ) {
                delete $aliases{ $alias };
            }

            $scheduler->unschedule( $mailbox );
        }
        else {
            # XXX - this should never happen, and this is
            # probably not the right way to deal with this
            # but we can leave it for now, knowing we want
            # to fix it later on.
            die "Could not find the actor_ref($actor_ref) with pid($pid) in this dispatcher!";
        }
    }

    ## ----------------------------------------------------
    ## Dispatch & Singal
    ## ----------------------------------------------------

    method dispatch ($message) {
        logger->log( DEBUG, "dispatch( $message )" ) if DEBUG;
        my $mailbox = $pid_to_mailbox{ $message->to->pid };
        # TODO:
        # if we do not find the mailbox,
        # or the mailbox is stopped
        # -> send to the DeadLetterQueue actor
        $mailbox->enqueue_message( $message );
        $scheduler->schedule( $mailbox );
    }

    method signal ($signal) {
        logger->log( DEBUG, "signal( $signal )" ) if DEBUG;
        my $mailbox = $pid_to_mailbox{ $signal->to->pid };
        # TODO:
        # if we do not find the mailbox,
        # or the mailbox is stopped
        # -> send to the DeadLetterQueue actor
        $mailbox->enqueue_signal( $signal );
        $scheduler->schedule( $mailbox );
    }

    ## ----------------------------------------------------
    ## Loop
    ## ----------------------------------------------------

    method loop (%options) {
        logger->line( "dispatcher::loop" ) if DEBUG;

        my $init_ref = $self->spawn_actor(
            Acktor::Props->new( class => 'Acktor::System::Init', alias => 'init' )
        );

        # TODO: spawn a sys/ actor which will handle system things
        #       - spawn DeadLetterQueue actor under here
        # TODO: spawn a user/ actor which will be the parent of all

        if (my $init = delete $options{init}) {
            $scheduler->next_tick(sub {
                # TODO: this should use the $user_ref context
                try {

                    # FIXME:
                    # this should be an actual async message pass
                    # not this bullshit.
                    local $Acktor::CURRENT_CONTEXT = $init_ref->context;
                    local $Acktor::CURRENT_MESSAGE = Acktor::Message->new(
                        to   => $init_ref,
                        from => $init_ref,
                        body => Acktor::Event->new(
                            symbol  => *Acktor::System::Init,
                            context => $init_ref->context
                        )
                    );

                    $init->( $init_ref->context );
                } catch ($e) {
                    logger->log( ERROR, "dispatcher::init callback failed with ($e)" ) if ERROR;
                    # TODO: this should trigger the shutdown of the system
                }
            });
        }

        try {
            $scheduler->loop(%options);
        } catch ($e) {
            logger->log( ERROR, "scheduler::loop failed with ($e)" ) if ERROR;
            # TODO: this should trigger the shutdown of the system
        }

        # TODO: collect stats (zombies, etc)
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
