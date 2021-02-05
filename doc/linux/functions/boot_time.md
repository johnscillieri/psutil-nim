# boot_time

boot_time returns the system boot time expressed in seconds since the epoch (time of boot), Integer type

# The function
```nim
proc boot_time*(): int =
    ## Return the system boot time expressed in seconds since the epoch, Integer type.
    let stat_path = PROCFS_PATH / "stat"
    for line in stat_path.lines:
        if line.strip.startswith("btime"):
            return line.strip.split()[1].parseInt()

    raise newException(OSError, "line 'btime' not found in $1" % stat_path)
```