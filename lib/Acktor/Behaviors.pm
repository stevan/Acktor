package Acktor::Behaviors;
use v5.38;
use experimental qw[ builtin];
use builtin      qw[ export_lexically ];

use Acktor::Event;
use Acktor::Props;
use Acktor::Logging ();

use Acktor::Behavior::Await;

sub import {
    export_lexically(
        '&await'    => \&await,
        '&event'    => \&event,
        '&spawn'    => \&spawn,
        '&context'  => \&context,
        '&sender'   => \&sender,
        '&logger'   => \&logger,
        '&actor_of' => \&actor_of,
    );
}

my %_receivers;
sub Acktor::FETCH_CODE_ATTRIBUTES  ($, $code) { $_receivers{ $code } }
sub Acktor::MODIFY_CODE_ATTRIBUTES ($, $code, @attrs) {
    #warn "HELLO $code => " . join ', ' => @attrs;
    grep { $_ !~ /^Receive/ }
    map  { $_receivers{ $code } = $_ if $_ =~ /^Receive/; $_; }
    @attrs;
}

our $CURRENT_ACTOR;
our $CURRENT_CONTEXT;
our $CURRENT_MESSAGE;

sub await ($symbol, $method) {
    $CURRENT_ACTOR // die 'Cannot call `await` outside of an active Acktor::Context';

    #warn "HELLO await: $method";

    #my @attrs = grep { $_ =~ /^Receive/ } grep defined, attributes::get($method);
    #use Data::Dumper;
    #warn Dumper \@attrs;
    #warn 'ATTRS: ', join ', ' => @attrs;

    #my ($symbol) = ($attrs[0] =~ /^Receive\((.*)\)$/);

    $CURRENT_ACTOR->become(
        Acktor::Behavior::Await->new(
            symbol   => $symbol,
            receiver => $method
        )
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
    $CURRENT_CONTEXT // die 'Cannot call `logger` outside of an active Acktor::Context';
    Acktor::Logging::logger( $CURRENT_CONTEXT )
}

sub spawn ($props) {
    my $c = $CURRENT_CONTEXT // die 'Cannot call `spawn` outside of an active Acktor::Context';
    $c->spawn( $props )
}

sub context {
    $CURRENT_CONTEXT // die 'Cannot call `context` outside of an active Acktor::Context';
}

sub sender {
    # it must at least be defined ...
    my $m = $CURRENT_MESSAGE // die 'Cannot call `sender` outside of an active Acktor::Context';
    return $m->context->self;
}

sub event ($symbol, @payload) {
    my $c = $CURRENT_CONTEXT // die 'Cannot create an event outside of an active Acktor::Context';
    Acktor::Event->new(
        symbol  => $symbol,
        payload => \@payload,
        context => $c
    );
}


__END__
