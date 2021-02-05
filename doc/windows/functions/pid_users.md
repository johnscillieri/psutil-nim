# pid_users

pid_users will return a sequence of strings (users), corresponding to the pids specified

Note: an exception will be raised if an error occurs for any of the pids specified.
If you don't want this, then look at the try_pid_users function.

- [try_pid_users]("./try_pid_users.md")
- 
# The function
```nim
proc pid_users*(pids: seq[int]): seq[string] =

    ## Function for getting a sequence of users
    for pid in pids:
        result.add(pid_user(pid))
```