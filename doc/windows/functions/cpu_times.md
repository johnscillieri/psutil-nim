# cpu_times

cpu_times retrieves system CPU timing information.
On a multiprocessor system, the values returned are the
sum of the designated times across all processors.

# The function

```nim
proc cpu_times*(): CPUTimes = 
    ## Retrieves system CPU timing information . On a multiprocessor system, 
    ## the values returned are the
    ## sum of the designated times across all processors.

    var idle_time: FILETIME
    var kernel_time: FILETIME
    var user_time: FILETIME
    
    if GetSystemTimes(addr idle_time, addr kernel_time, addr user_time).bool == false:
        raiseError()

    let idle = (HI_T * idle_time.dwHighDateTime.float) + (LO_T * idle_time.dwLowDateTime.float)
    let user = (HI_T * user_time.dwHighDateTime.float) + (LO_T * user_time.dwLowDateTime.float)
    let kernel = (HI_T * kernel_time.dwHighDateTime.float) + (LO_T * kernel_time.dwLowDateTime.float)

    # Kernel time includes idle time.
    # We return only busy kernel time subtracting idle time from kernel time.
    let system = kernel - idle
    
    # Internally, GetSystemTimes() is used, and it doesn't return interrupt and dpc times. 
    # per_cpu_times() does, so we rely on it to get those only.
    let per_times = per_cpu_times()
    let interrupt_sum = sum(per_times.mapIt(it.interrupt))
    let dpc_sum = sum(per_times.mapIt(it.dpc))
    return CPUTimes(user:user, system:system, idle:idle, interrupt:interrupt_sum, dpc:dpc_sum)
```

# The type

- [CPUTimes](../types/CPUTimes.md)