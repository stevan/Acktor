#!perl

use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

use Data::Dumper;
use Test::More;

use Acktor;
use Acktor::System;
use Acktor::Behaviors;

class Service :isa(Acktor) {
    use Acktor::Logging;

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

class Client :isa(Acktor) {
    use Acktor::Logging;
    use Test::More;

    our $RESPONSE;

    field $service;

    method Call :Receive ($op, $x, $y) {
        unless ($service) {
            $service = context->lookup('service');
            isa_ok($service, 'Acktor::Ref');
            is($service->props->class, 'Service', '... the Actor lookup gave us the expected class');
        }

        logger->log( INFO, "Sending Service request ... ($op, $x, $y)") if INFO;
        $service->send( event *Service::Request => ( $op, $x, $y ) );

        await *Service::Response => method ($value) {
            logger->log( INFO, "Got Response($value)") if INFO;
            $RESPONSE = $value;

            # tail call ;)
            context->self->send( event *Client::Call => add => $value, $value )
                if $value < 100;
        };

        logger->log( INFO, "Awaiting response ...") if INFO;
    }
}

sub init ($ctx) {
    my $Service = spawn( actor_of(*Service::, alias => 'service'));

    isa_ok($Service, 'Acktor::Ref');
    is($Service->props->class, 'Service', '... the Actor is of the expected class');

    my $Client  = spawn( actor_of(*Client:: ));

    isa_ok($Client, 'Acktor::Ref');
    is($Client->props->class, 'Client', '... the Actor is of the expected class');

    $Client->send( event *Client::Call => add => 10, 10 );
    #$Client->send( event *Client::Call => add => 10, 15 );
}

my $system = Acktor::System->new;
isa_ok($system, 'Acktor::System');

$system->run( init => \&init );

is($Client::RESPONSE, 160, '... got the expected response');

done_testing;


