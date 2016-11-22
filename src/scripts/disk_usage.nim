## List all mounted disk partitions a-la "df -h" command.
## $ python scripts/disk_usage.py
## Device               Total     Used     Free  Use %      Type  Mount
## /dev/sdb3            18.9G    14.7G     3.3G    77%      ext4  /
## /dev/sda6           345.9G    83.8G   244.5G    24%      ext4  /home
## /dev/sda1           296.0M    43.1M   252.9M    14%      vfat  /boot/efi
## /dev/sda2           600.0M   312.4M   287.6M    52%   fuseblk  /media/Recovery

import strutils
import stringinterpolation
import ../psutil

proc main() =
    echo( format( "%-25s %10s %10s %10s %5s%% %9s  %s",
                  "Device", "Total", "Used", "Free", "Use ", "Type", "Mount" ) )
    for part in psutil.disk_partitions(all=false):
        when defined(windows):
            if "cdrom" in part.opts or part.fstype == "":
                # skip cd-rom drives with no disk in it; they may raise
                # ENOENT, pop-up a Windows GUI error for a non-ready
                # partition or just hang.
                continue
        let usage = psutil.disk_usage( part.mountpoint )
        echo( format( "%-25s %10s %10s %10s %5s%% %9s  %s",
                      part.device,
                      formatSize( usage.total, prefix=bpColloquial ),
                      formatSize( usage.used, prefix=bpColloquial ),
                      formatSize( usage.free, prefix=bpColloquial ),
                      int( usage.percent ),
                      part.fstype,
                      part.mountpoint ) )

when isMainModule:
    main()
