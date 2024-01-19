
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

class Acktor::Node::Watcher {

    field $reading  = false;
    field $writing = false;

    method is_reading :lvalue { $reading }
    method is_writing :lvalue { $writing }

    method init_socket;
    method socket;

    method handle_read  ($node) { ... }
    method handle_write ($node) { ... }
}
