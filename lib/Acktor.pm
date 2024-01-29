use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

use Acktor::Behaviors ();

class Acktor {

    field $behavior;
    field @behaviors;

    ADJUST {
        $behavior = $self->receive;
    }

    method receive {
        Acktor::Behaviors->behavior_for( blessed $self )
    }

    # ...

    method become ($b) { unshift @behaviors => $b }
    method unbecome    { shift @behaviors         }

    # ...

    method accept ($ctx, $message) {
        return ($behaviors[0] // $behavior)->accept( $self, $ctx, $message );
    }
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Acktor

=head1 DESCRIPTION

=cut
