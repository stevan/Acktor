
## Receive attribute

Currently we just check for it when the event is received. We need to do a pre-check
to build a map of event-symbols accepted -> methods.

We also need to parse so we can do `:Receive(Some::Event)` and dispatch accordingly.

## Implement Interval Timers

Think about this more.

```ruby

    $ctx->schedule(
        event => event( *Hello::Goodbye => "Cruel World" ),
        for   => $hello,
        after => 2,
    );

    $ctx->schedule(
        event => event( *Hello::Goodbye => "Cruel World" ),
        for   => $hello,
        every => 2,
    );

```


# Await Blocks

Here in this example we have the `await` function, which will have the affect of changing the
behavior of the system, to just be a receiver of the given event. After receiving this response
it will revert back to the previous behavior.

It effectively blocks that instance until the right symbol arrives. Any other messages will
result in an error.


```ruby

class HTTPServer :isa(Acktor) {
    use Acktor::Behaviors;

    method Request :Receive ($method, $url) {
        sender->send( event *Response => '200 OK' );
    }
}

class HTTPClient :isa(Acktor) {
    use Acktor::Behaviors;

    field $server;

    method Request :Receive ($url) {

        $server->send( event *HTTPServer::Request => ( GET => $url ) );

        await method :Receive(HTTPServer::Response) ($body) {
            ...
        };
    }
}


$client->send(
    event *HTTPClient::Request, ('http://www.google.com')
);


```

# Protocols

Add protocols, that create the event symbols and use the `Receive` attribute to direct messages to
a given method.

```ruby

class HTTP {
    use Acktor::Protocol;

    event *Request;
    event *Response;
}

class HTTPServer :isa(Acktor) {
    use Acktor::Behaviors;

    method Request :Receive(HTTP::Request) ($method, $url) {
        sender->send( event *HTTP::Response => '200 OK' );
    }
}

class HTTPClient :isa(Acktor) {
    use Acktor::Behaviors;

    field $server;

    method Get :Receive ($url) {

        $server->send( event *HTTP::Request => ( GET => $url ) );

        await method :Receive(HTTP::Response) ($body) {
            ...
        };
    }
}


$client->send(
    event *HTTPClient::Get, ('http://www.google.com')
);

```

An example of an `await` that takes multiple different cases and will handle them accordingly. Not 100% sure this is workable, but it is a sketch. One issue is that with a single case `await` (like above) the reverseal (`unbecome`) is
obvious. In this it would need to be manual.

```ruby

class HTTPClient :isa(Acktor) {
    use Acktor::Behaviors;

    field $server;

    method Request :Receive ($url) {

        $server->send( event *HTTP::Request => ( GET => $url ) );

        await { timeout => 10 },
            method :Receive(HTTP::Response) ($body) {
                # ... handle the body, after which we go back to
            },
            method :Receive(HTTPClient::Request) ($url) {
                # ... and buffer any of those incoming requests
            },
            method :Receive(Timeout) {
                # timeout!
            }
        ;
    }
}

```

# Futures

Whereas `await` blocks the actor and only accepts the expected event, which is not always desireable. The `future` keyword would, behind the scenes, create a Future Actor instance, whcih would get the response, and call the callbacks which are set with `is_done`, etc.

THe advantage of the `future` is that it does not affect the actors state. Whereas `await` affects the state of the instance.

```ruby

class HTTPClient :isa(Acktor) {
    use Acktor::Behaviors;

    field $server;

    method Request :Receive ($url) {

        my $f = future[*HTTP::Response] => (
            to    => $server,
            event => event( *HTTP::Request => ( GET => $url ) ),
        );

        $f->is_done(method { ... })
          ->is_error(method { ... })
          ->timeout(5)
          ->go; # or something else to say "start this future"
    }
}



```

# https://proto.actor/docs/futures/

# https://soft.vub.ac.be/amop/at/tutorial/actors#futures
# https://en.wikipedia.org/wiki/Futures_and_promises#Semantics_of_futures_in_the_actor_model
# https://docs.oracle.com/en/java/javase/19/docs/api/java.base/java/util/concurrent/Future.html


<!---------------------------------------------------------------------------->
# TODO
<!---------------------------------------------------------------------------->

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
