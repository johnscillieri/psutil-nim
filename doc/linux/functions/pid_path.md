# pid_path

pid_path will attempt to get the link path of the specified pid. 

Note:  This will raise an exception if this fails. If you don't want this then look at 
try_pid_path

- [try_pid_path](./try_pid_path.md)

# The function
```nim
proc pid_path*(pid: int): string = 

    ## Function for getting the path of the elf of the running pid
    var p_path: cstring = PROCFS_PATH / $pid / "exe"
    var buf: array[PATH_MAX, char]
    if readlink(p_path, buf, PATH_MAX) == -1:
        raise newException(IOError, "Cannot read /proc/$1/exe | $2" % [$pid, $strerror(errno)])
    result = buf.join("").strip()
```