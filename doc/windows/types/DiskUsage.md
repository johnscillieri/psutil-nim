# DiskUsage

DiskUsage is a type that holds information regarding disk usage on specified path

# The type

```nim
type DiskUsage* = object of RootObj
    total*: int
    used*: int
    free*:int
    percent*: float
```

# Information

total   : the amount of disk on specified path
used    : the amount of used disk space on specified path
free    : the amount of free disk space on the specified path
percent : percent of disk used on specified path

# Functions

- [disk_usage](../functions/disk_usage.md)