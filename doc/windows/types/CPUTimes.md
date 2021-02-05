# CPUTimes

CPUTimes type hold information regarding cpu times on the system

# The type
```nim
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
```

# Information

user        : holds user cpu time
system      : holds system cpu time
idle        : holds idle cpu time
interrupt   : holds interrupt cpu time
dpc         : holds dpc cpu time
nice        : holds nice cpu time
iowait      : holds io wait cpu time
irq         : holds irq cpu time
softirq     : holds softirq cpu time
steal       : holds steal cpu time
guest       : holds guest cpu time
guest_nice  : holds guest_nice cpu time

# Functions

- [per_cpu_times](../functions/per_cpu_times.md)