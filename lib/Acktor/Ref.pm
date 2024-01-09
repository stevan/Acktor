
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

class Acktor::Ref {
    use Acktor::Logging;

    use if LOG_LEVEL, 'overload' => '""' => \&to_string;

    field $props   :param;
    field $context :param;
    field $pid     :param;

    ADJUST {
        $context->assign_self($self);
    }

    method props   { $props   }
    method pid     { $pid     }
    method context { $context }

    method send ($event) {
        $context->send( $event );
    }

    field $_to_str;
    method to_string {
        $_to_str //= sprintf 'Ref[ %s ]' => $pid;
    }

}

__END__

=pod

=encoding UTF-8

=head1 NAME

Acktor::Ref

=head1 DESCRIPTION

=cut
