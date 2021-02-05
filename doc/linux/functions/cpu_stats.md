# cpu_stats

cpu_stats will get the cpu status of system, and return the ctx switches, interrupts, soft_interrupts, and syscalls.

* Note: linux only

# The function
```nim
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
```