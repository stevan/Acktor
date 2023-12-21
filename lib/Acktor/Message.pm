
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr   ];

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
        $_to_str //= sprintf 'Msg[ %s, %s, %s ]' => $to->pid, ($from ? $from->pid : '_'), $body;
    }
}

__END__
