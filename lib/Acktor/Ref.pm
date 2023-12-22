
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr   ];

use Acktor::Message;

class Acktor::Ref {
    use Acktor::Logging;

    use if LOG_LEVEL, 'overload' => '""' => \&to_string;

    field $context :param;
    field $pid     :param;

    ADJUST {
        $context->assign_self($self);
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

}

__END__

=pod

=encoding UTF-8

=head1 NAME

Acktor::Ref

=head1 DESCRIPTION

=cut
