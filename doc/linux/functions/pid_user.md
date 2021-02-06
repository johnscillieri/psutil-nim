# pid_user

pid_user will attempt to get the 

# The function
```nim
proc pid_user*(pid: int): string =
    
    ## Function for getting the username running the specified pid
    var p_path = PROCFS_PATH / $pid / "status"
    var uid = -1
    var data = p_path.readFile()
    for line in data.split("\n"):
        if "Uid:" in line:
            uid = parseInt(line.split("Uid:")[1].strip().split("\t")[0])
            debugEcho fmt"Uid: {uid}"

    var pws = getpwuid(cast[Uid](uid))
    if pws.isNil:
        raise newException(OSError, "UID $1 not found" % [$uid])
    result = $pws.pw_name
```