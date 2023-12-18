
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr   ];

class Acktor::System::Init :isa(Acktor) {
    field $init :param;

    method receive($ctx, $message) {
        $init->($ctx);
    }
}


__END__
