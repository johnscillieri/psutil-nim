# pids_cmdline

pids_cmdline returns a sequence of strings. Each string being the command the pid is run as.

# The function
```nim
proc pids_cmdline*(pids: seq[int]): seq[string] =

    ## function for getting the cmdline of a sequence of pids
    ## this gets path of command and arguments
    var ret: seq[string]
    for pid in pids:
        ret.add(pid_cmdline(pid))
```