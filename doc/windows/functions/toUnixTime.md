# toUnixTime

toUnixTime converts the FILETIME structure to the 32 bit Unix time structure.
The time_t is a 32-bit value for the number of seconds since January 1, 1970. 
A FILETIME is a 64-bit for the number of 100-nanosecond periods since January 1, 1601. 
Convert by subtracting the number of 100-nanosecond period between 01-01-1970
and 01-01-1601, from time_t then divide by 1e+7 to get to the same base granularity.

Note: FILETIME is defined in windef

# The function
```nim
proc toUnixTime(ft: FILETIME): float = 
    # HUGE thanks to:
    # http://johnstewien.spaces.live.com/blog/cns!E6885DB5CEBABBC8!831.entry
    # This function converts the FILETIME structure to the 32 bit
    # Unix time structure.
    # The time_t is a 32-bit value for the number of seconds since
    # January 1, 1970. A FILETIME is a 64-bit for the number of
    # 100-nanosecond periods since January 1, 1601. Convert by
    # subtracting the number of 100-nanosecond period between 01-01-1970
    # and 01-01-1601, from time_t then divide by 1e+7 to get to the same
    # base granularity.
    let ll = (int64(ft.dwHighDateTime) shl 32) + int64(ft.dwLowDateTime)
    result = int(ll - 116444736000000000) / 10000000

```