
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

class Acktor::System::Message {
    use Acktor::Logging;

    use if LOG_LEVEL, 'overload' => '""' => \&to_string;

    field $to   :param;
    field $from :param;

    method to   { $to   }
    method from { $from }

    field $_to_str;
    method to_string {
        $_to_str //= sprintf 'SystemMsg[ %s, %s, %s ]' => blessed $self, $to->pid, $from->pid
    }
}

class Acktor::System::Message::PoisonPill :isa(Acktor::System::Message) {}

__END__

=pod

=encoding UTF-8

=head1 NAME

Acktor::System::Message

=head1 DESCRIPTION

=cut
