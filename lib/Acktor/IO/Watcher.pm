
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

use Acktor::IO::BufferedReader;
use Acktor::IO::BufferedWriter;

class Acktor::IO::Watcher {

    field $fh :param;

    field $reader;
    field $writer;

    field $reading = false;
    field $writing = false;

    ADJUST {
        $fh->autoflush(1);
        $fh->blocking(0);

        $reader = Acktor::IO::BufferedReader->new;
        $writer = Acktor::IO::BufferedWriter->new;

        $self->is_reading = true;
        $self->is_writing = false;
    }

    method is_reading :lvalue { $reading }
    method is_writing :lvalue { $writing }

    method fh { $fh }

    method to_write ($data) {
        $self->is_writing = true;
        $writer->send_letters($data);
    }

    method handle_read ($f) {
        if ($reader->read( $fh )) {
            my @letters = $reader->fetch_letters;
            $f->( @letters );
        }

        if ( my $error = $reader->get_error ) {
            if ($error == $reader->EOF) {
                $self->is_reading = false;
                $self->is_writing = false;
                # TODO - do something here ... dunno what yet
            }
        }
    }

    method handle_write () {
        $self->is_writing = $writer->write( $fh );
    }
}
