# pid_parents

pid_parents will attempt to get the parent pids of the corresponding pids specified, and return them as a sequence of integers.

# The function
```nim
proc pid_parents*(pids: seq[int]): seq[int] =

    ## Function for getting the parent pids of the corresponding pids specified.
    for pid in pids:
        result.add(pid_parent(pid))
```