
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

use Acktor::Behaviors;

use Acktor::Streams::Source;
use Acktor::Streams::Subscription;
use Acktor::Streams::Subscriber;
use Acktor::Streams::Subscription::Observer;

class Acktor::Streams::Publisher :isa(Acktor) {
    use Acktor::Logging;

    field $source :param;

    field @subscriptions;

    method Subscribe :Receive ($subscriber) {
        logger->log( INFO, '*Subscribe called with Subscriber('.$subscriber.')' ) if INFO;

        my $subscription = spawn(
            actor_of Acktor::Streams::Subscription:: => (
                publisher  => context->self,
                subscriber => $subscriber
            )
        );

        push @subscriptions => $subscription;
        $subscriber->send( event *Acktor::Streams::Subscriber::OnSubscribe, $subscription );
    }

    method Unsubscribe :Receive ($subscription) {
        logger->log( INFO, '*Unsubscribe called with Subscription('.$subscription.')' ) if INFO;

        @subscriptions = grep { refaddr $_ ne refaddr $subscription } @subscriptions;

        $subscription->send( event *Acktor::Streams::Subscription::OnUnsubscribe );

        if (scalar @subscriptions == 0) {
            logger->log( INFO, '*Unsubscribe called and no more subscrptions, exiting') if INFO;
            # TODO: this should be more graceful, sending
            # a shutdown message or something, **shrug**
            context->stop( context->self );
        }
    }

    method GetNext :Receive ($observer) {
        logger->log( INFO, '*GetNext called with Observer('.$observer.')' ) if INFO;

        my $next;
        try {
            $next = $source->get_next;
        } catch ($e) {
            $observer->send( event *Acktor::Streams::Subscription::Observer::OnError, $e );
            # ???
            #return;
        }

        if ( $next ) {
            logger->log( INFO, '... *GetNext sending next('.$next.')') if INFO;
            $observer->send( event *Acktor::Streams::Subscription::Observer::OnNext, $next );
        }
        else {
            $observer->send( event *Acktor::Streams::Subscription::Observer::OnComplete );
        }
    }

}

__END__

=pod

=encoding UTF-8

=head1 NAME

Acktor::Streams::Publisher

=head1 DESCRIPTION

=cut
