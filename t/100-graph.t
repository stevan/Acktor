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
        $self->drain_buffer if $subscription;
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
    }
}


sub init ($ctx) {

    my $p = spawn actor_of Publisher::;
    my $s = spawn actor_of Subscriber:: => ( request_size => 3 );

    $p->send( event *Publisher::Subscribe => $s );

    my $x = 1;

    foreach my $i (1 .. 4) {
        foreach my $j (1 .. 10) {
            context->schedule(
                event => event(*Publisher::Submit => $x++),
                for   => $p,
                after => ($i + rand()),
            );
        }
    }

    context->schedule(
        event => event(*Publisher::Close),
        for   => $p,
        after => 10,
    );
}

my $system = Acktor::System->new;
isa_ok($system, 'Acktor::System');

$system->run( init => \&init );

done_testing;
