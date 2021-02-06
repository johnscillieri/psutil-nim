# disk_partitions

This function will return a sequence of a type DiskPartition.

# The function

```nim
proc disk_partitions*( all=false ): seq[DiskPartition] =
    result = newSeq[DiskPartition]()

    # avoid to visualize a message box in case something goes wrong
    # see https://github.com/giampaolo/psutil/issues/264
    discard SetErrorMode( SEM_FAILCRITICALERRORS )
    
    var drive_strings = newWString( 256 )
    let returned_len = GetLogicalDriveStringsW( 256, drive_strings )
    if returned_len == 0:
        raiseError()
        return
    
    let letters = split( strip( $drive_strings, chars={'\0'} ), '\0' )
    for drive_letter in letters:
        let drive_type = GetDriveType( drive_letter )

        # by default we only show hard drives and cd-roms
        if not all:
            if drive_type == DRIVE_UNKNOWN or
               drive_type == DRIVE_NO_ROOT_DIR or
               drive_type == DRIVE_REMOTE or
               drive_type == DRIVE_RAMDISK: continue

            # floppy disk: skip it by default as it introduces a considerable slowdown.
            if drive_type == DRIVE_REMOVABLE and drive_letter == "A:\\":
                continue


        var fs_type: LPWSTR = newString( 256 )
        var pflags: DWORD = 0
        var lpdl: LPCWSTR = drive_letter
        let gvi_ret = GetVolumeInformationW( lpdl,
                                             NULL,
                                             DWORD( drive_letter.len ),
                                             NULL,
                                             NULL,
                                             addr pflags,
                                             fs_type,
                                             DWORD( 256 ) )
        var opts = ""
        if gvi_ret == 0:
            # We might get here in case of a floppy hard drive, in
            # which case the error is ( 21, "device not ready").
            # Let's pretend it didn't happen as we already have
            # the drive name and type ('removable').
            SetLastError( 0 )
        else:
            opts = if ( pflags and FILE_READ_ONLY_VOLUME ) != 0: "ro" else: "rw"
            
            if ( pflags and FILE_VOLUME_IS_COMPRESSED ) != 0:
                opts &= ",compressed"
                    
        if len( opts ) > 0:
            opts &= ","
        opts &= psutil_get_drive_type( drive_type )
        
        result.add( DiskPartition( mountpoint: drive_letter,
                                   device: drive_letter,
                                   fstype: $fs_type, # either FAT, FAT32, NTFS, HPFS, CDFS, UDF or NWFS
                                   opts: opts ) )
        discard SetErrorMode( 0 )
```

# Type DiskPartition

```nim
type DiskPartition* = object of RootObj
    device*: string
    mountpoint*: string
    fstype*: string
    opts*: string

```

