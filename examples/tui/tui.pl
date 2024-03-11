#!perl

use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

use Acktor;
use Acktor::System;
use Acktor::Behaviors;

$|++;

## ----------------------------------------------------------------------------
## Input
## ----------------------------------------------------------------------------

class Keyboard {
    use Term::ReadKey qw[ ReadKey ReadMode ];

    use constant UP    => 1;
    use constant DOWN  => 2;
    use constant RIGHT => 3;
    use constant LEFT  => 4;

    my $UP_ARROW    = "\e[A";
    my $DOWN_ARROW  = "\e[B";
    my $RIGHT_ARROW = "\e[C";
    my $LEFT_ARROW  = "\e[D";

    field $fh :param = \*STDIN;

    method turn_echo_off { ReadMode cbreak  => $fh }
    method turn_echo_on  { ReadMode restore => $fh }

    method capture_keypress {
        my $message = ReadKey -1, $fh;
        return unless $message;

        if ( $message eq "\e" ) {
            $message .= ReadKey -1, $fh;
            $message .= ReadKey -1, $fh;
        }

        return UP    if $message eq $UP_ARROW;
        return DOWN  if $message eq $DOWN_ARROW;
        return RIGHT if $message eq $RIGHT_ARROW;
        return LEFT  if $message eq $LEFT_ARROW;
    }
}

## ----------------------------------------------------------------------------
## Boxes
## ----------------------------------------------------------------------------

class Box {
    use constant RESET        => "\e[0m";
    use constant FORMAT_BG_COLOR => "\e[48;2;%d;%d;%d;m";
    use constant FORMAT_FG_COLOR => "\e[38;2;%d;%d;%d;m";
    use constant FORMAT_COLOR    => "\e[38;2;%d;%d;%d;48;2;%d;%d;%d;m";

    use constant FORMAT_LINE_BREAK => "\e[B\e[%dD";

    method draw;
    method clear;
}

class TextBox :isa(Box) {

    field $contents :param = '';

    method contents :lvalue { $contents }

    method clear {
        my $content_width = length $contents;
        my $width         = $content_width + 4;
        my $height        = 3;
        my $line_break    = sprintf $self->FORMAT_LINE_BREAK, $width;

        return join $line_break => ((' ' x $width) x $height);
    }

    method draw {
        my $content_width = length $contents;
        my $line_break    = sprintf $self->FORMAT_LINE_BREAK, $content_width + 4;

        return join $line_break => (
            (sprintf "╭─%s─╮"                  => ('─' x $content_width)),
            (sprintf "│ %-${content_width}s │" => ($contents))           ,
            (sprintf "╰─%s─╯"                  => ('─' x $content_width)),
        );
    }
}

class Clock :isa(TextBox) {

    field $counter = 0;

    ADJUST {
        $self->contents = scalar localtime;
    }

    method draw {
        $self->contents = scalar localtime;
        return $self->SUPER::draw;
    }
}

## ----------------------------------------------------------------------------
## Actors
## ----------------------------------------------------------------------------

class Widget :isa(Acktor) {
    use constant FORMAT_GOTO => "\e[%d;%dH";

    field $tty  :param = \*STDOUT;

    field $top  :param;
    field $left :param;
    field $box  :param;

    field $timer;

    method draw  { $tty->print((sprintf FORMAT_GOTO, $top, $left), $box->draw  ) }
    method clear { $tty->print((sprintf FORMAT_GOTO, $top, $left), $box->clear ) }

    method Start :Receive {
        $self->draw
    }

    method MoveTo :Receive ($t, $l) {
        $self->clear;
        ($top, $left) = ($t, $l);
        $self->draw;
    }

    method Refresh :Receive { $self->draw  }
    method Clear   :Receive { $self->clear }

    method Animate :Receive ($refresh_rate) {
        $self->draw;

        $timer = context->schedule(
            event => event( *Animate => $refresh_rate ),
            for   => context->self,
            after => $refresh_rate,
        );
    }

    method Stop :Receive {
        $timer->cancel if $timer;
    }

    method OnKeyPress :Receive ($key) {
        $self->clear;
        if ( $key == Keyboard->UP ) {
            $top-- unless !$top;
        } elsif ( $key == Keyboard->DOWN ) {
            $top++;
        } elsif ( $key == Keyboard->LEFT ) {
            $left-- unless !$left;
        } elsif ( $key == Keyboard->RIGHT ) {
            $left++;
        }
        $self->draw;
    }
}


class Window :isa(Acktor) {
    use Term::ReadKey qw[ GetTerminalSize ];

    use constant CLEAR_SCREEN => "\e[2J";
    use constant HOME_CURSOR  => "\e[H";

    use constant HIDE_CURSOR  => "\e[?25l";
    use constant SHOW_CURSOR  => "\e[?25h";

    use constant ENABLE_ALT_BUF  => "\e[?1049h";
    use constant DISABLE_ALT_BUF => "\e[?1049l";

    field $tty          :param = \*STDOUT;
    field $refresh_rate :param = 0.03;

    field $height;
    field $width;

    field $keyboard;
    field @elements;
    field @listeners;

    field $keypress_timer;

    ADJUST {
        ($width, $height) = GetTerminalSize();

        $keyboard = Keyboard->new;
    }

    method clear_screen { $tty->print( CLEAR_SCREEN ) }
    method home_cursor { $tty->print( HOME_CURSOR  ) }

    method hide_cursor { $tty->print( HIDE_CURSOR ) }
    method show_cursor { $tty->print( SHOW_CURSOR ) }

    method enable_alt_buffer {  $tty->print( ENABLE_ALT_BUF  ) }
    method disable_alt_buffer {  $tty->print( DISABLE_ALT_BUF ) }


    method AddElements  :Receive (@e) { push @elements  => @e }
    method AddListeners :Receive (@l) { push @listeners => @l }

    method Start :Receive {

        $self->clear_screen;
        $self->home_cursor;

        $self->hide_cursor;
        $keyboard->turn_echo_off;
        $keypress_timer = context->schedule(
            event => event( *CheckKeyPress ),
            for   => context->self,
            after => $refresh_rate,
        );

        $_->send( event *Widget::Start ) foreach @elements;
    }

    method Stop :Receive {
        $self->show_cursor;
        $keyboard->turn_echo_on;
        $keypress_timer->cancel;

        $_->send( event *Widget::Stop ) foreach @elements;
    }

    method Refresh :Receive {
        $_->send( event *Widget::Refresh ) foreach @elements;
    }

    method CheckKeyPress :Receive {

        if ( my $dir = $keyboard->capture_keypress ) {
            $_->send( event *Widget::OnKeyPress => $dir ) foreach @listeners;
        }

        # tail recursion ;)
        $keypress_timer = context->schedule(
            event => event( *CheckKeyPress ),
            for   => context->self,
            after => $refresh_rate,
        );
    }
}

sub init ($ctx) {
    my $window = spawn Props[ Window:: ];

    my $widget = spawn Props[ Widget::, (
            top  => 1,
            left => 1,
            box  => TextBox->new( contents => 'Hello World' )
        )
    ];

    my $clock = spawn Props[ Widget::, (
            top  => 1,
            left => 20,
            box  => Clock->new( contents => 'foo' )
        )
    ];

    $window->send( event *Window::AddElements  => $widget, $clock );
    $window->send( event *Window::AddListeners => $widget );
    $window->send( event *Window::Start );

    $clock->send( event *Widget::Animate => 1 );

    my $Stop = event( *Window::Stop );

    my $self_destruct = $ctx->schedule(
        event => $Stop,
        for   => $window,
        after => 5,
    );

    $SIG{INT} = sub {
        $self_destruct->cancel;
        $window->send( $Stop );
    };
}

my $system = Acktor::System->new;
$system->run( init => \&init );


__END__
