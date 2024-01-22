
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

use Acktor::Behavior;

class Acktor::Behavior::Method :isa(Acktor::Behavior) {

    method receive ($actor, $context, $message) {
        my $method = $message->symbol;
        my $ref    = $actor->can( $method );

        die "Method ($method) not found in ($actor)" unless $ref;

        local $Acktor::Behaviors::CURRENT_ACTOR   = $actor;
        local $Acktor::Behaviors::CURRENT_CONTEXT = $context;
        local $Acktor::Behaviors::CURRENT_MESSAGE = $message;

        $actor->$ref( $message->payload->@* );
    }
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Acktor::Behavior::Method

=head1 DESCRIPTION

=cut
