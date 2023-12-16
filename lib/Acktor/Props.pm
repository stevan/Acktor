
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr   ];

class Acktor::Props {
    field $class :param;
    field $args  :param = undef;

    method new_actor {
        return $class->new( $args ? %$args : () )
    }
}

__END__
