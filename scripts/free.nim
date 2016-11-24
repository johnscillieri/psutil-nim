## A clone of 'free' cmdline utility.
## $ nim c -r free.nim
##              total       used       free     shared    buffers      cache
## Mem:       9198316    4714076     374348     406372     363140    3746752
## Swap:      9424892    1091644    8333248


import stringinterpolation
import ../psutil/psutil

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
