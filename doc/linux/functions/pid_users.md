# pid_users

pid_users will attempt to return the user running the corresponding pid, in the specified sequence, and return the users as a sequence of strings.

Note: If an exception occurs for any of the pids it will be raised. If you don't want this
look at try_pid_users

- [try_pid_users](./try_pid_users.md)


# The function
```nim
proc pid_users*(pids: seq[int]): seq[string] =

    for pid in pids:
        result.add(pid_user(pid))
```