#!perl

use v5.38;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];

use Data::Dumper;
use Test::More;

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

    my sub render_acktor_tree ($ctx, $indent='') {
        my $tree = sprintf "%s+ %s\n" => $indent, $ctx->self;
        foreach my $child ($ctx->all_children) {
            $tree .= __SUB__->( $child->context, $indent.'  ' )
        }
        return $tree;
    }

    method ShowAcktorTree :Receive {
        logger->log(INFO, 'Showing Acktor Tree' ) if INFO;
        logger->log(INFO, render_acktor_tree( $document->context ) ) if INFO;
    }

    method Refresh :Receive {
        logger->log(INFO, 'Refreshing Window' ) if INFO;
        $document->send( event *Element::Refresh );
    }
}

class Element :isa(Acktor) {
    use Acktor::Logging;

    field $id    :param;
    field $cdata :param = '';

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

    method Refresh :Receive ($indent='') {
        logger->log( INFO, sprintf '%s> Element[%s](%s)' => $indent, $id, $cdata ) if INFO;
        foreach my $e (context->all_children) {
            $e->send( event *Refresh => $indent.'  ' );
        }
    }
}

sub init ($ctx) {

    my $window   = spawn Props[ Window:: ];
    my $document = spawn Props[ Element::, (alias => '#root', id => 'root' )];

    $window->send( event *Window::AttachDocument => $document );

    $document->ask( event *Element::AddElement =>
        Props[ Element:: => ( alias => '#foo', id => 'foo', cdata => 'Foo!!' ) ]
    )->when(
        *Element::ElementAdded => sub ($foo) {
            $foo->ask( event *Element::AddElement =>
                Props[ Element:: => ( alias => '#bar', id => 'bar', cdata => 'Bar!!' ) ]
            )
        }
    )->when(
        *Element::ElementAdded => sub ($bar) {
            $bar->ask( event *Element::AddElement =>
                Props[ Element:: => ( alias => '#baz', id => 'baz', cdata => 'Baz!!' ) ],
            )
        }
    )->then(sub ($) {
        $window->send( event *Window::ShowAcktorTree );
        $document->ask( event *Element::FindElementById => '#foo' );
    })->when(
        *Element::ElementFound => sub ($bar) {
            $bar->ask( event *Element::AddElement =>
                Props[ Element:: => ( alias => '#gorch', id => 'gorch', cdata => 'Gorch!!' ) ],
            )
        },
        *Element::ElementNotFound => sub ($id) {
            logger->log( WARN, "Could not find Element with ID($id)" ) if WARN;
        }
    )->then(sub ($) {
        $window->send( event *Window::ShowAcktorTree );
        $window->send( event *Window::Refresh );
    });
}

my $system = Acktor::System->new;
isa_ok($system, 'Acktor::System');

$system->run( init => \&init );


done_testing;

__END__




