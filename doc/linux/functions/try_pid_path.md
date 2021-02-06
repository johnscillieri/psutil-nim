# try_pid_path

try_pid_path will attempt to get the path of the elf of the running pid, but instead of raising
an exception upon error. It will instead return "".

# The function
```nim
proc try_pid_path*(pid: int): string =

    ## Function for getting the path of the elf of the running pid
    ## Note: Instead of raising an error. It will instread return ""
    var p_path: cstring = PROCFS_PATH / $pid / "exe"
    var buf: array[PATH_MAX, char]
    if readlink(p_path, buf, PATH_MAX) == -1:
        result = ""
    else:
        result = buf.join("").strip()
```