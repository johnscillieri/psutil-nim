import math
import os
import posix
import sequtils
import strutils
import tables

import common
import psutil_posix


################################################################################
const PROCFS_PATH = "/proc"

const UT_LINESIZE = 32
const UT_NAMESIZE = 32
const UT_HOSTSIZE = 256
const USER_PROCESS = 7  # Normal process.

let CLOCK_TICKS = sysconf( SC_CLK_TCK )
let PAGESIZE = sysconf( SC_PAGE_SIZE )

type timeval_32 = object
    tv_sec: int32  # Seconds.
    tv_usec: int32 # Microseconds.

type exit_status = object
    e_termination: int16 # Process termination status.
    e_exit: int16        # Process exit status.

type utmp = object
    ut_type: int16    # Type of login.
    ut_pid: Pid       # Process ID of login process.
    ut_line: array[UT_LINESIZE, char]  # Devicename.
    ut_id: array[4, char]              # Inittab ID.
    ut_user: array[UT_NAMESIZE, char]  # Username.
    ut_host: array[UT_HOSTSIZE, char]  # Hostname for remote login.
    ut_exit: exit_status # Exit status of a process marked as DEAD_PROCESS.
    ut_session: int32 # Session ID, used for windowing.
    ut_tv: timeval_32             # Time entry was made.
    ut_addr_v6: array[4, int32] # Internet address of remote host.
    unused: array[20, char]     # Reserved for future use.

type SysInfo = object
    uptime*: uint             # Seconds since boot
    loads*: array[3, uint]   # 1, 5, and 15 minute load averages
    totalram*: uint  # Total usable main memory size
    freeram*: uint   # Available memory size
    sharedram*: uint # Amount of shared memory
    bufferram*: uint # Memory used by buffers
    totalswap*: uint # Total swap space size
    freeswap*: uint  # swap space still available
    procs*: uint16    # Number of current processes
    totalhigh*: uint # Total high memory size
    freehigh*: uint  # Available high memory size
    mem_unit*: uint   # Memory unit size in bytes
    f: array[20-2*sizeof(int)-sizeof(int32), char] #Padding to 64 bytes


################################################################################
proc getutent(): ptr utmp {.header: "<utmp.h>".}
proc setutent() {.header: "<utmp.h>".}
proc endutent() {.header: "<utmp.h>".}
proc sysinfo(info: var SysInfo): cint {.header: "<sys/sysinfo.h>".}


proc boot_time*(): float =
    ## Return the system boot time expressed in seconds since the epoch
    let stat_path = PROCFS_PATH / "stat"
    for line in stat_path.lines:
        if line.startswith("btime"):
            return line.strip().split( " " )[1].parseFloat()

    raise newException(OSError, "line 'btime' not found in $1" % stat_path)


proc pids*(): seq[int] =
    ## Returns a list of PIDs currently running on the system.
    let all_files = toSeq( walkDir(PROCFS_PATH, relative=true) )
    return mapIt( filterIt( all_files, isdigit( it.path ) ), parseInt( it.path ) )


proc pid_exists*( pid: int ): bool =
    ## Check For the existence of a unix pid

    let exists = psutil_posix.pid_exists( pid )
    if not exists: return false

    try:
        # Note: already checked that this is faster than using a regular expr.
        # Also (a lot) faster than doing "return pid in pids()"
        let status_path = PROCFS_PATH / $pid / "status"
        for line in status_path.lines:
            if line.startswith( "Tgid:" ):
                let tgid = parseInt( line.split()[1] )
                return tgid == pid

        raise newException(OSError, "Tgid line not found in " & status_path)
    except:
        return pid in pids()


proc users*(): seq[User] =
    result = newSeq[User]()

    setutent()

    var ut = getutent()
    while ut != nil:
        let is_user_proc = ut.ut_type == USER_PROCESS
        if not is_user_proc:
            ut = getutent()
            continue

        var hostname = $ut.ut_host
        if hostname == ":0.0" or hostname == ":0":
            hostname = "localhost"

        let user_tuple = User( name:($ut.ut_user),
                               terminal:($ut.ut_line),
                               host:hostname,
                               started:ut.ut_tv.tv_sec.float )
        result.add( user_tuple )
        ut = getutent()

    endutent()


proc parse_cpu_time_line( text: string ): CPUTimes =
    let values = filterIt( text.split(), it.strip() != "" )
    let times = mapIt( values[1..<len(values)], parseFloat(it) / CLOCK_TICKS.float)
    if len(times) >= 7:
        result.user = times[0]
        result.nice = times[1]
        result.system = times[2]
        result.idle = times[3]
        result.iowait = times[4]
        result.irq = times[5]
        result.softirq = times[6]
    if len(times) >= 8:
        result.steal = times[7]
    if len(times) >= 9:
        result.guest = times[8]
    if len(times) >= 10:
        result.guest_nice = times[9]


proc cpu_times*(): CPUTimes =
    # Return a tuple representing the following system-wide CPU times:
    # (user, nice, system, idle, iowait, irq, softirq [steal, [guest,
    #  [guest_nice]]])
    # Last 3 fields may not be available on all Linux kernel versions.
    for line in lines( PROCFS_PATH / "stat" ):
        result = parse_cpu_time_line( line )
        break


proc per_cpu_times*(): seq[CPUTimes] =
    ## Return a list of tuples representing the CPU times for every
    ## CPU available on the system.
    result = newSeq[CPUTimes]()
    for line in lines( PROCFS_PATH / "stat" ):
        if not line.startswith("cpu"): continue
        let entry = parse_cpu_time_line( line )
        result.add( entry )
    # get rid of the first line which refers to system wide CPU stats
    result.delete(0)
    return result


proc cpu_stats*(): tuple[ctx_switches, interrupts, soft_interrupts, syscalls: int] =
    var ctx_switches, interrupts, soft_interrupts = 0
    for line in lines( PROCFS_PATH / "stat" ):
        if line.startswith("ctxt"):
            ctx_switches = parseint( line.split()[1] )
        elif line.startswith("intr"):
            interrupts = parseint( line.split()[1] )
        elif line.startswith("softirq"):
            soft_interrupts = parseint( line.split()[1] )
        if ctx_switches != 0 and soft_interrupts != 0 and interrupts != 0:
            break
    # syscalls = 0
    return (ctx_switches, interrupts, soft_interrupts, 0)


proc cpu_count_logical*(): int =
    ## Return the number of logical CPUs in the system.
    try:
        return sysconf( SC_NPROCESSORS_ONLN )
    except ValueError:
        # as a second fallback we try to parse /proc/cpuinfo
        for line in lines(PROCFS_PATH / "cpuinfo"):
            if line.toLowerAscii().startswith("processor"):
                result += 1

        # unknown format (e.g. amrel/sparc architectures), see:
        # https://github.com/giampaolo/psutil/issues/200
        # try to parse /proc/stat as a last resort
        if result == 0:
            for line in lines(PROCFS_PATH / "stat"):
                if line.toLowerAscii().startswith("cpu"):
                    result += 1
            # Remove one from the count for the top "cpu" line (with no digit)
            # Saves us the regular expression used in the python impl
            if result != 0: result -= 1

        return result


proc cpu_count_physical*(): int =
    ## Return the number of physical cores in the system.
    var mapping = initTable[int, int]()
    var current_info = initTable[string, int]()
    for raw_line in lines(PROCFS_PATH / "cpuinfo"):
        let line = raw_line.strip().toLowerAscii()
        if line == "":
            # new section
            if "physical id" in current_info and "cpu cores" in current_info:
                mapping[current_info["physical id"]] = current_info["cpu cores"]
            current_info = initTable[string, int]()
        else:
            # ongoing section
            if line.startswith("physical id") or line.startswith("cpu cores"):
                let parts = line.split("\t:")
                current_info[parts[0].strip()] = parseInt(parts[1].strip())

    let values = toSeq(mapping.values())
    return sum(values)


proc calculate_avail_vmem( mems:TableRef[string,int] ): int =
    ## Fallback for kernels < 3.14 where /proc/meminfo does not provide
    ## "MemAvailable:" column (see: https://blog.famzah.net/2014/09/24/).
    ## This code reimplements the algorithm outlined here:
    ## https://git.kernel.org/cgit/linux/kernel/git/torvalds/linux.git/
    ##     commit/?id=34e431b0ae398fc54ea69ff85ec700722c9da773
    ## XXX: on recent kernels this calculation differs by ~1.5% than
    ## "MemAvailable:" as it's calculated slightly differently, see:
    ## https://gitlab.com/procps-ng/procps/issues/42
    ## https://github.com/famzah/linux-memavailable-procfs/issues/2
    ## It is still way more realistic than doing (free + cached) though.

    # Fallback for very old distros. According to
    # https://git.kernel.org/cgit/linux/kernel/git/torvalds/linux.git/
    #     commit/?id=34e431b0ae398fc54ea69ff85ec700722c9da773
    # ...long ago "avail" was calculated as (free + cached).
    # We might fallback in such cases:
    # "Active(file)" not available: 2.6.28 / Dec 2008
    # "Inactive(file)" not available: 2.6.28 / Dec 2008
    # "SReclaimable:" not available: 2.6.19 / Nov 2006
    # /proc/zoneinfo not available: 2.6.13 / Aug 2005
    let free = mems["MemFree:"]
    let fallback = free + mems.getOrDefault("Cached:")

    var lru_active_file = 0
    var lru_inactive_file = 0
    var slab_reclaimable = 0
    try:
        lru_active_file = mems["Active(file):"]
        lru_inactive_file = mems["Inactive(file):"]
        slab_reclaimable = mems["SReclaimable:"]
    except KeyError:
        return fallback

    var watermark_low = 0
    try:
        for line in lines( PROCFS_PATH / "zoneinfo" ):
            if line.strip().startswith("low"):
                watermark_low += parseInt(filterIt(line.split(), it != "")[1])
    except IOError:
        return fallback  # kernel 2.6.13

    watermark_low *= PAGESIZE
    watermark_low = watermark_low

    var avail = free - watermark_low
    var pagecache = lru_active_file + lru_inactive_file
    pagecache -= min(int(pagecache / 2), watermark_low)
    avail += pagecache
    avail += slab_reclaimable - min(int(slab_reclaimable / 2), watermark_low)
    return int(avail)


proc virtual_memory*(): VirtualMemory =
    ## Report virtual memory stats.
    ## This implementation matches "free" and "vmstat -s" cmdline
    ## utility values and procps-ng-3.3.12 source was used as a reference
    ## (2016-09-18):
    ## https://gitlab.com/procps-ng/procps/blob/
    ##     24fd2605c51fccc375ab0287cec33aa767f06718/proc/sysinfo.c
    ## For reference, procps-ng-3.3.10 is the version available on Ubuntu
    ## 16.04.
    ## Note about "available" memory: up until psutil 4.3 it was
    ## calculated as "avail = (free + buffers + cached)". Now
    ## "MemAvailable:" column (kernel 3.14) from /proc/meminfo is used as
    ## it's more accurate.
    ## That matches "available" column in newer versions of "free".

    var missing_fields = newSeq[string]()
    var mems = newTable[string, int]()
    for line in lines( PROCFS_PATH / "meminfo" ):
        let fields = filterIt( line.split(), it.strip() != "" )
        mems[fields[0]] = parseInt(fields[1]) * 1024

    # /proc doc states that the available fields in /proc/meminfo vary
    # by architecture and compile options, but these 3 values are also
    # returned by sysinfo(2); as such we assume they are always there.
    let total = mems["MemTotal:"]
    let free = mems["MemFree:"]
    let buffers = mems["Buffers:"]

    var cached = 0
    try:
        cached = mems["Cached:"]
        # "free" cmdline utility sums reclaimable to cached.
        # Older versions of procps used to add slab memory instead.
        # This got changed in:
        # https://gitlab.com/procps-ng/procps/commit/
        #     05d751c4f076a2f0118b914c5e51cfbb4762ad8e
        cached += mems.getOrDefault("SReclaimable:")  # since kernel 2.6.19
    except KeyError:
        missing_fields.add("cached")

    var shared = 0
    try:
        shared = mems["Shmem:"]  # since kernel 2.6.32
    except KeyError:
        try:
            shared = mems["MemShared:"]  # kernels 2.4
        except KeyError:
            missing_fields.add("shared")

    var active = 0
    try:
        active = mems["Active:"]
    except KeyError:
        missing_fields.add("active")

    var inactive = 0
    try:
        inactive = mems["Inactive:"]
    except KeyError:
        try:
            inactive = mems["Inact_dirty:"] + mems["Inact_clean:"] + mems["Inact_laundry:"]
        except KeyError:
            missing_fields.add("inactive")

    var used = total - free - cached - buffers
    if used < 0:
        # May be symptomatic of running within a LCX container where such
        # values will be dramatically distorted over those of the host.
        used = total - free

    # - starting from 4.4.0 we match free's "available" column.
    #   Before 4.4.0 we calculated it as (free + buffers + cached)
    #   which matched htop.
    # - free and htop available memory differs as per:
    #   http://askubuntu.com/a/369589
    #   http://unix.stackexchange.com/a/65852/168884
    # - MemAvailable has been introduced in kernel 3.14
    var avail = 0
    try:
        avail = mems["MemAvailable:"]
    except KeyError:
        avail = calculate_avail_vmem(mems)

    if avail < 0:
        avail = 0
        missing_fields.add("available")

    # If avail is greater than total or our calculation overflows,
    # that's symptomatic of running within a LCX container where such
    # values will be dramatically distorted over those of the host.
    # https://gitlab.com/procps-ng/procps/blob/
    #     24fd2605c51fccc375ab0287cec33aa767f06718/proc/sysinfo.c#L764
    if avail > total:
        avail = free

    let percent = usage_percent( (total - avail), total, places=1 )

    # Warn about missing metrics which are set to 0.
    if len( missing_fields ) > 0:
        echo( missing_fields.join( ", " ),
              " memory stats couldn't be determined and ",
              if len(missing_fields) == 1: "was" else: "were",
              " set to 0" )

    return VirtualMemory( total:total, avail:avail, percent:percent, used:used,
                          free:free, active:active, inactive:inactive,
                          buffers:buffers, cached:cached, shared:shared )


proc swap_memory*(): SwapMemory =
    var si: SysInfo
    if sysinfo( si ) == -1:
        echo( "Error calling sysinfo in swap_memory(): ", errno )
        return

    let total = si.totalswap * si.mem_unit
    let free = si.freeswap * si.mem_unit
    let used = total - free
    let percent = usage_percent(used.int, total.int, places=1)

    result = SwapMemory( total:total.int, used:used.int, free:free.int,
                         percent:percent, sin:0, sout:0 )

    # try to get pgin/pgouts
    if not existsFile( PROCFS_PATH / "vmstat" ):
        # see https://github.com/giampaolo/psutil/issues/722
        echo( "'sin' and 'sout' swap memory stats couldn't be determined ",
              "and were set to 0" )
        return result

    for line in lines( PROCFS_PATH / "vmstat" ):
        # values are expressed in 4 kilo bytes, we want bytes instead
        if line.startswith("pswpin"):
            result.sin = parseInt(line.split()[1]) * 4 * 1024
        elif line.startswith("pswpout"):
            result.sout = parseInt(line.split()[1]) * 4 * 1024
        if result.sin != 0 and result.sout != 0:
            return result

    # we might get here when dealing with exotic Linux flavors, see:
    # https://github.com/giampaolo/psutil/issues/313
    echo( "'sin' and 'sout' swap memory stats couldn't be determined ",
            "and were set to 0" )
