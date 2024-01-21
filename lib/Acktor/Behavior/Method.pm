
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

use Acktor::Behavior;

class Acktor::Behavior::Method :isa(Acktor::Behavior) {

    our $CURRENT_CONTEXT;
    our $CURRENT_MESSAGE;

    method apply ($actor, $context, $message) {
        my $method = $message->symbol;
        my $ref    = $actor->can( $method );

        die "Method ($method) not found in ($actor)" unless $ref;

        local $CURRENT_CONTEXT = $context;
        local $CURRENT_MESSAGE = $message;

        $actor->$ref( $message->payload->@* );
    }

}

__END__

=pod

=encoding UTF-8

=head1 NAME

Acktor::Behavior

=head1 DESCRIPTION

=cut
