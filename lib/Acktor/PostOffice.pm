
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

class Acktor::PostOffice {
    use Acktor::Logging;

    field @outgoing;

    method outgoing { @outgoing }

    method post_letters (@letters) {
        logger->log( DEBUG, "Posting(".(join ", " => @letters)) if DEBUG;
        push @outgoing => @letters;
    }
}


__END__

=pod

=encoding UTF-8

=head1 NAME

Acktor::PostOffice

=head1 DESCRIPTION

=cut
