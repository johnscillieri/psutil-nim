## List all mounted disk partitions a-la "df -h" command.
## $ nim c -r disk_usage.nim
## Device               Total      Used     Free   Use %      Type  Mount
## /dev/sdb3           18.9GB    14.7GB     3.3GB    77%      ext4  /
## /dev/sda6          345.9GB    83.8GB   244.5GB    24%      ext4  /home
## /dev/sda1          296.0MB    43.1MB   252.9MB    14%      vfat  /boot/efi
## /dev/sda2          600.0MB   312.4MB   287.6MB    52%   fuseblk  /media/Recovery

import sequtils
import strutils
import strformat
import psutil

proc main() =
  var n: int = max(mapIt(psutil.disk_partitions(all=false), len(it.device)))

  echo(&"""{alignString("Device", n)} {"Total":>10} {"Used":>10} """ &
       &"""{"Free":>10} {"Use":>5}% {"Type":>9}  Mount""")
  for part in psutil.disk_partitions(all=false):
    when defined(windows):
      if "cdrom" in part.opts or part.fstype == "":
        # skip cd-rom drives with no disk in it; they may raise
        # ENOENT, pop-up a Windows GUI error for a non-ready
        # partition or just hang.
        continue
    let usage = psutil.disk_usage(part.mountpoint)
    echo(&"{alignString(part.device, n)} " &
         &"{formatSize(usage.total, prefix=bpColloquial):>10} " &
         &"{formatSize(usage.used, prefix=bpColloquial ):>10} " &
         &"{formatSize(usage.free, prefix=bpColloquial ):>10} " &
         &"{usage.percent:>5}% {part.fstype:>9}  {part.mountpoint:9}")

when isMainModule:
  main()
