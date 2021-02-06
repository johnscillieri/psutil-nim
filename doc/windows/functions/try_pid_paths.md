# try_pid_paths

try_pid_paths returns a sequence of strings. Each string being the path to the corresponding pid in the sequence of integers (pids) given, but instead of raising an exception if an exception occurs for any of the pids, the result will instead be "" for the corresponding pid in the specified sequence.

# The function
```nim
proc try_pid_paths*(pid: seq[int]): seq[string] =

    ## Function to return the paths of the exes (sequence of strings) of the running pids.
    for pid in pids:
        result.add(try_pid_path(pid)) 
```