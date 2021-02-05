# pid_name

This function will return the process name of the given pid.
This is not the same as pid_name!!!
This function only gets the name of the process.
Not the path of the program, and arguments.
This reads and sanitizes /proc/pid/comm

# The function

```nim
proc pid_name*(processID: int): string =

    #[
        function for getting the process name of pid
    ]#
    var szProcessName: array[MAX_PATH, TCHAR]
    
    # szProcessName[0] = cast[TCHAR]("")

    #  Get a handle to the process.

    var hProcess = OpenProcess( cast[DWORD](PROCESS_QUERY_INFORMATION or PROCESS_VM_READ), FALSE, cast[DWORD](processID) )

    #  Get the process name.

    if hProcess.addr != nil:

        var hMod: HMODULE
        var cbNeeded: DWORD

        if EnumProcessModules( hProcess, hMod.addr, cast[DWORD](sizeof(hMod)), cbNeeded.addr):

            GetModuleBaseName( hProcess, hMod, szProcessName, 
                               cast[DWORD](szProcessName.len) )

    # Release the handle to the process.

    CloseHandle( hProcess )

    # return the process name
    var ret: string
    for c in szProcessName:
        if cast[char](c) == '\0':
            break

        ret.add(cast[char](c))
        
    return ret
```