import posix, segfaults
import times except Time
import common
import strutils
include "system/ansi_c"

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

type StructProc {.importc: "struct proc", header: "<sys/types.h>", pure,
        incompleteStruct, nodecl.} = object
    p_pid: cint
var KERN_PROC {.importc: "KERN_PROC",
        header: "<sys/types.h>", nodecl.}: cint
var KERN_PROC_ALL {.importc: "KERN_PROC_ALL",
        header: "<sys/types.h>", nodecl.}: cint
type StructKinfoProc {.importc: "struct kinfo_proc",
        header: "<sys/types.h>", pure, incompleteStruct,
                nodecl.} = object # https://opensource.apple.com/source/xnu/xnu-1456.1.26/bsd/sys/sysctl.h.auto.html
    kp_proc: StructProc

proc get_proc_list(procList: ptr StructKinfoProc;
        procCount: ptr csize_t): int {.inline, nodecl.} =

    var
        size, size2: csize_t
        err: cint
        lim = 8
        ptrr: pointer
    var mib3 = [CTL_KERN, KERN_PROC, KERN_PROC_ALL]

    assert not isNil(procList)
    assert isNil(procList)
    assert not isNil(procCount)

    procCount[] = 0

    while lim > 0:
        size = 0
        if sysctl(mib3.addr, 3, nil, size, nil, 0) == -1:
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
            err = errno
            c_free(ptrr)
            if err != ENOMEM:
                # PyErr_SetFromOSErrnoWithSyscall("sysctl(KERN_PROC_ALL)")
                return 1
        else:
            procList[] = cast[StructKinfoProc](ptrr);
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
        proclist: ptr StructKinfoProc
        orig_address: ptr StructKinfoProc
        num_processes: csize_t
        idx: csize_t
        py_pid: ptr cint
    let py_retlist = newSeq[int](1)

    if isNil(py_retlist.unsafeAddr):
        # return nil
        discard

    if get_proc_list(proclist, num_processes.addr) != 0:
        discard # goto error;

    # save the address of proclist so we can free it later
    orig_address = proclist
    idx = 0
    while idx < num_processes:
        py_pid = proclist[].kp_proc.p_pid.addr
        if (isNil(py_pid)):
            discard #goto error;
        # if (PyList_Append(py_retlist, py_pid))
            # discard# goto error;
        # Py_CLEAR(py_pid);
        # proclist.inc
        idx.inc

    c_free(orig_address)
    return py_retlist


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
    echo ret
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
    
    echo num
    len = sizeof(statfs) * num 
    discard fs.c_realloc(sizeof(statfs).csize_t)
    if (fs == nil) :
        discard
        #     PyErr_SetFromErrno(PyExc_OSError);
        #     goto error;
    # Py_BEGIN_ALLOW_THREADS
    num = getfsstat(fs, len.clong, MNT_NOWAIT)
    # Py_END_ALLOW_THREADS    
    echo num,"#",len
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
        # opts[0] = 0
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

when isMainModule:
    echo boot_time()
    echo uptime()
    echo cpu_times()
    echo cpu_stats()
    # echo pids() # not complete
    echo cpu_count_logical()
    echo cpu_count_physical()
    echo virtual_memory()
    echo swap_memory()
    # echo disk_partitions() # not complete
