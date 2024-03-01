
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

use Acktor::PostOffice::Letter;

class Acktor::Remote::Ref {
    use Acktor::Logging;

    use if LOG_LEVEL, 'overload' => '""' => \&to_string;

    field $address     :param;
    field $post_office :param;
    field $context     :param;

    ADJUST {
        $context->self = $self;
    }

    method pid     { $address->pid }
    method address { $address      }
    method context { $context      }

    method send ($event) {
        $post_office->post_letters(
            Acktor::PostOffice::Letter->new(
                from        => $post_office->dispatcher->address->with_pid( $event->context->self->pid ),
                to          => $address,
                event       => $event,
            )
        )
    }

    field $_to_str;
    method to_string {
        $_to_str //= sprintf 'Ref[%s]' => $self->pid;
    }

}

__END__

=pod

=encoding UTF-8

=head1 NAME

Acktor::Remote::Ref

=head1 DESCRIPTION

=cut
