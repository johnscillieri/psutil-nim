# try_pid_user

try_pid_user will attempt to get the username running the specified pid, but if an exception occurs
it will return "". Instead of raising it.

# The function
```nim
proc try_pid_user*(pid: int): string =

    ## Attempt to get the username associated with the given pid.
    var hProcess: HANDLE
    var hToken: HANDLE
    var pUser: TOKEN_USER
    var peUse: SID_NAME_USE
    var dwUserLength = cast[DWORD](512)
    var dwDomainLength = cast[DWORD](0)
    var dwLength: DWORD
    var dwPid = cast[DWORD](pid)
    var wcUser: array[512, TCHAR]
    var wcDomain: array[512, TCHAR]


    hProcess = OpenProcess(PROCESS_QUERY_INFORMATION, FALSE, dwPid)
    defer: CloseHandle(hProcess)
    if hProcess == cast[DWORD](-1) or hProcess == cast[DWORD](NULL):
        return ""

    if OpenProcessToken(hProcess, TOKEN_QUERY, cast[PHANDLE](hToken.addr)) == FALSE:
        return ""

    defer: CloseHandle(hToken)

    if hToken == cast[HANDLE](-1) or hToken == cast[HANDLE](NULL):
        return ""

    ## Get required buffer size and allocate the TOKEN_USER buffer
    GetTokenInformation(hToken, tokenUser, cast[LPVOID](pUser.addr), cast[DWORD](0), cast[PDWORD](dwLength.addr))

    GetTokenInformation(hToken, tokenUser, pUser.addr, cast[DWORD](dwLength), cast[PDWORD](dwLength.addr))

    
    if LookupAccountSidW(cast[LPCWSTR](NULL), pUser.User.Sid, wcUser, dwUserLength.addr, wcDomain, dwDomainLength.addr, peUse.addr) == FALSE:
        return ""

    let user = wcUser[0..^1]
    var retu: string
    for c in user:
        if cast[char](c) != '\0': 
            retu.add(cast[char](c)) 
        else: 
            break

    return retu
```