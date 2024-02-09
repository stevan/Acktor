
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

use Acktor::Behaviors;

use Acktor::Streams::Subscription::Observer;
use Acktor::Streams::Publisher;
use Acktor::Streams::Subscriber;

class Acktor::Streams::Subscription :isa(Acktor) {
    use Acktor::Logging;

    field $publisher  :param;
    field $subscriber :param;

    field $observer;

    method Request :Receive ($num_elements) {
        logger->log( INFO, '*Request called with num_elements('.$num_elements.')' ) if INFO;

        if ( $observer ) {
            logger->log( INFO, '*Request called, killing old Observer('.$observer.')' ) if INFO;
            context->stop( $observer );
        }

        $observer = spawn(
            actor_of Acktor::Streams::Subscription::Observer:: => (
                num_elements => $num_elements,
                subscriber   => $subscriber
            )
        );

        while ($num_elements--) {
            $publisher->send( event *Acktor::Streams::Publisher::GetNext, $observer );
        }
    }

    method Cancel :Receive {
        logger->log( INFO, '*Cancel called' ) if INFO;
        $publisher->send( event *Acktor::Streams::Publisher::Unsubscribe, context->self );
    }

    method OnUnsubscribe :Receive {
        logger->log( INFO, '*OnUnsubscribe called' ) if INFO;
        $subscriber->send( event *Acktor::Streams::Subscriber::OnUnsubscribe );
        context->stop( context->self ); # this will stop any running $observer
    }

}

__END__

=pod

=encoding UTF-8

=head1 NAME

Acktor::Streams::Subscription

=head1 DESCRIPTION

=cut
