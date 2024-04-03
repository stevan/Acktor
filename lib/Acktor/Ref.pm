
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

class Acktor::Ref {
    use Acktor::Logging;

    use if LOG_LEVEL, 'overload' => '""' => \&to_string;

    field $props   :param;
    field $context :param;

    field $pid;

    ADJUST {
        $context->self = $self;
    }

    method props   { $props   }
    method context { $context }

    method pid {
        state $PID_SEQ = 0;
        $pid //= sprintf '%04d:%s' => ++$PID_SEQ, $props->class;
    }

    method send ($event) {
        $context->send( $self, $event );
    }

    method ask ($event) {
        $context->ask( $self, $event );
    }

    field $_to_str;
    method to_string {
        $_to_str //= sprintf 'Ref[ %s ]' => $self->pid;
    }

}

__END__

=pod

=encoding UTF-8

=head1 NAME

Acktor::Ref

=head1 DESCRIPTION

=cut
