
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr   ];

class Acktor::Context {
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
        say "$self spawn $props" if $ENV{DEBUG};
        my $child = $dispatcher->spawn_actor($props);
        push @children => $child;
        return $child;
    }

    method send ($message) {
        say "$self send $message" if $ENV{DEBUG};
        $dispatcher->dispatch($message);
    }
}

__END__
