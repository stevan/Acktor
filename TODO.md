# TODO

- stop sequence
    - https://getakka.net/articles/actors/receive-actor-api.html#stopping-actors


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
  <! = I/O watcher
<..> = The code you write


System
    Dispatcher
        Scheduler
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
