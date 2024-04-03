
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

class Acktor::Props {
    use Acktor::Logging;

    use if LOG_LEVEL, 'overload' => '""' => \&to_string;

    field $class :param;
    field $args  :param = undef;
    field $alias :param = undef;

    method class { $class }
    method args  { $args  }

    method alias :lvalue { $alias }

    method new_actor {
        return $class->new( $args ? %$args : () )
    }

    method to_string {
        sprintf 'Props[ %s ]%s' => $class, ($alias ? "( $alias )" : '');
    }
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Acktor::Props

=head1 DESCRIPTION

=cut
