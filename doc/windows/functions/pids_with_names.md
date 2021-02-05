# pids_with_names

This function with return a tuple of a sequence of integers (pids), and a sequence of strings (names)

# The function

```nim
proc pids_with_names*(): (seq[int], seq[string]) =

    var pids_seq = pids()
    var names_seq = process_names(pids_seq)

    return (pids_seq, names_seq)
```