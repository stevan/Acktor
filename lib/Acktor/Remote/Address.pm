
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

class Acktor::Remote::Address {
    use Acktor::Logging;

    use if LOG_LEVEL, 'overload' => '""' => \&to_string;

    field $address :param = undef;
    field $pid     :param = undef;
    field $host    :param = '127.0.0.1';
    field $port    :param = undef;

    ADJUST {
        if ($address) {
            ($pid)  = $address =~ /^(.*)\@/;
            ($host) = $pid ? ($address =~ /^.*\@(.*)\:/) : ($address =~ /^(.*)\:/);
            ($port) = $address =~ /\:(\d*)$/;
        } else {
            die 'You must specity either an `address` or a `host` + `port` or a local `port`'
                unless $host && $port;
            $address = ($pid ? "${pid}@" : '') . "${host}:${port}";
        }
    }

    method address { $address }

    method pid  { $pid  }
    method host { $host }
    method port { $port }

    method hostname { "${host}:${port}" }

    # ...

    method with_pid ($pid) {
        Acktor::Remote::Address->new(
            pid  => $pid,
            host => $host,
            port => $port,
        )
    }

    # ...

    method pack { $address }

    # ...

    field $_to_str;
    method to_string {
        $_to_str //= sprintf 'Address[%s]' => $address;
    }
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Acktor::Remote::Address

=head1 DESCRIPTION

=cut
