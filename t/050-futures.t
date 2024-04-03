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
    method Error;    # TODO : protocols

    method Request :Receive ($op, $x, $y) {
        logger->log( INFO, "Got Client request ... ($op, $x, $y)") if INFO;
        sender->send(event *Response => (
            ($op eq 'add') ? $x + $y :
            ($op eq 'sub') ? $x - $y :
            ($op eq 'mul') ? $x * $y :
            ($op eq 'div') ? $x / $y :
            die 'Unsupported Operation'
        ));
    }
}


sub init ($ctx) {

    my $Service = spawn Props[Service::];
    isa_ok($Service, 'Acktor::Ref');

    my $promise = $Service->ask( event *Service::Request => ( add => 2, 2 ) );

    $promise->then(
        sub ($result) {
            logger($ctx)->log( INFO, "... promise resolved!" ) if INFO;
            isa_ok($result, 'Acktor::Event');
            is($result->symbol, *Service::Response, '... got the expected result type');
            my ($val) = $result->payload->@*;
            is($val, 4, '... got the expected result (4)');
        },
        sub ($error)  {
            logger($ctx)->log( INFO, "... promise rejected!" ) if INFO;
            isa_ok($error, 'Acktor::Event');
            is($error->symbol, *Service::Error, '... got the expected error type');
            my ($err) = $error->payload->@*;
            fail('... got an unexpected error: '.$err);
        }
    );

}

# -----------------------------------------------------------------------------
# Lets-ago!
# -----------------------------------------------------------------------------

my $system = Acktor::System->new;
isa_ok($system, 'Acktor::System');

$system->run( init => \&init );

done_testing();








