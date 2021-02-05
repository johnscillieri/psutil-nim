# get_partitions

get_partition returns a sequence of strings (the partitions on the system)

# The functions
```nim
proc get_partitions*(): seq[string] =
    # Determine partitions to look for
    result = newSeq[string]()
    var lines = toSeq( lines( PROCFS_PATH / "partitions" ) )
    for line in reversed( lines[2..<len(lines)] ):
        let name = line.splitWhitespace()[3]
        if name[len(name)-1].isdigit():
            # we're dealing with a partition (e.g. 'sda1'); 'sda' will
            # also be around but we want to omit it
            result.add( name )
        elif len(result) == 0 or not result[len(result)-1].startswith( name ):
            # we're dealing with a disk entity for which no
            # partitions have been defined (e.g. 'sda' but
            # 'sda1' was not around), see:
            # https://github.com/giampaolo/psutil/issues/338
            result.add( name )
```