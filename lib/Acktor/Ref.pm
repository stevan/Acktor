
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr   ];

use Acktor::Message;

class Acktor::Ref {
    field $context :param;

    ADJUST {
        $context->assign_self($self);
    }

    method pid     { refaddr $self }
    method context { $context      }

    method send ($body, $from=undef) {
        $context->send(Acktor::Message->new( to => $self, from => $from, body => $body ));
    }
}

__END__
