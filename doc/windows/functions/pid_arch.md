# pid_arch

This function returns an integer saying the architecture of the pid
PROCESS_ARCH_X64 is 64 bit
PROCESS_ARCH_X86 is 32 bit
PROCESS_ARCH_UNKNOWN if we can't get the architecture. (Permissions or other reasons)

# The function
```nim
proc pid_arch*(pid: int) : int =

    ## function for getting the architecture of the pid running
    var bIsWow64: BOOL
    var nativeArch = static PROCESS_ARCH_UNKNOWN
    var hProcess: HANDLE
    # var pIsWow64Process: ISWOW64PROCESS
    var dwPid = cast[DWORD](pid)
    # now we must default to an unknown architecture as the process may be either x86/x64 and we may not have the rights to open it
    result = PROCESS_ARCH_UNKNOWN

    ## grab the native systems architecture the first time we use this function we use this funciton.
    if nativeArch == PROCESS_ARCH_UNKNOWN:
        nativeArch = getnativearch()

   
    hProcess = OpenProcess(PROCESS_QUERY_INFORMATION, FALSE, dwPid)
    defer: CloseHandle(hProcess)
    if hProcess == cast[HANDLE](-1):
        hProcess = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, dwPid)
        if hProcess == cast[HANDLE](-1):
            raiseError()

    if IsWow64Process(hProcess, bIsWow64.addr) == FALSE:
        return

    if bIsWow64:
        result = PROCESS_ARCH_X86
    else:
        result = nativeArch
```