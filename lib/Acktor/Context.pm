
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

use Acktor::Timer;

class Acktor::Context {
    use Acktor::Logging;

    field $dispatcher :param;
    field $parent     :param = undef;

    field $actor_ref;
    field $mailbox;
    field @children;

    method dispatcher { $dispatcher }

    method self    :lvalue { $actor_ref }
    method parent  :lvalue {    $parent }
    method mailbox :lvalue {   $mailbox }

    method has_self   { defined $actor_ref }
    method has_parent { defined $parent    }

    method all_children {           @children }
    method has_children { !! scalar @children }

    # ...

    method lookup ($alias) { $dispatcher->lookup($alias) }

    method schedule (%options) {
        my $timeout = $options{after} // die 'You must specify an `after` value for the timeout';
        my $for     = $options{for};
        my $event   = $options{event};

        logger->log( DEBUG, "schedule( $timeout, $for, $event )" ) if DEBUG;

        my $timer = Acktor::Timer->new(
            timeout  => $timeout,
            callback => sub { $for->send($event) }
        );

        $dispatcher->schedule( $timer );

        return $timer;
    }

    method spawn ($props) {
        logger->log( DEBUG, "$actor_ref -> spawn( $props )" ) if DEBUG;
        my $child_ref = $dispatcher->spawn_actor($props);
        $child_ref->context->parent = $self;
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
