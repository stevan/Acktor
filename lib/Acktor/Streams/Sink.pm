
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

class Acktor::Streams::Sink {
    use constant DROP  => \'DROP';
    use constant DONE  => \'DONE';
    use constant DRAIN => \'DRAIN';

    method drip;
    method done;
    method drain;
}

class Acktor::Streams::Sink::ToCallback :isa(Acktor::Streams::Sink) {
    field $callback :param;

    method drip ($drop) { $callback->( $drop, $self->DROP  ) }
    method done         { $callback->( undef, $self->DONE  ) }
    method drain        { $callback->( undef, $self->DRAIN ) }
}

class Acktor::Streams::Sink::ToBuffer :isa(Acktor::Streams::Sink) {
    field @buffer;

    method drip ($drop) {
        return if @buffer
               && $buffer[-1] == $self->DONE;
        push @buffer => $drop;
    }

    method done { push @buffer => $self->DONE }

    method drain {
        my @sink = @buffer;
        @buffer = ();
        pop @sink if $sink[-1] == $self->DONE;
        @sink;
    }
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Acktor::Streams::Sink

=head1 DESCRIPTION

=cut

