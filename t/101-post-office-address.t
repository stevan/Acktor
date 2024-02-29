#!perl

use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

use Data::Dumper;
use Test::More;

use Acktor::Remote::Address;

subtest '... simple' => sub {
    my $addr = Acktor::Remote::Address->new( address => '127.0.0.1:3000' );
    isa_ok($addr, 'Acktor::Remote::Address');

    is($addr->address, '127.0.0.1:3000', '... got the expected address');
    is($addr->host, '127.0.0.1', '... got the expected host');
    is($addr->port, '3000', '... got the expected port');

    is($addr->pid, undef, '... got the expected pid');

    is_deeply(
        $addr->pack,
        '127.0.0.1:3000',
        '... got the expected packed address'
    );
};

subtest '... simple' => sub {
    my $addr = Acktor::Remote::Address->new( address => 'foo@127.0.0.1:3000' );
    isa_ok($addr, 'Acktor::Remote::Address');

    is($addr->address, 'foo@127.0.0.1:3000', '... got the expected address');
    is($addr->host, '127.0.0.1', '... got the expected host');
    is($addr->port, '3000', '... got the expected port');

    is($addr->pid, 'foo', '... got the expected pid');

    is_deeply(
        $addr->pack,
        'foo@127.0.0.1:3000',
        '... got the expected packed address'
    );
};

subtest '... simple' => sub {
    my $addr = Acktor::Remote::Address->new( host => '127.0.0.1', port => '3000' );
    isa_ok($addr, 'Acktor::Remote::Address');

    is($addr->address, '127.0.0.1:3000', '... got the expected address');
    is($addr->host, '127.0.0.1', '... got the expected host');
    is($addr->port, '3000', '... got the expected port');

    is($addr->pid, undef, '... got the expected pid');

    is_deeply(
        $addr->pack,
        '127.0.0.1:3000',
        '... got the expected packed address'
    );
};

subtest '... simple' => sub {
    my $addr = Acktor::Remote::Address->new( pid => 'foo', host => '127.0.0.1', port => '3000' );
    isa_ok($addr, 'Acktor::Remote::Address');

    is($addr->address, 'foo@127.0.0.1:3000', '... got the expected address');
    is($addr->host, '127.0.0.1', '... got the expected host');
    is($addr->port, '3000', '... got the expected port');
    is($addr->pid, 'foo', '... got the expected pid');

    is_deeply(
        $addr->pack,
        'foo@127.0.0.1:3000',
        '... got the expected packed address'
    );
};


subtest '... simple' => sub {
    my $addr = Acktor::Remote::Address->new( port => '3000' );
    isa_ok($addr, 'Acktor::Remote::Address');

    is($addr->address, '127.0.0.1:3000', '... got the expected address');
    is($addr->host, '127.0.0.1', '... got the expected host');
    is($addr->port, '3000', '... got the expected port');

    is($addr->pid, undef, '... got the expected pid');

    is_deeply(
        $addr->pack,
        '127.0.0.1:3000',
        '... got the expected packed address'
    );
};

subtest '... simple' => sub {
    my $addr = Acktor::Remote::Address->new( pid => 'foo', port => '3000' );
    isa_ok($addr, 'Acktor::Remote::Address');

    is($addr->address, 'foo@127.0.0.1:3000', '... got the expected address');
    is($addr->host, '127.0.0.1', '... got the expected host');
    is($addr->port, '3000', '... got the expected port');
    is($addr->pid, 'foo', '... got the expected pid');

    is_deeply(
        $addr->pack,
        'foo@127.0.0.1:3000',
        '... got the expected packed address'
    );
};

subtest '... simple' => sub {
    my $addr = Acktor::Remote::Address->new( address => '0002:Echo@127.0.0.1:3001' );
    isa_ok($addr, 'Acktor::Remote::Address');

    is($addr->address, '0002:Echo@127.0.0.1:3001', '... got the expected address');
    is($addr->host, '127.0.0.1', '... got the expected host');
    is($addr->port, '3001', '... got the expected port');
    is($addr->pid, '0002:Echo', '... got the expected pid');

    is_deeply(
        $addr->pack,
        '0002:Echo@127.0.0.1:3001',
        '... got the expected packed address'
    );
};

subtest '... simple' => sub {
    my $addr = Acktor::Remote::Address->new( address => '0002:Echo::This::Package@127.0.0.1:3001' );
    isa_ok($addr, 'Acktor::Remote::Address');

    is($addr->address, '0002:Echo::This::Package@127.0.0.1:3001', '... got the expected address');
    is($addr->host, '127.0.0.1', '... got the expected host');
    is($addr->port, '3001', '... got the expected port');
    is($addr->pid, '0002:Echo::This::Package', '... got the expected pid');

    is_deeply(
        $addr->pack,
        '0002:Echo::This::Package@127.0.0.1:3001',
        '... got the expected packed address'
    );
};





done_testing;
