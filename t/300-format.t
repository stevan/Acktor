#!perl

use v5.38;
use utf8;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];
use open         qw[ :std :encoding(UTF-8) ];

use List::Util qw[ max ];

use Data::Dumper;
use Test::More;

use constant LEFT_ALIGN  => 1;
use constant RIGHT_ALIGN => 2;

use constant ACTIVE   => true;
use constant INACTIVE => false;

use constant BLACK   => 0;
use constant RED     => 1;
use constant GREEN   => 2;
use constant YELLOW  => 3;
use constant BLUE    => 4;
use constant MAGENTA => 5;
use constant CYAN    => 6;
use constant WHITE   => 7;

sub color ($box, $color) {
    my @out;
    foreach my $line (@$box) {
        push @out => "\e[38;5;${color};m${line}\e[0m";
    }
    return \@out;
}

sub uncolor ($x) {
    $x =~ s/\e\[38\;5\;[0-7]\;m//g;
    $x =~ s/\e\[0m//g;
    $x;
}

sub box ($contents, $height=undef, $width=undef, $align=undef) {
    $align //= LEFT_ALIGN;
    $contents = [ $contents ] unless ref $contents eq 'ARRAY';

    $width //= length $contents->[0];

    my $format = '%'.($align == LEFT_ALIGN ? '-':'').$width.'s';

    $width += 2;

    my $h = scalar @$contents;
    if ($height && $height > $h) {
        foreach ( 0 .. ($height - $h)) {
            push @$contents => ' ';
        }
    }

    return [
        ('╭'.('─' x $width).'╮'),
        (map { '│ '.(sprintf $format => $_).' │' } @$contents),
        ('╰'.('─' x $width).'╯'),
    ];
}

sub tab ($contents, $height=undef, $width=undef, $align=undef, $active=INACTIVE) {
    $align //= LEFT_ALIGN;
    $contents = [ $contents ] unless ref $contents eq 'ARRAY';

    $width //= (length $contents->[0]);

    my $format = '%'.($align == LEFT_ALIGN ? '-':'').$width.'s';

    $width += 2;

    my $h = scalar @$contents;
    if ($height && $height > $h) {
        foreach ( 0 .. ($height - $h)) {
            push @$contents => ' ';
        }
    }

    my @out = (
        ('╭'.('─' x $width).'╮'),
        (map { '│ '.(sprintf $format => $_).' │' } @$contents)
    );

    if ($active) {
        push @out => ('┘'.(' ' x $width).'└'),
    } else {
        push @out => ('┴'.('─' x $width).'┴'),
    }

    return \@out;
}

sub zip ($b1, $b2, @rest) {
    my @out;
    foreach my $i (0 .. $#{$b1}) {
        push @out => $b1->[$i] . $b2->[$i];
    }
    return \@out unless @rest;
    return zip(\@out, @rest);
}

sub stack ($b1, $b2, @rest ) {
    return [ @$b1, @$b2 ] unless @rest;
    return stack([ @$b1, @$b2 ], @rest);
}

sub glue ($b1, $b2, @rest) {
    my @top    = @$b1;
    my @bottom = @$b2;

    pop   @top;
    shift @bottom;

    my $width = max( map length $_, (@top, @bottom) ) - 2;

    my $out = [
        @top,
        ('╞'.('═' x $width).'╡'),
        @bottom
    ];

    return $out unless @rest;
    return glue($out, @rest);
}

sub attach ($b1, $b2, @rest) {
    my @top    = @$b1;
    my @bottom = @$b2;

    my $top_bottom = pop @top;
    my $bottom_top = shift @bottom;

    my $join = $top_bottom .  substr $bottom_top, length $top_bottom;

    my $out = [ @top, $join, @bottom ];

    return $out unless @rest;
    return glue($out, @rest);
}

sub merge ($b1, $b2, @rest) {
    my @top    = @$b1;
    my @bottom = @$b2;

    pop   @top;
    shift @bottom;

    return [ @top, @bottom ] unless @rest;
    return merge([ @top, @bottom ], @rest);
}

sub dialog ($title, $body, $ok="OK", $cancel="Cancel") {
    my $buttons = zip( box($ok), box($cancel) );
    my $width   = max(
        map length $_, @$body, # the longest string in the body
        $title,                # the title
        $buttons->[0]          # the width of the buttons
    );

    return glue(
        box([ $title ], undef, $width),
        merge(
            box($body,    undef, $width),
            box($buttons, undef, $width, RIGHT_ALIGN)
        ),
    )
}

sub tabbed ($tabs, $body, $height=undef, $width=undef) {
    my $t = zip( [' ',' ','╭'], @$tabs );

    $width = max(
        length $t->[0],
        (map length $_, @$body),
        $width // ()
    );

    return attach(
        $t,
        box( $body, $height, $width )
    );
}

say join "\n" => @{
stack(
    tabbed(
        [
            tab('System', undef, undef, undef, INACTIVE),
            tab('Network', undef, undef, undef, ACTIVE),
            tab('Metrics', undef, undef, undef, INACTIVE)
        ],
        [
            'The system is the system. Yah know what I mean?'
        ],
        10,
        60
    ),

    dialog(
        "Hello World!",
        [
            "This is a basic dialog box, it has a body,",
            "as well as `ok` & `cancel` buttons.",
            "",
            "This can be pretty flexible if you want!",
            "",
        ],
        "Submit",
        "Quit"
    ),


    box(
        zip(
            box("Foo"),
            box("Bar"),
            box("Baz"),
        ),
        10,
        40,
        RIGHT_ALIGN
    )
)
};


pass('... done');


done_testing;
