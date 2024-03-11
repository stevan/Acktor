#!perl

use v5.38;
use utf8;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];
use open         qw[ :std :encoding(UTF-8) ];

$|++;

my $LIGHT  = "\e[38;5;2;m▓\e[0m";
my $MIDDLE = "\e[38;5;3;m▒\e[0m";
my $DARK   = "\e[38;5;4;m░\e[0m";

class Rect {
    method origin;

    method set_position;

    method height;
    method width;

    method draw;
    method render;

    method clear {
        my $height = $self->height;
        my $width  = $self->width;

        my @out = map { (' ' x $width) } (1 .. $height);

        return @out;
    }
}

class Zip :isa(Rect) {
    use Data::Dumper;
    use List::Util qw[ max sum ];

    use Coords;

    field $origin :param = [0,0];
    field $boxes  :param;

    field $position;

    ADJUST {
        $position = $origin;
    }

    method origin { $origin }

    method set_position ($p) { $position = $p }

    method height { max map $_->height, @$boxes }
    method width  { sum map $_->width,  @$boxes }

    method draw {
        my $height = $self->height;
        my $width  = $self->width;

        # render the boxes and pad the height as needed
        my @drawn;
        foreach my $box (@$boxes) {
            my @lines = $box->draw;
            if ( scalar(@lines) < $height ) {
                my $w = $box->width;
                push @lines => (' ' x $w) foreach (1 .. ($height - scalar(@lines)));
            }
            push @drawn => \@lines;
        }

        # now zip the lines together ...
        my @out;
        foreach my $i ( 0 .. ($height - 1) ) {
            my @line;
            foreach my $drawn (@drawn) {
                push @line => $drawn->[$i];
            }
            push @out => join '' => @line;
        }

        return @out;
    }

    method render {
        my $indent = 1;
        foreach my $i ( 0 .. $#{$boxes} ) {
            my $offset = add( $position, $boxes->[$i]->origin );
            $offset->[X] = $indent;
            $boxes->[$i]->set_position( $offset );
            #warn "GOT", join ',' => @$offset;
            $boxes->[$i]->render;
            $indent += $boxes->[$i]->width;
        }
    }
}

class Box :isa(Rect) {
    use ANSI;

    field $origin :param = [0,0];

    field $height :param;
    field $width  :param;
    field $fill   :param;

    field $position;

    ADJUST {
        $position = $origin;
    }

    method origin { $origin }
    method height { $height }
    method width  { $width  }

    method set_position ($p) { $position = $p }

    method render {
        my $line_break = format_line_break( $width );
        print format_move_cursor( map ($_ || 1), reverse @$position );
        print map { $_, $line_break } $self->draw;
    }

    method draw {
        my @out = map { ($fill x $width) } (1 .. $height);
        return @out;
    }
}

use ANSI;

sub render ($r) {
    $r->render;
}

sub draw ($r) {
    my $line_break = format_line_break( $r->width );
    print map { $_, $line_break } $r->draw;
}

sub clear ($r) {
    my $line_break = format_line_break( $r->width );
    print map { $_, $line_break } $r->clear;
}

my $r1 = Box->new( height => 5,  width => 10, fill => $DARK );
my $r2 = Box->new( height => 10, width => 20, fill => $LIGHT );
my $r3 = Box->new( height => 3,  width => 3,  fill => $MIDDLE );

my $z = Zip->new( boxes => [ $r1, $r3 ], origin => [2,2] );

render($_) foreach ( $z );

say'' foreach 0 .. 20;

#sleep 1;
#print format_move_cursor(2, 1);
#clear($z);
