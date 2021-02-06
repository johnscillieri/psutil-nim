# try_pid_user

try_pid_user will attempt to get the user running the specified pid, but instead of raising an 
exception if it fails. It'll simply return ""

# The function
```nim
proc try_pid_user*(pid: int): string =
    
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
        result = ""
    else:
        result = $pws.pw_name
```