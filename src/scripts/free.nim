## A clone of 'free' cmdline utility.
## $ python scripts/free.py
##              total       used       free     shared    buffers      cache
## Mem:      10125520    8625996    1499524          0     349500    3307836
## Swap:            0          0          0

import stringinterpolation
import ../psutil

proc main() =
    let virt = psutil.virtual_memory()
    let swap = psutil.swap_memory()
    echo("%-7s %10s %10s %10s %10s %10s %10s".format(
         "", "total", "used", "free", "shared", "buffers", "cache"))
    echo("%-7s %10s %10s %10s %10s %10s %10s".format(
        "Mem:",
        int(virt.total / 1024),
        int(virt.used / 1024),
        int(virt.free / 1024),
        int(virt.shared / 1024),
        int(virt.buffers / 1024),
        int(virt.cached / 1024)))
    echo("%-7s %10s %10s %10s %10s %10s %10s".format(
        "Swap:",
        int(swap.total / 1024),
        int(swap.used / 1024),
        int(swap.free / 1024),
        "",
        "",
        ""))


when isMainModule:
    main()
