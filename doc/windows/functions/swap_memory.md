# swap_memory

This function will return a SwapMemory type. Which holds information regarding system swap memory 

# The function

```nim
proc swap_memory*(): SwapMemory = 
    ## Swap system memory as a (total, used, free, sin, sout)
    var memInfo: MEMORYSTATUSEX
    memInfo.dwLength = sizeof(MEMORYSTATUSEX).DWORD

    if GlobalMemoryStatusEx( addr memInfo ) == 0:
        raiseError()

    let total = memInfo.ullTotalPageFile.int
    let free = memInfo.ullAvailPageFile.int
    let used = total - free
    let percent = usage_percent(used, total, places=1)
    return SwapMemory(total:total, used:used, free:free, percent:percent, sin:0, sout:0)
```

# The type

- [SwapMemory](../types/SwapMemory.md)