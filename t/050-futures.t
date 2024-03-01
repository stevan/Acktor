#!perl

use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

use Data::Dumper;
use Test::More;


sub Future :prototype(&;@) ($f, %rest) {
    return [ $f, \%rest ];
}

sub onSuccess :prototype(&;@) ($f, @rest) {
    return (on_success => $f, @rest);
}

sub onError :prototype(&;@) ($f, @rest) {
    return (on_error => $f, @rest);
}


my $future = Future {
    1;
} onError {
    3;
} onSuccess {
    2;
};

warn Dumper $future;

warn $future->[0]->();
warn $future->[1]->{on_success}->();
warn $future->[1]->{on_error}->();

#warn $_->() foreach @$future;

done_testing;
