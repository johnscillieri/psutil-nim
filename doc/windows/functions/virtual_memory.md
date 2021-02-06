# virtual_memory

This function will return type VirtualMemory which contains information on the virtual memory of the 
system

# The function

```nim
proc virtual_memory*(): VirtualMemory = 
    ## System virtual memory
    var memInfo: MEMORYSTATUSEX
    memInfo.dwLength = sizeof(MEMORYSTATUSEX).DWORD

    if GlobalMemoryStatusEx( addr memInfo ) == 0:
        raiseError()

    let used = int(memInfo.ullTotalPhys - memInfo.ullAvailPhys)
    let percent =  usage_percent( used, memInfo.ullTotalPhys.int, places=1 )
    return VirtualMemory( total: memInfo.ullTotalPhys.int,      
                          avail: memInfo.ullAvailPhys.int,      
                          percent: percent,  
                          used: used,
                          free: memInfo.ullAvailPhys.int )

```

# The type

- [VirtualMemory](../types/VirtualMemory.md)
