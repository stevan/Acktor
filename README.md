```fortran
__  __  _________        _    _
\ \ \ \ \______/ \______| | _| |_ ___  _ __
 \ \ \ \ \____/ _ \ / __| |/ / __/ _ \| '__|
 / / / / /___/ ___ \ (__|   <| || (_) | |
/_/ /_/ /___/_/   \_\___|_|\_\\__\___/|_|

```

## YAAAAAM4P

Yet Another Attempt At An Actor Model For Perl.

## Example

```ruby
use Acktor;
use Acktor::System;
use Acktor::Behaviors;

class Pong :isa(Acktor) {
    field $ping;

    method Start :Receive {
        $ping = sender;
        $ping->send( event *Ping::Ping, 0 );
    }

    method Pong :Receive ($count) {
        $ping->send( event *Ping::Ping, $count );
    }
}

class Ping :isa(Acktor) {
    field $max_bounce :param;
    field $pong;

    method Start :Receive {
        $pong = spawn( actor_of *Pong:: );
        $pong->send( event *Pong::Start );
    }

    method Ping :Receive ($count) {
        $count++;

        if ( $count <= $max_bounce ) {
            $pong->send( event *Pong::Pong, $count );
        } else {
            context->stop(context->self); # will stop $pong as well
        }
    }
}

sub init ($ctx) {
    my $Ping = spawn( actor_of *Ping::, ( max_bounce => 5 ) );
    $Ping->send( event *Ping::Start );
}

Acktor::System->new
              ->loop( init => \&init );
```
