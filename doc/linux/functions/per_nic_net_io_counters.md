# per_nic_net_io_counters

Return network I/O statistics (NetIO) for every network interface
installed on the system as a dict of raw tuples.

# The function
```nim
proc per_nic_net_io_counters*(): TableRef[string, NetIO] =
    ## Return network I/O statistics for every network interface
    ## installed on the system as a dict of raw tuples.
    result = newTable[string, NetIO]()
    for line in lines( PROCFS_PATH / "net/dev" ):
        if not( ":" in line ): continue
        let colon = line.rfind(':')
        let name = line[..colon].strip()
        let lst = line[(colon + 1)..len(line) - 1].strip.replace("\x00", "").splitWhitespace
        let fields = mapIt(lst, parseInt(it))

        result[name] = NetIO( bytes_sent: fields[8],
                              bytes_recv: fields[0],
                              packets_sent: fields[9],
                              packets_recv: fields[1],
                              errin: fields[2],
                              errout: fields[10],
                              dropin: fields[3],
                              dropout: fields[11] )

```

# The type

- [NetIO](../types/NetIO.md)