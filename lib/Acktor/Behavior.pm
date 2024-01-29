
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

class Acktor::Behavior {
    method accept ($actor, $context, $message) {
        return false;
    }
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Acktor::Behavior

=head1 DESCRIPTION

=cut
