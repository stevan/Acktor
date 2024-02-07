
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

class Acktor::PostOffice::Letter {
    use Acktor::Logging;

    use if LOG_LEVEL, 'overload' => '""' => \&to_string;

    field $to    :param;
    field $from  :param;
    field $event :param;

    method to    { $to    }
    method from  { $from  }
    method event { $event }

    field $_to_str;
    method to_string {
        $_to_str //= sprintf 'Letter[ %s, %s, %s ]' => $to, $from, $event;
    }

    field $_packed;
    method pack {
        $_packed //= {
            to    => $to->pack,
            from  => $from->pack,
            event => $event->pack,
        };
    }
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Acktor::PostOffice::Letter

=head1 DESCRIPTION

=cut
