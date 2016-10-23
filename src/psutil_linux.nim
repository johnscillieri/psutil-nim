import os
import sequtils
import strutils
import posix

import types

const PROCFS_PATH = "/proc"

proc boot_time*(): float =
    ## Return the system boot time expressed in seconds since the epoch
    let stat_path = PROCFS_PATH / "stat"
    for line in stat_path.lines:
        if line.startswith("btime"):
            return line.strip().split( " " )[1].parseFloat()

    raise newException(OSError, "line 'btime' not found in $1" % stat_path)


const UT_LINESIZE = 32
const UT_NAMESIZE = 32
const UT_HOSTSIZE = 256
const USER_PROCESS = 7  # Normal process.

type timeval_32 = object
    tv_sec: int32  # Seconds.
    tv_usec: int32 # Microseconds.

type exit_status = object
    e_termination: int16 # Process termination status.
    e_exit: int16        # Process exit status.

type utmp = object
    ut_type: int16    # Type of login.
    ut_pid: Pid       # Process ID of login process.
    ut_line: array[UT_LINESIZE, char]  # Devicename.
    ut_id: array[4, char]              # Inittab ID.
    ut_user: array[UT_NAMESIZE, char]  # Username.
    ut_host: array[UT_HOSTSIZE, char]  # Hostname for remote login.
    ut_exit: exit_status # Exit status of a process marked as DEAD_PROCESS.
    ut_session: int32 # Session ID, used for windowing.
    ut_tv: timeval_32             # Time entry was made.
    ut_addr_v6: array[4, int32] # Internet address of remote host.
    unused: array[20, char]     # Reserved for future use.

proc getutent(): ptr utmp {.header: "<utmp.h>".}
proc setutent() {.header: "<utmp.h>".}
proc endutent() {.header: "<utmp.h>".}

proc users*(): seq[User] =
    result = newSeq[User]()

    setutent()

    var ut = getutent()
    while ut != nil:
        let is_user_proc = ut.ut_type == USER_PROCESS
        if not is_user_proc:
            ut = getutent()
            continue

        var hostname = $ut.ut_host
        if hostname == ":0.0" or hostname == ":0":
            hostname = "localhost"

        let user_tuple = User( name:($ut.ut_user),
                               terminal:($ut.ut_line),
                               host:hostname,
                               started:ut.ut_tv.tv_sec.float )
        result.add( user_tuple )
        ut = getutent()

    endutent()

proc pids*(): seq[int] =
    ## Returns a list of PIDs currently running on the system.
    let all_files = toSeq( walkDir(PROCFS_PATH, relative=true) )
    return mapIt( filterIt( all_files, isdigit( it.path ) ), parseInt( it.path ) )
