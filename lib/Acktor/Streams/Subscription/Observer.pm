
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

use Acktor::Behaviors;
use Acktor::Streams::Subscriber;

class Acktor::Streams::Subscription::Observer :isa(Acktor) {
    use Acktor::Logging;

    field $num_elements :param;
    field $subscriber   :param;

    field $seen = 0;
    field $done = 0;

    method OnComplete :Receive {
        if (!$done) {
            logger->log( INFO, '*OnComplete circuit breaker tripped' ) if INFO;
            $done = 1;
        }

        $seen++;
        if ( $num_elements <= $seen ) {
            logger->log( INFO,
                '*OnComplete observed seen('.$seen.') '
                .'of num_elements('.$num_elements.') '
                .'sending *OnComplete to Subscriber('.$subscriber.')'
            ) if INFO;

            $subscriber->send( event *Acktor::Streams::Subscriber::OnComplete );
            $seen = 0;
        }
    }

    method OnNext :Receive ($value) {
        logger->log( INFO, '*OnNext observed with value('.$value.')' ) if INFO;

        $subscriber->send( event *Acktor::Streams::Subscriber::OnNext, $value );

        $seen++;
        if ( $num_elements <= $seen ) {
            logger->log( INFO,
                '*OnNext observed seen('.$seen.') '
                .'of num_elements('.$num_elements.') '
                .'sending *OnRequestComplete to Subscriber('.$subscriber.')'
            ) if INFO;

            $subscriber->send( event *Acktor::Streams::Subscriber::OnRequestComplete );
            $seen = 0;
            $done = 1;
        }
    }

    method OnError :Receive ($error) {
        logger->log( INFO, '*OnError observed with error('.$error.')' ) if INFO;
        $subscriber->send( event *Acktor::Streams::Subscriber::OnError, $error );
    }
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Acktor::Streams::Observer::Subscription

=head1 DESCRIPTION

=cut
