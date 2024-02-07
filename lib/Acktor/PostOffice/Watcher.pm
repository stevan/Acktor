
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

class Acktor::PostOffice::Watcher {

    field $address :param;
    field $socket  :param;

    field $reading = false;
    field $writing = false;

    ADJUST {
        $socket->autoflush(1);
        $socket->blocking(0);
    }

    method is_reading :lvalue { $reading }
    method is_writing :lvalue { $writing }

    # socket access
    method socket  { $socket  }
    method address { $address }

    # read/write events

    method handle_read  ($post_office) { ... }
    method handle_write ($post_office) { ... }

    # socket info

    method _address      { join ":" => grep defined, map { $_->sockhost, $_->sockport } $socket }
    method _peer_address { join ":" => grep defined, map { $_->peerhost, $_->peerport } $socket }
}
