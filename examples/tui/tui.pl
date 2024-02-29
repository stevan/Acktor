#!perl

use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

use Acktor;
use Acktor::System;
use Acktor::Behaviors;

$|++;

## ----------------------------------------------------------------------------

class Box {
    use constant RESET        => "\e[0m";
    use constant FORMAT_BG_COLOR => "\e[48;2;%d;%d;%d;m";
    use constant FORMAT_FG_COLOR => "\e[38;2;%d;%d;%d;m";
    use constant FORMAT_COLOR    => "\e[38;2;%d;%d;%d;48;2;%d;%d;%d;m";

    use constant FORMAT_LINE_BREAK => "\e[B\e[%dD";

    method draw;
}

class TextBox :isa(Box) {

    field $contents :param;

    field $content_width;
    field $width;
    field $height;
    field $line_break;

    ADJUST {
        $content_width = length $contents;
        $width         = $content_width + 4;
        $height        = 3;
        $line_break    = sprintf $self->FORMAT_LINE_BREAK, $width;
    }

    method clear {
        return join $line_break => ((' ' x $width) x $height);
    }

    method draw {
        return join $line_break => (
            (sprintf "┌─%s─┐"                  => ('─' x $content_width)),
            (sprintf "│ %-${content_width}s │" => ($contents))           ,
            (sprintf "└─%s─┘"                  => ('─' x $content_width)),
        );
    }
}

## ----------------------------------------------------------------------------

class Widget :isa(Acktor) {
    use constant FORMAT_GOTO => "\e[%d;%dH";

    field $tty  :param = \*STDOUT;

    field $top  :param;
    field $left :param;
    field $box  :param;

    method draw  { $tty->print((sprintf FORMAT_GOTO, $top, $left), $box->draw  ) }
    method clear { $tty->print((sprintf FORMAT_GOTO, $top, $left), $box->clear ) }

    method MoveTo :Receive ($t, $l) {
        $self->clear;
        ($top, $left) = ($t, $l);
        $self->draw;
    }

    method Draw  :Receive { $self->draw  }
    method Clear :Receive { $self->clear }
}


class Window :isa(Acktor) {
    use Term::ReadKey qw[ GetTerminalSize ];

    use constant CLEAR_SCREEN => "\e[2J";
    use constant HOME_CURSOR  => "\e[H";

    use constant HIDE_CURSOR  => "\e[?25l";
    use constant SHOW_CURSOR  => "\e[?25h";

    use constant ENABLE_ALT_BUF  => "\e[?1049h";
    use constant DISABLE_ALT_BUF => "\e[?1049l";


    use constant STARTED => 1;
    use constant STOPPED => 0;

    field $tty          :param = \*STDOUT;
    field $refresh_rate :param = 0.5;

    field $height;
    field $width;

    field @widgets;

    field $status;

    ADJUST {
        ($width, $height) = GetTerminalSize();
        $status = STOPPED;
    }

    method ClearScreen :Receive { $tty->print( CLEAR_SCREEN ) }
    method HomeCursor  :Receive { $tty->print( HOME_CURSOR  ) }

    method HideCursor  :Receive { $tty->print( HIDE_CURSOR ) }
    method ShowCursor  :Receive { $tty->print( SHOW_CURSOR ) }

    method EnableAltBuffer  :Receive {  $tty->print( ENABLE_ALT_BUF  ) }
    method DisableAltBuffer :Receive {  $tty->print( DISABLE_ALT_BUF ) }

    method AddWidget :Receive ($widget) {
        push @widgets => $widget;
        if ( $status == STARTED ) {
            $widget->send( event *Widget::Draw );
        }
    }

    method Start :Receive {

        $self->ClearScreen;
        $self->HomeCursor;

        $status = STARTED;

        foreach my $widget ( @widgets ) {
            $widget->send( event *Widget::Draw );
        }

        context->schedule(
            event => event( *Update ),
            for   => context->self,
            after => $refresh_rate,
        );
    }

    method Stop :Receive {
        $status = STOPPED;
    }

    method Update :Receive {
        if ( $status != STOPPED ) {
            # tail recursion ;)
            context->schedule(
                event => event( *Update ),
                for   => context->self,
                after => $refresh_rate,
            );
        }
    }
}

sub init ($ctx) {
    my $window = spawn Props[ Window:: ];

    my $widget = spawn Props[ Widget::, (
            top  => 5,
            left => 5,
            box  => TextBox->new( contents => 'Hello World' )
        )
    ];

    $window->send( event *Window::AddWidget => $widget );
    $window->send( event *Window::Start );

    $ctx->schedule(
        event => event( *Widget::MoveTo => 10, 10 ),
        for   => $widget,
        after => 3,
    );

    $ctx->schedule(
        event => event( *Widget::MoveTo => 1, 1 ),
        for   => $widget,
        after => 5,
    );
}

my $system = Acktor::System->new;

$system->run( init => \&init );


__END__

╭────────╮
│ System │
├──────┬─┴─────────────╮
│ 0001 │ Init          │◁───────────╮
╰──────┼───────────────╯            │
       │                            │
       │                            │
╭──────┴───────────────╮            │
│ PID  │ Props         │            │
│ ─────┼────────────── │            │
│ 0002 │ Ping        □ │     ╭──────┴──────────────╮
│ 0003 │ Pong        □ │     │                     │
│ 0004 │ Ping        ■ ╞════▷│                     │
│ 0005 │ Pong        □ │     │                     │
│ 0006 │ Ping        □ │     ╰─ Dead Letter Queue ─╯
╰──────────────────────╯

┌─┬┐  ╔═╦╗  ╓─╥╖  ╒═╤╕
│ ││  ║ ║║  ║ ║║  │ ││
├─┼┤  ╠═╬╣  ╟─╫╢  ╞═╪╡
└─┴┘  ╚═╩╝  ╙─╨╜  ╘═╧╛

▕▕
 ╲╲
  ╲╲
   ╳╲
   ╳╱
  ╱╱
 ╱╱


▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽
△△△△△△△△△△△△△△△△△△△△△△△△

●●●●●●●●●●●●●●●●●●●●●●●●
◯◯◯◯◯◯◯◯◯◯◯◯◯◯◯◯◯◯◯◯◯◯◯◯

◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆
◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇
◻◻◻◻◻◻◻◻◻◻◻◻◻◻◻◻◻◻◻◻◻◻◻◻


▷▷▷▷▷▷▷▷▷▷▷▷▷▷▷▷▷▷▷▷▷▷▷▷
▶▶▶▶▶▶▶▶▶▶▶▶▶▶▶▶▶▶▶▶▶▶▶▶
◀◀◀◀◀◀◀◀◀◀◀◀◀◀◀◀◀◀◀◀◀◀◀◀
◁◁◁◁◁◁◁◁◁◁◁◁◁◁◁◁◁◁◁◁◁◁◁◁
◀▶◀▶◀▶◀▶◀▶◀▶◀▶◀▶◀▶◀▶◀▶◀▶

▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼
▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲
▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼

◫◫◫◫◫◫◫◫◫◫◫◫◫◫◫◫◫◫◫◫◫◫◫◫

◰◱◲◳◰◱◲◳◰◱◲◳◰◱◲◳◰◱◲◳◰◱◲◳
◰◱◲◳◰◱◲◳◰◱◲◳◰◱◲◳◰◱◲◳◰◱◲◳
◰◱◲◳◰◱◲◳◰◱◲◳◰◱◲◳◰◱◲◳◰◱◲◳

             ╱╲╲╲
            ╱  ╲╲╲
           ╱    ╲╲╲
   ╱╲╲╲╲╲╲╲╲     ╲╲╲
  ╱  ╲╲╲╲╲╲╲╲    ╱╱╳
 ╱    ╲╲╲╲╲╲╲╲  ╱╱╳╲╲
╱      ╲╲╲╲╲╲╲╲╱╱╳╲╲╲╲
╲      ╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱
 ╲    ╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱
┌───────────────────┬┐
└───────────────────┴┘

 ╳╳╳╳╳╳╳╳
 ╳╳╳╳╳╳╳╳
 ╳╳╳╳╳╳╳╳
 ╳╳╳╳╳╳╳╳
 ╳╳╳╳╳╳╳╳
 ╳╳╳╳╳╳╳╳

