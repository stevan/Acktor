
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

class Acktor::IO::BufferedReader {
    use Acktor::Logging;

    use Errno 'EWOULDBLOCK';

    use constant MAX_BUFFER => 1024;
    use constant EOF        => 506;

    field $buffer = '';
    field $error;
    field @letters;

    method has_error { !! $error }
    method get_error {    $error }

    method has_letters { !! @letters }
    method fetch_letters {
        my @msgs = @letters;
        @letters = ();
        @msgs;
    }

    my sub parse_buffer ($b) {
        my @l;
        while (length $b) {
            #say "Parsing ($b)";

            my $index = index($b, ':');
            if ($index == -1) {
                #say "Unable to find : in buffer($b) leaving ...";
                last;
            }

            my $size = substr($b, 0, $index, '');
            #say "Length ($size) : ($b)";

            if (length $b < $size) {
                #say "Not enough in buffer($b) leaving ...";
                last;
            }

            substr($b, 0, 1, ''); # clear colon

            my $letter = substr($b, 0, $size, '');
            #say "Letter($letter) : ($b)";

            push @l => $letter;
        }
        #say "LETTERS: ".join ', ' => @ls;
        return @l;
    }

    method read ($socket) {
        logger->log( DEBUG, "read started with buffer($buffer)" ) if DEBUG;

        my $bytes_read = $socket->sysread( $buffer, MAX_BUFFER );

        if (defined $bytes_read) {
            if ($bytes_read > 0) {
                logger->log( DEBUG, "read bytes($bytes_read) into buffer($buffer)" ) if DEBUG;
                push @letters => parse_buffer( $buffer );
            }
            else {
                logger->log( DEBUG, "got EOF with buffer($buffer)" ) if DEBUG;
                $error = EOF;
            }
        } elsif ($! == EWOULDBLOCK) {
            logger->log( DEBUG, "would block, with buffer($buffer)" ) if DEBUG;
        } else {
            logger->log( ERROR, "sysread error($!), with buffer($buffer)" ) if ERROR;
            $error = $!;
        }

        # returns true if we
        # have read letters
        # and false if not
        return !! scalar @letters;
    }

}
