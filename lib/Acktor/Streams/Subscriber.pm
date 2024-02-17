
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

use Acktor::Behaviors;
use Acktor::Streams::Subscription;

class Acktor::Streams::Subscriber :isa(Acktor) {
    use Acktor::Logging;

    field $request_size :param;

    field $received = 0;
    field @received;

    field $subscription;

    method OnSubscribe :Receive ($s) {
        logger->log( INFO, "*OnSubscribe got subscription($s)" ) if INFO;
        $subscription = $s;
        $subscription->send( event *Acktor::Streams::Subscription::Request => $request_size );
    }

    method OnUnsubscribe :Receive {
        logger->log( INFO, '*OnUnsubscribe called' ) if INFO;
        # ...
    }

    method OnNext :Receive ($next) {
        logger->log( INFO, "*OnNext got next($next)" ) if INFO;
        $received++;
        if ($received == $request_size) {
            logger->log( INFO, "*OnNext reached limit($request_size)" ) if INFO;
            $received = 0;
            $subscription->send( event *Acktor::Streams::Subscription::Request => $request_size );
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


__END__

=pod

=encoding UTF-8

=head1 NAME

Acktor::Streams::Subscriber

=head1 DESCRIPTION

=cut

