# pids_with_names

pids_with_names returns a tuple of sequences. The first sequence being the pids (integers), and the second being the process names of each of the corresponding pids.

# The function
```nim
proc pids_with_names*(): (seq[int], seq[string]) =

    ## Function for returning tuple of pids and names
    
    var pids_seq = pids()
    var names_seq = process_names(pids_seq)

    return (pids_seq, names_seq)
```