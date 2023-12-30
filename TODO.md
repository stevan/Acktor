# TODO

- Singals
    https://github.com/akka/akka/blob/v2.8.5/akka-actor-typed/src/main/scala/akka/actor/typed/MessageAndSignals.scala
    - for system messages
        - PreRestart  - sent to Actor right before it is restarted
        - PostStop    - fired after the Actor, and all it's children are terminated
        - Terminated  - sent after PostStop to all watchers of this Actor
        - ChildFailed - the child Actor has failed permanently

- Stopping
    - $ctx->stop($child);
    - $ctx->exit;

- Scheduler
    - for timers, etc.

- Watcher
    - for I/O

- Protocols for cross Process communication
    - Spawn
    - Send
    - Lookup
    - Identity

# NOTES:

- send "accidently" returns the Mailbox object the message was sent to
    - this could be fun
    - or this could be bad
    - and is this useful??


## Dependency Diagram

```
System
    PostOffice
        %Registered
            >Dispatcher
        @Letters
    Dispatcher
        %PID-MAILBOX
            MailBox
                <Actor>
                @Messages
                Ref
                    Context
                        Props
                        >Dispatcher
                        >Ref
                        >>(parent/children)
        >PostOffice
        Scheduler
            @Functions
            @Mailboxes

```
