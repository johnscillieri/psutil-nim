##[
Linux To Do -
    cpu_percent(interval=None, percpu=False)
    cpu_times_percent(interval=None, percpu=False)
    virtual_memory()
    swap_memory()
    disk_partitions(all=False)
    disk_usage(path)
    disk_io_counters(perdisk=False)
    net_io_counters(pernic=False)
    net_connections(kind='inet')
    net_if_stats()
    process_iter()
    wait_procs(procs, timeout=None, callback=None)
]##
import tables

when defined(posix):
    import psutil_posix

when defined(linux):
    import psutil_linux as platform


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


################################################################################
export tables

export net_if_addrs
export boot_time
export users
export pids
export cpu_times
export per_cpu_times
export cpu_stats
export cpu_count
