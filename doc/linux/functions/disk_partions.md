# disk_partions

This function returns a type DiskUsage.

# The function
```nim
proc disk_partitions*(all=false): seq[DiskPartition] =
    ## Return mounted disk partitions as a sequence of DiskPartitions
    var fstypes = initHashSet[string]()
    for raw_line in lines( PROCFS_PATH / "filesystems" ):
        let line = raw_line.strip()
        if not line.startswith("nodev"):
            fstypes.incl( line )
        else:
            # ignore all lines starting with "nodev" except "nodev zfs"
            if line.split("\t")[1] == "zfs":
                fstypes.incl( "zfs" )

    result = newSeq[DiskPartition]()

    let file = setmntent(MOUNTED, "r");
    var entry = getmntent( file )
    while entry != nil:
        let device = if entry.mnt_fsname == "none": "" else: $entry.mnt_fsname
        let mountpoint = $entry.mnt_dir
        let fstype = $entry.mnt_type
        let opts = $entry.mnt_opts

        if not all:
            if device == "" or not( fstype in fstypes ):
                entry = getmntent( file )
                continue
        let partition = DiskPartition( device:device, mountpoint:mountpoint,
                                       fstype:fstype, opts:opts )
        result.add( partition )
        entry = getmntent( file )

    discard endmntent( file )

```

# The type

- [DiskUsage](../types/DiskUsage.md)