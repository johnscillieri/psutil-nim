##[
Linux To Do -
    cpu_times(percpu=False)
    cpu_percent(interval=None, percpu=False)
    cpu_times_percent(interval=None, percpu=False)
    cpu_count(logical=True)
    cpu_stats()
    virtual_memory()
    swap_memory()
    disk_partitions(all=False)
    disk_usage(path)
    disk_io_counters(perdisk=False)
    net_io_counters(pernic=False)
    net_connections(kind='inet')
    net_if_stats()
    pids()
    pid_exists(pid)
    process_iter()
    wait_procs(procs, timeout=None, callback=None)
]##

import tables

when defined(posix):
    import psutil_posix

when defined(linux):
    import psutil_linux

echo net_if_addrs()
echo boot_time()
echo users()
