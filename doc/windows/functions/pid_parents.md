# pid_parents

pid_parents returns a sequence of integers, each being the parent pid of each corresponding 
pid given as a sequence of integers

# The function
```nim
proc pid_parents*(pids: int): seq[int] =

    var ret: string[int]
    for pid in pids:
        ret.add(pid_parent(pid))

    return ret
```