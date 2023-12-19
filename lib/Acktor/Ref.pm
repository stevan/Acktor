
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr   ];

use Acktor::Message;

class Acktor::Ref {
    use Acktor::Logging;

    use if LOG_LEVEL, 'overload' => '""' => \&to_string;

    field $context :param;

    field $pid;

    ADJUST {
        $context->assign_self($self);

        $pid = sprintf '%d:%s' => refaddr $self, $context->props->class;
    }

    method pid     { $pid     }
    method context { $context }

    method send ($body, $from=undef) {
        $context->send(Acktor::Message->new( to => $self, from => $from, body => $body ));
    }

    field $_to_str;
    method to_string {
        $_to_str //= sprintf 'Ref[ %s ]' => $pid;
    }

    # packing for transport
    method pack {
        +{ ref => $pid }
    }
}

__END__
