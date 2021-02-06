# DiskIO

# The type
```nim
type DiskIO* = object of RootObj
    read_count*: int
    write_count*: int
    read_bytes*: int
    write_bytes*: int
    read_time*: int
    write_time*: int
    when defined(linux):
        read_merged_count*: int
        write_merged_count*: int
        busy_time*: int
```

# Information

read_count  : amount read
write_count : amount written
read_bytes  : amount of bytes read
write_bytes : amount of byte written
