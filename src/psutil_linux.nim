import math
import os
import posix
import sequtils
import strutils
import tables

import types
import psutil_posix

const PROCFS_PATH = "/proc"

const UT_LINESIZE = 32
const UT_NAMESIZE = 32
const UT_HOSTSIZE = 256
const USER_PROCESS = 7  # Normal process.

let CLOCK_TICKS = sysconf( SC_CLK_TCK )

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

proc getutent(): ptr utmp {.header: "<utmp.h>".}
proc setutent() {.header: "<utmp.h>".}
proc endutent() {.header: "<utmp.h>".}


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
        # Also (a lot) faster than doing 'return pid in pids()'
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


proc cpu_times*(): tuple[user, nice, system, idle, iowait, irq, softirq, steal, guest, guest_nice : float] =
    # Return a tuple representing the following system-wide CPU times:
    # (user, nice, system, idle, iowait, irq, softirq [steal, [guest,
    #  [guest_nice]]])
    # Last 3 fields may not be available on all Linux kernel versions.

    var values: seq[string]
    for line in lines( PROCFS_PATH / "stat" ):
        values = line.split()
        break

    var fields = values[2..<len(values)]
    let times = mapIt( fields, parseFloat(it) / CLOCK_TICKS.float)
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
