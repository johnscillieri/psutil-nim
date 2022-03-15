# DiskPartition

DiskPartition is a type that hold disk partition information

# the type

```nim
type DiskPartition* = object of RootObj
    device*: string
    mountpoint*: string
    fstype*: string
    opts*: string
```

# information
device      : the device name of the partition
mountpoint  : the mountpoint of the partition
fstype      : the file system type of the partition
opts        : options of the partition