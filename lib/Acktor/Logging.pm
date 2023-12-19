package Acktor::Logging;
use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr   ];

use constant LOG_LEVEL => $ENV{ACKTOR_DEBUG} ? 4 : ($ENV{ACKTOR_LOG} // 0);

use constant INFO  => (LOG_LEVEL >= 1 ? 1 : 0);
use constant WARN  => (LOG_LEVEL >= 2 ? 2 : 0);
use constant ERROR => (LOG_LEVEL >= 3 ? 3 : 0);
use constant DEBUG => (LOG_LEVEL >= 4 ? 4 : 0);

use Exporter 'import';

our @EXPORT = qw[
    DEBUG
    INFO
    WARN
    ERROR

    LOG_LEVEL

    logger
];

use Acktor::Logging::Logger;

sub logger ($ctx=undef) {
    state $default = Acktor::Logging::Logger->new;
    state %to_ctx;

    return $default unless $ctx;
    return $to_ctx{ refaddr $ctx } //= Acktor::Logging::Logger->new( target => $ctx->self->pid );
}

__END__
