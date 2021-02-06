# pid_exists

pid_exists returns a boolean which is true if the given pid (integer) exists on the system else false.

# The function
```nim
proc pid_exists*( pid: int ): bool =
    ## Check For the existence of a unix pid

    let exists = psutil_posix.pid_exists( pid )
    if not exists: return false

    try:
        # Note: already checked that this is faster than using a regular expr.
        # Also (a lot) faster than doing "return pid in pids()"
        let status_path = PROCFS_PATH / $pid / "status"
        for line in status_path.lines:
            if line.startswith( "Tgid:" ):
                let tgid = parseInt( line.split()[1] )
                return tgid == pid

        raise newException(OSError, "Tgid line not found in " & status_path)
    except:
        return pid in pids()
```
