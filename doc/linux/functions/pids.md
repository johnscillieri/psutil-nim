# pids

pids returns a sequence of integers (PIDs) currently running on the system

Note: isnumber is defined in psutil_linux.nim

# The function
```nim
proc pids*(): seq[int] =
    ## Returns a list of PIDs currently running on the system.
    let all_files = toSeq( walkDir(PROCFS_PATH, relative=true) )

    return mapIt( filterIt( all_files, isnumber(it.path) ), parseInt( it.path ) )

```
