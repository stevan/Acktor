package ANSI;

use v5.38;
use experimental qw[ builtin ];
use builtin      qw[ ceil export_lexically ];

sub import {
    {
        no strict 'refs';
        my $to = caller;
        #*{"${to}::X"} = \&X;
    }

    export_lexically(
        '&format_line_break'  => \&format_line_break,
        '&format_move_cursor' => \&format_move_cursor
    );
}

sub format_line_break ($width) { sprintf "\e[B\e[%dD" => $width }
sub format_move_cursor   (@to) { sprintf "\e[%d;%dH"  => @to    }

__END__
