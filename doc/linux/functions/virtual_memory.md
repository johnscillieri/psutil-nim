# virtual_memory

This function will return type VirtualMemory which contains information on the virtual memory of the 
system


# The function
```nim
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

```

# The type

- [VirtualMemory](../types/VirtualMemory.md)
