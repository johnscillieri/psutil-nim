# pid_names


pid_names returns a sequence of strings (process names) for every given pid 
in the sequence pids.

* Note: please read carefully. pid_names is not pid_name

# The function
```nim
proc pid_names*(pids: seq[int]): seq[string] =
    ## Function for getting the process name of a sequence of pids
    ## not to be mmixed with pids_cmdline. This only gets the 
    ## program name. Not the path and arguments.
    var ret: seq[string]
    for pid in pids:
        ret.add(pid_name(pid))

    return ret
```