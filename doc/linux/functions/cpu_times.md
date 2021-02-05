# cpu_times

cpu_times retrieves system CPU timing information.
On a multiprocessor system, the values returned are the
sum of the designated times across all processors.


# The function
```nim
proc cpu_times*(): CPUTimes =
    # Return a tuple representing the following system-wide CPU times:
    # (user, nice, system, idle, iowait, irq, softirq [steal, [guest,
    #  [guest_nice]]])
    # Last 3 fields may not be available on all Linux kernel versions.
    for line in lines( PROCFS_PATH / "stat" ):
        result = parse_cpu_time_line(line)
        break
```

# The type

- [CPUTimes](../types/CPUTimes.md)