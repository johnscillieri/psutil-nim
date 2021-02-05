# SwapMemory

SwapMemory is a type that hold information regarding swap memory on the system

# The type

```nim
type SwapMemory* = object of RootObj
    total*: int
    used*: int
    free*: int
    percent*: float
    sin*: int
    sout*: int
```

# Information

total   : total amount of swap memory on the system
used    : amount of swap memory used on the system
free    : amount of swap memory free on the system
percent : percent of swap memory being used on the system
sin     : unused
sout    : unused

# Functions

- [swap_memory](../functions/swap_memory.md)