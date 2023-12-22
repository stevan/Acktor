
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr   ];

use Acktor::Dispatcher;
use Acktor::PostOffice;

class Acktor::System {
    use Acktor::Logging;

    field $post_office;
    field $dispatcher;

    ADJUST {
        $post_office = Acktor::PostOffice->new;
        $dispatcher  = Acktor::Dispatcher->new( post_office => $post_office );
    }

    # TODO:
    # make socketpair($child, $parent, ... )
    # fork
        # in parent
            # close child socket
            # make PostOffice with socket $parent
            # enter basic select() loop
                # read Events on $parent are new messages
                    # they are then written to ???
        # in child
            # close parent socket
            # make PostOffice::Local with socket $child
                # read Events on $child are new messages
            # make Dispatcher
            # enter loop
                # messages posted to Remote are sent to PostOffice
                    # and then written to the child socket


    method loop (%options) {
        logger->line( "system::loop" ) if DEBUG;
        $dispatcher->loop(%options);
        logger->line( "system::exit" ) if DEBUG;
    }
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Acktor::System

=head1 DESCRIPTION

=cut
