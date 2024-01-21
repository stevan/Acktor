use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

use Acktor::Behavior::Method;

class Acktor {

    field @behavior;

    ADJUST {
        push @behavior => Acktor::Behavior::Method->new;
    }

    # ...

    method become ($behavior) {
        push @behavior => $behavior;
    }

    method unbecome {
        # TODO - do not allow it to pop off the last one
        pop @behavior;
    }

    # ...

    method apply ($ctx, $message) {
        $behavior[-1]->receive( $self, $ctx, $message );
    }
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Acktor

=head1 DESCRIPTION

=cut
