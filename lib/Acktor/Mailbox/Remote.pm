
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

use Acktor::Mailbox::Letter;

class Acktor::Mailbox::Remote :isa(Acktor::Mailbox) {
    use Acktor::Logging;

    field $post_office :param;

    method tick {
        logger->log( DEBUG, "tick ... posting messages to PostOffice" ) if DEBUG;
        my $context = $self->owner->context;
        $post_office->post_letters( map {
            Acktor::Mailbox::Letter->new( message => $_, origin => $context )
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
