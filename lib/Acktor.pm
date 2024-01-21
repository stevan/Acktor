use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

use Acktor::Behavior::Method;

class Acktor {

    field $behavior;

    method behavior {
        $behavior //= Acktor::Behavior::Method->new;
    }

    # TODO - implement stacked behaviors
    method become ($new_behavior) {
        $behavior = $new_behavior;
    }

    method receive ($ctx, $message) {
        $self->behavior->apply( $self, $ctx, $message );
    }
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Acktor

=head1 DESCRIPTION

=cut
