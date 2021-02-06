# pid_parent

pid_parent returns the pid of the process that called the given pid. The processes that called the
given pid is the parent.

# The function
```nim
proc pid_parent*(pid: int): int =

    var h: HANDLE
    var pe: PROCESSENTRY32
    var ppid = cast[DWORD](0)
    pe.dwSize = cast[DWORD](sizeof(PROCESSENTRY32))
    h = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0)
    if Process32First(h, pe.addr):
        while Process32Next(h, pe.addr):
            if cast[int](pe.th32ParentProcessID) == pid:
                ppid = pe.th32ParentProcessID
                break
    
    CloseHandle(h);
    return cast[int](ppid)

```