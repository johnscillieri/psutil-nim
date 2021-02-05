import math, nativesockets, posix

# type TSa_Family* {.importc: "sa_family_t", header: "<sys/socket.h>".} = cint
type Address* = object of RootObj
    family*: posix.TSa_Family  # int
    address*: string
    netmask*: string
    broadcast*: string
    ptp*: string

type User* = object
    name*: string
    terminal*: string
    host*: string
    started*: float

type CPUTimes* = object of RootObj
    user*: float
    system*: float
    idle*: float
    when defined(windows):
        interrupt*: float
        dpc*: float
    when defined(posix):
        nice*: float
        iowait*: float
        irq*: float
        softirq*: float
        steal*: float
        guest*: float
        guest_nice*: float
    

type DiskUsage* = object of RootObj
    total*: int
    used*: int
    free*:int
    percent*: float

type DiskPartition* = object of RootObj
    device*: string
    mountpoint*: string
    fstype*: string
    opts*: string

type VirtualMemory* = object of RootObj
    total*: int
    avail*: int
    percent*: float
    used*: int
    free*: int
    active*: int
    inactive*: int
    buffers*: int
    cached*: int
    shared*: int

type SwapMemory* = object of RootObj
    total*: int
    used*: int
    free*: int
    percent*: float
    sin*: int
    sout*: int

type NetIO* = object of RootObj
    bytes_sent*: int
    bytes_recv*: int
    packets_sent*: int
    packets_recv*: int
    errin*: int
    errout*: int
    dropin*: int
    dropout*: int

type NicDuplex* = enum
    NIC_DUPLEX_UNKNOWN, NIC_DUPLEX_HALF, NIC_DUPLEX_FULL

type NICStats* = object of RootObj
    isup*: bool
    duplex*: NicDuplex
    speed*: int
    mtu*: int

type DiskIO* = object of RootObj
    read_count*: int
    write_count*: int
    read_bytes*: int
    write_bytes*: int
    read_time*: int
    write_time*: int
    when defined(linux) or defined(macosx):
        reads_merged*: int
        read_merged_count*: int
        write_merged_count*: int
        busy_time*: int

type Connection* = object of RootObj
    fd*: int
    family*: int
    `type`*: int
    laddr*: string
    lport*: Port
    raddr*: string
    rport*: Port
    status*: string
    pid*: int


proc usage_percent*[T](used: T, total: T, places = 0): float =
  ## Calculate percentage usage of 'used' against 'total'.
  try:
    result = (used.int / total.int) * 100
  except DivByZeroError:
    result = if used is float or total is float: 0.0 else: 0
  if places != 0:
    return round(result, places)
  else:
    return result
