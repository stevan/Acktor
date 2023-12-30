
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

class Acktor::Context {
    use Acktor::Logging;

    field $props      :param;
    field $dispatcher :param;
    field $parent     :param = undef;

    field $actor_ref;
    field @children;

    method props      { $props      }
    method dispatcher { $dispatcher }

    method self               { $actor_ref }
    method assign_self ($ref) { $actor_ref = $ref }

    method has_parent { defined $parent }
    method parent     {         $parent }

    method all_children {           @children }
    method has_children { !! scalar @children }

    # ...

    method lookup ($alias) { $dispatcher->lookup($alias) }

    method spawn ($props) {
        logger->log( DEBUG, "spawn( $props )" ) if DEBUG;
        my $child_ref = $dispatcher->spawn_actor($props, parent => $self);
        push @children => $child_ref;
        return $child_ref;
    }

    method send ($message) {
        logger->log( DEBUG, "send( $message )" ) if DEBUG;
        $dispatcher->dispatch($message);
    }

    # ...

    method watch   ($to_watch) {}
    method unwatch ($to_watch) {}

    method stop ($child) {
        # child must actually be a child
        # call ->exit() on that child's context
    }

    method exit {
        # call exit() on all children
        # despawn this actor-ref
        # signal all watchers that we've terminated
    }

}

__END__

=pod

=encoding UTF-8

=head1 NAME

Acktor::Context

=head1 DESCRIPTION

=cut
