# Connection

# The type
```nim
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
```

# Information

fd      : the file descriptor the connection is on
family  : the family type of connection (i.e. AF_INET and so on)
'type'  : socket type
laddr   : interface address on the machine for the connection
lport   : port open on the machine for the connection
raddr   : remote address the connection is made with
rport   : port on the remote machine for connection
status  : status of connection
pid     : pid of process making connection