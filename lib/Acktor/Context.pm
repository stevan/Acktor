
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr   ];

class Acktor::Context {
    field $props  :param;
    field $system :param;

    field $actor_ref;
    field @children;

    method props  { $props  }
    method system { $system }

    method self               { $actor_ref }
    method assign_self ($ref) { $actor_ref = $ref }

    method all_children {           @children }
    method has_children { !! scalar @children }

    # ...

    method spawn ($props) {
        my $child = $system->spawn_actor($props);
        push @children => $child;
        return $child;
    }

    method send ($message) {
        $system->dispatch_message($message);
    }
}

__END__
