# TODO

- add Exceptions
    - throw em all over the place

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
                        >Ref
                        >>(parent/children)
        >PostOffice
        Scheduler
            @Functions
            @Mailboxes

```
