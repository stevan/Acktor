package ANSI;

use v5.38;
use experimental qw[ builtin ];
use builtin      qw[ export_lexically ];

sub import {
    export_lexically(
        '&format_line_break'   => \&format_line_break,
        '&format_move_cursor'  => \&format_move_cursor,

        '&format_move_up'      => \&format_move_up,
        '&format_move_down'    => \&format_move_down,
        '&format_move_left'    => \&format_move_left,
        '&format_move_right'   => \&format_move_right,

        '&format_insert_line'  => \&format_insert_line,
        '&format_delete_line'  => \&format_delete_line,

        '&format_shift_left'   => \&format_shift_left,
        '&format_shift_right'  => \&format_shift_right,

        '&format_delete_chars' => \&format_delete_chars,
        '&format_erase_chars'  => \&format_erase_chars,
        '&format_repeat_char'  => \&format_repeat_char,

        '&format_reset'        => \&format_reset,
        '&format_bg_color'     => \&format_bg_color,
        '&format_fg_color'     => \&format_fg_color,
        '&format_color'        => \&format_color,
    );
}

sub format_line_break ($width) { sprintf "\e[B\e[%dD" => $width }
sub format_move_cursor   (@to) { sprintf "\e[%d;%dH"  => @to    }

sub format_move_up    ($by) { sprintf "\e[%dA"  => $by }
sub format_move_down  ($by) { sprintf "\e[%dB"  => $by }
sub format_move_left  ($by) { sprintf "\e[%dD"  => $by }
sub format_move_right ($by) { sprintf "\e[%dC"  => $by }

sub format_insert_line  ($count=1) { sprintf "\e[%dL"  => $count }
sub format_delete_line  ($count=1) { sprintf "\e[%dM"  => $count }

sub format_shift_left  ($count=0) { sprintf "\e[%d \@"  => $count }
sub format_shift_right ($count=0) { sprintf "\e[%d A"  => $count }

sub format_delete_chars ($count=1) { sprintf "\e[%dP"  => $count }
sub format_erase_chars ($count=0) { sprintf "\e[%dX"  => $count }
sub format_repeat_char ($char, $count=0) { sprintf "%s\e[%db"  => $char, $count }

sub format_reset               { "\e[0m" }
sub format_bg_color ($color)   { sprintf "\e[48;2;%d;%d;%d;m" => @$color }
sub format_fg_color ($color)   { sprintf "\e[38;2;%d;%d;%d;m" => @$color }
sub format_color    ($fg, $bg) { sprintf "\e[38;2;%d;%d;%d;48;2;%d;%d;%d;m"  => @$fg, @$bg }

__END__
