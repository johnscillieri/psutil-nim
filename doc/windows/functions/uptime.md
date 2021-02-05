# uptime

uptime the system uptime expressed in seconds, Integer type.

# The function
```nim
proc uptime*(): int =
    ## Return the system uptime expressed in seconds, Integer type.
    int(GetTickCount64().float / 1000.float)
```