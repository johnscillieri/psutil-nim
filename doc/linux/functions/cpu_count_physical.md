# cpu_count_physical

cpu_count_physical returns the amount of physical cpus are on the system

# The function
```nim
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
```