
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

class Acktor::PostOffice::BufferedReader {
    use Acktor::Logging;

    use constant MAX_BUFFER => 1024;

    field $buffer;
    field @messages;

    method has_messages { !! @messages }
    method fetch_messages {
        my @msgs = @messages;
        @messages = ();
        @msgs;
    }

    method read ($socket) {

        $socket->sysread( $buffer, MAX_BUFFER );

        if (length $buffer) {
            logger->log( DEBUG, "Reading messages ...[ $buffer ]" ) if DEBUG;

            my ($length, $body) = $buffer =~ /^(\d*)\:(.*)$/;
            push @messages => $body;
            $buffer = '';
        }

        # returns true if we
        # have read messages
        # and false if not
        return !! scalar @messages;
    }

}
