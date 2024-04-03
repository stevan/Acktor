
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

class Acktor::Future::Ref {

    field $to         :param;
    field $event      :param;

    field $timeout    :param = undef;
    field $on_timeout :param = undef;

    field $future     :param;
    field $context    :param;

    field $pid;
    field $timer;
    field $timed_out = false;

    my $FUTURE_SEQ = 0;

    ADJUST {
        $context->self = $self;

        $pid = sprintf '%04d:Future' => ++$FUTURE_SEQ;

        $to->send( $event->clone( $context ) );

        if ($timeout) {
            $timer = $context->schedule(
                event => Acktor::Event->new( symbol => *Timeout, context => $context ),
                for   => $self,
                after => $timeout,
            );
        }
    }

    method pid     { $pid     }
    method context { $context }

    method send ($event) {
        if ( $event->symbol eq *Timeout ) {
            # TODO: think about sending a cancel request to $to
            $on_timeout->() if $on_timeout;
            $timed_out = true;
        } else {
            $future->resolve( $event );
            $timer->cancel if $timer;
        }
        # FIXME:
        # detach context and allow
        # for destruction of this ref
        # otherwise it just sticks around
    }
}


__END__

=pod

=encoding UTF-8

=head1 NAME

Acktor::Future::Ref

=head1 DESCRIPTION

=cut
