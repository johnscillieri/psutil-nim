# disk_usage

This function returns a type DiskUsage.

# The function

```nim
proc disk_usage*( path: string ): DiskUsage =
    ## Return disk usage associated with path.
    var total, free: ULARGE_INTEGER
    
    let ret_code = GetDiskFreeSpaceExW( path, nil, addr total, addr free )
    if ret_code != 1: raiseError()

    let used = total.QuadPart - free.QuadPart
    let percent = usage_percent( used.int, total.QuadPart.int, places=1 )
    return DiskUsage( total:total.QuadPart.int, used:used.int,
                      free:free.QuadPart.int, percent:percent )
```

# The type

- [DiskUsage](../types/DiskUsage.md)