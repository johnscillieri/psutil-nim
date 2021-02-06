# pid_exists

pid_exists returns a boolean which is true if the given pid exists, else false

# The function
```nim
proc pid_exists*(pid: int): bool =

    var p = OpenProcess(SYNCHRONIZE, FALSE, cast[DWORD](pid));
    var r = WaitForSingleObject(p, 0);
    CloseHandle(p);
    return r == WAIT_TIMEOUT
```