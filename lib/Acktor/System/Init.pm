
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

class Acktor::System::Init :isa(Acktor) {

    method receive($ctx, $message) {
        state $receive = +{
            get_actor_tree => sub ($ctx) {
                $message->from->send( $self->actor_tree($ctx) );
            }
        };

        my ($symbol, @args) = $message->body->@*;
        $receive->{ $symbol }->( $ctx, @args );
    }

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

=pod

=encoding UTF-8

=head1 NAME

Acktor::System::Init

=head1 DESCRIPTION

=cut
