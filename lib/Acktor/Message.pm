
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

class Acktor::Message {
    use Acktor::Logging;

    use if LOG_LEVEL, 'overload' => '""' => \&to_string;

    field $to   :param;
    field $from :param;
    field $body :param;

    method to   { $to   }
    method from { $from }
    method body { $body }

    field $_to_str;
    method to_string {
        $_to_str //= sprintf 'Msg[ %s, %s, %s ]' =>
            $to->pid,
            $from->pid,
            ref $body ? $body : '"'.($body =~ s/\n/\\n/gr).'"';
    }

    field $_packed;
    method pack {
        $_packed //= { to => $to->pid, from => $from->pid, body => $body };
    }
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Acktor::Message

=head1 DESCRIPTION

=cut
