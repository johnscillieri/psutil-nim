# net_connections

net_connections returns a sequence of the type Connection. This should return a Connection type
for each network connection on the system

# The function
```nim
proc net_connections*( kind= "inet", pid= -1 ): seq[Connection] =
    var inodes : OrderedTable[string, seq[tuple[pid:int, fd:int]]]
    result = newSeq[Connection]()

    if not tmap.hasKey( kind ):
        return result

    if pid != -1:
        inodes = get_proc_inodes( pid )
        if inodes.len == 0: # no connections for this process
            return result
    else:
        inodes = get_all_inodes()

    let conTypes = tmap[kind]
    for f, family, socketType in conTypes.items():
        if family in {posix.AF_INET, posix.AF_INET6}:
            for conn in process_inet( "/proc/net/$1" % f, family, socketType, inodes, filter_pid=pid ):
                result.add( conn )
        else:
            for conn in process_unix( "/proc/net/$1" % f, family, inodes, filter_pid=pid ):
                result.add( conn )

    return result
```

# The type
