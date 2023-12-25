# TODO

- Context
    - coordinated shutdown with recursive `stop`

- Registry
    - so Actors can have names
    - and know under which Process those names live
    - and can query/cache names from other Processes

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
    Dispatcher
        %PID-MAILBOX
            MailBox
                <Actor>
                Ref
                    Context
                        Props
                        >Dispatcher
                        >Mailbox
                        >Ref
                        >>(parent/children)
        >PostOffice
        Scheduler
            @Functions
            @Mailboxes

```
