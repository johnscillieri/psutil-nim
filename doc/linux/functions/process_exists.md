# process_exists

process_exists returns a boolean which is true if the given processName (like "firefox")
exists else false

# The function
```nim
proc process_exists*(processName: string): bool =

    let names_seq = process_names(pids())
    for name in names_seq:
        if processName == name:
            return true

    return false
```