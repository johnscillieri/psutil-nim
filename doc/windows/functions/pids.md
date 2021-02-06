# pids

This function will return a sequence of integers. Those integers being the pids of current running processes.s

# The function

```nim
proc pids*(): seq[int] = 
    ## Returns a list of PIDs currently running on the system.
    result = newSeq[int]()

    var procArray: seq[DWORD]
    var procArrayLen = 0
    # Stores the byte size of the returned array from enumprocesses
    var enumReturnSz: DWORD = 0

    while enumReturnSz == DWORD( procArrayLen * sizeof(DWORD) ):
        procArrayLen += 1024
        procArray = newSeq[DWORD](procArrayLen)

        if EnumProcesses( addr procArray[0], 
                          DWORD( procArrayLen * sizeof(DWORD) ), 
                          addr enumReturnSz ) == 0:
            raiseError()
            return result

    # The number of elements is the returned size / size of each element
    let numberOfReturnedPIDs = int( int(enumReturnSz) / sizeof(DWORD) )
    for i in 0..<numberOfReturnedPIDs:
        result.add( procArray[i].int )

```