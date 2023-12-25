
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

class Acktor::Mailbox::Remote :isa(Acktor::Mailbox) {
    use Acktor::Logging;

    field $post_office :param;

    method is_started { 1 }
    # No-ops (for now)
    method start { () }
    method stop  { () }

    method tick {
        logger->log( DEBUG, "tick ... posting messages to PostOffice" ) if DEBUG;
        $post_office->post_messages( $self->drain_messages );
    }
}


__END__

=pod

=encoding UTF-8

=head1 NAME

Acktor::Mailbox::Remote

=head1 DESCRIPTION

=cut
