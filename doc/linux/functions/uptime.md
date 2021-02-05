# uptime

uptime returns the system uptime expressed in seconds, Integer type.

# The function
```nim
proc uptime*(): int =
  ## Return the system uptime expressed in seconds, Integer type.
  epochTime().int - boot_time()
```