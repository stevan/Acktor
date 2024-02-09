
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

use Acktor::Behaviors;
use Acktor::Streams::Subscription;

class Acktor::Streams::Subscriber :isa(Acktor) {
    use Acktor::Logging;

    field $request_size :param;
    field $sink         :param;

    field $subscription;

    method OnSubscribe :Receive ($s) {
        logger->log( INFO, '*OnSubscribe called with Subscription('.$s.')' ) if INFO;
        $subscription = $s;
        $subscription->send( event *Acktor::Streams::Subscription::Request, $request_size );
    }

    method OnUnsubscribe :Receive {
        logger->log( INFO, '*OnUnsubscribe called' ) if INFO;
        context->stop( context->self );
    }

    method OnComplete :Receive {
        logger->log( INFO, '*OnComplete called' ) if INFO;
        $sink->done;
        $subscription->send( event *Acktor::Streams::Subscription::Cancel );
    }

    method OnRequestComplete :Receive {
        logger->log( INFO, '*OnRequestComplete called' ) if INFO;
        $subscription->send( event *Acktor::Streams::Subscription::Request, $request_size );
    }

    method OnNext :Receive ($value) {
        logger->log( INFO, '*OnNext called with value('.$value.')' ) if INFO;
        $sink->drip( $value );
    }

    method OnError :Receive ($error) {
        logger->log( INFO, '*OnError called with error('.$error.')' ) if INFO;
    }

}

__END__

=pod

=encoding UTF-8

=head1 NAME

Acktor::Streams::Subscriber

=head1 DESCRIPTION

=cut

