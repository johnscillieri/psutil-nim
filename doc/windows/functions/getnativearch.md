# getnativearch

This function returns a string that shows the native architecture of the system
"x64" is 64 bit
"x86" is 32 bit
"unknown" if we can't get the architecture. (Permissions or other reasons)

# The function
```nim
proc getnativearch*(): string =
    ## Get the native architecture of the system we are running on
    var pGetNativeSystemInfo: SYSTEM_INFO
    var nativeArch = "unknown"

    GetNativeSystemInfo(pGetNativeSystemInfo.addr)

    if pGetNativeSystemInfo.isNil:
        raiseError()

    
    case pGetNativeSystemInfo.union1.struct1.wProcessorArchitecture
        of PROCESSOR_ARCHITECTURE_AMD64:
            ## 64 bit (x64)
            # dwNativeArch = PROCESSOR_ARCHITECTURE_AMD64
            nativeArch = "x64"
        
        of PROCESSOR_ARCHITECTURE_IA64:
            # dwNativeArch = PROCESSOR_ARCHITECTURE_IA64
            nativeArch = "x64"
                            
        of PROCESSOR_ARCHITECTURE_INTEL:
            # 32 bit (x86)
            # dwNativeArch = PROCESSOR_ARCHITECTURE_INTEL
            nativeArch = "x86"
            
        else:
            # dwNativeArch  = PROCESSOR_ARCHITECTURE_UNKNOWN
            nativeArch = "unknown"

    return nativeArch
```