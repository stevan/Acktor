
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

class Acktor::Future::Ref {

    field $to         :param;
    field $event      :param;

    field $future     :param;
    field $context    :param;

    field $pid;

    my $FUTURE_SEQ = 0;

    ADJUST {
        $context->self = $self;

        $pid = sprintf '%04d:Future' => ++$FUTURE_SEQ;

        $to->send( $event->clone( $context ) );
    }

    method pid     { $pid     }
    method context { $context }

    method send ($event) {
        $future->resolve( $event );
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
