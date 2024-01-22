
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

use Acktor::Behavior;

class Acktor::Behavior::Await :isa(Acktor::Behavior) {

    field $symbol   :param;
    field $receiver :param;

    method receive ($actor, $context, $message) {

        die "Can only accept messages of ($symbol), not (".$message->symbol.")"
            unless $message->symbol eq $symbol;

        local $Acktor::Behaviors::CURRENT_ACTOR   = $actor;
        local $Acktor::Behaviors::CURRENT_CONTEXT = $context;
        local $Acktor::Behaviors::CURRENT_MESSAGE = $message;

        $actor->$receiver( $message->payload->@* );

        $actor->unbecome;
    }
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Acktor::Behavior::Await

=head1 DESCRIPTION

=cut
