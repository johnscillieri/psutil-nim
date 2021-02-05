# per_disk_io_counters

per_disk_io_counters returns a table of strings to DiskIO

# The function
```nim
proc per_disk_io_counters*(): TableRef[string, DiskIO] =
    result = newTable[string, DiskIO]()
    for line in lines( PROCFS_PATH / "diskstats" ):
        # OK, this is a bit confusing. The format of /proc/diskstats can
        # have 3 variations.
        # On Linux 2.4 each line has always 15 fields, e.g.:
        # "3     0   8 hda 8 8 8 8 8 8 8 8 8 8 8"
        # On Linux 2.6+ each line *usually* has 14 fields, and the disk
        # name is in another position, like this:
        # "3    0   hda 8 8 8 8 8 8 8 8 8 8 8"
        # ...unless (Linux 2.6) the line refers to a partition instead
        # of a disk, in which case the line has less fields (7):
        # "3    1   hda1 8 8 8 8"
        # See:
        # https://www.kernel.org/doc/Documentation/iostats.txt
        # https://www.kernel.org/doc/Documentation/ABI/testing/procfs-diskstats
        let fields = line.splitWhitespace()
        let fields_len = len(fields)
        var name: string
        var reads, reads_merged, rbytes, rtime, writes, writes_merged,
                wbytes, wtime, busy_time, ignore1, ignore2 = 0
        if fields_len == 15:
            # Linux 2.4
            name = fields[3]
            reads = parseInt( fields[2] )
            (reads_merged, rbytes, rtime, writes, writes_merged,
                wbytes, wtime, ignore1, busy_time, ignore2) = map( fields[4..<14], parseInt )
        elif fields_len == 14:
            # Linux 2.6+, line referring to a disk
            name = fields[2]
            (reads, reads_merged, rbytes, rtime, writes, writes_merged,
                wbytes, wtime, ignore1, busy_time, ignore2) = map(fields[3..<14], parseInt)
        elif fields_len == 7:
            # Linux 2.6+, line referring to a partition
            name = fields[2]
            ( reads, rbytes, writes, wbytes ) = map(fields[3..<7], parseInt)
        else:
            raise newException( ValueError, "not sure how to interpret line $1" % line )

        if name in get_partitions():
            rbytes = rbytes * SECTOR_SIZE
            wbytes = wbytes * SECTOR_SIZE
            result[name] = DiskIO( read_count:reads, write_count:writes,
                                   read_bytes:rbytes, write_bytes:wbytes,
                                   read_time:rtime, write_time:wtime,
                                   read_merged_count:reads_merged, write_merged_count:writes_merged,
                                   busy_time:busy_time )
```

# The type

- [DiskIO](../types/DiskIO.md)