# cpu_count_physical

cpu_count_physical returns the amount of physical cpus are on the system

# The function
```nim
proc cpu_count_physical*(): int = 
    var length: DWORD = 0
    var rc = GetLogicalProcessorInformationEx(relationAll, NULL, addr length)

    var buffer = cast[PSYSTEM_LOGICAL_PROCESSOR_INFORMATION_EX](alloc0(length))
    rc = GetLogicalProcessorInformationEx(relationAll, buffer, addr length)

    if rc == 0:
        dealloc(buffer)
        raiseError()

    var currentPtr = buffer
    var offset = 0
    var prevProcessorInfoSize = 0
    while offset < length:
        # Advance ptr by the size of the previous SYSTEM_LOGICAL_PROCESSOR_INFORMATION_EX struct.
        currentPtr = cast[PSYSTEM_LOGICAL_PROCESSOR_INFORMATION_EX](cast[int](currentPtr) + prevProcessorInfoSize)

        if currentPtr.Relationship == relationProcessorCore:
            result += 1
        
        # When offset == length, we've reached the last processor info struct in the buffer.
        offset += currentPtr.Size
        prevProcessorInfoSize = currentPtr.Size
    
    dealloc(buffer)

```