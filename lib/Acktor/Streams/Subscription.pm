
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

use Acktor::Behaviors;

use Acktor::Streams::Publisher;
use Acktor::Streams::Subscriber;

class Acktor::Streams::Subscription :isa(Acktor) {
    use Acktor::Logging;

    field $subscriber :param;
    field $publisher  :param;

    method Request :Receive ($amount) {
        logger->log( INFO, "*Request got amount($amount)" ) if INFO;
        $publisher->send( event *Acktor::Streams::Publisher::Request => $amount );
    }

    method Cancel :Receive {
        logger->log( INFO, '*Cancel called' ) if INFO;
        $publisher->send( event *Acktor::Streams::Publisher::Unsubscribe, context->self );
        # ....
    }

    method OnUnsubscribe :Receive {
        logger->log( INFO, '*OnUnsubscribe called' ) if INFO;
        $subscriber->send( event *Acktor::Streams::Subscriber::OnUnsubscribe );
        # ...
    }

    method OnNext :Receive ($next) {
        logger->log( INFO, "*OnNext got next($next)" ) if INFO;
        $subscriber->send( event *Acktor::Streams::Subscriber::OnNext => $next );
    }

    method OnCompleted :Receive {
        logger->log( INFO, "*OnCompleted" ) if INFO;
        $subscriber->send( event *Acktor::Streams::Subscriber::OnCompleted );
    }

    method OnError :Receive ($error) {
        logger->log( INFO, "*OnError got error($error)" ) if INFO;
        $subscriber->send( event *Acktor::Streams::Subscriber::OnError => $error );
    }

}


__END__

=pod

=encoding UTF-8

=head1 NAME

Acktor::Streams::Subscription

=head1 DESCRIPTION

=cut
