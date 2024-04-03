#!perl

use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

use Data::Dumper;
use Time::HiRes 'time';

use Acktor;
use Acktor::System;
use Acktor::Behaviors;
use Acktor::Logging;

class Window :isa(Acktor) {
    use Acktor::Logging;

    field $document;

    method AttachDocument :Receive ($d) {
        $document = $d;
    }

    sub render_tree ($ctx, $indent='') {
        my $tree = sprintf "%s+ %s\n" => $indent, $ctx->self;
        foreach my $child ($ctx->all_children) {
            $tree .= render_tree( $child->context, $indent.'  ' )
        }
        return $tree;
    }

    method ShowAcktorTree :Receive {
        logger->log(INFO, 'Showing Acktor Tree' ) if INFO;
        logger->log(INFO, render_tree( $document->context ) ) if INFO;
    }

    method Refresh :Receive {
        logger->log(INFO, 'Refreshing Window' ) if INFO;
        $document->send( event *Element::Render );
    }
}

class Element :isa(Acktor) {
    use Acktor::Logging;

    field $id       :param;
    field $cdata    :param = '';
    field $elements :param = [];

    ADJUST {
        if ( @$elements ) {
            logger->log(INFO, 'Got sub Elements') if INFO;
            foreach my $props (@$elements) {
                logger->log( INFO, "Adding (sub) Element($props)" ) if INFO;
                spawn $props;
            }
        }
    }

    method ElementAdded;

    method ElementFound;
    method ElementNotFound;

    method AddElement :Receive ($props) {
        logger->log( INFO, "Adding Element($props)" ) if INFO;
        sender->send( event *Element::ElementAdded => spawn $props );
    }

    method FindElementById :Receive ($id) {
        logger->log( INFO, "FindElementById($id)" ) if INFO;
        if (my $el = context->lookup( $id )) {
            sender->send( event *Element::ElementFound => $el );
        } else {
            sender->send( event *Element::ElementNotFound => $id );
        }
    }

    method Render :Receive ($indent='') {
        logger->log( INFO, sprintf '%s> Element[%s](%s)' => $indent, $id, $cdata ) if INFO;
        foreach my $e (context->all_children) {
            $e->send( event *Render => $indent.'  ' );
        }
    }
}

sub init ($ctx) {

    my $window   = spawn Props[ Window:: ];
    my $document = spawn Props[ Element::, (alias => '#root', id => 'root' )];

    $window->send( event *Window::AttachDocument => $document );

    $document->ask( event *Element::AddElement =>
        Props[ Element:: => ( alias => '#foo', id => 'foo', cdata => 'Foo!!' ) ]
    )->then(sub ($e) {
        my ($foo) = $e->payload->@*;
        $foo->ask( event *Element::AddElement =>
            Props[ Element:: => ( alias => '#bar', id => 'bar', cdata => 'Bar!!' ) ]
        );
    })->then(sub ($e) {
        my ($bar) = $e->payload->@*;

        $bar->ask( event *Element::AddElement =>
            Props[ Element:: => ( alias => '#baz', id => 'baz', cdata => 'Baz!!' ) ],
        );
    })->then(sub ($e) {
        $window->send( event *Window::ShowAcktorTree );
        $window->send( event *Window::Refresh );
    })->then(sub ($e) {
        $document->ask( event *Element::FindElementById => '#bar' );
    })->then(sub ($e) {
        my ($bar) = $e->payload->@*;

        $bar->ask( event *Element::AddElement =>
            Props[ Element:: => ( alias => '#gorch', id => 'gorch', cdata => 'Gorch!!' ) ],
        );
    })->then(sub ($e) {
        $window->send( event *Window::ShowAcktorTree );
        $window->send( event *Window::Refresh );
    })
}

my $system = Acktor::System->new;

$system->run( init => \&init );


__END__

my $e = Props[ Element:: => ( alias => '#foo', id => 'foo', cdata => 'Foo!!',
        elements => [
            Props[ Element:: => ( alias => '#bar',   id => 'bar',   cdata => 'Bar!!',
                elements => [
                    Props[ Element:: => ( alias => '#bork',    id => 'bork',    cdata => 'Bork!!'    ) ],
                    Props[ Element:: => ( alias => '#borg',    id => 'borg',    cdata => 'Borg!!'    ) ],
                    Props[ Element:: => ( alias => '#klingon', id => 'klingon', cdata => 'Klingon!!' ) ],
                ]
            )],
            Props[ Element:: => ( alias => '#baz',   id => 'baz',   cdata => 'Baz!!'   ) ],
            Props[ Element:: => ( alias => '#gorch', id => 'gorch', cdata => 'Gorch!!',
                elements => [
                    Props[ Element:: => ( alias => '#bling', id => 'bling', cdata => 'Bling!!' ) ],
                ]
            )],
        ]
    )];



