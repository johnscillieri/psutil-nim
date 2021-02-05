# cpu_count_logical

This function runs GetActiveProcesserCount with the argument ALL_PROCESSOR_GROUPS.
Which returns the number of active processors in the system.


# The function
```nim
proc cpu_count_logical*(): int = 
    return cast[int](GetActiveProcessorCount(ALL_PROCESSOR_GROUPS))

```