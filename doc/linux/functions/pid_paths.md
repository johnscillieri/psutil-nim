# pid_paths

pid_paths will attempt to get the elf path for each of the specified pids and return the paths as a sequence of strings. 

Note: This will raise an exception if this fails for any of the specified pids. If you don't want an error to be raised then look at try_pid_paths

- [try_pid_paths](./try_pid_paths.md)

# The function
```nim
proc pid_paths*(pids: seq[int]): seq[string] =

    ## Function for getting the elf paths of the specified pids
    for pid in pids:
        result.add(pid_path(pid))
```