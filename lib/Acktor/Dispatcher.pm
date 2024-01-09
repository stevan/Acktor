
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

use Acktor::Scheduler;
use Acktor::Mailbox;
use Acktor::Ref;
use Acktor::Context;
use Acktor::Props;

use Acktor::System::Init;

class Acktor::Dispatcher {
    use Acktor::Logging;

    field $scheduler;
    field %aliases;

    ADJUST {
        $scheduler = Acktor::Scheduler->new;
    }

    ## ----------------------------------------------------

    method init_ref { $aliases{init} }

    method scheduler { $scheduler }

    method lookup ($alias) { $aliases{ $alias } }

    ## ----------------------------------------------------
    ## Spawn
    ## ----------------------------------------------------

    method spawn_actor ($props, %options) {
        my $parent = $options{parent};

        my $actor_ref = Acktor::Ref->new(
            props   => $props,
            context => Acktor::Context->new(
                dispatcher => $self,
                ($parent ? (parent  => $parent) :()),
            )
        );

        # TODO: add try/catch to catch anything throwm by Mailbox::new and rethrow a reasonable error
        $scheduler->register( $actor_ref, Acktor::Mailbox->new( actor_ref => $actor_ref ) );

        if ( my $alias = $props->alias ) {
            $aliases{ $alias } = $actor_ref;
        }

        logger->log( DEBUG, "spawn_actor( $props ) => $actor_ref" ) if DEBUG;

        return $actor_ref;
    }

    method despawn_actor ($actor_ref, %options) {
        logger->log( DEBUG, "despawn_actor( $actor_ref )" ) if DEBUG;

        if ( my $alias = $actor_ref->props->alias ) {
            delete $aliases{ $alias };
        }

        $scheduler->deregister( $actor_ref );
    }

    ## ----------------------------------------------------
    ## Dispatch & Singal
    ## ----------------------------------------------------

    method dispatch ($to, $event) {
        logger->log( DEBUG, "dispatch( $to, $event )" ) if DEBUG;
        $scheduler->schedule_message( $to, $event );
    }

    method signal ($signal) {
        logger->log( DEBUG, "signal( $signal )" ) if DEBUG;
        $scheduler->schedule_signal( $signal );
    }

    ## ----------------------------------------------------
    ## Loop
    ## ----------------------------------------------------

    method loop (%options) {
        logger->line( "dispatcher::loop" ) if DEBUG;

        my $init = delete $options{init} // sub {};

        my $init_ref = $self->spawn_actor(
            Acktor::Props->new(
                alias => 'init',
                class => Acktor::System::Init::,
                args  => { init_callback => $init }
            )
        );

        # TODO: spawn a sys/ actor which will handle system things
        #       - spawn DeadLetterQueue actor under here
        # TODO: spawn a user/ actor which will be the parent of all

        # TODO: this should be the user/ actor, when we have one
        $scheduler->schedule_callback(sub {
            $init_ref->send(
                Acktor::Event->new(
                    symbol  => *Acktor::System::Init::Initialize,
                    context => $init_ref->context
                )
            );
        });

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
