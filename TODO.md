Node1 = perl start-note.pl --at 3000
Node2 = perl start-node.pl --at 3001 --connect 3000

Node2
    - connects to Node1

Node1
    - accepts connection from Node2
        - sends WelcomeMessage to Node2

Node2
    - reads WelcomeMessage
        - sends WelcomeResponse to Node1

Node1
    - reach WelcomeResponse
        - sends WelcomeRepsonse to Node2

WelcomeMessage
    - container sender for response

WelcomeResponse
    - contains list of important PIDs and their addresses



# TODO

- Make a distributed Hash Table
    - https://www.youtube.com/watch?v=1QdKhNpsj8M&ab_channel=number0

# TO ADD

- Scheduler
    - for timers, etc.

- Watcher
    - for I/O

- Protocols for cross Process communication
    - Spawn
    - Send
    - Lookup
    - Identity

- Singals
    https://github.com/akka/akka/blob/v2.8.5/akka-actor-typed/src/main/scala/akka/actor/typed/MessageAndSignals.scala
    - for system messages
        - PreRestart  - sent to Actor right before it is restarted
        - PostStop    - fired after the Actor, and all it's children are terminated
        - Terminated  - sent after PostStop to all watchers of this Actor
        - ChildFailed - the child Actor has failed permanently


## Dependency Diagram

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
