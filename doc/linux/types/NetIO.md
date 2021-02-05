# NetIO

# The type
```nim
type NetIO* = object of RootObj
    bytes_sent*: int
    bytes_recv*: int
    packets_sent*: int
    packets_recv*: int
    errin*: int
    errout*: int
    dropin*: int
    dropout*: int
```

# Information
bytes_sent      : total amount of bytes sent
bytes_recv      : total amount of bytes received
packets_sent    : total amount of packets sent
packets_recv    : total amount of packets received
errin           : total amount of errors in
errout          : total amount of errors out
dropin          : total amount or dropped packets coming in