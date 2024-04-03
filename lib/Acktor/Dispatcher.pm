
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

use Acktor::Scheduler;
use Acktor::Mailbox;
use Acktor::Ref;
use Acktor::Context;
use Acktor::Props;
use Acktor::PostOffice;
use Acktor::Remote::Ref;
use Acktor::Future::Ref;
use Acktor::Future::Promise;

use Acktor::System::Init;

class Acktor::Dispatcher {
    use Acktor::Logging;

    field $address;

    field $post_office;
    field $scheduler;
    field %lookup;

    ADJUST {
        $post_office = Acktor::PostOffice->new( dispatcher => $self );
        $scheduler   = Acktor::Scheduler->new( post_office => $post_office );
    }

    ## ----------------------------------------------------

    method address { $address }

    method lookup ($alias) { $lookup{ $alias } }

    method scheduler { $scheduler }

    ## ----------------------------------------------------
    ## Spawn
    ## ----------------------------------------------------

    method spawn_remote_actor ($address) {

        logger->log( DEBUG, "spawn_remote_actor( $address )" ) if DEBUG;

        my $remote_ref = $lookup{ $address->pack } //= Acktor::Remote::Ref->new(
            address     => $address,
            post_office => $post_office,
            context     => Acktor::Context->new(
                dispatcher => $self,
            )
        );

        return $remote_ref;
    }

    method spawn_future_ref ($to, $event) {
        my $promise = Acktor::Future::Promise->new( scheduler => $scheduler );

        my $future = Acktor::Future::Ref->new(
            to         => $to,
            event      => $event,
            context    => Acktor::Context->new(
                dispatcher => $self,
            ),
            on_success => sub ($e) { $promise->resolve( $e ) },
        );

        return $promise;
    }

    method spawn_actor ($props) {

        my $actor_ref = Acktor::Ref->new(
            props   => $props,
            context => Acktor::Context->new(
                dispatcher => $self,
            )
        );

        logger->log( DEBUG, "spawn_actor( $props ) => $actor_ref" ) if DEBUG;
        my $mailbox = Acktor::Mailbox->new(
            actor_ref => $actor_ref,
        );

        $scheduler->register( $actor_ref, $mailbox );

        $lookup{ $actor_ref->pid } = $actor_ref;

        if ( my $alias = $props->alias ) {
            $lookup{ $alias } = $actor_ref;
        }

        return $actor_ref;
    }

    method despawn_actor ($actor_ref) {
        logger->log( DEBUG, "despawn_actor( $actor_ref )" ) if DEBUG;

        delete $lookup{ $actor_ref->pid };

        if ( my $alias = $actor_ref->props->alias ) {
            delete $lookup{ $alias };
        }

        $scheduler->suspend( $actor_ref );

        my $context = $actor_ref->context;

        if ( my @children = $context->all_children ) {
            $scheduler->schedule_callback(sub {
                logger->log( DEBUG, "despawn_actor( $actor_ref ) stop children" ) if DEBUG;
                $context->stop( $_ ) foreach @children;

                $scheduler->schedule_callback(sub {
                    logger->log( DEBUG, "despawn_actor( $actor_ref ) deregister after stopping children" ) if DEBUG;
                    # TODO: this should actually happen after
                    # the stop($child) calls completely resolove
                    # but we do not have that capability yet, so
                    # this will have to suffice
                    $scheduler->deregister( $actor_ref );
                });
            });
        }
        else {
            $scheduler->schedule_callback(sub {
                logger->log( DEBUG, "despawn_actor( $actor_ref ) deregister" ) if DEBUG;
                $scheduler->deregister( $actor_ref );
            });
        }
    }

    ## ----------------------------------------------------
    ## Dispatch & Singal
    ## ----------------------------------------------------

    method dispatch ($to, $event) {
        logger->log( DEBUG, "dispatch( $to, $event )" ) if DEBUG;
        $scheduler->schedule_message( $to, $event );
    }

    method schedule (%options) {
        return $scheduler->schedule_timer(%options);
    }

    ## ----------------------------------------------------
    ## Loop
    ## ----------------------------------------------------

    method run (%options) {
        logger->line( "dispatcher::start" ) if DEBUG;

        if (my $listen_on = delete $options{listen_on}) {
            $address = $post_office->listen_on( $listen_on );
        }

        if (my $connections = delete $options{connect_to}) {
            foreach my $c (@$connections) {
                my $addr = $post_office->connect_to( $c );
                $self->spawn_remote_actor( $addr->with_pid('init') );
            }
        }

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
            $scheduler->run(%options);
        } catch ($e) {
            logger->log( ERROR, "scheduler::run failed with ($e)" ) if ERROR;
            # TODO: this should trigger the shutdown of the system
        }

        # TODO: collect stats (zombies, etc)
        # TODO: despawn $init_ref

        logger->line( "dispatcher::exit" ) if DEBUG;
    }

    method shutdown {
        $post_office->shutdown;
        $scheduler->shutdown;
    }
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Acktor::Dispatcher

=head1 DESCRIPTION

=cut
