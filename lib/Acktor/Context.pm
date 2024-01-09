
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

class Acktor::Context {
    use Acktor::Logging;

    field $dispatcher :param;
    field $parent     :param = undef;

    field $actor_ref;
    field @children;

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
        logger->log( DEBUG, "$actor_ref -> spawn( $props )" ) if DEBUG;
        my $child_ref = $dispatcher->spawn_actor($props, parent => $self);
        push @children => $child_ref;
        return $child_ref;
    }

    method send ($to, $event) {
        logger->log( DEBUG, "$to -> send( $event )" ) if DEBUG;
        $dispatcher->dispatch( $to, $event );
    }

    method stop ($ref) {
        logger->log( DEBUG, "stop( $ref )" ) if DEBUG;
        $dispatcher->despawn_actor( $ref );
        # remove this if it is one of our children ,,.
        @children = grep { refaddr $_ != refaddr $ref } @children;
    }

}

__END__

=pod

=encoding UTF-8

=head1 NAME

Acktor::Context

=head1 DESCRIPTION

=cut
