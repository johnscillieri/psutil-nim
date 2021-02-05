# try_pid_users

try_pid_users will attempt to get the user running the corresponding pid in the specified sequence, but instead of raising an exception if failed. It'll instead return "" for the pid that failed.

# The function
```nim
proc try_pid_users*(pids: seq[int]): seq[string] =

    for pid in pids:
        result.add(try_pid_user(pid))
```