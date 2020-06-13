##[
Linux To Do -
    cpu_times_percent(interval=None, percpu=False)
    process_iter()
    wait_procs(procs, timeout=None, callback=None)
]##
import math
import os
import sequtils
import strutils
import tables

import psutil/common

when defined(posix):
  import psutil/psutil_posix

when defined(linux):
  import psutil/psutil_linux as platform

when defined(windows):
  import psutil/psutil_windows as platform

when defined(macosx):
  import psutil/psutil_macosx as platform
################################################################################
var g_last_cpu_times: CPUTimes
var g_last_per_cpu_times: seq[CPUTimes]
try:
    g_last_cpu_times = cpu_times()
    g_last_per_cpu_times = per_cpu_times()
except IOError:
    discard

var g_total_phymem: int


################################################################################
proc pid_exists*( pid: int ): bool =
    ## Return True if given PID exists in the current process list.
    ## This is faster than doing "pid in psutil.pids()" and should be preferred.

    if pid < 0:
        return false

    elif pid == 0 and defined(posix):
        # On POSIX we use os.kill() to determine PID existence.
        # According to "man 2 kill" PID 0 has a special meaning
        # though: it refers to <<every process in the process
        # group of the calling process>> and that is not we want
        # to do here.
        return pid in pids()

    else:
        return platform.pid_exists(pid)


proc cpu_count*(logical=true): int =
    # Return the number of logical CPUs in the system.
    # If logical is False return the number of physical cores only
    # (e.g. hyper thread CPUs are excluded).
    # Return 0 if undetermined.
    if logical: platform.cpu_count_logical()
    else: platform.cpu_count_physical()


proc calculate(t1, t2: CPUTimes): float =
    when defined(windows):
        let t1_all = t1.user + t1.system + t1.idle + t1.interrupt + t1.dpc
    else:
        let t1_all = t1.user + t1.nice + t1.system + t1.idle + t1.iowait +
                    t1.irq + t1.softirq + t1.steal + t1.guest + t1.guest_nice
    let t1_busy = t1_all - t1.idle

    when defined(windows):
        let t2_all = t2.user + t2.system + t2.idle + t2.interrupt + t2.dpc
    else:
        let t2_all = t2.user + t2.nice + t2.system + t2.idle + t2.iowait +
                    t2.irq + t2.softirq + t2.steal + t2.guest + t2.guest_nice
    let t2_busy = t2_all - t2.idle

    # this usually indicates a float precision issue
    if t2_busy <= t1_busy:
        return 0.0

    let busy_delta = t2_busy - t1_busy
    let all_delta = t2_all - t1_all
    let busy_perc = ( busy_delta / all_delta ) * 100
    return round( busy_perc, 1 )


proc cpu_percent*( interval=0.0 ): float =
    ## Return a float representing the current system-wide CPU utilization as a percentage.
    ##
    ## When interval is > 0.0 compares system CPU times elapsed before
    ## and after the interval (blocking).
    ##
    ## When interval is == 0.0 compares system CPU times elapsed since last
    ## call or module import, returning immediately (non
    ## blocking). That means the first time this is called it will
    ## return a meaningless 0.0 value which you should ignore.
    ## In this case is recommended for accuracy that this function be
    ## called with at least 0.1 seconds between calls.
    ## When percpu is True returns a list of floats representing the
    ## utilization as a percentage for each CPU.
    ## First element of the list refers to first CPU, second element
    ## to second CPU and so on.
    ## The order of the list is consistent across calls.
    ## Examples:
    ##   >>> # blocking, system-wide
    ##   >>> psutil.cpu_percent(interval=1)
    ##   2.0
    ##   >>>
    ##   >>> # blocking, per-cpu
    ##   >>> psutil.cpu_percent(interval=1, percpu=True)
    ##   [2.0, 1.0]
    ##   >>>
    ##   >>> # non-blocking (percentage since last call)
    ##   >>> psutil.cpu_percent(interval=None)
    ##   2.9
    ##   >>>

    let blocking = interval > 0.0
    if interval < 0:
        raise newException(ValueError, "interval is not positive (got $1)" % $interval)

    # system-wide usage
    var t1 = g_last_cpu_times
    if blocking:
        t1 = cpu_times()
        sleep( int(interval * 1000) )
    else:
        var empty: CPUTimes
        if t1 == empty:
            # Something bad happened at import time. We'll
            # get a meaningful result on the next call. See:
            # https://github.com/giampaolo/psutil/pull/715
            t1 = cpu_times()
    g_last_cpu_times = cpu_times()
    return calculate(t1, g_last_cpu_times)


proc per_cpu_percent*( interval=0.0 ): seq[float] =
    let blocking = interval > 0.0
    if interval < 0:
        raise newException(ValueError, "interval is not positive (got $1)" % $interval)

    result = newSeq[float]()
    var tot1 = g_last_per_cpu_times
    if blocking:
        tot1 = per_cpu_times()
        sleep( int( interval * 1000 ) )
    else:
        if not tot1.len > 0:
            # Something bad happened at import time. We'll
            # get a meaningful result on the next call. See:
            # https://github.com/giampaolo/psutil/pull/715
            tot1 = per_cpu_times()

    g_last_per_cpu_times = per_cpu_times()
    for pair in zip(tot1, g_last_per_cpu_times):
        result.add(calculate(pair[0], pair[1]))
    return result


proc virtual_memory*(): VirtualMemory =
    ## Return statistics about system memory usage as a namedtuple
    ## including the following fields, expressed in bytes:
    ##  - total:
    ##    total physical memory available.
    ##  - available:
    ##    the memory that can be given instantly to processes without the
    ##    system going into swap.
    ##    This is calculated by summing different memory values depending
    ##    on the platform and it is supposed to be used to monitor actual
    ##    memory usage in a cross platform fashion.
    ##  - percent:
    ##    the percentage usage calculated as (total - available) / total * 100
    ##  - used:
    ##    memory used, calculated differently depending on the platform and
    ##    designed for informational purposes only:
    ##     OSX: active + inactive + wired
    ##     BSD: active + wired + cached
    ##     LINUX: total - free
    ##  - free:
    ##    memory not being used at all (zeroed) that is readily available;
    ##    note that this doesn't reflect the actual memory available
    ##    (use 'available' instead)
    ## Platform-specific fields:
    ##  - active (UNIX):
    ##    memory currently in use or very recently used, and so it is in RAM.
    ##  - inactive (UNIX):
    ##    memory that is marked as not used.
    ##  - buffers (BSD, Linux):
    ##    cache for things like file system metadata.
    ##  - cached (BSD, OSX):
    ##    cache for various things.
    ##  - wired (OSX, BSD):
    ##    memory that is marked to always stay in RAM. It is never moved to disk.
    ##  - shared (BSD):
    ##    memory that may be simultaneously accessed by multiple processes.
    ## The sum of 'used' and 'available' does not necessarily equal total.
    ## On Windows 'available' and 'free' are the same.

    result = platform.virtual_memory()
    # cached for later use in Process.memory_percent()
    g_total_phymem = result.total


proc net_io_counters*(): NetIO =
    ## Return total network I/O statistics including the following fields:
    ##  - bytes_sent:   number of bytes sent
    ##  - bytes_recv:   number of bytes received
    ##  - packets_sent: number of packets sent
    ##  - packets_recv: number of packets received
    ##  - errin:        total number of errors while receiving
    ##  - errout:       total number of errors while sending
    ##  - dropin:       total number of incoming packets which were dropped
    ##  - dropout:      total number of outgoing packets which were dropped
    ##                  (always 0 on OSX and BSD)

    let raw_counters = platform.per_nic_net_io_counters()
    if len(raw_counters) == 0:
        raise newException( Exception, "couldn't find any network interface")

    for _, counter in raw_counters:
        result.bytes_sent += counter.bytes_sent
        result.bytes_recv += counter.bytes_recv
        result.packets_sent += counter.packets_sent
        result.packets_recv += counter.packets_recv
        result.errin += counter.errin
        result.errout += counter.errout
        result.dropin += counter.dropin
        result.dropout += counter.dropout


proc disk_io_counters: DiskIO =
    ## Return system disk I/O statistics as a namedtuple including
    ## the following fields:
    ##  - read_count:  number of reads
    ##  - write_count: number of writes
    ##  - read_bytes:  number of bytes read
    ##  - write_bytes: number of bytes written
    ##  - read_time:   time spent reading from disk (in milliseconds)
    ##  - write_time:  time spent writing to disk (in milliseconds)
    ## If perdisk is True return the same information for every
    ## physical disk installed on the system as a dictionary
    ## with partition names as the keys and the namedtuple
    ## described above as the values.
    ## On recent Windows versions 'diskperf -y' command may need to be
    ## executed first otherwise this function won't find any disk.

    let counters = per_disk_io_counters()
    if len( counters ) == 0:
        raise newException( Exception, "couldn't find any physical disk")

    for counter in counters.values():
        result.read_count += counter.read_count
        result.write_count += counter.write_count
        result.read_bytes += counter.read_bytes
        result.write_bytes += counter.write_bytes
        result.read_time += counter.read_time
        result.write_time += counter.write_time

        when defined(linux):
            result.read_merged_count += counter.read_merged_count
            result.write_merged_count += counter.write_merged_count
            result.busy_time += counter.busy_time


################################################################################
export tables

export NicDuplex
export AF_PACKET

export net_if_addrs
export boot_time
export uptime
export users
export pids
export cpu_times
export per_cpu_times
export cpu_stats
export cpu_count
export disk_usage
export swap_memory
export disk_partitions
export net_io_counters
export per_nic_net_io_counters

export disk_io_counters
export per_disk_io_counters
export net_if_stats
export net_connections