
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

use Acktor::Tools;

class Acktor::System::Init :isa(Acktor) {
    use Acktor::Logging;

    field $init_callback :param;

    method Initialize {
        try {
            $init_callback->( context );
        } catch ($e) {
            logger->log( ERROR, "dispatcher::init callback failed with ($e)" ) if ERROR;
            # TODO: this should trigger the shutdown of the system
        }
    }
}


__END__

=pod

=encoding UTF-8

=head1 NAME

Acktor::System::Init

=head1 DESCRIPTION

=cut
