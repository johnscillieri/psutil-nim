# pids_names

This function returns a sequence of strings (names) given a sequence of integers (pids)

# The function

'''nim
proc pid_names*(pids: seq[int]): seq[string] =

    #[
        function for getting the process name of pid
    ]#
    var ret: seq[string]
    for pid in pids:
        ret.add(pid_name(pid))

    return ret
    
'''