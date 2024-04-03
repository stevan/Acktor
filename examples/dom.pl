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

    method AddElement :Receive ($props) {
        logger->log( INFO, "Adding Element($props)" ) if INFO;
        spawn $props;
    }

    sub render_tree ($ctx, $indent='') {
        my $tree    = '';
        my $current = $ctx->self;

        $tree .= sprintf "%s+ %s\n" => $indent, $current;
        foreach my $child ($ctx->all_children) {
            $tree .= render_tree( $child->context, $indent.'  ' )
        }

        return $tree;
    }

    method Render :Receive {
        logger->log(INFO, render_tree( context ) ) if INFO;
    }
}

sub init ($ctx) {

    my $document = spawn Props[ Element::, (alias => '#root', id => 'root' ) ];

    $document->send(
        event *Element::AddElement => Props[
            Element:: => (
                alias => '#foo', id => 'foo', cdata => 'Foo!!',
                elements => [
                    Props[ Element:: => ( alias => '#bar',   id => 'bar',   cdata => 'Bar!!'   ) ],
                    Props[ Element:: => ( alias => '#baz',   id => 'baz',   cdata => 'Baz!!'   ) ],
                    Props[ Element:: => ( alias => '#gorch', id => 'gorch', cdata => 'Gorch!!',
                        elements => [
                            Props[ Element:: => ( alias => '#bling', id => 'bling', cdata => 'Bling!!' ) ],
                        ]
                    )],
                ]
            )
        ]
    );

    $document->send( event *Element::Render );

}

my $system = Acktor::System->new;

$system->run( init => \&init );




