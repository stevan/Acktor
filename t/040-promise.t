#!perl

use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

use Data::Dumper;
use Test::More;

use Acktor;
use Acktor::System;
use Acktor::Logging;
use Acktor::Behaviors;

use Acktor::Future::Promise;

# ...

class Service :isa(Acktor) {
    use Acktor::Logging;

    method Response; # TODO : protocols
    method Error;

    method Request :Receive ($action, $args, $promise) {
        logger->log( INFO, "Got Client request ... ($action, @$args, $promise)") if INFO;

        my ($x, $y) = @$args;
        try {
            $promise->resolve(
                event *Response => (
                    ($action eq 'add') ? ($x + $y) :
                    ($action eq 'sub') ? ($x - $y) :
                    ($action eq 'mul') ? ($x * $y) :
                    ($action eq 'div') ? ($x / $y) :
                    die "Invalid Action: $action"
                )
            );
            logger->log( INFO, "Promise resolved!" ) if INFO;
        } catch ($e) {
            chomp $e;
            logger->log( INFO, "Error running service: $e" ) if INFO;
            $promise->reject( event *Error, $e );
        }
    }
}


sub init ($ctx) {

    my $Service = spawn Props[Service::];
    isa_ok($Service, 'Acktor::Ref');

    my $promise = Acktor::Future::Promise->new( scheduler => $ctx->dispatcher->scheduler );
    isa_ok($promise, 'Acktor::Future::Promise');

    $Service->send( event *Service::Request => ( add => [ 2, 2 ], $promise ) );

    $promise->then(
        sub ($result) {
            logger($ctx)->log( INFO, "... promise resolved!" ) if INFO;

            isa_ok($result, 'Acktor::Event');

            is($result->symbol, *Service::Response, '... got the expected result type');

            my ($val) = $result->payload->@*;
            is($val, 4, '... got the expected result');
        },
        sub ($error)  {
            logger($ctx)->log( INFO, "... promise rejected!" ) if INFO;

            isa_ok($error, 'Acktor::Event');

            is($error->symbol, *Service::Error, '... got the expected error type');

            my ($err) = $error->payload->@*;

            fail('... got an unexpected error: '.$err);
        },
    )

}

# -----------------------------------------------------------------------------
# Lets-ago!
# -----------------------------------------------------------------------------

my $system = Acktor::System->new;
isa_ok($system, 'Acktor::System');

$system->run( init => \&init );

done_testing();








