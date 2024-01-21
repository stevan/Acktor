
# Behaviors DSL

`use Acktor::Behaviors;`

This will export all the stuff Acktor::Tools exports, but do it into the package instead.
It will also add a `:Receive` attribute for the methods, which can be tracked by the
`Acktor::Behavior::Method` class to only allow the calling of those methods.


```
class Pong :isa(Acktor) {
    use Acktor::Behaviors;

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
    use Acktor::Behaviors;

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
            context->stop(context->self);
        }
    }
}
```

# Receive Blocks

Here in this example we have the `receive` function, which will have the affect of changing the
behavior of the system, to just be a receiver of the given event. After receiving this response
it will revert back to the previous behavior.

```
class Greeter :isa(Acktor) {
    use Acktor::Behaviors;

    method Greet :Receive ($greeting) {
        sender->send( event *Response, 'Greetings!' );
    }
}

class HelloWorld :isa(Acktor) {
    use Acktor::Behaviors;

    method SayHello :Receive {
        $ping->send( event *Greeter::Greet, 'Hello' );

        receive[*Greeter::Response] => sub ($ctx, $message) {
            # TODO ????
        };
    }
}
```



<!---------------------------------------------------------------------------->
# TODO
<!---------------------------------------------------------------------------->

## Implement Behaviors

- make them stacked, so that it is possible to change behavior
    - normal behavior is to use the same
        - but can use some kind of `become` function to change
    - but you can replace it with a `recieve` block to await a response
        - this could be how to handle "Futures"

## Re-Add the RemoteMailbox/PostOffice stuff

- get it from the history
    - it is completely broken
        - but the theory is sound
    - re-add it and make it work

- NOTE: this should help answer some questions about where to
  take the watchers stuff.

## Implement Node connection protocol

>   Node1 = perl start-note.pl --at 3000
>   Node2 = perl start-node.pl --at 3001 --connect 3000
>
>   Node2
>       - connects to Node1
>
>   Node1
>       - accepts connection from Node2
>           - sends WelcomeMessage to Node2
>
>   Node2
>       - reads WelcomeMessage
>           - sends WelcomeResponse to Node1
>
>   Node1
>       - reach WelcomeResponse
>           - sends WelcomeRepsonse to Node2
>
>   WelcomeMessage
>       - container sender for response
>
>   WelcomeResponse
>       - contains list of important PIDs and their addresses

## Implement Watchers

- in progress

## Implement Timers

- this is part of the integration of the Watchers

<!---------------------------------------------------------------------------->
# TODO (examples)
<!---------------------------------------------------------------------------->

- Make a distributed Hash Table
    - https://www.youtube.com/watch?v=1QdKhNpsj8M&ab_channel=number0

<!---------------------------------------------------------------------------->
# TO ADD (MAYBE)
<!---------------------------------------------------------------------------->

- Protocols for cross Process communication
    - Spawn
    - Send
    - Lookup
    - Identify

- Singals
    https://github.com/akka/akka/blob/v2.8.5/akka-actor-typed/src/main/scala/akka/actor/typed/MessageAndSignals.scala
    - for system messages
        - PreRestart  - sent to Actor right before it is restarted
        - PostStop    - fired after the Actor, and all it's children are terminated
        - Terminated  - sent after PostStop to all watchers of this Actor
        - ChildFailed - the child Actor has failed permanently

<!---------------------------------------------------------------------------->
# Dependency Diagram
<!---------------------------------------------------------------------------->

```
Legend:
   % = map of objects
   @ = list of objects
   > = circular reference
  >> = many circular refs
<..> = The code you write


System
    Dispatcher
        Scheduler
            @Callbacks
            %MailBox
                <Actor>
                @Messages
                Ref
                    Props
                    Context
                        >Dispatcher
                        >Ref
                        >>(parent/children)


```
