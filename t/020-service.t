#!perl

use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

use Data::Dumper;
use Test::More;

use Acktor;
use Acktor::System;
use Acktor::Tools;

our $NUM_PROCESSES = $ARGV[0] // 10;
our $NUM_MESSAGES  = $ARGV[1] // 10;

our $START = time;
our $MSG_START;


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

    field $service;

    method Call ($op, $x, $y) {
        $service = context->lookup('service') unless $service;
        $service->send( event *Service::Request => ( $op, $x, $y ) );
    }

    method Response ($value) {
        logger->log( INFO, "value($value)") if INFO;
    }

}

sub init ($ctx) {
    my $Service = spawn( actor_of(*Service::, alias => 'service'));
    my $Client  = spawn( actor_of(*Client:: ));

    $Client->send( event *Client::Call => add => 10, 10 );
}

my $system = Acktor::System->new;

$system->loop( init => \&init );

done_testing;


