#!perl

use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

use Data::Dumper;
use Test::More;
use Test::Differences;

use Acktor;
use Acktor::System;
use Acktor::Behaviors;

use Acktor::Streams::Publisher;
use Acktor::Streams::Sink;
use Acktor::Streams::Source;
use Acktor::Streams::Subscriber;
use Acktor::Streams::Subscription;
use Acktor::Streams::Subscription::Observer;

my $MAX_ITEMS = 17;

my $Source = Acktor::Streams::Source::FromGenerator->new(
    generator => sub {
        state $count = 0;
        return $count if ++$count <= $MAX_ITEMS;
        return;
    }
);

my @Sinks = (
    Acktor::Streams::Sink::ToBuffer->new,
    Acktor::Streams::Sink::ToBuffer->new,
    Acktor::Streams::Sink::ToCallback->new(
        callback => sub ($item, $marker) {
            state @sink;
            state $done;

            if ($marker == Acktor::Streams::Sink->DROP) {
                push @sink => $item unless $done;
            }
            elsif ($marker == Acktor::Streams::Sink->DONE) {
                $done++;
            }
            elsif ($marker == Acktor::Streams::Sink->DRAIN) {
                my @d = @sink;
                @sink = ();
                $done--;
                @d;
            }
            else {
                die "Unrecognized marker($marker)";
            }
        }
    )
);

# ...

sub init ($ctx) {

    my $publisher = spawn( actor_of Acktor::Streams::Publisher:: => ( source => $Source ) );

    my @subscribers = (
        spawn(
            actor_of Acktor::Streams::Subscriber:: => (
                request_size => 5,
                sink         => $Sinks[0]
            )
        ),
        spawn(
            actor_of Acktor::Streams::Subscriber:: => (
                request_size => 10,
                sink         => $Sinks[1]
            )
        ),
        spawn(
            actor_of Acktor::Streams::Subscriber:: => (
                request_size => 2,
                sink         => $Sinks[2]
            )
        ),
    );

    $publisher->send( event *Acktor::Streams::Publisher::Subscribe, $_  ) foreach @subscribers;
}

my $system = Acktor::System->new;
isa_ok($system, 'Acktor::System');

$system->run( init => \&init );

eq_or_diff(
    [ sort { $a <=> $b } ($Sinks[0]->drain, $Sinks[1]->drain, $Sinks[2]->drain) ],
    [ 1 .. 17 ],
    '... the sinks contrain the right items');


done_testing();

1;

__END__
