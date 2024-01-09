#!perl

use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

use Data::Dumper;
use Test::More;

use Acktor;
use Acktor::System;
use Acktor::Tools;

class Service :isa(Acktor) {
    method Request ($op, $x, $y) {
        sender->send(event *Client::Response => (
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

    method Call ($op, $x, $y) {
        unless ($service) {
            $service = context->lookup('service');
            isa_ok($service, 'Acktor::Ref');
            is($service->props->class, 'Service', '... the Actor lookup gave us the expected class');
        }
        $service->send( event *Service::Request => ( $op, $x, $y ) );
    }

    method Response ($value) {
        logger->log( INFO, "value($value)") if INFO;
        $RESPONSE = $value;
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
}

my $system = Acktor::System->new;
isa_ok($system, 'Acktor::System');

$system->loop( init => \&init );

is($Client::RESPONSE, 20, '... got the expected response');

done_testing;


