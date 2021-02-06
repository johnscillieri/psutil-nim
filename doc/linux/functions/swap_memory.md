# swap_memory

This function will return a SwapMemory type. 
Which holds information regarding system swap memory.

# The function
```nim
proc swap_memory*(): SwapMemory =
    var si: SysInfo
    if sysinfo( si ) == -1:
        echo( "Error calling sysinfo in swap_memory(): ", errno )
        return

    let total = si.totalswap * si.mem_unit
    let free = si.freeswap * si.mem_unit
    let used = total - free
    let percent = usage_percent(used.int, total.int, places=1)

    result = SwapMemory( total:total.int, used:used.int, free:free.int,
                         percent:percent, sin:0, sout:0 )

    # try to get pgin/pgouts
    if not existsFile( PROCFS_PATH / "vmstat" ):
        # see https://github.com/giampaolo/psutil/issues/722
        echo( "'sin' and 'sout' swap memory stats couldn't be determined ",
              "and were set to 0" )
        return result

    for line in lines( PROCFS_PATH / "vmstat" ):
        # values are expressed in 4 kilo bytes, we want bytes instead
        if line.startswith("pswpin"):
            result.sin = parseInt(line.split()[1]) * 4 * 1024
        elif line.startswith("pswpout"):
            result.sout = parseInt(line.split()[1]) * 4 * 1024
        if result.sin != 0 and result.sout != 0:
            return result

    # we might get here when dealing with exotic Linux flavors, see:
    # https://github.com/giampaolo/psutil/issues/313
    echo( "'sin' and 'sout' swap memory stats couldn't be determined ",
            "and were set to 0" )

```

# The type

- [SwapMemory](../types/SwapMemory.md)