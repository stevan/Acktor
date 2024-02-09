
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

class Acktor::Streams::Source {
    method get_next;
}

class Acktor::Streams::Source::FromList :isa(Acktor::Streams::Source) {
    field $list :param;

    method get_next { shift $list->@* }
}

class Acktor::Streams::Source::FromGenerator :isa(Acktor::Streams::Source) {
    field $generator :param;

    method get_next { $generator->() }
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Acktor::Streams::Source

=head1 DESCRIPTION

=cut
