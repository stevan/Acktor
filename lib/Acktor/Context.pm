
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr   ];

class Acktor::Context {
    use Acktor::Logging;

    field $props      :param;
    field $dispatcher :param;

    field $actor_ref;
    field @children;

    method props      { $props      }
    method dispatcher { $dispatcher }

    method self               { $actor_ref }
    method assign_self ($ref) { $actor_ref = $ref }

    method all_children {           @children }
    method has_children { !! scalar @children }

    # ...

    method spawn ($props) {
        logger->log( DEBUG, "spawn( $props )" ) if DEBUG;
        my $child = $dispatcher->spawn_actor($props);
        push @children => $child;
        return $child;
    }

    method send ($message) {
        logger->log( DEBUG, "send( $message )" ) if DEBUG;
        $dispatcher->dispatch($message);
    }

}

__END__

=pod

=encoding UTF-8

=head1 NAME

Acktor::Context

=head1 DESCRIPTION

=cut
