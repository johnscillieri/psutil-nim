import posix, segfaults,tables
import times except Time
import common
import strutils

include "system/ansi_c"

template offset*[T](p: ptr T, count: int): ptr T =
    ## Offset a pointer to T by count elements. Behavior is undefined on
    ## overflow.
    
    # Actual behavior is wrapping, but this may be revised in the future to enable
    # better optimizations.
    
    # We turn off checking here - too large counts is UB
    {.checks: off.}
    let bytes = count * sizeof(T)
    cast[ptr T](offset(cast[pointer](p), bytes))

template offset*(p: pointer, bytes: int): pointer =
    ## Offset a memory address by a number of bytes. Behavior is undefined on
    ## overflow.
    # Actual behavior is wrapping, but this may be revised in the future to enable
    # better optimizations
    
    # We assume two's complement wrapping behaviour for `uint`
    cast[pointer](cast[uint](p) + cast[uint](bytes))

const
    CTL_KERN = 1.cint          #
    KERN_SUCCESS = 0           # mach/kern_return.h.
    CTL_VM = 2.cint
    KERN_BOOTTIME = 21.cint
    # host_statistics()
    HOST_LOAD_INFO = 1.cint    # System loading stats
    HOST_VM_INFO = 2.cint      # Virtual memory stats
    HOST_CPU_LOAD_INFO = 3     # CPU load stats

    # host_statistics64()
    HOST_VM_INFO64 = 4         # 64-bit virtual memory stats
    HOST_EXTMOD_INFO64 = 5     # External modification stats
    HOST_EXPIRED_TASK_INFO = 6 # Statistics for expired tasks


var CPU_STATE_MAX {.importc: "CPU_STATE_MAX", header: "<mach/machine.h>".}: cint
var CPU_STATE_USER {.importc: "CPU_STATE_USER",
        header: "<mach/machine.h>".}: cint
var CPU_STATE_NICE {.importc: "CPU_STATE_NICE",
        header: "<mach/machine.h>".}: cint
var CPU_STATE_SYSTEM {.importc: "CPU_STATE_SYSTEM",
        header: "<mach/machine.h>".}: cint
var CPU_STATE_IDLE {.importc: "CPU_STATE_IDLE",
        header: "<mach/machine.h>".}: cint
var CLK_TCK {.importc: "CLK_TCK", header: "<sys/time.h>".}: cdouble
var CTL_HW {.importc: "CTL_HW", header: "<sys/sysctl.h>".}: cint
var HW_NCPU {.importc: "HW_NCPU", header: "<sys/sysctl.h>".}: cint
var HW_AVAILCPU {.importc: "HW_AVAILCPU", header: "<sys/sysctl.h>".}: cint
var HW_MEMSIZE {.importc: "HW_MEMSIZE", header: "<sys/sysctl.h>".}: cint


type host_cpu_load_info_data_t {.importc: "host_cpu_load_info_data_t",
        header: "<mach/host_info.h>".} = object
    cpu_ticks*: array[0..3, cint] #limit to CPU_STATE_MAX but cant refer it as array length at compile time.

type Timeval = object
    tv_sec*: Time
    tv_usec*: int32
type host_info_t = ptr cint
type mach_port_t {.importc: "mach_port_t", header: "<mach/message.h>",
        nodecl.} = object
type mach_msg_type_number_t {.importc: "mach_msg_type_number_t",
        header: "<mach/message.h>", nodecl.} = object

type Vmmeter {.importc: "struct vmmeter", header: "<sys/vmmeter.h>",
        nodecl.} = object
    v_swtch: cint
    v_intr: cint
    v_soft: cint
    v_syscall: cint

type VmStatistics {.importc: "struct vm_statistics",
        header: "<mach/vm_statistics.h>", pure, incompleteStruct,
        nodecl.} = object # https://opensource.apple.com/source/xnu/xnu-3789.51.2/osfmk/mach/vm_statistics.h.auto.html
    free_count: cint        # of pages free
    active_count: cint      # of pages active
    inactive_count: cint    # of pages inactive
    wire_count: cint        # of pages wired down
    pageins: cint
    pageouts: cint
        #[
                            * NB: speculative pages are already accounted for in "free_count",
                            * so "speculative_count" is the number of "free" pages that are
                            * used to hold data that was read speculatively from disk but
                            * haven't actually been used by anyone so far.
                            *]#
    speculative_count: cint # of pages speculative
                            # type VmStatistics64 {.importc: "struct vm_statistics64", header: "<mach/vm_statistics64.h>", pure, incompleteStruct,nodecl.} = object
                            #     free_count:cint # of pages free
                            #     active_count:cint  # of pages active
                            #     inactive_count:cint # of pages inactive
                            #     wire_count:cint  # of pages wired down
                            #Used by all architectures
type vm_statistics_t = ptr VmStatistics
type vm_statistics_data_t = VmStatistics
type xsw_usage {.importc: "struct xsw_usage", header: "<sys/sysctl.h>",
        nodecl.} = object
    xsu_total: uint64
    xsu_avail: uint64
    xsu_used: uint64
    xsu_pagesize: uint32
    xsu_encrypted: bool

type fsid_t = object
    val:array[2,cint]

const MFSNAMELEN      = 15 # length of fs type name, not inc. nul */
const MNAMELEN        = 90 # length of buffer for returned name */
const MFSTYPENAMELEN  = 16 # length of fs type name including null */
const MAXPATHLEN      = 1024

type statfs {.importc: "struct statfs", header: "<sys/mount.h>",pure, incompleteStruct,nodecl.}  = object # {.importc: "struct statfs", header: "<sys/syscall.h>",pure,nodecl.}

    # https://linux.die.net/man/2/statfs
    f_bsize: clong
    f_iosize: clong
    f_blocks: clong
    f_bfree: clong
    f_bavail: clong
    f_files: clong
    f_ffree: clong
    f_fsid: fsid_t
    f_frsize:clong
    f_spare: array[5,clong]
    f_namelen: clong
    # https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man2/statfs.2.html
    f_flags:clong
    f_otype: cshort
    f_oflags: cshort
    f_owner: uint
    f_reserved1:cshort
    f_type:cshort
    f_reserved2:array[2,clong]
    f_fstypename:array[MFSNAMELEN,char] # fs type name */
    f_mntonname:array[MNAMELEN,char]    # directory on which mounted */
    f_mntfromname:array[MNAMELEN,char]  # mounted file system */
    f_reserved3:char              # reserved for future use */
    f_reserved4:array[4,clong] # reserved for future use */
    
 
const MNT_SYNCHRONOUS = 0x00000002 # file system written synchronously
const MNT_RDONLY      = 0x00000001 # read only filesystem
const MNT_NOEXEC      = 0x00000004 # can't exec from filesystem
const MNT_NOSUID      = 0x00000008 # don't honor setuid bits on fs
const MNT_NODEV       = 0x00000010 # don't interpret special files
const MNT_UNION       = 0x00000020 # union with underlying filesystem
const MNT_ASYNC       = 0x00000040 # file system written asynchronously
const MNT_CPROTECT    = 0x00000080 # file system supports content protection
const MNT_EXPORTED    = 0x00000100 # file system is exported
const MNT_QUARANTINE  = 0x00000400 # file system is quarantined
const MNT_LOCAL       = 0x00001000 # filesystem is stored locally
const MNT_QUOTA       = 0x00002000 # quotas are enabled on filesystem
const MNT_ROOTFS      = 0x00004000 # identifies the root filesystem
const MNT_DOVOLFS     = 0x00008000 # FS supports volfs (deprecated)
const MNT_DONTBROWSE  = 0x00100000 # FS is not appropriate path to user data
const MNT_IGNORE_OWNERSHIP = 0x00200000 # VFS will ignore ownership info on FS objects
const MNT_AUTOMOUNTED = 0x00400000 # filesystem was mounted by automounter
const MNT_JOURNALED   = 0x00800000 # filesystem is journaled
const MNT_NOUSERXATTR = 0x01000000 # Don't allow user extended attributes
const MNT_DEFWRITE    = 0x02000000 # filesystem should defer writes
const MNT_MULTILABEL  = 0x04000000 # MAC support for individual labels
const MNT_NOATIME     = 0x10000000 # disable update of file access time
const MNT_UPDATE      = 0x00010000
const MNT_RELOAD      = 0x00040000
const MNT_FORCE       = 0x00080000

const MNT_CMDFLAGS = (MNT_UPDATE or MNT_RELOAD  or MNT_FORCE)

const MNT_WAIT = 1
const MNT_NOWAIT = 2

proc strlcat(dst:ptr UncheckedArray[char];src: cstring ,size:csize_t ) : csize_t {.importc: "strlcat", nodecl.}
proc getfsstat(buf:ptr statfs; bufsize: clong;mode: cint) : cint {.importc: "getfsstat", nodecl.}
    #https://www.freebsd.org/cgi/man.cgi?query=getfsstat&sektion=2&manpath=freebsd-release-ports

proc sysctl(x: pointer, y: cint, z: pointer,
            a: var csize_t, b: pointer, c: int): cint {.
            importc: "sysctl", nodecl.}

proc sysctlbyname(name: cstring; oldp: ptr cint; oldlenp: ptr csize_t;
        newp: pointer; newlen: csize_t): cint {.importc: "sysctl", nodecl.}

proc mach_host_self(): mach_port_t{.importc: "mach_host_self",
        header: "<mach/mach_init.h>", nodecl.}
proc mach_port_deallocate(): void {.importc: "mach_port_deallocate",
        header: "<mach/mach_port.h>", nodecl, varargs.}
proc mach_task_self(): cint{.importc: "mach_task_self",
        header: "<mach/thread_act.h>", nodecl.}
proc mach_error_string(): string{.importc: "mach_error_string",
        header: "<mach/thread_act.h>", nodecl, varargs.}
proc host_statistics(a: mach_port_t; b: cint; c: host_info_t;
        d: ptr mach_msg_type_number_t): cint{.importc: "host_statistics",
                header: "<mach/mach_host.h>", nodecl, varargs.}

proc host_statistics64(a: mach_port_t; b: cint; c: host_info_t;
        d: ptr mach_msg_type_number_t): cint{.importc: "host_statistics64",
    header: "<mach/mach_host.h>", nodecl, varargs.}

proc boot_time*(): int =
    ## Return the system boot time expressed in seconds since the epoch, Integer type.
    var
        mib: array[0..3, cint]
        boot_time: Time
        len: csize_t
        r: Timeval
    mib[0] = CTL_KERN
    mib[1] = KERN_BOOTTIME
    len = sizeof(r).csize_t
    if sysctl(mib.addr, 2, addr(r), len, nil, 0) == -1:
        raise newException(OSError, "")
    boot_time = (Time)r.tv_sec
    return boot_time.int

proc uptime*(): int =
    ## Return the system uptime expressed in seconds, Integer type.
    times.epochTime().int - boot_time()

var HOST_CPU_LOAD_INFO_COUNT {.importc: "HOST_CPU_LOAD_INFO_COUNT",
    header: "<mach/mach_host.h>", nodecl.}: cint


proc cpu_times*(): CPUTimes =

    var count = cast[mach_msg_type_number_t](HOST_CPU_LOAD_INFO_COUNT)
    let host_port = mach_host_self()
    var r_load: host_cpu_load_info_data_t
    let error = host_statistics(host_port, HOST_CPU_LOAD_INFO, cast[
            host_info_t](r_load.unsafeAddr), count.addr)

    if error != KERN_SUCCESS:
        raise newException(OSError, "host_statistics(HOST_CPU_LOAD_INFO) syscall failed: $1" %
                mach_error_string(error))
    mach_port_deallocate(mach_task_self(), host_port)

    result.user = r_load.cpu_ticks[CPU_STATE_USER].cdouble / CLK_TCK
    result.nice = r_load.cpu_ticks[CPU_STATE_NICE].cdouble / CLK_TCK
    result.system = r_load.cpu_ticks[CPU_STATE_SYSTEM].cdouble / CLK_TCK
    result.idle = r_load.cpu_ticks[CPU_STATE_IDLE].cdouble / CLK_TCK

proc cpu_stats*(): tuple[ctx_switches, interrupts, soft_interrupts,
        syscalls: int] =
    var vmstat: Vmmeter

    var count: mach_msg_type_number_t = cast[mach_msg_type_number_t](sizeof(
            vmstat) div sizeof(cint));
    let mport = mach_host_self()
    let ret = host_statistics(mport, HOST_VM_INFO, cast[host_info_t](
            vmstat.unsafeAddr), count.unsafeAddr)
    if ret != KERN_SUCCESS:
        raise newException(OSError, "host_statistics(HOST_VM_INFO) syscall failed: $1" %
        mach_error_string(ret))

    mach_port_deallocate(mach_task_self(), mport)

    return (vmstat.v_swtch.int, vmstat.v_intr.int, vmstat.v_soft.int,
            vmstat.v_syscall.int)

type StructProc {.importc: "struct proc", header: "<sys/proc.h>", pure,
        incompleteStruct, nodecl.} = object
    p_pid: cint
var KERN_PROC {.importc: "KERN_PROC",
        header: "<sys/sysctl.h>", nodecl.}: cint
var KERN_PROC_ALL {.importc: "KERN_PROC_ALL",
        header: "<sys/sysctl.h>", nodecl.}: cint
type StructKinfoProc {.importc: "struct kinfo_proc",
        header: "<sys/sysctl.h>", pure, incompleteStruct,
                nodecl.} = object # https://opensource.apple.com/source/xnu/xnu-1456.1.26/bsd/sys/sysctl.h.auto.html
    kp_proc: StructProc

proc get_proc_list(procList:ptr ptr StructKinfoProc;
        procCount: ptr csize_t): int  =

    var
        size, size2: csize_t
        err: cint
        lim = 8
        ptrr: pointer
    var mib3 = [CTL_KERN, KERN_PROC, KERN_PROC_ALL]
    
    assert not isNil(procList)
    assert isNil(procList[])
    assert not isNil(procCount)

    procCount[] = 0
 
    while lim > 0:
        size = 0
        if sysctl(mib3.addr, 3, nil, size, nil, 0) == -1:
            debugEcho "get_proc_list sysctl fails"
            # PyErr_SetFromOSErrnoWithSyscall("sysctl(KERN_PROC_ALL)")
            return 1
        size2 = size + (size shr 3) # add some
        if size2 > size:
            ptrr = c_malloc(size2)
            if (ptrr == nil):
                ptrr = c_malloc(size)
            else:
                size = size2
        else:
            ptrr = c_malloc(size)
        if ptrr == nil:
            # PyErr_NoMemory()
            return 1;
        if sysctl(mib3.addr, 3, ptrr, size, nil, 0) == -1:
            debugEcho "get_proc_list sysctl fails"
            err = errno
            c_free(ptrr)
            if err != ENOMEM:
                # PyErr_SetFromOSErrnoWithSyscall("sysctl(KERN_PROC_ALL)")
                return 1
        else:
            procList[] = cast[ptr StructKinfoProc](ptrr)
            procCount[] = size div sizeof(StructKinfoProc).csize_t
            if (procCount[] <= 0):
                # PyErr_Format(PyExc_RuntimeError, "no PIDs found")
                return 1

            return 0 # success
    # PyErr_Format(PyExc_RuntimeError, "couldn't collect PIDs list")
        lim -= 1
    return 1

proc pids*(): seq[int] =
    var
        proclist:ptr  StructKinfoProc
        orig_address:ptr  StructKinfoProc
        num_processes: csize_t
        idx: csize_t
        pid:  cint
    result = newSeq[int](1)
    # proclist = (new StructKinfoProc).unsafeAddr
    if isNil(result.unsafeAddr):
        # return nil
        discard
    let proclistdupaddr = proclist.addr
    if get_proc_list(proclistdupaddr, num_processes.addr) != 0:
        debugEcho "get_proc_list fails"
        discard # goto error;

    # save the address of proclist so we can free it later
    orig_address = proclist
    idx = 0
    while idx < num_processes:
        pid = proclist[].kp_proc.p_pid
        # if (isNil(pid)):
        #     discard #goto error;
        result.add pid.int
        # if (PyList_Append(result, pid))
            # discard# goto error;
        # CLEAR(pid);
        proclist = proclist.offset(1)
        idx.inc

    c_free(orig_address)
    return result


proc cpu_count_logical*(): cint =
    ## shared with BSD
    var
        mib: array[0..3, cint]
        len: csize_t
        r: cint
    mib[0] = CTL_HW
    mib[1] = HW_NCPU
    len = sizeof(r).csize_t
    if sysctl(mib.addr, 2, addr(r), len, nil, 0) == -1:
        return -1
    else:
        return r


proc cpu_count_physical*(): int =
    ## just OSX
    var
        mib: array[0..3, cint]
        len: csize_t
        r: cint
    mib[0] = CTL_HW
    mib[1] = HW_AVAILCPU
    len = sizeof(r).csize_t
    if sysctl(mib.addr, 2, addr(r), len, nil, 0) != 0:
        return -1
    else:
        return r

proc sys_vminfo(vmstat: ptr vm_statistics_data_t): int =

    var
        count: mach_msg_type_number_t = cast[mach_msg_type_number_t](sizeof(
        vmstat[]) div sizeof(cint))
        mport = mach_host_self()

    let ret = host_statistics(mport, HOST_VM_INFO, cast[host_info_t](
            vmstat), count.addr);
    if (ret != KERN_SUCCESS):
        raise newException(OSError, "host_statistics(HOST_VM_INFO) syscall failed: $1" %
                mach_error_string(ret))
        # return 0
    mach_port_deallocate(mach_task_self(), mport);
    return 1;


proc virtual_memory*(): VirtualMemory =
    ## Return system virtual memory stats.
    ## See:
    ## https://opensource.apple.com/source/system_cmds/system_cmds-790/vm_stat.tproj/vm_stat.c.auto.html
    var
        mib: array[0..2, cint]
        len: csize_t
        total: uint64
        vm: vm_statistics_data_t
    let PAGESIZE = sysconf(SC_PAGE_SIZE)
    mib[0] = CTL_HW
    mib[1] = HW_MEMSIZE
    len = sizeof(total).csize_t
    if sysctl(mib.addr, 2, addr(total), len, nil, 0) == -1:
        discard
        # PyErr_SetFromErrno(PyExc_OSError);
    else:
        discard
        # PyErr_Format(
        #         PyExc_RuntimeError, "sysctl(HW_MEMSIZE) syscall failed");
        # return nil
    let ret = sys_vminfo(vm.addr)
    if not 1 == ret:
        return
    return VirtualMemory(total: total.int,
        active: vm.active_count * PAGESIZE,
        inactive: vm.inactive_count * PAGESIZE,
        # wire: vm.wire_count * PAGESIZE,
        free: vm.free_count * PAGESIZE,
        # speculative: vm.speculative_count * PAGESIZE
        )

proc swap_memory*(): SwapMemory =
    var
        mib: array[0..2, cint]
        len: csize_t
        totals: xsw_usage
        vm: vm_statistics_data_t
    let PAGESIZE = sysconf(SC_PAGE_SIZE)
    mib[0] = CTL_HW
    mib[1] = HW_MEMSIZE
    len = sizeof(totals).csize_t
    if sysctl(mib.addr, 2, addr(totals), len, nil, 0) == -1:
        discard
        # PyErr_SetFromErrno(PyExc_OSError);
    else:
        discard
        # PyErr_Format(
        #         PyExc_RuntimeError, "sysctl(HW_MEMSIZE) syscall failed");
        # return nil
    let ret = sys_vminfo(vm.addr)
    if not 1 == ret:
        return
    let percent = usage_percent(totals.xsu_used, totals.xsu_total, 1)
    return SwapMemory(total: totals.xsu_total.int, used: totals.xsu_used.int,
        free: totals.xsu_avail.int,
        percent: percent, sin: vm.pageins * PAGESIZE, sout: vm.pageouts * PAGESIZE)

proc calloc*(p: int, newsize: csize_t): pointer {.
    importc: "calloc", header: "<stdlib.h>".}

proc disk_partitions*(all = false): seq[DiskPartition] =
    var
        num:int
        i:int
        len: clong
        flags: clong
        opts: array[400, char]
        fs:ptr statfs
    # get the number of mount points
    # Py_BEGIN_ALLOW_THREADS
    num = getfsstat(nil, 0, MNT_NOWAIT)
    # Py_END_ALLOW_THREADS  
    # if (num == -1) :
    #     PyErr_SetFromErrno(PyExc_OSError);
    #     goto error;
    len = sizeof(fs[]) * num 
    fs = cast[ptr statfs](c_malloc(len.csize_t))
    if (fs == nil) :
        discard
        #     PyErr_SetFromErrno(PyExc_OSError);
        #     goto error;
    # Py_BEGIN_ALLOW_THREADS
    num = getfsstat(fs, len.clong, MNT_NOWAIT)
    # Py_END_ALLOW_THREADS    
    if (num == -1) :
        discard
        # PyErr_SetFromErrno(PyExc_OSError);
        # goto error

    var 
        partition:DiskPartition
        device: cstring
        mountpoint: cstring
        fstype: cstring
        popts: cstring
        fss:ptr UncheckedArray[statfs]
    while i < num :
        fss = cast[ptr UncheckedArray[statfs]](fs)
        flags = fss[i].f_flags
        # see sys/mount.h
        if (flags and MNT_RDONLY) != 0:
            discard strlcat(cast[ptr UncheckedArray[char]](opts.addr), "ro", sizeof(opts).csize_t)
        else:
            discard strlcat(cast[ptr UncheckedArray[char]](opts.addr), "rw", sizeof(opts).csize_t)
        if (flags and MNT_SYNCHRONOUS) != 0:
            discard strlcat(cast[ptr UncheckedArray[char]](opts.addr), ",sync", sizeof(opts).csize_t)
        if (flags and MNT_NOEXEC) != 0:
            discard strlcat(cast[ptr UncheckedArray[char]](opts.addr), "noexec", sizeof(opts).csize_t)
        if (flags and MNT_NOSUID) != 0:
            discard strlcat(cast[ptr UncheckedArray[char]](opts.addr), ",nosuid", sizeof(opts).csize_t)
        if (flags and MNT_UNION) != 0:
            discard strlcat(cast[ptr UncheckedArray[char]](opts.addr), ",union", sizeof(opts).csize_t)
        if (flags and MNT_ASYNC) != 0:
            discard strlcat(cast[ptr UncheckedArray[char]](opts.addr), ",async", sizeof(opts).csize_t)
        if (flags and MNT_EXPORTED) != 0:
            discard strlcat(cast[ptr UncheckedArray[char]](opts.addr), ",exported", sizeof(opts).csize_t)
        if (flags and MNT_QUARANTINE) != 0:
            discard strlcat(cast[ptr UncheckedArray[char]](opts.addr), ",quarantine", sizeof(opts).csize_t)
        if (flags and MNT_LOCAL) != 0:
            discard strlcat(cast[ptr UncheckedArray[char]](opts.addr), ",local", sizeof(opts).csize_t)
        if (flags and MNT_QUOTA) != 0:
            discard strlcat(cast[ptr UncheckedArray[char]](opts.addr), ",quota", sizeof(opts).csize_t)
        if (flags and MNT_ROOTFS) != 0:
            discard strlcat(cast[ptr UncheckedArray[char]](opts.addr), ",rootfs", sizeof(opts).csize_t)
        if (flags and MNT_DOVOLFS) != 0:
            discard strlcat(cast[ptr UncheckedArray[char]](opts.addr), ",dovolfs", sizeof(opts).csize_t)
        if (flags and MNT_DONTBROWSE) != 0:
            discard strlcat(cast[ptr UncheckedArray[char]](opts.addr), ",dontbrowse", sizeof(opts).csize_t)
        if (flags and MNT_IGNORE_OWNERSHIP) != 0:
            discard strlcat(cast[ptr UncheckedArray[char]](opts.addr), ",ignore-ownership", sizeof(opts).csize_t)
        if (flags and MNT_AUTOMOUNTED) != 0:
            discard strlcat(cast[ptr UncheckedArray[char]](opts.addr), ",automounted", sizeof(opts).csize_t)
        if (flags and MNT_JOURNALED) != 0:
            discard strlcat(cast[ptr UncheckedArray[char]](opts.addr), ",journaled", sizeof(opts).csize_t)
        if (flags and MNT_NOUSERXATTR) != 0:
            discard strlcat(cast[ptr UncheckedArray[char]](opts.addr), ",nouserxattr", sizeof(opts).csize_t)
        if (flags and MNT_DEFWRITE) != 0:
            discard strlcat(cast[ptr UncheckedArray[char]](opts.addr), ",defwrite", sizeof(opts).csize_t)
        if (flags and MNT_MULTILABEL) != 0:
            discard strlcat(cast[ptr UncheckedArray[char]](opts.addr), ",multilabel", sizeof(opts).csize_t)
        if (flags and MNT_NOATIME) != 0:
            discard strlcat(cast[ptr UncheckedArray[char]](opts.addr), ",noatime", sizeof(opts).csize_t)
        if (flags and MNT_UPDATE) != 0:
            discard strlcat(cast[ptr UncheckedArray[char]](opts.addr), ",update", sizeof(opts).csize_t)
        if (flags and MNT_RELOAD) != 0:
            discard strlcat(cast[ptr UncheckedArray[char]](opts.addr), ",reload", sizeof(opts).csize_t)
        if (flags and MNT_FORCE) != 0:
            discard strlcat(cast[ptr UncheckedArray[char]](opts.addr), ",force", sizeof(opts).csize_t)
        if (flags and MNT_CMDFLAGS) != 0:
            discard strlcat(cast[ptr UncheckedArray[char]](opts.addr), ",cmdflags", sizeof(opts).csize_t)
        device = newString(sizeof(fss[i].f_mntfromname))
        device.copyMem(fss[i].f_mntfromname.addr,sizeof(fss[i].f_mntfromname))
        mountpoint = newString(sizeof(fss[i].f_mntonname))
        mountpoint.copyMem(fss[i].f_mntonname.addr,sizeof(fss[i].f_mntonname))
        fstype =  newString(sizeof(fss[i].f_fstypename))
        fstype.copyMem(fss[i].f_fstypename.addr,sizeof(fss[i].f_fstypename))
        popts =  newString(sizeof(opts))
        popts.copyMem(opts.addr, sizeof(opts))
        partition = DiskPartition( device: $(device), mountpoint: $(mountpoint), fstype: $(fstype), opts: $(popts) )
        result.add( partition )    
        i.inc

const UTX_USERSIZE = 256
const UTX_LINESIZE = 32
const UTX_IDSIZE = 4
const UTX_HOSTSIZE = 256
const USER_PROCESS = 7  # Normal process.

type timeval_32 = object
    tv_sec: int32  # Seconds.
    tv_usec: int32 # Microseconds.

type utmpx {.importc: "struct utmpx",header: "<utmpx.h>".}= object
    ut_type: cshort    # Type of login.
    ut_pid: Pid       # Process ID of login process.
    ut_line: array[UTX_LINESIZE, char]  # Devicename.
    ut_id: array[UTX_IDSIZE, char]              # Inittab ID.
    ut_user: array[UTX_USERSIZE, char]  # Username.
    ut_host: array[UTX_HOSTSIZE, char]  # Hostname for remote login.
    ut_tv: timeval_32             # Time entry was made.
    ut_pad: array[16,uint32] #reserved for future use

proc getutxent(): ptr utmpx {.header: "<utmpx.h>".}
proc setutxent(): void {.header: "<utmpx.h>".}
proc endutxent(): void {.header: "<utmpx.h>".}

proc users*(): seq[User] =
    #Return currently connected users as a list of tuples.
    result = newSeq[User]()
    setutxent()
    var ut = getutxent()
    while ut != nil:
        let is_user_proc = ut.ut_type == USER_PROCESS
        if not is_user_proc:
            ut = getutxent()
            continue

        var hostname = $ut.ut_host
        if hostname == ":0.0" or hostname == ":0":
            hostname = "localhost"

        let user_tuple = User( name:($ut.ut_user.join().strip.replace("\x00", "")),
                            terminal:($ut.ut_line.join().strip.replace("\x00", "")),
                            started:ut.ut_tv.tv_sec.float )
        result.add( user_tuple )
        ut = getutxent()
    endutxent()

type processor_info_array_t {.importc: "processor_info_array_t",header: "<mach/processor_info.h>",pure, incompleteStruct,nodecl.} = object
type processor_cpu_load_info_data_t {.importc: "processor_cpu_load_info_data_t",header: "<mach/processor_info.h>".} = object
    cpu_ticks*: array[0..3, cint] 

proc host_processor_info(a: mach_port_t; b: cint; c: ptr cint;d: ptr processor_info_array_t;e:ptr mach_msg_type_number_t) : cint{.importc:"host_processor_info",header: "<mach/processor_info.h>".} 

var PROCESSOR_CPU_LOAD_INFO {.importc: "PROCESSOR_CPU_LOAD_INFO",header: "<mach/processor_info.h>".}:cint

proc per_cpu_times*(): seq[CPUTimes] =
    ## Return a list of tuples representing the CPU times for every
    ## CPU available on the system.
    result = newSeq[CPUTimes]()
    var 
        cpu_count:cint
        i:int
        info_array: processor_info_array_t
        info_count:mach_msg_type_number_t
        cpu_load_info:ptr processor_cpu_load_info_data_t
        user,nice,system,idle:cdouble
        
    let host_port = mach_host_self()

    let error = host_processor_info(host_port, PROCESSOR_CPU_LOAD_INFO,
                                cpu_count.addr, info_array.addr, info_count.addr)
    if error != KERN_SUCCESS:
        raise newException(OSError, "host_processor_info(PROCESSOR_CPU_LOAD_INFO) syscall failed: $1" % mach_error_string(error))
       
    mach_port_deallocate(mach_task_self(), host_port)
    cpu_load_info = cast[ptr processor_cpu_load_info_data_t](info_array)
    let info = cast[ptr UnCheckedArray[processor_cpu_load_info_data_t]](cpu_load_info)
    while i < cpu_count:
        user = info[i].cpu_ticks[CPU_STATE_USER].cdouble / CLK_TCK
        nice = info[i].cpu_ticks[CPU_STATE_NICE].cdouble / CLK_TCK
        system = info[i].cpu_ticks[CPU_STATE_SYSTEM].cdouble / CLK_TCK
        idle = info[i].cpu_ticks[CPU_STATE_IDLE].cdouble / CLK_TCK
        result.add CPUTimes(user:user,nice:nice,system:system,idle:idle)
        i.inc

const 
    NET_RT_IFLIST2 = 6
    PF_ROUTE = 17
    CTL_NET = 4
    RTM_IFINFO2 = 0x12

type if_msghdr {.importc: "struct if_msghdr",header: "<sys/socket.h>",pure, incompleteStruct,nodecl.} = object
    ifm_msglen:cint
    ifm_type:cint

type if_data64 {.importc: "struct if_data64",header: "<sys/socket.h>",nodecl.} = object
    ifi_type: uint8
    ifi_typelen: uint8
    ifi_physical: uint8
    ifi_addrlen: uint8
    ifi_hdrlen: uint8
    ifi_recvquota: uint8
    ifi_xmitquota: uint8
    ifi_unused1: uint8
    ifi_mtu: uint32
    ifi_metric: uint32
    ifi_baudrate: uint32
    ifi_ipackets: uint64
    ifi_ierrors: uint64
    ifi_opackets: uint64
    ifi_oerrors: uint64
    ifi_collisions: uint64
    ifi_ibytes: uint64
    ifi_obytes: uint64
    ifi_imcasts: uint64
    ifi_omcasts: uint64
    ifi_iqdrops: uint64
    ifi_noproto: uint64
    ifi_recvtiming: uint32
    ifi_xmittiming: uint32

type if_msghdr2 {.importc: "struct if_msghdr2",header: "<net/if.h>",pure, incompleteStruct,nodecl.} = object
    ifm_data:if_data64

type sockaddr_dl {.importc: "struct sockaddr_dl",header: "<net/if_dl.h>",pure, incompleteStruct,nodecl.} = object
    sdl_len:uint8
    sdl_family:uint8
    sdl_index:cshort
    sdl_type:uint8
    sdl_nlen:uint8
    sdl_alen:uint8
    sdl_slen:uint8
    sdl_data:array[12,uint8]

      
proc per_nic_net_io_counters*(): TableRef[string, NetIO] =
    ## Return network I/O statistics for every network interface
    ## installed on the system as a dict of raw tuples.
    result = newTable[string, NetIO]()
    var 
        next: ptr char
        buf:ptr char
        lim: ptr char
        ifm:ptr if_msghdr
        mib:array[6,cint]
        name:cstring
        len:csize_t
    # name = cstring("")
    mib[0] = CTL_NET          # networking subsystem
    mib[1] = PF_ROUTE         # type of information
    mib[2] = 0                # protocol (IPPROTO_xxx)
    mib[3] = 0                # address family
    mib[4] = NET_RT_IFLIST2   # operation
    mib[5] = 0
    # if isNil(buf):
        # discard
        # PyErr_NoMemory();
        # goto error;
    let ret = sysctl(mib.addr, 6, nil, len, nil, 0) 
    if ret < 0:
        discard
        # PyErr_SetFromErrno(PyExc_OSError);
        # goto error;
    buf = cast[ptr char](c_malloc( len.c_size_t ))
    if sysctl(mib.addr, 6, buf, len, nil, 0) < 0:
        discard
        # PyErr_SetFromErrno(PyExc_OSError);
        # goto error;
    lim = buf.offset(len.int)
    next = buf
    while cast[int](next) < cast[int](lim):
        ifm = cast[ptr if_msghdr](next)
        next = next.offset(ifm.ifm_msglen)
        if (ifm.ifm_type == RTM_IFINFO2):
            let if2m = cast[ptr if_msghdr2](ifm)
            let sdl = cast[ptr sockaddr_dl](cast[ptr UncheckedArray[if_msghdr2]](if2m.offset(1)))
            var a :array[sizeof(sdl.sdl_data),uint]
            a.addr.copyMem(sdl.sdl_data.addr,sizeof(sdl.sdl_data))
            name = cast[cstring](a.addr)  #@todo can be unicode ?
            result[$name] = NetIO( 
                bytes_sent : if2m[].ifm_data.ifi_obytes.int,
                bytes_recv : if2m[].ifm_data.ifi_ibytes.int,
                packets_sent : if2m[].ifm_data.ifi_opackets.int,
                packets_recv : if2m[].ifm_data.ifi_ipackets.int,
                errin : if2m[].ifm_data.ifi_ierrors.int,
                errout : if2m[].ifm_data.ifi_oerrors.int,
                dropin : if2m[].ifm_data.ifi_iqdrops.int,
                dropout : 0 # dropout not supported
                )

when isMainModule:
    echo boot_time()
    echo uptime()
    echo cpu_times()
    echo cpu_stats()
    echo pids()
    echo cpu_count_logical()
    echo cpu_count_physical()
    echo virtual_memory()
    echo swap_memory()
    echo users()
    echo per_cpu_times()
    echo disk_partitions()
    echo per_nic_net_io_counters()
