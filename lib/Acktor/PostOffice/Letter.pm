
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

class Acktor::PostOffice::Letter {
    use Acktor::Logging;

    use if LOG_LEVEL, 'overload' => '""' => \&to_string;

    field $origin      :param;
    field $destination :param;

    field $to    :param;
    field $from  :param;
    field $event :param;

    method origin      { $origin      }
    method destination { $destination }

    method to    { $to    }
    method from  { $from  }
    method event { $event }

    field $_to_str;
    method to_string {
        $_to_str //= sprintf 'Letter[ %s@%s, %s@%s, %s ]' => $to, $destination, $from, $origin, $event;
    }

    field $_packed;
    method pack {
        $_packed //= {
            origin      => $origin,
            destination => $destination,
            envelope    => {
                to    => $to->pid,
                from  => $from->pid,
                event => $event->pack,
            }
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
