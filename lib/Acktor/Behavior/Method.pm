
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

use Acktor::Behavior;

class Acktor::Behavior::Method :isa(Acktor::Behavior) {

    method receive ($actor, $context, $message) {
        my $method = $message->symbol;
        my $ref    = $actor->can( $method );

        die "Method ($method) not found in ($actor)" unless $ref;

        # TODO:
        # do this attribute check earlier, and collect list of
        # valid methods. Which will change how this whole
        # thing behaviors, so keep that in mind.
        my @attrs = grep { $_ && $_ =~ /^Receive/ } attributes::get($ref);
        die "Method must be a Receiver" unless @attrs;

        # TODO:
        # if we have a pre built set of methods with attributes
        # then we can parse the attribute to see if we need to accept
        # a different event type, and adjust the set of methods
        # accordingly.

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
