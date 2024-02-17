
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

use Acktor::Behaviors;

use Acktor::Streams::Subscription;
use Acktor::Streams::Subscriber;

class Acktor::Streams::Publisher :isa(Acktor) {
    use Acktor::Logging;

    field $subscriber;
    field $subscription;

    field @buffer;
    field $amount_requested = 0;

    method Subscribe :Receive ($s) {
        logger->log( INFO, "*Subscribe got subscriber($s)" ) if INFO;

        $subscriber   = $s;
        $subscription = spawn(
            actor_of Acktor::Streams::Subscription:: => (
                subscriber => $subscriber,
                publisher  => context->self
            )
        );

        $subscriber->send( event *Acktor::Streams::Subscriber::OnSubscribe => $subscription );
    }

    method Unsubscribe :Receive ($subscription) {
        logger->log( INFO, '*Unsubscribe called with Subscription('.$subscription.')' ) if INFO;
        # ...
    }

    method Request :Receive ($amount) {
        logger->log( INFO, "*Request got amount($amount) total($amount_requested)" ) if INFO;
        $amount_requested += $amount;
        if ($subscription) {
            $self->drain_buffer;
        } else {
            $subscription->send( event *Acktor::Streams::Subscription::OnError => 'called Request without active subscription' );
        }
    }

    method Submit :Receive ($value) {
        logger->log( INFO, "*Submit got value($value)" ) if INFO;
        push @buffer => $value;
        $self->drain_buffer if $subscription && $amount_requested;
    }

    method Close :Receive {
        logger->log( INFO, "*Close" ) if INFO;
        $self->drain_buffer;
        $subscription->send( event *Acktor::Streams::Subscription::OnCompleted );
    }

    method drain_buffer {
        while (@buffer && $amount_requested) {
            $subscription->send( event *Acktor::Streams::Subscription::OnNext => shift @buffer );
            $amount_requested--;
        }

        logger->log( WARN, "AMOUNT REQUESTED ($amount_requested) IN BUFFER(".scalar(@buffer).")" ) if WARN;
    }
}


__END__

=pod

=encoding UTF-8

=head1 NAME

Acktor::Streams::Publisher

=head1 DESCRIPTION

=cut
