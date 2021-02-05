# pid_cmdline

pid_cmdline gets the command that the pid is ran as. Reads /proc/pid/cmdline

Note: linux only

# The function
```nim
proc pid_cmdline*(pid: int): string =

    ## Function for getting the cmdline of a pid
    ## this gets path of command and arguments
    
    let cmdline_path = PROCFS_PATH / $pid / "cmdline"
    return cmdline_path.readFile()
```