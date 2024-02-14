#!perl

use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

use Data::Dumper;
use Test::More;
use Test::Differences;

use Acktor;
use Acktor::Behaviors;

use Acktor::System;
use Acktor::Logging;

class Subscriber :isa(Acktor) {
    use Acktor::Logging;

    field $request_size :param;

    field $received = 0;
    field @received;

    field $subscription;

    method OnSubscribe :Receive ($s) {
        logger->log( INFO, "*OnSubscribe got subscription($s)" ) if INFO;
        $subscription = $s;
        $subscription->send( event *Subscription::Request => $request_size );
    }

    method OnNext :Receive ($next) {
        logger->log( INFO, "*OnNext got next($next)" ) if INFO;
        $received++;
        if ($received == $request_size) {
            logger->log( INFO, "*OnNext reached limit($request_size)" ) if INFO;
            $received = 0;
            $subscription->send( event *Subscription::Request => $request_size );
        }
        push @received => $next;
    }

    method OnCompleted :Receive {
        logger->log( INFO, "*OnCompleted" ) if INFO;
        logger->log( INFO, "Received:\n\t".(join ', ' => @received)) if INFO;
        logger->log( INFO, "Sorted:\n\t".(join ', ' => sort { $a <=> $b } @received)) if INFO;
    }

    method OnError :Receive ($error) {
        logger->log( INFO, "*OnError got error($error)" ) if INFO;
    }
}

class Subscription :isa(Acktor) {
    use Acktor::Logging;

    field $subscriber :param;
    field $publisher  :param;

    method Request :Receive ($amount) {
        logger->log( INFO, "*Request got amount($amount)" ) if INFO;
        $publisher->send( event *Publisher::Request => $amount );
    }

    method OnNext :Receive ($next) {
        logger->log( INFO, "*OnNext got next($next)" ) if INFO;
        $subscriber->send( event *Subscriber::OnNext => $next );
    }

    method OnCompleted :Receive {
        logger->log( INFO, "*OnCompleted" ) if INFO;
        $subscriber->send( event *Subscriber::OnCompleted );
    }

    method OnError :Receive ($error) {
        logger->log( INFO, "*OnError got error($error)" ) if INFO;
        $subscriber->send( event *Subscriber::OnError => $error );
    }

}

class Processor :isa(Acktor) {
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

    method Subscribe :Receive(*Publisher::Subscribe) ($s) {
        logger->log( INFO, "*Subscribe got subscriber($s)" ) if INFO;

        $subscriber       = $s;
        $subscription_out = spawn(
            actor_of Subscription:: => (
                subscriber => $subscriber,
                publisher  => context->self
            )
        );

        $subscriber->send( event *Subscriber::OnSubscribe => $subscription_out );
    }

    method Request :Receive(*Publisher::Request) ($amount) {
        logger->log( INFO, "*Request got amount($amount) total($amount_requested)" ) if INFO;
        $amount_requested += $amount;
        if ($subscription_out) {
            $self->drain_buffer;
        } else {
            $subscription_out->send( event *Subscription::OnError => 'called Request without active subscription' );
        }
    }

    method OnSubscribe :Receive(*Subscriber::OnSubscribe) ($s) {
        logger->log( INFO, "*OnSubscribe got subscription($s)" ) if INFO;
        $subscription_in = $s;
        $subscription_in->send( event *Subscription::Request => $request_size );
    }

    method OnNext :Receive(*Subscriber::OnNext) ($next) {
        logger->log( INFO, "*OnNext got next($next)" ) if INFO;
        $received++;
        if ($received == $request_size) {
            logger->log( INFO, "*OnNext reached limit($request_size)" ) if INFO;
            $received = 0;
            $subscription_in->send( event *Subscription::Request => $request_size );
        }
        push @buffer => $next;
        $self->drain_buffer if $subscription_out && $amount_requested;
    }

    method OnCompleted :Receive(*Subscriber::OnCompleted) {
        logger->log( INFO, "*OnCompleted" ) if INFO;
        $self->drain_buffer;
        $subscription_out->send( event *Subscription::OnCompleted );
    }

    method OnError :Receive(*Subscriber::OnError) ($error) {
        logger->log( INFO, "*OnError got error($error)" ) if INFO;
        $subscription_out->send( event *Subscription::OnError => $error );
    }

    method drain_buffer {
        while (@buffer && $amount_requested) {
            if ( $filter && !$filter->( $buffer[0] ) ) {
                shift @buffer;
                next;
            }
            $subscription_out->send( event *Subscription::OnNext => $map->( shift @buffer ) );
            $amount_requested--;
        }

        logger->log( WARN, "AMOUNT REQUESTED ($amount_requested) IN BUFFER(".scalar(@buffer).")" ) if WARN;
    }
}

class Publisher :isa(Acktor) {
    use Acktor::Logging;

    field $subscriber;
    field $subscription;

    field @buffer;
    field $amount_requested = 0;

    method Subscribe :Receive ($s) {
        logger->log( INFO, "*Subscribe got subscriber($s)" ) if INFO;

        $subscriber   = $s;
        $subscription = spawn(
            actor_of Subscription:: => (
                subscriber => $subscriber,
                publisher  => context->self
            )
        );

        $subscriber->send( event *Subscriber::OnSubscribe => $subscription );
    }

    method Request :Receive ($amount) {
        logger->log( INFO, "*Request got amount($amount) total($amount_requested)" ) if INFO;
        $amount_requested += $amount;
        if ($subscription) {
            $self->drain_buffer;
        } else {
            $subscription->send( event *Subscription::OnError => 'called Request without active subscription' );
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
        $subscription->send( event *Subscription::OnCompleted );
    }

    method drain_buffer {
        while (@buffer && $amount_requested) {
            $subscription->send( event *Subscription::OnNext => shift @buffer );
            $amount_requested--;
        }

        logger->log( WARN, "AMOUNT REQUESTED ($amount_requested) IN BUFFER(".scalar(@buffer).")" ) if WARN;
    }
}


sub init ($ctx) {

    my $p = spawn actor_of Publisher::;
    my $f = spawn actor_of Processor:: => (
        request_size => 1000,

        map    => sub ($x) {  $x * 2 },
        filter => sub ($x) { ($x % 2) == 0 }
    );
    my $s = spawn actor_of Subscriber:: => ( request_size => 1000 );

    $p->send( event *Publisher::Subscribe => $f );
    $f->send( event *Publisher::Subscribe => $s );

    my $x = 1;
    foreach my $j (1 .. 500_000) {
        $p->send(event(*Publisher::Submit => $x++));
    }

}

my $system = Acktor::System->new;
isa_ok($system, 'Acktor::System');

$system->run( init => \&init );

done_testing;
