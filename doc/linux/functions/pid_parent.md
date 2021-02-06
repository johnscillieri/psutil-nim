# pid_parent

pid_parent will get the parent pid of the specified pid.

# The function
```nim
proc pid_parent*(pid: int): int =
    
    ## Function for getting the parent pid of the specified pid
    var p_path = PROCFS_PATH / $pid / "status"
    var data = p_path.readFile()
    for line in data.split("\n"):
        if "PPid:" in line:
            result = parseInt(line.split("PPid:")[^1].strip())

```