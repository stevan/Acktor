
use v5.38;
use experimental 'class';

class Acktor::Event {
    use Acktor::Logging;

    use if LOG_LEVEL, 'overload' => '""' => \&to_string;

    field $symbol  :param;
    field $payload :param = [];
    field $context :param;

    method symbol  { $symbol  }
    method payload { $payload }
    method context { $context }

    field $_to_str;
    method to_string {
        $_to_str //= sprintf 'Event[ %s => ( %s ) ]' =>
            $symbol,
            (join ', ' => @$payload)
    }

    field $_packed;
    method pack {
        $_packed //= {
            symbol  => "$symbol",
            # TODO:
            # we need to make sure to serialize the payload
            # which means looking any Ref instances. It might
            # be better to use some JSON feature for this?
            payload => $payload,
        };
    }
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Acktor::Event

=head1 DESCRIPTION

A L<Acktor::Event> can thought of as a deffered method call. The C<$symbol> being
the name of the method, and the C<$payload> being a list of arguments to the method.

An L<Acktor::Event> is the primary payload of the message pipeline

=cut
