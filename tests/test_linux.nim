import unittest
import osproc
import strutils

import ../src/psutil

template echo_proc(x: untyped) =
  echo "\n\n", astToStr(x), "\n", x
    

proc vmstat(stat: string): int =
    for line in splitlines( execProcess("vmstat -s") ):
        if stat in line:
            return parseInt(line.splitWhitespace()[0])
    raise newException( ValueError, "can't find $1 in 'vmstat' output" % stat)


test "test boot time":
    let vmstat_value = vmstat("boot time")
    let psutil_value = psutil.boot_time()
    check( vmstat_value == int(psutil_value) )




debugEcho pid_user(1)
quit(0)
#[
echo_proc pid_name(1)
echo_proc process_exists("Discord")
echo_proc pids_with_names()
for pid in pids():
    try:
        echo_proc pid_path(pid)
        debugEcho try_pid_user(pid)
        discard pid_parent(pid)
    except:
        discard

]#
