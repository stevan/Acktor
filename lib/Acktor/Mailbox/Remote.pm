
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

use Acktor::Mailbox::Letter;

class Acktor::Mailbox::Remote :isa(Acktor::Mailbox) {
    use Acktor::Logging;

    field $destination :param;
    field $post_office :param;

    method tick {
        return unless $self->has_messages;

        logger->log( DEBUG, "tick ... posting messages to PostOffice" ) if DEBUG;
        $post_office->post_letters( map {
            Acktor::Mailbox::Letter->new(
                origin      => $self->origin,
                destination => $destination,
                message     => $_,
            )
        } $self->drain_messages );
    }
}


__END__

=pod

=encoding UTF-8

=head1 NAME

Acktor::Mailbox::Remote

=head1 DESCRIPTION

=cut
