package Acktor::Behaviors;
use v5.38;
use experimental qw[ builtin ];
use builtin      qw[ export_lexically ];

use Sub::Util ();

use Acktor::Event;
use Acktor::Props;
use Acktor::Logging ();

use Acktor::Behavior::Await;
use Acktor::Behavior::Method;

use Acktor::Future::Future;

sub import {
    export_lexically(
        '&await'    => \&await,
        '&event'    => \&event,
        '&spawn'    => \&spawn,
        '&context'  => \&context,
        '&sender'   => \&sender,
        '&logger'   => \&logger,
        '&Props'    => \&Props,
        '&collect'  => \&collect
    );
}

## ----------------------------------------------------------------------------
## Behavior Factory
## ----------------------------------------------------------------------------

my %_attributes;
my %_methods;
sub Acktor::FETCH_CODE_ATTRIBUTES  ($pkg, $code) { $_attributes{ $pkg }{ $code } }
sub Acktor::MODIFY_CODE_ATTRIBUTES ($pkg, $code, @attrs) {
    grep { $_ !~ /^Receive/ }
    map  {
        if ($_ =~ /^Receive/) {
            $_attributes{ $pkg }{ $code } = $_;
            my $symbol;
            if ($_ =~ /^Receive\((.*)\)$/ ) {
                $symbol = $1;
            }
            else {
                $symbol = '*'.Sub::Util::subname( $code );
            }
            $_methods{ $pkg }{ $symbol } = $code;
        }
        $_;
    }
    @attrs;
}

my %_behaviors;
sub behavior_for ($, $class) {
    #use Data::Dumper;
    #warn Dumper {
    #    class      => $class,
    #    attributes => \%_attributes,
    #    methods    => \%_methods,
    #};

    $_behaviors{$class} //= Acktor::Behavior::Method->new(
        receivers => (
            $_methods{ $class }
                // die "No method receivers found for class($class)"
        )
    );
}

## ----------------------------------------------------------------------------
## DSL
## ----------------------------------------------------------------------------

our $CURRENT_ACTOR;
our $CURRENT_CONTEXT;
our $CURRENT_MESSAGE;

sub await :prototype($$) ($symbol, $method) {
    $CURRENT_ACTOR // die 'Cannot call `await` outside of an active Acktor::Context';

    $CURRENT_ACTOR->become(
        Acktor::Behavior::Await->new(
            symbol   => $symbol,
            receiver => $method
        )
    );
}

sub Props :prototype($) ($props) {

    my ($class, %args) = @$props;

    $class =~ s/^\*(main\:\:)?(.*)\:\:/$2/;

    my $alias = delete $args{alias};

    Acktor::Props->new(
        class => $class,
        (keys %args ? (args  => \%args) : ()),
        (    $alias ? (alias => $alias) : ()),
    );
}

sub logger ($ctx=undef) {
    $CURRENT_CONTEXT // $ctx // die 'Cannot call `logger` outside of an active Acktor::Context';
    Acktor::Logging::logger( $CURRENT_CONTEXT // $ctx )
}

sub spawn :prototype($) ($props) {
    my $c = $CURRENT_CONTEXT // die 'Cannot call `spawn` outside of an active Acktor::Context';
    $c->spawn( $props )
}

sub context :prototype() {
    $CURRENT_CONTEXT // die 'Cannot call `context` outside of an active Acktor::Context';
}

sub sender :prototype() {
    # it must at least be defined ...
    my $m = $CURRENT_MESSAGE // die 'Cannot call `sender` outside of an active Acktor::Context';
    return $m->context->self;
}

sub event :prototype($;@) ($symbol, @payload) {
    my $c = $CURRENT_CONTEXT // die 'Cannot create an event outside of an active Acktor::Context';
    Acktor::Event->new(
        symbol  => $symbol,
        payload => \@payload,
        context => $c
    );
}

sub collect (@futures) {
    my $c = $CURRENT_CONTEXT // die 'Cannot collect futures of an active Acktor::Context';

    my $collector = Acktor::Future::Future->new(
        context => $c
    )->resolve([]);

    foreach my $f ( @futures ) {
        my @results;
        $collector = $collector
            ->then(sub ($result) {
                #warn "hello from 1 for $p";
                #warn Dumper { p => "$p", state => 1, collector => [ @results ], result => $result };
                push @results => @$result;
                #warn Dumper { p => "$p", state => 1.5, collector => [ @results ] };
                $f;
            })
            ->then(sub ($result) {
                #warn "hello from 2 for $p";
                #warn Dumper { p => "$p", state => 2, collector => [ @results ], result => $result };
                my $r = [ @results, $result ];
                #warn Dumper { p => "$p", state => 2.5, collector => $r };
                return $r;
            });
    }

    return $collector;
}


__END__
