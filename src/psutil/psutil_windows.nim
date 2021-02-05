{.deadCodeElim: on.}

import math
import sequtils
import strformat
import strutils
import tables

import winim except `&`

import common


var AF_PACKET* = -1
const LO_T = 1e-7
const HI_T = 429.4967296

# Make some constants for process architecture
const PROCESS_ARCH_UNKNOWN* = 0 # architecture is unknown
const PROCESS_ARCH_X86* = 1     # architecture is 32 bit
const PROCESS_ARCH_X64* = 2     # architecture is 64 bit

# The last 3 fields are unexposed traditionally so this has the potential
# to break in the future, but this is how psutil does it too. 
type SYSTEM_PROCESSOR_PERFORMANCE_INFORMATION* {.pure.} = object
    IdleTime*: LARGE_INTEGER
    KernelTime*: LARGE_INTEGER
    UserTime*: LARGE_INTEGER
    DpcTime*: LARGE_INTEGER
    InterruptTime*: LARGE_INTEGER
    InterruptCount*: ULONG


proc raiseError() = 
    var error_message: LPWSTR = newStringOfCap( 256 )
    let error_code = GetLastError()
    discard FormatMessageW( FORMAT_MESSAGE_FROM_SYSTEM, 
                            NULL, 
                            error_code,
                            MAKELANGID( LANG_NEUTRAL, SUBLANG_DEFAULT ).DWORD,
                            error_message, 
                            256, 
                            NULL )
    discard SetErrorMode( 0 )
    raise newException( OSError, "ERROR ($1): $2" % [$error_code, $error_message] )


proc psutil_get_drive_type*( drive_type: UINT ): string =
    case drive_type
        of DRIVE_FIXED: "fixed"
        of DRIVE_CDROM: "cdrom"
        of DRIVE_REMOVABLE: "removable"
        of DRIVE_UNKNOWN: "unknown"
        of DRIVE_NO_ROOT_DIR: "unmounted"
        of DRIVE_REMOTE: "remote"
        of DRIVE_RAMDISK: "ramdisk"
        else: "?"

proc psutil_get_drive_type*(drive: string): string =

    var drive_type = GetDriveTypeA(cast[LPCSTR](drive))
    case drive_type
        of DRIVE_FIXED: "fixed"
        of DRIVE_CDROM: "cdrom"
        of DRIVE_REMOVABLE: "removable"
        of DRIVE_UNKNOWN: "unknown"
        of DRIVE_NO_ROOT_DIR: "unmounted"
        of DRIVE_REMOTE: "remote"
        of DRIVE_RAMDISK: "ramdisk"
        else: "?"

proc getnativearch*(): int =
    ## Get the native architecture of the system we are running on
    var pGetNativeSystemInfo: SYSTEM_INFO
    var nativeArch = PROCESS_ARCH_UNKNOWN

    GetNativeSystemInfo(pGetNativeSystemInfo.addr)

    if pGetNativeSystemInfo.isNil:
        raiseError()

    
    case pGetNativeSystemInfo.union1.struct1.wProcessorArchitecture
        of PROCESSOR_ARCHITECTURE_AMD64:
            ## 64 bit (x64)
            # dwNativeArch = PROCESSOR_ARCHITECTURE_AMD64
            nativeArch = PROCESS_ARCH_X64
        
        of PROCESSOR_ARCHITECTURE_IA64:
            # dwNativeArch = PROCESSOR_ARCHITECTURE_IA64
            nativeArch = PROCESS_ARCH_X64
                            
        of PROCESSOR_ARCHITECTURE_INTEL:
            # 32 bit (x86)
            # dwNativeArch = PROCESSOR_ARCHITECTURE_INTEL
            nativeArch = PROCESS_ARCH_X64
            
        else:
            # dwNativeArch  = PROCESSOR_ARCHITECTURE_UNKNOWN
            nativeArch = PROCESS_ARCH_UNKNOWN

    return nativeArch
            

proc pids*(): seq[int] = 
    ## Returns a list of PIDs currently running on the system.
    result = newSeq[int]()

    var procArray: seq[DWORD]
    var procArrayLen = 0
    # Stores the byte size of the returned array from enumprocesses
    var enumReturnSz: DWORD = 0

    while enumReturnSz == DWORD( procArrayLen * sizeof(DWORD) ):
        procArrayLen += 1024
        procArray = newSeq[DWORD](procArrayLen)

        if EnumProcesses( addr procArray[0], 
                          DWORD( procArrayLen * sizeof(DWORD) ), 
                          addr enumReturnSz ) == 0:
            raiseError()
            return result

    # The number of elements is the returned size / size of each element
    let numberOfReturnedPIDs = int( int(enumReturnSz) / sizeof(DWORD) )
    for i in 0..<numberOfReturnedPIDs:
        result.add( procArray[i].int )

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

    else:
        CloseHandle(hProcess)
        raiseError()

    # Release the handle to the process.

    CloseHandle( hProcess )

    # return the process name
    var ret: string
    for c in szProcessName:
        if cast[char](c) == '\0':
            break

        ret.add(cast[char](c))
        
    return ret

proc pid_names*(pids: seq[int]): seq[string] =

    #[
        function for getting the process name of pid
    ]#
    var ret: seq[string]
    for pid in pids:
        ret.add(pid_name(pid))

    return ret

proc pid_path*(pid: int): string =

    var processHandle: HANDLE
    var filename: array[MAX_PATH, char]
    var dwSize = MAX_PATH

    processHandle = OpenProcess(cast[DWORD](PROCESS_QUERY_INFORMATION or PROCESS_VM_READ), FALSE, 
        cast[DWORD](pid))
    defer: CloseHandle(processHandle)

    if processHandle.addr != nil or processHandle == cast[HANDLE](1) or processHandle == cast[HANDLE](NULL):

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

proc pid_paths*(pids: seq[int]): seq[string] = 

    var ret: seq[string]
    for pid in pids:
        ret.add(pid_path(pid))

    return ret

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

proc try_pid_paths*(pids: seq[int]): seq[string] =

    ## Function to return the paths of the exes (sequence of strings) of the running pids.
    for pid in pids:
        result.add(try_pid_path(pid)) 

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

proc pid_parents*(pids: seq[int]): seq[int] =

    var ret: seq[int]
    for pid in pids:
        ret.add(pid_parent(pid))

    return ret

proc pids_with_names*(): (seq[int], seq[string]) =

    ## Function for returning tuple of pids and names
    
    var pids_seq = pids()
    var names_seq = pid_names(pids_seq)

    return (pids_seq, names_seq)


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
    
proc pid_user*(pid: int): string =

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
        raiseError()

    if OpenProcessToken(hProcess, TOKEN_QUERY, cast[PHANDLE](hToken.addr)) == FALSE:
        raiseError()

    defer: CloseHandle(hToken)

    if hToken == cast[HANDLE](-1) or hToken == cast[HANDLE](NULL):
        raiseError()

    ## Get required buffer size and allocate the TOKEN_USER buffer
    GetTokenInformation(hToken, tokenUser, cast[LPVOID](pUser.addr), cast[DWORD](0), cast[PDWORD](dwLength.addr))

    GetTokenInformation(hToken, tokenUser, pUser.addr, cast[DWORD](dwLength), cast[PDWORD](dwLength.addr))

    
    if LookupAccountSidW(cast[LPCWSTR](NULL), pUser.User.Sid, wcUser, dwUserLength.addr, wcDomain, dwDomainLength.addr, peUse.addr) == FALSE:
        raiseError()

    let user = wcUser[0..^1]
    var retu: string
    for c in user:
        if cast[char](c) != '\0': 
            retu.add(cast[char](c)) 
        else: 
            break

    return retu

proc pid_users*(pids: seq[int]): seq[string] =

    ## Function for getting a sequence of users
    for pid in pids:
        result.add(pid_user(pid))


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


proc try_pid_users*(pids: seq[int]): seq[string] =

    ## Function for getting users of specified pids
    for pid in pids:
        result.add(try_pid_user(pid))

proc pid_domain*(pid: int): string =

    ## Attempt to get the domain associated with the given pid.
    var hProcess: HANDLE
    var hToken: HANDLE
    var pUser: TOKEN_USER
    var peUse: SID_NAME_USE
    var dwUserLength = cast[DWORD](512)
    var dwDomainLength = cast[DWORD](512)
    var dwLength: DWORD
    var dwPid = cast[DWORD](pid)
    var wcUser: array[512, TCHAR]
    var wcDomain: array[512, TCHAR]


    hProcess = OpenProcess(PROCESS_QUERY_INFORMATION, FALSE, dwPid)
    defer: CloseHandle(hProcess)
    if hProcess == cast[DWORD](-1) or hProcess == cast[DWORD](NULL):
        raiseError()

    if OpenProcessToken(hProcess, TOKEN_QUERY, cast[PHANDLE](hToken.addr)) == FALSE:
        raiseError()

    defer: CloseHandle(hToken)

    if hToken == cast[HANDLE](-1) or hToken == cast[HANDLE](NULL):
        raiseError()

    ## Get required buffer size and allocate the TOKEN_USER buffer
    GetTokenInformation(hToken, tokenUser, cast[LPVOID](pUser.addr), cast[DWORD](0), cast[PDWORD](dwLength.addr))

    GetTokenInformation(hToken, tokenUser, pUser.addr, cast[DWORD](dwLength), cast[PDWORD](dwLength.addr)) 
    
    if LookupAccountSidW(cast[LPCWSTR](NULL), pUser.User.Sid, wcUser, dwUserLength.addr, wcDomain, dwDomainLength.addr, peUse.addr) == FALSE:
        raiseError()

    let domain = wcDomain[0..^1]
    var retd: string
    for c in domain:

        if cast[char](c) != '\0': 
            retd.add(cast[char](c)) 
        else: 
            break

    return retd


proc pid_domain_user*(pid: int): (string, string) =

    ## Attempt to get the domain and username associated with the given pid.
    var hProcess: HANDLE
    var hToken: HANDLE
    var pUser: TOKEN_USER
    var peUse: SID_NAME_USE
    var dwUserLength = cast[DWORD](512)
    var dwDomainLength = cast[DWORD](512)
    var dwLength: DWORD
    var dwPid = cast[DWORD](pid)
    var wcUser: array[512, TCHAR]
    var wcDomain: array[512, TCHAR]


    hProcess = OpenProcess(PROCESS_QUERY_INFORMATION, FALSE, dwPid)
    defer: CloseHandle(hProcess)
    if hProcess == cast[DWORD](-1) or hProcess == cast[DWORD](NULL):
        raiseError()

    if OpenProcessToken(hProcess, TOKEN_QUERY, cast[PHANDLE](hToken.addr)) == FALSE:
        raiseError()

    defer: CloseHandle(hToken)

    if hToken == cast[HANDLE](-1) or hToken == cast[HANDLE](NULL):
        raiseError()

    ## Get required buffer size and allocate the TOKEN_USER buffer
    GetTokenInformation(hToken, tokenUser, cast[LPVOID](pUser.addr), cast[DWORD](0), cast[PDWORD](dwLength.addr)) #== FALSE:
        # raiseError()

    GetTokenInformation(hToken, tokenUser, pUser.addr, cast[DWORD](dwLength), cast[PDWORD](dwLength.addr)) #== FALSE:
        # raiseError()
    
    if LookupAccountSidW(cast[LPCWSTR](NULL), pUser.User.Sid, wcUser, dwUserLength.addr, wcDomain, dwDomainLength.addr, peUse.addr) == FALSE:
        raiseError()

    let user = wcUser[0..^1]
    var retu: string
    for c in user:

        if cast[char](c) != '\0': 
            retu.add(cast[char](c)) 
        else: 
            break

    let domain = wcDomain[0..^1]
    var retd: string
    for c in domain:
        if cast[char](c) != '\0':
            retd.add(cast[char](c))
        else:
            break

    return (retd, retu)

proc disk_partitions*( all=false ): seq[DiskPartition] =
    result = newSeq[DiskPartition]()

    # avoid to visualize a message box in case something goes wrong
    # see https://github.com/giampaolo/psutil/issues/264
    discard SetErrorMode( SEM_FAILCRITICALERRORS )
    
    var drive_strings = newWString( 256 )
    let returned_len = GetLogicalDriveStringsW( 256, drive_strings )
    if returned_len == 0:
        raiseError()
        return
    
    let letters = split( strip( $drive_strings, chars={'\0'} ), '\0' )
    for drive_letter in letters:
        let drive_type = GetDriveType( drive_letter )

        # by default we only show hard drives and cd-roms
        if not all:
            if drive_type == DRIVE_UNKNOWN or
               drive_type == DRIVE_NO_ROOT_DIR or
               drive_type == DRIVE_REMOTE or
               drive_type == DRIVE_RAMDISK: continue

            # floppy disk: skip it by default as it introduces a considerable slowdown.
            if drive_type == DRIVE_REMOVABLE and drive_letter == "A:\\":
                continue


        var fs_type: LPWSTR = newString( 256 )
        var pflags: DWORD = 0
        var lpdl: LPCWSTR = drive_letter
        let gvi_ret = GetVolumeInformationW( lpdl,
                                             NULL,
                                             DWORD( drive_letter.len ),
                                             NULL,
                                             NULL,
                                             addr pflags,
                                             fs_type,
                                             DWORD( 256 ) )
        var opts = ""
        if gvi_ret == 0:
            # We might get here in case of a floppy hard drive, in
            # which case the error is ( 21, "device not ready").
            # Let's pretend it didn't happen as we already have
            # the drive name and type ('removable').
            SetLastError( 0 )
        else:
            opts = if ( pflags and FILE_READ_ONLY_VOLUME ) != 0: "ro" else: "rw"
            
            if ( pflags and FILE_VOLUME_IS_COMPRESSED ) != 0:
                opts &= ",compressed"
                    
        if len( opts ) > 0:
            opts &= ","
        opts &= psutil_get_drive_type( drive_type )
        
        result.add( DiskPartition( mountpoint: drive_letter,
                                   device: drive_letter,
                                   fstype: $fs_type, # either FAT, FAT32, NTFS, HPFS, CDFS, UDF or NWFS
                                   opts: opts ) )
        discard SetErrorMode( 0 )


proc disk_usage*( path: string ): DiskUsage =
    ## Return disk usage associated with path.
    var total, free: ULARGE_INTEGER
    
    let ret_code = GetDiskFreeSpaceExW( path, nil, addr total, addr free )
    if ret_code != 1: raiseError()

    let used = total.QuadPart - free.QuadPart
    let percent = usage_percent( used.int, total.QuadPart.int, places=1 )
    return DiskUsage( total:total.QuadPart.int, used:used.int,
                      free:free.QuadPart.int, percent:percent )


proc virtual_memory*(): VirtualMemory = 
    ## System virtual memory
    var memInfo: MEMORYSTATUSEX
    memInfo.dwLength = sizeof(MEMORYSTATUSEX).DWORD

    if GlobalMemoryStatusEx( addr memInfo ) == 0:
        raiseError()

    let used = int(memInfo.ullTotalPhys - memInfo.ullAvailPhys)
    let percent =  usage_percent( used, memInfo.ullTotalPhys.int, places=1 )
    return VirtualMemory( total: memInfo.ullTotalPhys.int,      
                          avail: memInfo.ullAvailPhys.int,      
                          percent: percent,  
                          used: used,
                          free: memInfo.ullAvailPhys.int )


proc swap_memory*(): SwapMemory = 
    ## Swap system memory as a (total, used, free, sin, sout)
    var memInfo: MEMORYSTATUSEX
    memInfo.dwLength = sizeof(MEMORYSTATUSEX).DWORD

    if GlobalMemoryStatusEx( addr memInfo ) == 0:
        raiseError()

    let total = memInfo.ullTotalPageFile.int
    let free = memInfo.ullAvailPageFile.int
    let used = total - free
    let percent = usage_percent(used, total, places=1)
    return SwapMemory(total:total, used:used, free:free, percent:percent, sin:0, sout:0)


proc toUnixTime(ft: FILETIME): float = 
    # HUGE thanks to:
    # http://johnstewien.spaces.live.com/blog/cns!E6885DB5CEBABBC8!831.entry
    # This function converts the FILETIME structure to the 32 bit
    # Unix time structure.
    # The time_t is a 32-bit value for the number of seconds since
    # January 1, 1970. A FILETIME is a 64-bit for the number of
    # 100-nanosecond periods since January 1, 1601. Convert by
    # subtracting the number of 100-nanosecond period between 01-01-1970
    # and 01-01-1601, from time_t then divide by 1e+7 to get to the same
    # base granularity.
    let ll = (int64(ft.dwHighDateTime) shl 32) + int64(ft.dwLowDateTime)
    result = int(ll - 116444736000000000) / 10000000


proc boot_time*(): float = 
    ## Return the system boot time expressed in seconds since the epoch
    var fileTime : FILETIME
    GetSystemTimeAsFileTime(addr fileTime)

    let pt = toUnixTime(fileTime)
    let uptime = int(GetTickCount64()) / 1000
    
    return pt - uptime


proc uptime*(): int =
    ## Return the system uptime expressed in seconds, Integer type.
    int(GetTickCount64().float / 1000.float)


proc per_cpu_times*(): seq[CPUTimes] = 
    ## Return system per-CPU times as a sequence of CPUTimes.
    
    let ncpus = GetActiveProcessorCount(ALL_PROCESSOR_GROUPS)
    if ncpus == 0:
        return result

    # allocates an array of _SYSTEM_PROCESSOR_PERFORMANCE_INFORMATION structures, one per processor
    var sppi = newSeq[SYSTEM_PROCESSOR_PERFORMANCE_INFORMATION](ncpus)
    let buffer_size = ULONG(ncpus * sizeof(SYSTEM_PROCESSOR_PERFORMANCE_INFORMATION))

    # gets cpu time informations
    let status = NtQuerySystemInformation(systemProcessorPerformanceInformation, addr sppi[0], buffer_size, NULL)
    if status != 0:
        raiseError()

    # computes system global times summing each processor value
    for i in 0 ..< ncpus:
        let user = (HI_T * sppi[i].UserTime.HighPart.float) +
                   (LO_T * sppi[i].UserTime.LowPart.float)
        let idle = (HI_T * sppi[i].IdleTime.HighPart.float) +
                   (LO_T * sppi[i].IdleTime.LowPart.float)
        let kernel = (HI_T * sppi[i].KernelTime.HighPart.float) +
                     (LO_T * sppi[i].KernelTime.LowPart.float)
        let interrupt = (HI_T * sppi[i].InterruptTime.HighPart.float) +
                        (LO_T * sppi[i].InterruptTime.LowPart.float)
        let dpc = (HI_T * sppi[i].DpcTime.HighPart.float) +
                  (LO_T * sppi[i].DpcTime.LowPart.float)

        # kernel time includes idle time on windows
        # we return only busy kernel time subtracting idle time from kernel time
        let system = kernel - idle

        result.add(CPUTimes(user:user, system:system, idle:idle, interrupt:interrupt, dpc:dpc))


proc cpu_times*(): CPUTimes = 
    ## Retrieves system CPU timing information . On a multiprocessor system, 
    ## the values returned are the
    ## sum of the designated times across all processors.

    var idle_time: FILETIME
    var kernel_time: FILETIME
    var user_time: FILETIME
    
    if GetSystemTimes(addr idle_time, addr kernel_time, addr user_time).bool == false:
        raiseError()

    let idle = (HI_T * idle_time.dwHighDateTime.float) + (LO_T * idle_time.dwLowDateTime.float)
    let user = (HI_T * user_time.dwHighDateTime.float) + (LO_T * user_time.dwLowDateTime.float)
    let kernel = (HI_T * kernel_time.dwHighDateTime.float) + (LO_T * kernel_time.dwLowDateTime.float)

    # Kernel time includes idle time.
    # We return only busy kernel time subtracting idle time from kernel time.
    let system = kernel - idle
    
    # Internally, GetSystemTimes() is used, and it doesn't return interrupt and dpc times. 
    # per_cpu_times() does, so we rely on it to get those only.
    let per_times = per_cpu_times()
    let interrupt_sum = sum(per_times.mapIt(it.interrupt))
    let dpc_sum = sum(per_times.mapIt(it.dpc))
    return CPUTimes(user:user, system:system, idle:idle, interrupt:interrupt_sum, dpc:dpc_sum)


proc cpu_count_logical*(): int = 
    return cast[int](GetActiveProcessorCount(ALL_PROCESSOR_GROUPS))


proc cpu_count_physical*(): int = 
    var length: DWORD = 0
    var rc = GetLogicalProcessorInformationEx(relationAll, NULL, addr length)

    var buffer = cast[PSYSTEM_LOGICAL_PROCESSOR_INFORMATION_EX](alloc0(length))
    rc = GetLogicalProcessorInformationEx(relationAll, buffer, addr length)

    if rc == 0:
        dealloc(buffer)
        raiseError()

    var currentPtr = buffer
    var offset = 0
    var prevProcessorInfoSize = 0
    while offset < length:
        # Advance ptr by the size of the previous SYSTEM_LOGICAL_PROCESSOR_INFORMATION_EX struct.
        currentPtr = cast[PSYSTEM_LOGICAL_PROCESSOR_INFORMATION_EX](cast[int](currentPtr) + prevProcessorInfoSize)

        if currentPtr.Relationship == relationProcessorCore:
            result += 1
        
        # When offset == length, we've reached the last processor info struct in the buffer.
        offset += currentPtr.Size
        prevProcessorInfoSize = currentPtr.Size
    
    dealloc(buffer)


type WTS_CONNECTSTATE_CLASS {.pure.} = enum 
    WTSActive,
    WTSConnected,
    WTSConnectQuery,
    WTSShadow,
    WTSDisconnected,
    WTSIdle,
    WTSListen,
    WTSReset,
    WTSDown,
    WTSInit


type WTS_SESSION_INFO = object
    sessionId: DWORD
    pWinStationName: LPWSTR 
    state: WTS_CONNECTSTATE_CLASS 


type PWTS_SESSION_INFO = ptr WTS_SESSION_INFO


type WTS_CLIENT_ADDRESS = object
    addressFamily: DWORD
    address: array[20, BYTE]


type PWTS_CLIENT_ADDRESS = ptr WTS_CLIENT_ADDRESS


const WTS_CURRENT_SERVER_HANDLE: HANDLE = 0 


type WTS_INFO_CLASS {.pure.} = enum
    WTSInitialProgram       = 0,
    WTSApplicationName      = 1,
    WTSWorkingDirectory     = 2,
    WTSOEMId                = 3,
    WTSSessionId            = 4,
    WTSUserName             = 5,
    WTSWinStationName       = 6,
    WTSDomainName           = 7,
    WTSConnectState         = 8,
    WTSClientBuildNumber    = 9,
    WTSClientName           = 10,
    WTSClientDirectory      = 11,
    WTSClientProductId      = 12,
    WTSClientHardwareId     = 13,
    WTSClientAddress        = 14,
    WTSClientDisplay        = 15,
    WTSClientProtocolType   = 16,
    WTSIdleTime             = 17,
    WTSLogonTime            = 18,
    WTSIncomingBytes        = 19,
    WTSOutgoingBytes        = 20,
    WTSIncomingFrames       = 21,
    WTSOutgoingFrames       = 22,
    WTSClientInfo           = 23,
    WTSSessionInfo          = 24


type WINSTATION_INFO_CLASS = enum  
    WinStationInformation = 8


type WINSTATION_INFO = object
    Reserved1: array[72, BYTE]
    SessionId: ULONG 
    Reserved2: array[4, BYTE]
    ConnectTime: FILETIME
    DisconnectTime: FILETIME 
    LastInputTime: FILETIME 
    LoginTime: FILETIME 
    Reserved3: array[1096, BYTE]
    CurrentTime: FILETIME 


proc WTSEnumerateSessionsW(
    hServer: HANDLE, 
    reserved: DWORD, 
    version: DWORD, 
    ppSessionInfo: ptr PWTS_SESSION_INFO, 
    pCount: PDWORD): WINBOOL {.winapi, stdcall, dynlib: "wtsapi32", importc.}


proc WTSQuerySessionInformationW(
    hServer: HANDLE, 
    sessionId: DWORD,
    wtsInfoClass: WTS_INFO_CLASS,
    ppBuffer: ptr LPWSTR,
    pBytesReturned: ptr DWORD): WINBOOL {.winapi, stdcall, dynlib: "wtsapi32", importc.}


proc WTSFreeMemory(pMemory: PVOID) {.winapi, stdcall, dynlib: "wtsapi32", importc.}


proc WinStationQueryInformation(
    serverHandle: HANDLE,
    sessionId: ULONG,
    winStationInformationClass: WINSTATION_INFO_CLASS,
    pWinStationInformation: ptr WINSTATION_INFO,
    winStationInformationLength: ULONG,
    pReturnLength: PULONG): BOOLEAN {.winapi, stdcall, dynlib: "winsta", importc: "WinStationQueryInformationW".}


proc getUserForSession(server: HANDLE, sessionId: DWORD): string = 
    var buffer_user: PWCHAR = NULL
    var bytes: DWORD = 0
    if WTSQuerySessionInformationW(WTS_CURRENT_SERVER_HANDLE, sessionId, WTSUserName, addr buffer_user, addr bytes) == 0:
        raiseError()
    
    if bytes <= 2:
        return ""

    result = $buffer_user

    WTSFreeMemory(buffer_user)


proc getAddressForSession(server: HANDLE, sessionId: DWORD): string = 
    var bytes: DWORD = 0
    var buffer_addr: LPWSTR = NULL
    if WTSQuerySessionInformationW(server, sessionId, WTS_INFO_CLASS.WTSClientAddress, addr buffer_addr, addr bytes) == 0:
        raiseError()

    let address = cast[PWTS_CLIENT_ADDRESS](buffer_addr).address
    let addressFamily = cast[PWTS_CLIENT_ADDRESS](buffer_addr).addressFamily

    if addressFamily == 0: 
        result = &"{address[0]}.{address[1]}.{address[2]}.{address[3]}"

    WTSFreeMemory(buffer_addr)


proc getLoginTimeForSession(server: HANDLE, sessionId: DWORD): float = 
    var station_info: WINSTATION_INFO
    var returnLen: ULONG
    if WinStationQueryInformation(server, sessionId, WinStationInformation, addr station_info, sizeof(station_info).ULONG, addr returnLen) == 0:
        return -1

    result = toUnixTime(station_info.ConnectTime)
    

proc users*(): seq[User] = 
    var count: DWORD = 0
    var sessions: PWTS_SESSION_INFO 
    if WTSEnumerateSessionsW(WTS_CURRENT_SERVER_HANDLE, 0, 1, addr sessions, addr count) == 0:
        raiseError()

    for i in 0 ..< count:
        let currentSession =  cast[PWTS_SESSION_INFO](cast[int](sessions) + (sizeof(WTS_SESSION_INFO)*i))
        let sessionId = currentSession.sessionId

        let user = getUserForSession(WTS_CURRENT_SERVER_HANDLE, sessionId)
        if user == "": continue

        let address = getAddressForSession(WTS_CURRENT_SERVER_HANDLE, sessionId)
        let login_time = getLoginTimeForSession(WTS_CURRENT_SERVER_HANDLE, sessionId)
        
        result.add(User(name:user, host:address, started:login_time))

    WTSFreeMemory(sessions)



## ToDo - These are all stubbed out so things compile. 
## It also shows what needs to be done for feature parity with Linux
proc cpu_stats*(): tuple[ctx_switches, interrupts, soft_interrupts, syscalls: int] = 
    raise newException( Exception, "Function is unimplemented!")

proc net_connections*( kind= "inet", pid= -1 ): seq[Connection] = 
    raise newException( Exception, "Function is unimplemented!")

proc net_if_addrs*(): Table[string, seq[common.Address]] = 
    raise newException( Exception, "Function is unimplemented!")

proc net_if_stats*(): TableRef[string, NICstats] = 
    raise newException( Exception, "Function is unimplemented!")

proc per_disk_io_counters*(): TableRef[string, DiskIO] = 
    raise newException( Exception, "Function is unimplemented!")

proc per_nic_net_io_counters*(): TableRef[string, NetIO] = 
    raise newException( Exception, "Function is unimplemented!")

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

proc pid_exists*(pid: int): bool =

    var p = OpenProcess(SYNCHRONIZE, FALSE, cast[DWORD](pid));
    var r = WaitForSingleObject(p, 0);
    CloseHandle(p);
    return r == WAIT_TIMEOUT



proc pid_cmdline*(pid: int): string = 
    raise newException( Exception, "Function is unimplemented!")
    

