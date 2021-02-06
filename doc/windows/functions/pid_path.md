# pid_path

pid_path will return the path of the exe (string) of the running pid. 

# The function
```nim
proc pid_path*(pid: int): string =

    var processHandle: HANDLE
    var filename: array[MAX_PATH, char]
    var dwSize = MAX_PATH

    processHandle = OpenProcess(cast[DWORD](PROCESS_QUERY_INFORMATION or PROCESS_VM_READ), FALSE, 
        cast[DWORD](pid))
    defer: CloseHandle(processHandle)

    if processHandle.addr != nil:

        if QueryFullProcessImageNameA(processHandle, cast[DWORD](0), filename, cast[PDWORD](dwSize.addr)) == FALSE:
            
            raiseError()

        else:

            var ret: string
            for c in filename:
                if cast[char](c) == '\0':
                    break

                ret.add(cast[char](c))
            
            return ret

    else:

        raiseError()
```