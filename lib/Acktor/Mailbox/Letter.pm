
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

class Acktor::Mailbox::Letter {
    use Acktor::Logging;

    use if LOG_LEVEL, 'overload' => '""' => \&to_string;

    field $origin      :param;
    field $destination :param;
    field $message     :param;

    method origin      { $origin      }
    method destination { $destination }
    method message     { $message     }

    field $_to_str;
    method to_string {
        $_to_str //= sprintf 'Letter[ %s, %s, %s ]' => $destination, $origin, $message;
    }
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Acktor::Mailbox::Letter

=head1 DESCRIPTION

=cut
