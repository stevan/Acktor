








<!---------------------------------------------------------------------------->
# TODO
<!---------------------------------------------------------------------------->

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

<!---------------------------------------------------------------------------->
# Remoting
<!---------------------------------------------------------------------------->

What is the PostOffice for??

## Implement Watchers

- in progress

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

<!---------------------------------------------------------------------------->
# Await Blocks
<!---------------------------------------------------------------------------->

Make await blocks support two things:

- multiple event cases
- timeouts (which are delivered as messages to the block)

This means we need to manage the timeout, so we have to cancel if we get a match.

- also decide how Timeout events will look.
    - do we use strings?
    - known constant (ex: `*Acktor::Timers::Timeout`)?
    - import a known constant so you can say `*Timeout`
    - is this a case for Protocols?

```ruby
use Acktor::Behaviors;

class HTTPServer :isa(Acktor) {

    method Request :Receive ($method, $url) {
        sender->send( event *Response => '200 OK' );
    }
}

class HTTPClient :isa(Acktor) {

    field $server;

    method Request :Receive ($url) {

        $server->send( event *HTTP::Request => ( GET => $url ) );

        await { timeout => 10 },
            *HTTPServer::Response => method :Receive ($body) {
                # ... handle the body
            },
            'Timeout' => method :Receive {
                # timeout!
            }
        ;
    }
}


$client->send(
    event *HTTPClient::Request, ('http://www.google.com')
);


```

Would love it if it could be this:

```ruby

class HTTPClient :isa(Acktor) {

    field $server;

    method Request :Receive ($url) {

        $server->send( event *HTTP::Request => ( GET => $url ) );

        await { timeout => 10 },
            method :Receive(*HTTPServer::Response) ($body) {
                # ... handle the body
            },
            method :Receive(*Timeout) {
                # timeout!
            }
        ;
    }
}


```

But the attributes do not work on methods at runtime, so that sucks.

<!---------------------------------------------------------------------------->
# Protocols
<!---------------------------------------------------------------------------->

Add protocols, that create the event symbols and use the `Receive` attribute to direct messages to
a given method.

```ruby

class Acktor::Protocol::HTTP {
    use Acktor::Protocol;

    event *Request;
    event *Response;
}

class HTTPServer :isa(Acktor) {
    use Acktor::Behaviors;
    use Acktor::Protocol => 'HTTP';

    method Request :Receive(*HTTP::Request) ($method, $url) {
        sender->send( event *HTTP::Response => '200 OK' );
    }
}

class HTTPClient :isa(Acktor) {
    use Acktor::Behaviors;
    use Acktor::Protocol => 'HTTP';

    field $server;

    method Get :Receive ($url) {

        $server->send( event *HTTP::Request => ( GET => $url ) );

        await *HTTP::Response => method :Receive ($body) {
            ...
        };
    }
}


$client->send(
    event *HTTPClient::Get, ('http://www.google.com')
);

```

<!---------------------------------------------------------------------------->
# TODO (examples)
<!---------------------------------------------------------------------------->

- Make a distributed Hash Table
    - https://www.youtube.com/watch?v=1QdKhNpsj8M&ab_channel=number0

<!---------------------------------------------------------------------------->
# TO ADD (MAYBE)
<!---------------------------------------------------------------------------->

# Futures

A future will return a promise (Thenable) that is connected to an Actor instance.
The Actor instance sends the message and awaits the result, assuming the actor
being called will respond to `sender`. When this actor instance gets a result, then
it resolves the promise it is attached to.

The advantage of this is that you can launch multiple futures at once, and then
collect them using the `collect` function turn them into a single promise.

Another advantage of the `future` is that it does not affect the actors state.
Whereas `await` affects the state of the instance via `become`.

```ruby

class HTTPClient :isa(Acktor) {
    use Acktor::Behaviors;

    field $server;

    method Request :Receive ($url) {

        my $f1 = future[*HTTP::Response] => (
            to     => $server,
            event  => event( *HTTP::Request => ( GET => $url1 ) ),
            timout => 3,
        );

        my $f2 = future[*HTTP::Response] => (
            to     => $server,
            event  => event( *HTTP::Request => ( GET => $url2 ) ),
            timout => 5,
        );

        # this is async, it does not block
        collect($f1, $f2)
            ->on_success(method ($results) { ... })
            ->on_error(method ($error)   { ... })
            ->on_timeout(method { ... });
    }
}



```

# https://proto.actor/docs/futures/

# https://soft.vub.ac.be/amop/at/tutorial/actors#futures
# https://en.wikipedia.org/wiki/Futures_and_promises#Semantics_of_futures_in_the_actor_model
# https://docs.oracle.com/en/java/javase/19/docs/api/java.base/java/util/concurrent/Future.html


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
