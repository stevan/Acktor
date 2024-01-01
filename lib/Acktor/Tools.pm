package Acktor::Tools;
use v5.38;
use experimental qw[ builtin];
use builtin      qw[ export_lexically ];

use Acktor::Event;
use Acktor::Logging ();

sub import {
    export_lexically(
        '&event'   => \&event,
        '&spawn'   => \&spawn,
        '&context' => \&context,
        '&sender'  => \&sender,
        '&logger'  => \&logger,
    );
}

sub logger {
    $Acktor::CURRENT_CONTEXT // die 'Cannot call `logger` outside of an active Acktor::Context';
    Acktor::Logging::logger( $Acktor::CURRENT_CONTEXT )
}

sub spawn ($props) {
    my $c = $Acktor::CURRENT_CONTEXT // die 'Cannot call `spawn` outside of an active Acktor::Context';
    $c->spawn( $props )
}

sub context {
    $Acktor::CURRENT_CONTEXT // die 'Cannot call `context` outside of an active Acktor::Context';
}

sub sender {
    # it must at least be defined ...
    my $m = $Acktor::CURRENT_MESSAGE // die 'Cannot call `sender` outside of an active Acktor::Context';
    return $m->from;
}

sub event ($symbol, @payload) {
    my $c = $Acktor::CURRENT_CONTEXT // die 'Cannot create an event outside of an active Acktor::Context';
    Acktor::Event->new(
        symbol  => $symbol,
        payload => \@payload,
        context => $c
    );
}


__END__
