# pid_paths

pid_paths returns a sequence of strings. Each string being the path to the corresponding pid in the sequence of integers (pids) given.

Note: this will raise an exception if an exception occurs for any of the pids specified. 

# The function
```nim
proc pid_paths*(pids: seq[int]): seq[string] = 

    var ret: seq[string]
    for pid in pids:
        ret.add(pid_path(pid))

    return ret
```