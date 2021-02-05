# try_pid_paths

try_pid_paths attempts to get the elf paths of the specified pids, and return them as a sequence of 
strings. 

Note: If an error occurs for any of the pids. The result of the corresponding pid will be ""

# The function
```nim
proc try_pid_paths*(pids: seq[int]): seq[string] =
    
    ## Function for getting the paths of the specified pids
    ## Note: If an error occurs for any of the pids. The result for the corresponding
    ## pid will be ""
    for pid in pids:
        result.add(try_pid_path(pid))
```