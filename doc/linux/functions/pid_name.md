# pid_name

pid_name returns the process name of a pid. 

This is not the same as pid_name!!!
This function only gets the name of the process.
Not the path of the program, and arguments.
This reads and sanitizes /proc/pid/comm

# The function
```nim
proc pid_name*(pid: int): string =
    ## Function for getting the process name of a pid
    ## not to be mixed with pid_cmdline. This only gets the 
    ## program name. Not the path and arguments
    let p_path = PROCFS_PATH / $pid / "status"
    var data = p_path.readFile()
    for line in data.split("\n"):
        if "Name:" in line:
            var name = line.split("Name:")[1].strip()
            result = name
```