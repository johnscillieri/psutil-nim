# process_exists

process_exists returns a boolean which returns true if the given processName is running, else false.

# Example

```nim
echo process_exists("cmd.exe")
```

# The function
```nim
proc process_exists*(processName: string): bool =

    var exists = false
    var entry: PROCESSENTRY32
    entry.dwSize = cast[DWORD](PROCESSENTRY32.sizeof)

    var snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0)

    if Process32First(snapshot, entry.addr):
        while Process32Next(snapshot, entry.addr):
            var name: string
            for c in entry.szExeFile:
                if cast[char](c) == '\0':
                    break

                name.add(cast[char](c))
            
            if name == processName:
                exists = true

    CloseHandle(snapshot)
    return exists
```