use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

class Acktor {

    our $CURRENT_CONTEXT;
    our $CURRENT_MESSAGE;

    method receive ($ctx, $message) {
        my $method = $message->body->symbol;
        my $ref    = $self->can( $method );

        die "Method ($method) not found in ($self)" unless $ref;

        local $CURRENT_CONTEXT = $ctx;
        local $CURRENT_MESSAGE = $message;

        $self->$ref( $message->body->payload->@* );
    }
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Acktor

=head1 DESCRIPTION

=cut
