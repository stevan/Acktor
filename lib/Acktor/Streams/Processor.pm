
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

use Acktor::Behaviors;

use Acktor::Streams::Sink;

class Acktor::Streams::Processor :isa(Acktor) {
    use Acktor::Logging;

    field $f            :param;
    field $request_size :param = 1;

    field $sink;
    field $subscription_in;
    field $subscription_out;

    ADJUST {
        $sink = Acktor::Streams::Sink::ToBuffer->new;
    }

    # does(Acktor::Streams::Publisher)

    method Subscribe :Receive(*Acktor::Streams::Publisher::Subscribe) ($subscriber) {
        logger->log( INFO, '*Subscribe called with Subscriber('.$subscriber.')' ) if INFO;

        $subscription_out = spawn(
            actor_of Acktor::Streams::Subscription:: => (
                publisher  => context->self,
                subscriber => $subscriber
            )
        );

        $subscriber->send( event *Acktor::Streams::Subscriber::OnSubscribe, $subscription_out );
    }

    method Unsubscribe :Receive(*Acktor::Streams::Publisher::UnSubscribe) ($subscription) {
        logger->log( INFO, '*Unsubscribe called with Subscription('.$subscription.')' ) if INFO;

        $subscription_out->send( event *Acktor::Streams::Subscription::OnUnsubscribe );

        logger->log( INFO, '*Unsubscribe called and no more subscrptions, exiting') if INFO;
        # TODO: this should be more graceful, sending
        # a shutdown message or something, **shrug**
        context->stop( context->self );
    }

    method GetNext :Receive(*Acktor::Streams::Publisher::GetNext) ($observer) {
        logger->log( INFO, '*GetNext called with Observer('.$observer.')' ) if INFO;

        if ( my $next = $sink->leak ) {
            $next = $f->( $next );
            logger->log( INFO, '... *GetNext sending next('.$next.')') if INFO;
            $observer->send( event *Acktor::Streams::Subscription::Observer::OnNext, $next );
        }
        elsif ($sink->is_done) {
            $observer->send( event *Acktor::Streams::Subscription::Observer::OnComplete );
        }
    }

    # does(Acktor::Streams::Subscriber)

    method OnComplete :Receive(*Acktor::Streams::Subscriber::OnComplete) {
        logger->log( INFO, '*OnComplete called' ) if INFO;
        $sink->done;
        $subscription_in->send( event *Acktor::Streams::Subscription::Cancel );

    }

    method OnRequestComplete :Receive(*Acktor::Streams::Subscriber::OnRequestComplete) {
        logger->log( INFO, '*OnRequestComplete called' ) if INFO;
        $subscription_in->send( event *Acktor::Streams::Subscription::Request, $request_size );
    }

    method OnNext :Receive(*Acktor::Streams::Subscriber::OnNext) ($value) {
        logger->log( INFO, '*OnNext called with value('.$value.')' ) if INFO;

    }

    method OnError :Receive(*Acktor::Streams::Subscriber::OnError) ($error) {
        logger->log( INFO, '*OnError called with error('.$error.')' ) if INFO;

    }

    # ...

    method OnSubscribe :Receive(*Acktor::Streams::Subscriber::OnSubscribe) ($s) {
        logger->log( INFO, '*OnSubscribe called with Subscription('.$s.')' ) if INFO;
        $subscription_in = $s;
        $subscription_in->send( event *Acktor::Streams::Subscription::Request, $request_size );
    }

    method OnUnsubscribe :Receive {
        logger->log( INFO, '*OnUnsubscribe called' ) if INFO;
        context->stop( context->self );
    }

}

__END__

=pod

=encoding UTF-8

=head1 NAME

Acktor::Streams::Processor

=head1 DESCRIPTION

=cut

