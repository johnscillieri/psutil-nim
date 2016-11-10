import unittest
import osproc
import strutils

import ../psutil


proc vmstat(stat: string): int =
    for line in splitlines( execProcess("vmstat -s") ):
        if stat in line:
            return parseInt(line.splitWhitespace()[0])
    raise newException( ValueError, "can't find $1 in 'vmstat' output" % stat)


test "test boot time":
    let vmstat_value = vmstat("boot time")
    let psutil_value = psutil.boot_time()
    check( vmstat_value == int(psutil_value) )
