
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr   ];

class Acktor::Message {
    field $to   :param;
    field $from :param;
    field $body :param;

    method to   { $to   }
    method from { $from }
    method body { $body }
}

__END__
