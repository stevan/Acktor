
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr   ];

class Acktor::System::Init :isa(Acktor) {
    field $init :param;

    method receive($ctx, $message) {
        $init->($ctx);
    }

    # NOTE:
    # for debugging for now, but is useful
    # if this could be a message that this
    # actor would respond to ...
    method actor_tree ($ctx, $depth=0) {
        my @tree = (('  ' x $depth) . '> ' . $ctx->self->to_string);
        $depth++;
        foreach my $child ($ctx->all_children) {
            push @tree => $self->actor_tree( $child->context, $depth );
        }
        return join "\n" => @tree;
    }
}


__END__
