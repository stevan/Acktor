
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

use Acktor::System::Signal;

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

    method stop ($child) {
        my $count = scalar @children;
        @children = grep { $_->pid ne $child->pid } @children;

        if ($count == scalar @children) {
            die "child($child) is not a Child of this context";
        }

        # TODO - make this better
        $self->send(
            Acktor::System::Signal::PoisonPill->new(
                to   => $child,
                from => $actor_ref
            )
        );
    }

    method exit {
        foreach my $child (@children) {
            $self->stop($child);
        }

        # TODO - make this better
        $self->send(
            Acktor::System::Signal::PoisonPill->new(
                to   => $actor_ref,
                from => $actor_ref
            )
        );
    }

}

__END__

=pod

=encoding UTF-8

=head1 NAME

Acktor::Context

=head1 DESCRIPTION

=cut
