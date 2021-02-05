# boot_time

boot_time returns the system boot time expressed in seconds since the epoch

# The function
```nim
proc boot_time*(): float = 
    ## Return the system boot time expressed in seconds since the epoch
    var fileTime : FILETIME
    GetSystemTimeAsFileTime(addr fileTime)

    let pt = toUnixTime(fileTime)
    let uptime = int(GetTickCount64()) / 1000
    
    return pt - uptime
```