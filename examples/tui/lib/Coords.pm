package Coords;

use v5.38;
use experimental qw[ builtin ];
use builtin      qw[ ceil export_lexically ];

use constant X => 0;
use constant Y => 1;

sub import {
    {
        no strict 'refs';
        my $to = caller;
        *{"${to}::X"} = \&X;
        *{"${to}::Y"} = \&Y;
    }

    export_lexically(
        '&add'             => \&add,
        '&subtract'        => \&subtract,
        '&scale_by_factor' => \&scale_by_factor,
    );
}

sub add      ($p1, $p2) { [ $p1->[X] + $p2->[X], $p1->[Y] + $p2->[Y] ] }
sub subtract ($p1, $p2) { [ $p1->[X] - $p2->[X], $p1->[Y] - $p2->[Y] ] }

sub scale_by_factor ($p, $factor) {
    [ ceil( $p->[X] * $factor ), ceil( $p->[Y] * $factor ) ]
}

__END__
