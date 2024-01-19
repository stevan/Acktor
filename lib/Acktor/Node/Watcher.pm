
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

class Acktor::Node::Watcher {

    field $reading = false;
    field $writing = false;

    method is_reading :lvalue { $reading }
    method is_writing :lvalue { $writing }

    # socket access and preparation

    method init_socket;
    method socket;

    # read/write events

    method handle_read  ($node) { ... }
    method handle_write ($node) { ... }

    # socket info

    method address      { join ":" => grep defined, map { $_->sockhost, $_->sockport } $self->socket }
    method peer_address { join ":" => grep defined, map { $_->peerhost, $_->peerport } $self->socket }
}
