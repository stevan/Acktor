
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

use Acktor::Behaviors;

use Acktor::Streams::Subscription;
use Acktor::Streams::Subscriber;
use Acktor::Streams::Publisher;

class Acktor::Streams::Processor :isa(Acktor) {
    use Acktor::Logging;

    field $map          :param;
    field $filter       :param;
    field $request_size :param;

    field $subscription_in;
    field $received = 0;

    field $subscriber;
    field $subscription_out;

    field @buffer;
    field $amount_requested = 0;

    method Subscribe :Receive(*Acktor::Streams::Publisher::Subscribe) ($s) {
        logger->log( INFO, "*Subscribe got subscriber($s)" ) if INFO;

        $subscriber       = $s;
        $subscription_out = spawn(
            actor_of Acktor::Streams::Subscription:: => (
                subscriber => $subscriber,
                publisher  => context->self
            )
        );

        $subscriber->send( event *Acktor::Streams::Subscriber::OnSubscribe => $subscription_out );
    }

    method Request :Receive(*Acktor::Streams::Publisher::Request) ($amount) {
        logger->log( INFO, "*Request got amount($amount) total($amount_requested)" ) if INFO;
        $amount_requested += $amount;
        if ($subscription_out) {
            $self->drain_buffer;
        } else {
            $subscription_out->send( event *Acktor::Streams::Subscription::OnError => 'called Request without active subscription' );
        }
    }

    method OnSubscribe :Receive(*Acktor::Streams::Subscriber::OnSubscribe) ($s) {
        logger->log( INFO, "*OnSubscribe got subscription($s)" ) if INFO;
        $subscription_in = $s;
        $subscription_in->send( event *Acktor::Streams::Subscription::Request => $request_size );
    }

    method OnNext :Receive(*Acktor::Streams::Subscriber::OnNext) ($next) {
        logger->log( INFO, "*OnNext got next($next)" ) if INFO;
        $received++;
        if ($received == $request_size) {
            logger->log( INFO, "*OnNext reached limit($request_size)" ) if INFO;
            $received = 0;
            $subscription_in->send( event *Acktor::Streams::Subscription::Request => $request_size );
        }
        push @buffer => $next;
        $self->drain_buffer if $subscription_out && $amount_requested;
    }

    method OnCompleted :Receive(*Acktor::Streams::Subscriber::OnCompleted) {
        logger->log( INFO, "*OnCompleted" ) if INFO;
        $self->drain_buffer;
        $subscription_out->send( event *Acktor::Streams::Subscription::OnCompleted );
    }

    method OnError :Receive(*Acktor::Streams::Subscriber::OnError) ($error) {
        logger->log( INFO, "*OnError got error($error)" ) if INFO;
        $subscription_out->send( event *Acktor::Streams::Subscription::OnError => $error );
    }

    method drain_buffer {
        while (@buffer && $amount_requested) {
            if ( $filter && !$filter->( $buffer[0] ) ) {
                shift @buffer;
                next;
            }
            $subscription_out->send( event *Acktor::Streams::Subscription::OnNext => $map->( shift @buffer ) );
            $amount_requested--;
        }

        logger->log( WARN, "AMOUNT REQUESTED ($amount_requested) IN BUFFER(".scalar(@buffer).")" ) if WARN;
    }
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Acktor::Streams::Processor

=head1 DESCRIPTION

=cut

