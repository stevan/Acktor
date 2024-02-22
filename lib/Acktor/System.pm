
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

use Acktor::Dispatcher;

class Acktor::System {
    use Acktor::Logging;

    field %forked;

    method run (%options) {
        logger->line( "system::start" ) if DEBUG;
        my $dispatcher = Acktor::Dispatcher->new;
        try {
            $dispatcher->run(%options);
        } catch ($e) {
            logger->log( ERROR, "dispatcher::run failed with ($e)" ) if ERROR;
        }
        logger->line( "system::exit" ) if DEBUG;
    }

    method fork (%options) {
        logger->line( "system::fork" ) if DEBUG;

        if (my $pid = fork()) {
            $forked{$pid}++;
        }
        else {

            if (my $log_to = delete $options{log_to}) {
                my $log = IO::File->new(">${log_to}") or die "Could not open log($log_to) because: $!";
                *STDOUT = $log;
                *STDERR = $log;
            }

            $self->run(%options);

            exit();
        }
    }

    method wait {
        logger->line( "system::wait" ) if DEBUG;
        while (%forked) {
            my $child = wait();
            last if $child == -1;
            logger->line( "system::wait got pid($child) exit" ) if DEBUG;
            delete $forked{$child};
        }
    }
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Acktor::System

=head1 DESCRIPTION

=cut
