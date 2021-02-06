# try_pid_users

try_pid_users will return a sequence of strings (users), corresponding to the pids specified, but
instead of raising an exception if an exception occurs for any of the pids. The result will be "" for the corresponding pid.

# The function
```nim
proc try_pid_users*(pids: seq[int]): seq[string] =

    ## Function for getting users of specified pids
    for pid in pids:
        result.add(try_pid_user(pid))
```