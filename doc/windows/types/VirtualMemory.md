# VirtualMemory

VirtualMemory is a type that holds information regarding the systems virtual memory

# The type

```nim
type VirtualMemory* = object of RootObj
    total*: int
    avail*: int
    percent*: float
    used*: int
    free*: int
    active*: int
    inactive*: int
    buffers*: int
    cached*: int
    shared*: int
```

# Information

total       : total amount of virtual memory
avail       : total amount of available virtual memory
percent     : percent of virtual memory
used        : total amount of used virtual memory
free        : total amount of free virtual memory
active      : total amount of active virtual memory
inactive    : total amount of inactive virtual memory
buffers     : total amount of buffers in virtual memory
cached      : total amount of cached virtual memory
shared      : total amount of shared virtual memory

# Function

- [virtual_memory](../functions/virtual_memory.md)