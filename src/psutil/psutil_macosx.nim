import posix
import times except Time

const
    CTL_KERN = 1
    KERN_BOOTTIME = 21

type Timeval = object
    tv_sec*: Time
    tv_usec*: int32

proc sysctl(x: ptr array[0..3, cint], y: cint, z: pointer,
            a: var csize, b: pointer, c: int): cint {.
            importc: "sysctl", nodecl.}

proc boot_time*(): int =
    ## Return the system boot time expressed in seconds since the epoch, Integer type.
    var
        mib: array[0..3, cint]
        boot_time: Time
        len: csize
        r: Timeval
    mib[0] = CTL_KERN
    mib[1] = KERN_BOOTTIME
    len = sizeof(r)
    if sysctl(addr(mib), 2, addr(r), len, nil, 0) == -1:
        raise newException(OSError,"")
    boot_time = (Time)r.tv_sec
    return boot_time.int

proc uptime*(): int =
    ## Return the system uptime expressed in seconds, Integer type.
    times.epochTime().int - boot_time()

when isMainModule:
    echo boot_time()
    echo uptime()
