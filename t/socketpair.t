#!/usr/bin/perl
# pipe2 - bidirectional communication using socketpair
#   "the best ones always go both ways"

use v5.36;
use Socket;
use IO::Handle;  # enable autoflush method before Perl 5.14

# We say AF_UNIX because although *_LOCAL is the
# POSIX 1003.1g form of the constant, many machines
# still don't have it.
socketpair(my $child, my $parent, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
                            ||  die "socketpair: $!";

$child->autoflush(1);
$parent->autoflush(1);

warn $$;

my $pid;
if ($pid = fork()) {
    close $parent;
    print $child "Parent Pid $$ is sending this\n";
    chomp(my $line = <$child>);
    print "Parent Pid $$ just read this: '$line'\n";
    close $child;
    waitpid($pid, 0);
} else {
    die "cannot fork: $!" unless defined $pid;
    close $child;
    chomp(my $line = <$parent>);
    print "Child Pid $$ just read this: '$line'\n";
    print $parent "Child Pid $$ is sending this\n";
    close $parent;
    exit(0);
}
