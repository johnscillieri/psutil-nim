# per_cpu_times

per_cpu_times returns system per-CPU times as a sequence of CPUTimes. CPUTimes holds information
regarding cpu times on the system

# The function
```nim
proc per_cpu_times*(): seq[CPUTimes] =
    ## Return a list of tuples representing the CPU times for every
    ## CPU available on the system.
    result = newSeq[CPUTimes]()
    for line in lines( PROCFS_PATH / "stat" ):
        if not line.startswith("cpu"): continue
        let entry = parse_cpu_time_line( line )
        result.add( entry )
    # get rid of the first line which refers to system wide CPU stats
    result.delete(0)
    return result
```

# The type

- [CPUTimes](../functions/per_cpu_times.md)