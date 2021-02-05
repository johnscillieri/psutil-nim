# Users

User type holds information regarding users on the system

# The type
```nim
type User* = object
    name*: string
    terminal*: string
    host*: string
    started*: float
```

# Information

name        : The username
terminal    : unused
host        : address of session (like for RDP, ssh, etc.)
started     : the login time

# Functions

- [users](../functions/users.md)