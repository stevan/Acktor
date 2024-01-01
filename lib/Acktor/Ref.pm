
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

use Acktor::Message;
use Acktor::Event;

class Acktor::Ref {
    use Acktor::Logging;

    use overload (
        fallback => 1,
        '>>=' => sub ($self, $event, @) {
            $self->send( $event );
            $self;
        },
        (LOG_LEVEL ? ('""' => \&to_string) : ())
    );

    field $context :param;
    field $pid     :param;

    ADJUST {
        $context->assign_self($self);
    }

    method pid     { $pid     }
    method context { $context }

    method send ($event) {
        $context->send(Acktor::Message->new(
            to   => $self,
            from => $event->context->self,
            body => $event
        ));
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
