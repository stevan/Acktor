
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

class Acktor::PostOffice::ConnectionWatcher :isa(Acktor::IO::Watcher) {

    field $address :param;

    ADJUST {
        $self->fh isa IO::Socket:: || die 'ConnectionWatcher can only watch sockets';
    }

    # socket access
    method socket  { $self->fh }
    method address { $address  }

    # read/write events

    method handle_read  ($post_office) { ... }
    method handle_write ($post_office) { ... }

    # socket info

    method _address      { join ":" => grep defined, map { $_->sockhost, $_->sockport } $self->fh }
    method _peer_address { join ":" => grep defined, map { $_->peerhost, $_->peerport } $self->fh }
}
