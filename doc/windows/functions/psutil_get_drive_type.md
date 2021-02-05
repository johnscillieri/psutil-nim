# psutil_get_drive_type

There are two version of this function the first will give you the drive_type if given the uint. This is 
normally returned by GetDriveTypeA.

# The first function

```nim
proc psutil_get_drive_type*( drive_type: UINT ): string =
    case drive_type
        of DRIVE_FIXED: "fixed"
        of DRIVE_CDROM: "cdrom"
        of DRIVE_REMOVABLE: "removable"
        of DRIVE_UNKNOWN: "unknown"
        of DRIVE_NO_ROOT_DIR: "unmounted"
        of DRIVE_REMOTE: "remote"
        of DRIVE_RAMDISK: "ramdisk"
        else: "?"
```

# The second function

The second version of this function will give you the drive_type if given the drive name. This will run GetDriveTypeA 
automatically.

```nim
proc psutil_get_drive_type*(drive: string): string =

    var drive_type = GetDriveTypeA(cast[LPCSTR](drive))
    case drive_type
        of DRIVE_FIXED: "fixed"
        of DRIVE_CDROM: "cdrom"
        of DRIVE_REMOVABLE: "removable"
        of DRIVE_UNKNOWN: "unknown"
        of DRIVE_NO_ROOT_DIR: "unmounted"
        of DRIVE_REMOTE: "remote"
        of DRIVE_RAMDISK: "ramdisk"
        else: "?"
```