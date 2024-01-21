package Acktor::Tools;
use v5.38;
use experimental qw[ builtin];
use builtin      qw[ export_lexically ];

use Acktor::Event;
use Acktor::Props;
use Acktor::Logging ();

sub import {
    export_lexically(
        '&event'    => \&event,
        '&spawn'    => \&spawn,
        '&context'  => \&context,
        '&sender'   => \&sender,
        '&logger'   => \&logger,
        '&actor_of' => \&actor_of,
    );
}

sub actor_of ($class, %args) {
    $class =~ s/^\*(main\:\:)?(.*)\:\:/$2/;

    my $alias = delete $args{alias};

    Acktor::Props->new(
        class => $class,
        (keys %args ? (args  => \%args) : ()),
        (    $alias ? (alias => $alias) : ()),
    );
}

sub logger {
    $Acktor::Behavior::Method::CURRENT_CONTEXT // die 'Cannot call `logger` outside of an active Acktor::Context';
    Acktor::Logging::logger( $Acktor::Behavior::Method::CURRENT_CONTEXT )
}

sub spawn ($props) {
    my $c = $Acktor::Behavior::Method::CURRENT_CONTEXT // die 'Cannot call `spawn` outside of an active Acktor::Context';
    $c->spawn( $props )
}

sub context {
    $Acktor::Behavior::Method::CURRENT_CONTEXT // die 'Cannot call `context` outside of an active Acktor::Context';
}

sub sender {
    # it must at least be defined ...
    my $m = $Acktor::Behavior::Method::CURRENT_MESSAGE // die 'Cannot call `sender` outside of an active Acktor::Context';
    return $m->context->self;
}

sub event ($symbol, @payload) {
    my $c = $Acktor::Behavior::Method::CURRENT_CONTEXT // die 'Cannot create an event outside of an active Acktor::Context';
    Acktor::Event->new(
        symbol  => $symbol,
        payload => \@payload,
        context => $c
    );
}


__END__
