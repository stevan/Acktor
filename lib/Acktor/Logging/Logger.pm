
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

class Acktor::Logging::Logger {
    use Term::ReadKey qw[ GetTerminalSize ];

    our $TERM_WIDTH = (GetTerminalSize())[0];

    state %level_color_map = (
        1 => "\e[96m",
        2 => "\e[93m",
        3 => "\e[91m",
        4 => "\e[92m",
    );
    state %level_map = (
        1 => $level_color_map{1}.".o(INFO)\e[0m",
        2 => $level_color_map{2}."^^[WARN]\e[0m",
        3 => $level_color_map{3}."!{ERROR}\e[0m",
        4 => $level_color_map{4}."?<DEBUG>\e[0m",
    );
    state %target_to_color;

    field $fh     :param = \*STDERR;
    field $target :param = undef;

    method format_message ($target, $level, @msg) {
        join '' => map {
            join '' =>
                $level_map{ $level },
                (sprintf " \e[20m\e[97m\e[48;2;%d;%d;%d;m %s \e[0m " => (
                    @{ $target_to_color{ $target }
                        //= [ map { (int(rand(20)) * 10) } 1,2,3 ] },
                    $target,
                )),
                $level_color_map{ $level }, $_, "\e[0m",
                "\n"
        } split /\n/ => "@msg";
    }

    method write ($msg) { $fh->print( $msg ) }

    method log ($level, @msg) {
        $self->write($self->format_message($target // (caller)[0], $level, @msg));
    }

    method line ($label) {
        my $width = ($TERM_WIDTH - ((length $label) + 2 + 2));
        $fh->print(
            "\e[38;2;125;125;125;m",
            '-- ', $label, ' ', ('-' x $width),
            "\e[0m",
            "\n"
        );
    }

}

__END__

=pod

=encoding UTF-8

=head1 NAME

Acktor::Logging::Logger

=head1 DESCRIPTION

=cut
