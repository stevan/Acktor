
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

class Acktor::Future::Future {
    field $context   :param;

    field $result;
    field $resolved = false;
    field @resolved;

    method result { $result }

    method is_in_progress { ! $resolved }
    method is_resolved    {   $resolved }

    my sub wrap ($p, $then) {
        return sub ($value) {
            my ($result, $error);
            try {
                $result = $then->( $value );
            } catch ($e) {
                chomp $e;
                $error = $e;
            }

            if ($error) {
                warn $error;
                $p->resolve( $error );
            }

            if ( $result isa Acktor::Future::Future ) {
                #warn "GOT PROMISE RESULT $result";
                $result->then(
                    sub {
                        #warn "Resolving PROMISE RESULT ($result) for P($p)";
                        $p->resolve(@_); () }
                );
            }
            else {
                $p->resolve( $result );
            }
            return;
        };
    }

    method then ($handler) {
        my $p = $self->new( context => $context );
        push @resolved => wrap( $p, $handler );
        $self->_notify unless $self->is_in_progress;
        $p;
    }

    method when (%handlers) {
        $self->then(sub ($e) {
            # XXX - catch errors ...
            return $handlers{ $e->symbol }->( $e->payload->@* )
        });
    }

    method resolve ($_result) {
        #warn "resolve $self";
        $self->is_in_progress || die "Cannot resolve again, already resolved";
        $result = $_result;
        $resolved = true;
        $self->_notify;
        $self;
    }

    method _notify {

        my ($value, @cbs);

        if ($self->is_resolved) {
            $value = $result;
            @cbs   = @resolved;
        }
        else {
            die "Bad Notify State, not resolved ($self)";
        }

        @resolved = ();

        #warn "SCHEDULING $self";
        $context->dispatcher->scheduler->schedule_callback(sub {
            #warn "$self => STATUS: $status";

            # FIXME: this should be here, but it needs to
            # be here to allow use of context within the
            # then/catch block. If this is not here then
            # it will throw an error
            local $Acktor::Behaviors::CURRENT_CONTEXT = $context;
            #warn "HELLO! ($value)" . join ', ' => @cbs;
            foreach my $cb (@cbs) {
                #warn "Calling $cb with ($value)";
                $cb->($value)
            }
        });
    }


}

__END__

=pod

=cut


