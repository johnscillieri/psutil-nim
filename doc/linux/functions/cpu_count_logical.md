# cpu_count_logical

cpu_count_logical returns the number of active processors in the system.

# The function
```nim
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
```