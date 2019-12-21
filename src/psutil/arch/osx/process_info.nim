import ./types
import ./socket

const MAXPATHLEN      = 1024

const PROC_PIDLISTFDS* = 2
const PROC_PIDLISTFD_SIZE* = 8
# defns of process file desc type  https://opensource.apple.com/source/xnu/xnu-1456.1.26/bsd/sys/proc_info.h.auto.html
const PROX_FDTYPE_ATALK* = 0
const PROX_FDTYPE_VNODE* = 1
const PROX_FDTYPE_SOCKET* = 2
const PROX_FDTYPE_PSHM* = 3
const PROX_FDTYPE_PSEM* = 4
const PROX_FDTYPE_KQUEUE* = 5
const PROX_FDTYPE_PIPE* = 6
const PROX_FDTYPE_FSEVENTS* = 7
const PROC_PIDFDVNODEPATHINFO* = 2

type proc_fdinfo* {.importc:"struct proc_fdinfo",header:"<sys/proc_info.h>".} = object
    proc_fdtype*:cint
    proc_fd*:cint

type vnode_fdinfowithpath* {.importc:"struct vnode_fdinfowithpath",header:"<sys/proc_info.h>".} = object


type proc_fileinfo* = object
    fi_openflags*:uint32
    fi_status*:uint32
    fi_offset*:off_t
    vip_path*:array[MAXPATHLEN,char]

type socket_fdinfo* {.importc:"struct socket_fdinfo",header:"<sys/proc_info.h>".} = object
    pfi*:proc_fileinfo
    psi*:socket_info


proc proc_pidinfo*(pid:cint,flavor:cint,arg:uint64,buffer:pointer,retval:ptr int32):cint{.importc:"proc_pidinfo",header:"<sys/proc_info.h>".}

proc proc_pidfdinfo*(pid:cint,flavor:cint,fd:cint,buffer:pointer,buffer_size:uint32,retval:ptr int32):cint{.importc:"proc_pidfdinfo",header:"<sys/proc_info.h>",varargs.}
proc proc_pidfdinfo*(pid:cint,flavor:cint,fd:cint,buffer:pointer,buffer_size:uint32):cint{.importc:"proc_pidfdinfo",header:"<sys/proc_info.h>",varargs.}
