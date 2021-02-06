# try_pid_path

try_pid_path will return the path of the exe (string) of the running pid, but instead of raising an exception the result would be "" if and exception occurs.

# The function
```nim
proc try_pid_path*(pid: int): string =

    var processHandle: HANDLE
    var filename: array[MAX_PATH, char]
    var dwSize = MAX_PATH

    processHandle = OpenProcess(cast[DWORD](PROCESS_QUERY_INFORMATION or PROCESS_VM_READ), FALSE, 
        cast[DWORD](pid))
    defer: CloseHandle(processHandle)

    if processHandle.addr != nil or processHandle == cast[HANDLE](1) or processHandle == cast[HANDLE](NULL):

        if QueryFullProcessImageNameA(processHandle, cast[DWORD](0), filename, cast[PDWORD](dwSize.addr)) == FALSE:
            
            result = ""

        else:

            var ret: string
            for c in filename:
                if cast[char](c) == '\0':
                    break

                ret.add(cast[char](c))
            
            return ret

    else:

        result = ""
```