
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

class Acktor::Props {
    use Acktor::Logging;

    use if LOG_LEVEL, 'overload' => '""' => \&to_string;

    field $class :param;
    field $args  :param = undef;

    method class { $class }

    method new_actor {
        return $class->new( $args ? %$args : () )
    }

    field $_to_str;
    method to_string {
        $_to_str //= sprintf 'Props[ %s ]' => $class;
    }
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Acktor::Props

=head1 DESCRIPTION

=cut
