{.deadCodeElim: on.} 
import algorithm, math, net, os, posix, sequtils, sets, strutils, tables, times
import strformat
import common, psutil_posix


################################################################################
const PROCFS_PATH = "/proc"

const UT_LINESIZE = 32
const UT_NAMESIZE = 32
const UT_HOSTSIZE = 256
const USER_PROCESS = 7  # Normal process.
const PATH_MAX = 4096

var MOUNTED {.header: "<mntent.h>".}: cstring
var DUPLEX_FULL {.header: "<linux/ethtool.h>".}: uint8
var DUPLEX_HALF {.header: "<linux/ethtool.h>".}: uint8
var DUPLEX_UNKNOWN {.header: "<linux/ethtool.h>".}: uint8
var ETHTOOL_GSET {.header: "<linux/ethtool.h>".}: uint8
var SIOCETHTOOL {.header: "<linux/sockios.h>".}: uint16

let tcp4 = ( "tcp", posix.AF_INET, posix.SOCK_STREAM )
let tcp6 = ( "tcp6", posix.AF_INET6, posix.SOCK_STREAM )
let udp4 = ( "udp", posix.AF_INET, posix.SOCK_DGRAM )
let udp6 = ( "udp6", posix.AF_INET6, posix.SOCK_DGRAM )
let unix = ( "unix", posix.AF_UNIX, posix.SOCK_RAW ) # raw probably isn't right
let tmap = {
    "all": @[tcp4, tcp6, udp4, udp6, unix],
    "tcp": @[tcp4, tcp6],
    "tcp4": @[tcp4,],
    "tcp6": @[tcp6,],
    "udp": @[udp4, udp6],
    "udp4": @[udp4,],
    "udp6": @[udp6,],
    "unix": @[unix,],
    "inet": @[tcp4, tcp6, udp4, udp6],
    "inet4": @[tcp4, udp4],
    "inet6": @[tcp6, udp6],
}.toOrderedTable()

const TCP_STATUSES = {
    "01": "ESTABLISHED",
    "02": "SYN_SENT",
    "03": "SYN_RECV",
    "04": "FIN_WAIT1",
    "05": "FIN_WAIT2",
    "06": "TIME_WAIT",
    "07": "CLOSE",
    "08": "CLOSE_WAIT",
    "09": "LAST_ACK",
    "0A": "LISTEN",
    "0B": "CLOSING"
}.toOrderedTable()

let CLOCK_TICKS = sysconf( SC_CLK_TCK )
let PAGESIZE = sysconf( SC_PAGE_SIZE )

proc get_sector_size(): int =
    try:
        return "/sys/block/sda/queue/hw_sector_size".readFile().parseInt()
    except:
        # man iostat states that sectors are equivalent with blocks and
        # have a size of 512 bytes since 2.4 kernels. This value is
        # needed to calculate the amount of disk I/O in bytes.
        return 512

let SECTOR_SIZE = get_sector_size()

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

type mntent = ref object
    mnt_fsname*:cstring   # name of mounted filesystem
    mnt_dir*:cstring      # filesystem path prefix
    mnt_type*:cstring     # mount type (see mntent.h)
    mnt_opts*:cstring     # mount options (see mntent.h)
    mnt_freq*:int         # dump frequency in days
    mnt_passno*:int       # pass number on parallel fsck

type ethtool_cmd = object
    cmd*: uint32
    supported*: uint32
    advertising*: uint32
    speed*: uint16
    duplex*: uint8
    port*: uint8
    phy_address*: uint8
    transceiver*: uint8
    autoneg*: uint8
    mdio_support*: uint8
    maxtxpkt*: uint32
    maxrxpkt*: uint32
    speed_hi*: uint16
    eth_tp_mdix*: uint8
    eth_tp_mdix_ctrl*: uint8
    lp_advertising*: uint32
    reserved*: array[2, uint32]

################################################################################
proc getutent(): ptr utmp {.header: "<utmp.h>".}
proc setutent() {.header: "<utmp.h>".}
proc endutent() {.header: "<utmp.h>".}
proc sysinfo(info: var SysInfo): cint {.header: "<sys/sysinfo.h>".}
proc setmntent(filename: cstring, `type`: cstring): File {.header: "<mntent.h>".}
proc getmntent(stream: File): mntent {.header: "<mntent.h>".}
proc endmntent(streamp: File): int {.header: "<mntent.h>".}
proc readlink(path: cstring, buf: array, bufsiz: int): int {.header: "<unistd.h>".}
proc getpwuid(uid: int): ptr Passwd {.header: "<pwd.h>".}

proc boot_time*(): int =
    ## Return the system boot time expressed in seconds since the epoch, Integer type.
    let stat_path = PROCFS_PATH / "stat"
    for line in stat_path.lines:
        if line.strip.startswith("btime"):
            return line.strip.split()[1].parseInt()

    raise newException(OSError, "line 'btime' not found in $1" % stat_path)

proc uptime*(): int =
  ## Return the system uptime expressed in seconds, Integer type.
  epochTime().int - boot_time()

proc isnumber(s : string): bool =
    #[
        function for check if string is a number
    ]#
    for c in s:
        if isdigit(c) == false:
            return false

    return true

proc pids*(): seq[int] =
    ## Returns a list of PIDs currently running on the system.
    let all_files = toSeq( walkDir(PROCFS_PATH, relative=true) )
    return mapIt( filterIt( all_files, isnumber(it.path) ), parseInt( it.path ) )


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

proc pid_cmdline*(pid: int): string =

    ## Function for getting the cmdline of a pid
    ## this gets path of command and arguments
    
    let cmdline_path = PROCFS_PATH / $pid / "cmdline"
    return cmdline_path.readFile()

proc pids_cmdline*(pids: seq[int]): seq[string] =

    ## function for getting the cmdline of a sequence of pids
    ## this gets path of command and arguments
    var ret: seq[string]
    for pid in pids:
        ret.add(pid_cmdline(pid))

proc pid_name*(pid: int): string =
    ## Function for getting the process name of a pid
    ## not to be mixed with pid_cmdline. This only gets the 
    ## program name. Not the path and arguments
    let p_path = PROCFS_PATH / $pid / "status"
    var data = p_path.readFile()
    for line in data.split("\n"):
        if "Name:" in line:
            var name = line.split("Name:")[1].strip()
            result = name


proc pid_names*(pids: seq[int]): seq[string] =
    ## Function for getting the process name of a sequence of pids
    ## not to be mmixed with pids_cmdline. This only gets the 
    ## program name. Not the path and arguments.
    var ret: seq[string]
    for pid in pids:
        ret.add(pid_name(pid))

    return ret

proc pid_path*(pid: int): string = 

    ## Function for getting the path of the elf of the running pid
    var p_path: cstring = PROCFS_PATH / $pid / "exe"
    var buf: array[PATH_MAX, char]
    if readlink(p_path, buf, PATH_MAX) == -1:
        raise newException(IOError, "Cannot read /proc/$1/exe | $2" % [$pid, $strerror(errno)])
    for c in buf:
        if c != '\0': result.add(c) else: break

proc try_pid_path*(pid: int): string =

    ## Function for getting the path of the elf of the running pid
    ## Note: Instead of raising an error. It will instread return ""
    var p_path: cstring = PROCFS_PATH / $pid / "exe"
    var buf: array[PATH_MAX, char]
    if readlink(p_path, buf, PATH_MAX) == -1:
        result = ""
    else:
        for c in buf:
            if c != '\0': result.add(c) else: break


proc pid_paths*(pids: seq[int]): seq[string] =

    ## Function for getting the elf paths of the specified pids
    for pid in pids:
        result.add(pid_path(pid))


proc try_pid_paths*(pids: seq[int]): seq[string] =
    
    ## Function for getting the paths of the specified pids
    ## Note: If an error occurs for any of the pids. The result for the corresponding
    ## pid will be ""
    for pid in pids:
        result.add(try_pid_path(pid))
        
proc pid_user*(pid: int): string =
    
    ## Function for getting the username running the specified pid
    var p_path = PROCFS_PATH / $pid / "status"
    var uid = -1
    var data = p_path.readFile()
    for line in data.split("\n"):
        if "Uid:" in line:
            uid = parseInt(line.split("Uid:")[1].strip().split("\t")[0])

    var pws = getpwuid(cast[Uid](uid))
    if pws.isNil:
        raise newException(OSError, "UID $1 not found" % [$uid])
    result = $pws.pw_name

proc try_pid_user*(pid: int): string =
    
    ## Function for getting the username running the specified pid
    var p_path = PROCFS_PATH / $pid / "status"
    var uid = -1
    var data = p_path.readFile()
    for line in data.split("\n"):
        if "Uid:" in line:
            uid = parseInt(line.split("Uid:")[1].strip().split("\t")[0])
        
    var pws = getpwuid(cast[Uid](uid))
    if pws.isNil:
        result = ""
    else:
        result = $pws.pw_name

proc pid_users*(pids: seq[int]): seq[string] =

    for pid in pids:
        result.add(pid_user(pid))

proc try_pid_users*(pids: seq[int]): seq[string] =

    for pid in pids:
        result.add(try_pid_user(pid))

proc pid_parent*(pid: int): int =
    
    ## Function for getting the parent pid of the specified pid
    var p_path = PROCFS_PATH / $pid / "status"
    var data = p_path.readFile()
    for line in data.split("\n"):
        if "PPid:" in line:
            result = parseInt(line.split("PPid:")[^1].strip())

proc pid_parents*(pids: seq[int]): seq[int] =

    ## Function for getting the parent pids of the corresponding pids specified.
    for pid in pids:
        result.add(pid_parent(pid))

proc process_exists*(processName: string): bool =

    let names_seq = pid_names(pids())
    for name in names_seq:
        if processName == name:
            return true

    return false

proc pids_with_names*(): (seq[int], seq[string]) =

    ## Function for returning tuple of pids and names
    
    var pids_seq = pids()
    var names_seq = pid_names(pids_seq)

    return (pids_seq, names_seq)

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

        let user_tuple = User( name:($ut.ut_user.join().strip.replace("\x00", "")),
                               terminal:($ut.ut_line.join().strip.replace("\x00", "")),
                               started:ut.ut_tv.tv_sec.float )
        result.add( user_tuple )
        ut = getutent()

    endutent()


proc parse_cpu_time_line(text: string): CPUTimes =
    let values = text.strip.splitWhitespace()
    let times = mapIt(values[1..len(values) - 1], parseFloat(it) / CLOCK_TICKS.float)
    if len(times) >= 7:
        result.user = parseFloat(fmt"{times[0]:.2f}")
        result.nice = parseFloat(fmt"{times[1]:.2f}")
        result.system = parseFloat(fmt"{times[2]:.2f}")
        result.idle = parseFloat(fmt"{times[3]:.2f}")
        result.iowait = parseFloat(fmt"{times[4]:.2f}")
        result.irq = parseFloat(fmt"{times[5]:.2f}")
        result.softirq = parseFloat(fmt"{times[6]:.2f}")
    if len(times) >= 8:
        result.steal = parseFloat(fmt"{times[7]:.2f}")
    if len(times) >= 9:
        result.guest = parseFloat(fmt"{times[8]:.2f}")
    if len(times) >= 10:
        result.guest_nice = parseFloat(fmt"{times[9]:.2f}")


proc cpu_times*(): CPUTimes =
    # Return a tuple representing the following system-wide CPU times:
    # (user, nice, system, idle, iowait, irq, softirq [steal, [guest,
    #  [guest_nice]]])
    # Last 3 fields may not be available on all Linux kernel versions.
    for line in lines( PROCFS_PATH / "stat" ):
        result = parse_cpu_time_line(line)
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
                watermark_low += parseInt(line.splitWhitespace()[1])
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
        let fields = line.splitWhitespace()
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


proc disk_partitions*(all=false): seq[DiskPartition] =
    ## Return mounted disk partitions as a sequence of DiskPartitions
    var fstypes = initHashSet[string]()
    for raw_line in lines( PROCFS_PATH / "filesystems" ):
        let line = raw_line.strip()
        if not line.startswith("nodev"):
            fstypes.incl( line )
        else:
            # ignore all lines starting with "nodev" except "nodev zfs"
            if line.split("\t")[1] == "zfs":
                fstypes.incl( "zfs" )

    result = newSeq[DiskPartition]()

    let file = setmntent(MOUNTED, "r");
    var entry = getmntent( file )
    while entry != nil:
        let device = if entry.mnt_fsname == "none": "" else: $entry.mnt_fsname
        let mountpoint = $entry.mnt_dir
        let fstype = $entry.mnt_type
        let opts = $entry.mnt_opts

        if not all:
            if device == "" or not( fstype in fstypes ):
                entry = getmntent( file )
                continue
        let partition = DiskPartition( device:device, mountpoint:mountpoint,
                                       fstype:fstype, opts:opts )
        result.add( partition )
        entry = getmntent( file )

    discard endmntent( file )


proc per_nic_net_io_counters*(): TableRef[string, NetIO] =
    ## Return network I/O statistics for every network interface
    ## installed on the system as a dict of raw tuples.
    result = newTable[string, NetIO]()
    for line in lines( PROCFS_PATH / "net/dev" ):
        if not( ":" in line ): continue
        let colon = line.rfind(':')
        let name = line[..colon].strip()
        let lst = line[(colon + 1)..len(line) - 1].strip.replace("\x00", "").splitWhitespace
        let fields = mapIt(lst, parseInt(it))

        result[name] = NetIO( bytes_sent: fields[8],
                              bytes_recv: fields[0],
                              packets_sent: fields[9],
                              packets_recv: fields[1],
                              errin: fields[2],
                              errout: fields[10],
                              dropin: fields[3],
                              dropout: fields[11] )


proc net_if_duplex_speed*( name: string ): tuple[ duplex: NicDuplex, speed: int ] =
    ## Return stats about a particular network interface.
    ## References:
    ## https://github.com/dpaleino/wicd/blob/master/wicd/backends/be-ioctl.py
    ## http://www.i-scream.org/libstatgrab/

    result = ( NIC_DUPLEX_UNKNOWN, 0 )

    var ifr: ifreq
    var ethcmd: ethtool_cmd
    ethcmd.cmd = ETHTOOL_GSET
    ifr.ifr_ifru.ifru_data = addr ethcmd
    if not ioctlsocket( name, SIOCETHTOOL, ifr ):
        return result

    let duplex_map = { DUPLEX_FULL: NIC_DUPLEX_FULL,
                       DUPLEX_HALF: NIC_DUPLEX_HALF,
                       DUPLEX_UNKNOWN: NIC_DUPLEX_UNKNOWN }.toTable()
    result.duplex = duplex_map[ethcmd.duplex]
    result.speed = int( ethcmd.speed )


proc net_if_stats*(): TableRef[string, NICstats] =
    ## Get NIC stats (isup, duplex, speed, mtu).
    let names = toSeq( per_nic_net_io_counters().keys() )
    result = newTable[string, NICStats]()
    for name in names:
        let (duplex, speed) = net_if_duplex_speed( name )
        result[name] = NICStats( isup:net_if_flags( name ),
                                 duplex:duplex,
                                 speed:speed,
                                 mtu:net_if_mtu( name ) )


proc get_partitions*(): seq[string] =
    # Determine partitions to look for
    result = newSeq[string]()
    var lines = toSeq( lines( PROCFS_PATH / "partitions" ) )
    for line in reversed( lines[2..<len(lines)] ):
        let name = line.splitWhitespace()[3]
        if name[len(name)-1].isdigit():
            # we're dealing with a partition (e.g. 'sda1'); 'sda' will
            # also be around but we want to omit it
            result.add( name )
        elif len(result) == 0 or not result[len(result)-1].startswith( name ):
            # we're dealing with a disk entity for which no
            # partitions have been defined (e.g. 'sda' but
            # 'sda1' was not around), see:
            # https://github.com/giampaolo/psutil/issues/338
            result.add( name )


proc per_disk_io_counters*(): TableRef[string, DiskIO] =
    result = newTable[string, DiskIO]()
    for line in lines( PROCFS_PATH / "diskstats" ):
        # OK, this is a bit confusing. The format of /proc/diskstats can
        # have 3 variations.
        # On Linux 2.4 each line has always 15 fields, e.g.:
        # "3     0   8 hda 8 8 8 8 8 8 8 8 8 8 8"
        # On Linux 2.6+ each line *usually* has 14 fields, and the disk
        # name is in another position, like this:
        # "3    0   hda 8 8 8 8 8 8 8 8 8 8 8"
        # ...unless (Linux 2.6) the line refers to a partition instead
        # of a disk, in which case the line has less fields (7):
        # "3    1   hda1 8 8 8 8"
        # See:
        # https://www.kernel.org/doc/Documentation/iostats.txt
        # https://www.kernel.org/doc/Documentation/ABI/testing/procfs-diskstats
        let fields = line.splitWhitespace()
        let fields_len = len(fields)
        var name: string
        var reads, reads_merged, rbytes, rtime, writes, writes_merged,
                wbytes, wtime, busy_time, ignore1, ignore2 = 0
        if fields_len == 15:
            # Linux 2.4
            name = fields[3]
            reads = parseInt( fields[2] )
            (reads_merged, rbytes, rtime, writes, writes_merged,
                wbytes, wtime, ignore1, busy_time, ignore2) = map( fields[4..<14], parseInt )
        elif fields_len == 14:
            # Linux 2.6+, line referring to a disk
            name = fields[2]
            (reads, reads_merged, rbytes, rtime, writes, writes_merged,
                wbytes, wtime, ignore1, busy_time, ignore2) = map(fields[3..<14], parseInt)
        elif fields_len == 7:
            # Linux 2.6+, line referring to a partition
            name = fields[2]
            ( reads, rbytes, writes, wbytes ) = map(fields[3..<7], parseInt)
        else:
            raise newException( ValueError, "not sure how to interpret line $1" % line )

        if name in get_partitions():
            rbytes = rbytes * SECTOR_SIZE
            wbytes = wbytes * SECTOR_SIZE
            result[name] = DiskIO( read_count:reads, write_count:writes,
                                   read_bytes:rbytes, write_bytes:wbytes,
                                   read_time:rtime, write_time:wtime,
                                   read_merged_count:reads_merged, write_merged_count:writes_merged,
                                   busy_time:busy_time )



proc get_proc_inodes( pid: int ): OrderedTable[string, seq[tuple[pid:int, fd:int]]] =
    result = initOrderedTable[string, seq[tuple[pid:int, fd:int]]]()
    for fd in os.walkPattern( "/proc/$1/fd/*" % $pid ):
        var inode = expandSymlink( fd )
        if inode.startswith( "socket:[" ):
            # the process is using a socket
            inode = inode[8..inode.len-2]
            let data = ( pid: pid, fd: os.extractFilename( fd ).parseInt() )
            result.mgetOrPut( inode, newSeq[tuple[pid:int, fd:int]]() ).add( data )
    return result


proc get_all_inodes(): OrderedTable[string, seq[tuple[pid:int, fd:int]]] =
    result = initOrderedTable[string, seq[tuple[pid:int, fd:int]]]()
    for pid in pids():
        try:
            let proc_inodes = get_proc_inodes( pid )
            for key, value in proc_inodes:
                result[key] = value
        except OSError:
            # os.listdir() is gonna raise a lot of access denied
            # exceptions in case of unprivileged user; that's fine
            # as we'll just end up returning a connection with PID
            # and fd set to None anyway.
            # Both netstat -an and lsof does the same so it's
            # unlikely we can do any better.
            # ENOENT just means a PID disappeared on us.
            let err = ( ref OSError ) getCurrentException()
            if err.errorCode.cint in {ENOENT, ESRCH, EPERM, EACCES} == false:
                raise
    return result


proc parseHexIP( ip: string, family: int ): string =
    if family == posix.AF_INET:
        var ip_int = parseHexInt( ip ).uint32
        result = $inet_ntoa( InAddr( s_addr:ip_int ) )

    elif family == posix.AF_INET6:
        var ip_address = IpAddress( family: IpAddressFamily.IPv6 )
        for i in 0..3:
            let offset = i * 8
            let piece = ip[offset..offset+7]
            var int_piece = parseHexInt( piece ).uint32
            copyMem( addr( ip_address.address_v6[int(offset/2)] ), addr int_piece, 4 )

        result = $ip_address

    else:
        result = ip


proc decode_address( address: string, family: int ): tuple[ip:string, port:Port] =
    ## Accept an "ip:port" address as displayed in /proc/net/*
    ## and convert it into a human readable form, like:
    ## "0500000A:0016" -> ( "10.0.0.5", 22 )
    ## "0000000000000000FFFF00000100007F:9E49" -> ( "::ffff:127.0.0.1", 40521 )
    ## The IP address portion is a little or big endian four-byte
    ## hexadecimal number; that is, the least significant byte is listed
    ## first, so we need to reverse the order of the bytes to convert it
    ## to an IP address.
    ## The port is represented as a two-byte hexadecimal number.
    ## Reference:
    ## http://linuxdevcenter.com/pub/a/linux/2000/11/16/LinuxAdmin.html
    var ipPortPair = address.split( ":" )
    let ip = parseHexIP( ipPortPair[0], family )
    let port = Port( parseHexInt( ipPortPair[1] ) )
    return ( ip, port )


iterator process_inet( file: string, family: int, socketType: int, inodes : OrderedTable[string, seq[tuple[pid:int, fd:int]]], filter_pid= -1 ) : Connection =
    var laddr, raddr, status, inode : string
    var pid, fd : int

    ## Parse /proc/net/tcp* and /proc/net/udp* files.
    if file.endsWith( "6" ) and not os.fileExists( file ):
        # IPv6 not supported
        yield Connection()

    for line in file.lines:
        try:
            let strings = line.splitWhitespace()[..10]
            laddr = strings[1]
            raddr = strings[2]
            status = strings[3]
            inode = strings[9]
            if laddr == "local_address":
                continue

        except ValueError:
            raise

        if inodes.hasKey(inode):
            # # We assume inet sockets are unique, so we error
            # # out if there are multiple references to the
            # # same inode. We won't do this for UNIX sockets.
            # if len( inodes[inode]) > 1 and family != socket.AF_UNIX:
            #     raise ValueError( "ambiguos inode with multiple "
            #                      "PIDs references" )
            pid = inodes[inode][0].pid
            fd = inodes[inode][0].fd

        else:
            pid = -1
            fd = -1

        if filter_pid != -1 and filter_pid != pid:
            continue

        else:
            if socketType == posix.SOCK_STREAM:
                status = TCP_STATUSES[status]
            else:
                status = "NONE"
            let lpair = decode_address( laddr, family )
            let rpair = decode_address( raddr, family )
            yield Connection( fd: fd, family:family, `type`: socketType,
                              laddr:lpair.ip, lport:lpair.port,
                              raddr:rpair.ip, rport:rpair.port,
                              status:status, pid:pid )


iterator process_unix(  file: string, family: int, inodes : OrderedTable[string, seq[tuple[pid:int, fd:int]]], filter_pid= -1 ): Connection =
    ## Parse /proc/net/unix files
    for line in file.lines:
        let tokens = line.splitWhitespace()
        var socketType: string
        var inode: string
        try:
            socketType = tokens[4]
            inode = tokens[6]
        except ValueError:
            if not( " " in line ):
                # see: https://github.com/giampaolo/psutil/issues/766
                continue
            raise newException(
                Exception, "error while parsing $1; malformed line $2" % [file, line] )

        # We're parsing the header, skip it
        if socketType == "Type": continue

        var pairs: seq[tuple[pid:int, fd:int]]
        if inodes.hasKey(inode):
            # With UNIX sockets we can have a single inode
            # referencing many file descriptors.
            pairs = inodes[inode]
        else:
            pairs = @[( -1, -1 )]

        for pid_fd_tuple in pairs:
            let (pid, fd) = pid_fd_tuple
            if filter_pid != -1 and filter_pid != pid:
                continue

            let path = if len( tokens ) == 8: tokens[7] else: ""
            yield Connection( fd: fd, family: family, `type`: parseInt(socketType),
                              laddr: path, status: "NONE", pid: pid )


proc net_connections*( kind= "inet", pid= -1 ): seq[Connection] =
    var inodes : OrderedTable[string, seq[tuple[pid:int, fd:int]]]
    result = newSeq[Connection]()

    if not tmap.hasKey( kind ):
        return result

    if pid != -1:
        inodes = get_proc_inodes( pid )
        if inodes.len == 0: # no connections for this process
            return result
    else:
        inodes = get_all_inodes()

    let conTypes = tmap[kind]
    for f, family, socketType in conTypes.items():
        if family in {posix.AF_INET, posix.AF_INET6}:
            for conn in process_inet( "/proc/net/$1" % f, family, socketType, inodes, filter_pid=pid ):
                result.add( conn )
        else:
            for conn in process_unix( "/proc/net/$1" % f, family, inodes, filter_pid=pid ):
                result.add( conn )

    return result


proc isSsd*(diskLetter: char): bool {.inline.} =
  ## Returns ``true`` if disk is SSD (Solid). Linux only.
  ##
  ## .. code-block:: nim
  ##   echo isSsd('a') ## 'a' for /dev/sda, 'b' for /dev/sdb, ...
  ##
  try: readFile("/sys/block/sd" & $diskLetter & "/queue/rotational") == "0\n" except: false

