# per_cpu_times

per_cpu_times returns system per-CPU times as a sequence of CPUTimes. CPUTimes holds information
regarding cpu times on the system

# The function
```nim
proc per_cpu_times*(): seq[CPUTimes] = 
    ## Return system per-CPU times as a sequence of CPUTimes.
    
    let ncpus = GetActiveProcessorCount(ALL_PROCESSOR_GROUPS)
    if ncpus == 0:
        return result

    # allocates an array of _SYSTEM_PROCESSOR_PERFORMANCE_INFORMATION structures, one per processor
    var sppi = newSeq[SYSTEM_PROCESSOR_PERFORMANCE_INFORMATION](ncpus)
    let buffer_size = ULONG(ncpus * sizeof(SYSTEM_PROCESSOR_PERFORMANCE_INFORMATION))

    # gets cpu time informations
    let status = NtQuerySystemInformation(systemProcessorPerformanceInformation, addr sppi[0], buffer_size, NULL)
    if status != 0:
        raiseError()

    # computes system global times summing each processor value
    for i in 0 ..< ncpus:
        let user = (HI_T * sppi[i].UserTime.HighPart.float) +
                   (LO_T * sppi[i].UserTime.LowPart.float)
        let idle = (HI_T * sppi[i].IdleTime.HighPart.float) +
                   (LO_T * sppi[i].IdleTime.LowPart.float)
        let kernel = (HI_T * sppi[i].KernelTime.HighPart.float) +
                     (LO_T * sppi[i].KernelTime.LowPart.float)
        let interrupt = (HI_T * sppi[i].InterruptTime.HighPart.float) +
                        (LO_T * sppi[i].InterruptTime.LowPart.float)
        let dpc = (HI_T * sppi[i].DpcTime.HighPart.float) +
                  (LO_T * sppi[i].DpcTime.LowPart.float)

        # kernel time includes idle time on windows
        # we return only busy kernel time subtracting idle time from kernel time
        let system = kernel - idle

        result.add(CPUTimes(user:user, system:system, idle:idle, interrupt:interrupt, dpc:dpc))

```

# The type

- [CPUTimes](../functions/per_cpu_times.md)