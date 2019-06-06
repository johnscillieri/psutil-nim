## A clone of 'free' cmdline utility.
## $ nim c -r free.nim
##              total       used       free     shared    buffers      cache
## Mem:       9198316    4714076     374348     406372     363140    3746752
## Swap:      9424892    1091644    8333248


import strformat
import psutil

proc main() =
    let virt = psutil.virtual_memory()
    let swap = psutil.swap_memory()
    echo(&"""{"total":>17} {"used":>10} {"free":>10} {"shared":>10} """ &
         &"""{"buffers":>10} {"cache":>10}""")
    echo(&"Mem: {int(virt.total / 1024):>12} {int(virt.used / 1024):>10} " &
         &"{int(virt.free / 1024):>10} {int(virt.shared / 1024):>10} " &
         &"{int(virt.buffers / 1024):>10} {int(virt.cached / 1024):>10}")
    echo(&"Swap: {int(swap.total / 1024):>11} {int(swap.used / 1024):>10} " &
         &"{int(swap.free / 1024):>10} ")

when isMainModule:
    main()
