
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

class Acktor::PostOffice {
    use Acktor::Logging;


=pod

Address (url) formats:
    local  - <ID>:<ACTOR>@<PID>:local
    UNIX   - <ID>:<ACTOR>@<PID>:<path>
    INET   - <ID>:<ACTOR>@<host>:<port>

- System owns PostOffice
    - will pass arguments such as:
        - listen <host>:<port>
        - connect <host>:<port>

- PostOffice owns Node
    - constructs Node from arguments (listen, connect)

- Dispatcher gets PostOffice
    - registers PostOffice->Node with Scheduler
    - if PostOffice
        - use that for address, not the `local` one

- Scheduler has Node
    - handles wait with `select`
    - calls Node->tick

- PostOffice
    - post_letters
        - loops over letters in outbox
            - add letters to connection outbox
    - deliver_letters
        - loop over letters in inbox
            - dispatch messages locally

    - register watchers for:
        - reading
            - for all watched connections
                - read letters and add to inbox
            - call deliver_letters
        - writing
            - for all watched connections
                - write letters from connection outbox

=cut

    method deliver_letters {
        logger->log( WARN, "Delivering...") if WARN;
    }

    method post_letters (@letters) {
        logger->log( WARN, "Posting(".(join ", " => @letters)) if WARN;
        # TODO - look through the letters and try to deliver them
        # if letter.destination in %registered
        #   enqueue message to dispatcher
        # else
        #   send to dead letter queue??
    }
}


__END__

=pod

=encoding UTF-8

=head1 NAME

Acktor::PostOffice

=head1 DESCRIPTION

=cut
