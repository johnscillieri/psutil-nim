import posix, strutils, tables
import common

const bsdPlatform = defined(macosx) or defined(freebsd) or
                    defined(netbsd) or defined(openbsd) or
                    defined(dragonfly)

const IFHWADDRLEN* = 6
const IF_NAMESIZE* = 16
const IFNAMSIZ* = IF_NAMESIZE

var AF_PACKET* {.header: "<sys/socket.h>".}: cint
var IFF_BROADCAST* {.header: "<net/if.h>".}: uint
var IFF_POINTOPOINT* {.header: "<net/if.h>".}: uint

var NI_MAXHOST* {.header: "<net/if.h>".}: cint
when bsdPlatform:
    var IFF_UP {.header: "<net/if.h>".}: uint
    var SIOCGIFFLAGS {.header: "<sys/sockio.h>".}: uint
    var SIOCGIFMTU {.header: "<sys/sockio.h>".}: uint

else:
    var IFF_UP {.header: "<linux/if.h>".}: uint
    var SIOCGIFFLAGS {.header: "<linux/sockios.h>".}: uint
    var SIOCGIFMTU {.header: "<linux/sockios.h>".}: uint

type ifaddrs = object
    pifaddrs: ptr ifaddrs # Next item in list
    ifa_name: cstring # Name of interface
    ifa_flags: uint   # Flags from SIOCGIFFLAGS
    ifa_addr: ptr SockAddr  # Address of interface
    ifa_netmask: ptr SockAddr # Netmask of interface
    ifu_broadaddr: ptr SockAddr # Broadcast address of interface
    ifa_data: pointer # Address-specific data

type sockaddr_ll = object
    sll_family: uint16 # Always AF_PACKET
    sll_protocol: uint16 # Physical-layer protocol */
    sll_ifindex: int32 # Interface number */
    sll_hatype: uint16 # ARP hardware type */
    ll_pkttype: uint8 # Packet type */
    sll_halen: uint8 # Length of address */
    sll_addr: array[8, uint8] # Physical-layer address */

type
  ifmap* = object
    mem_start*: culong
    mem_end*: culong
    base_addr*: cushort
    irq*: cuchar
    dma*: cuchar
    port*: cuchar              ## # 3 bytes spare

type
  INNER_C_UNION_9261176668105079294* = object {.union.}
    ifrn_name*: array[IFNAMSIZ, char] ## # Interface name, e.g. "en0".

  INNER_C_UNION_7660000764852079517* = object {.union.}
    ifru_addr*: SockAddr
    ifru_dstaddr*: SockAddr
    ifru_broadaddr*: SockAddr
    ifru_netmask*: SockAddr
    ifru_hwaddr*: SockAddr
    ifru_flags*: cshort
    ifru_ivalue*: cint
    ifru_mtu*: cint
    ifru_map*: ifmap
    ifru_slave*: array[IFNAMSIZ, char] ## # Just fits the size
    ifru_newname*: array[IFNAMSIZ, char]
    ifru_data*: pointer

  ifreq* = object
    ifr_ifrn*: INNER_C_UNION_9261176668105079294
    ifr_ifru*: INNER_C_UNION_7660000764852079517


################################################################################
proc ioctl*(f: FileHandle, device: uint, data: pointer): int {.header: "<sys/ioctl.h>".}
proc getifaddrs( ifap: var ptr ifaddrs ): int {.header: "<ifaddrs.h>".}
proc freeifaddrs( ifap: ptr ifaddrs ): void {.header: "<ifaddrs.h>".}

proc psutil_convert_ipaddr(address: ptr SockAddr, family: posix.TSa_Family): string


proc pid_exists*( pid: int ): bool =
    ## Check whether pid exists in the current process table.
    if pid == 0:
        # According to "man 2 kill" PID 0 has a special meaning:
        # it refers to <<every process in the process group of the
        # calling process>> so we don't want to go any further.
        # If we get here it means this UNIX platform *does* have
        # a process with id 0.
        return true

    let ret_code = kill( pid.int32, 0 )

    if ret_code == 0: return true

    # ESRCH == No such process
    if errno == ESRCH: return false

    # EPERM clearly means there's a process to deny access to
    elif errno == EPERM: return true

    # According to "man 2 kill" possible error values are
    # (EINVAL, EPERM, ESRCH) therefore we should never get
    # here. If we do let's be explicit in considering this
    # an error.
    else: raise newException(OSError, "Unknown error from pid_exists: " & $errno )


proc net_if_addrs*(): Table[string, seq[Address]] =
    ## Return the addresses associated to each NIC (network interface card)
    ##   installed on the system as a table whose keys are the NIC names and
    ##   value is a seq of Addresses for each address assigned to the NIC.
    ##
    ##   *family* can be either AF_INET, AF_INET6, AF_LINK, which refers to a MAC address.
    ##   *address* is the primary address and it is always set.
    ##   *netmask*, *broadcast* and *ptp* may be ``None``.
    ##   *ptp* stands for "point to point" and references the destination address on a point to point interface (typically a VPN).
    ##   *broadcast* and *ptp* are mutually exclusive.
    ##   *netmask*, *broadcast* and *ptp* are not supported on Windows and are set to nil.
    var interfaces : ptr ifaddrs
    var current : ptr ifaddrs
    let ret_code = getifaddrs( interfaces )
    if ret_code == -1:
        echo( "net_if_addrs error: ", strerror( errno ) )
        return result

    result = initTable[string, seq[Address]]()

    current = interfaces
    while current != nil:
        let name = $current.ifa_name
        let family = current.ifa_addr.sa_family
        let address = psutil_convert_ipaddr( current.ifa_addr, family )
        let netmask = psutil_convert_ipaddr( current.ifa_netmask, family )
        let bc_or_ptp = psutil_convert_ipaddr( current.ifu_broadaddr, family )
        let broadcast = if (current.ifa_flags and IFF_BROADCAST) != 0: bc_or_ptp else: ""
        # ifu_broadcast and ifu_ptp are a union in C, but we don't really care what C calls it
        let ptp = if (current.ifa_flags and IFF_POINTOPOINT) != 0: bc_or_ptp else: ""

        if not( name in result ): result[name] = newSeq[Address]()
        result[name].add( Address( family: family, # psutil_posix.nim(138, 42) Error: type mismatch: got <int32> but expected 'TSa_Family = uint16'
                                   address: address,
                                   netmask: netmask,
                                   broadcast: broadcast,
                                   ptp: ptp ) )

        current = current.pifaddrs

    freeifaddrs( interfaces )


proc psutil_convert_ipaddr(address: ptr SockAddr, family: posix.TSa_Family): string =
    result = newString(NI_MAXHOST)
    var addrlen: Socklen
    var resultLen: Socklen = NI_MAXHOST.uint32

    if address == nil:
        return ""

    if family.int == AF_INET or family.int == AF_INET6:
        if family.int == AF_INET:
            addrlen = sizeof(SockAddr_in).uint32
        else:
            addrlen = sizeof(SockAddr_in6).uint32

        let err = getnameinfo( address, addrlen, result, resultLen, nil, 0, NI_NUMERICHOST )
        if err != 0:
            # // XXX we get here on FreeBSD when processing 'lo' / AF_INET6
            # // broadcast. Not sure what to do other than returning None.
            # // ifconfig does not show anything BTW.
            return ""

        else:
            return result.strip(chars=Whitespace + {'\x00'})

    elif defined(linux) and family.int == AF_PACKET:
        var hw_address = cast[ptr sockaddr_ll](address)
        # TODO - this is going to break on non-Ethernet addresses (e.g. mac firewire - 8 bytes)
        # psutil actually handles this, i just wanted to test that it was working
        return "$1:$2:$3:$4:$5:$6".format( hw_address.sll_addr[0].int.toHex(2),
                                           hw_address.sll_addr[1].int.toHex(2),
                                           hw_address.sll_addr[2].int.toHex(2),
                                           hw_address.sll_addr[3].int.toHex(2),
                                           hw_address.sll_addr[4].int.toHex(2),
                                           hw_address.sll_addr[5].int.toHex(2) ).tolowerAscii()


    elif ( defined(freebsd) or defined(openbsd) or defined(darwin) or defined(netbsd) ) and family.int == AF_PACKET:
        # struct sockaddr_dl *dladdr = (struct sockaddr_dl *)addr;
        # len = dladdr->sdl_alen;
        # data = LLADDR(dladdr);
        discard

    else:
        # unknown family
        return ""


proc disk_usage*(path: string): DiskUsage =
    ## Return disk usage associated with path.
    ## Note: UNIX usually reserves 5% disk space which is not accessible
    ## by user. In this function "total" and "used" values reflect the
    ## total and used disk space whereas "free" and "percent" represent
    ## the "free" and "used percent" user disk space.

    var st: Statvfs
    let ret_code = statvfs(path, st)
    if ret_code == -1:
        raise newException(OSError, "disk_usage error: $1" % [$strerror( errno )] )

    # Total space which is only available to root (unless changed at system level).
    let total = (st.f_blocks * st.f_frsize)
    # Remaining free space usable by root.
    let avail_to_root = (st.f_bfree * st.f_frsize)
    # Remaining free space usable by user.
    let avail_to_user = (st.f_bavail * st.f_frsize)
    # Total space being used in general.
    let used = (total - avail_to_root)
    # Total space which is available to user (same as 'total' but for the user).
    let total_user = used + avail_to_user
    # User usage percent compared to the total amount of space
    # the user can use. This number would be higher if compared
    # to root's because the user has less space (usually -5%).
    let usage_percent_user = usage_percent(used, total_user, places=1)

    # NB: the percentage is -5% than what shown by df due to
    # reserved blocks that we are currently not considering:
    # https://github.com/giampaolo/psutil/issues/829#issuecomment-223750462
    return DiskUsage(total: total.int, used: used.int, free: avail_to_user.int, percent: usage_percent_user.float)


proc ioctlsocket*( iface_name: string, ioctl: uint, ifr: var ifreq ): bool =
    ##
    let sock = socket(posix.AF_INET, posix.SOCK_DGRAM, 0)
    if sock == SocketHandle(-1): return false
    var interface_name = iface_name
    copyMem( addr ifr.ifr_ifrn.ifrn_name, addr(interface_name[0]), len(iface_name) )

    let ret = ioctl(sock.cint, ioctl, addr ifr)
    if ret == -1: return false
    discard close( sock )
    return true


proc net_if_mtu*( name: string ): int =
    ## Return NIC MTU.
    ## References: http://www.i-scream.org/libstatgrab/

    var ifr: ifreq
    if ioctlsocket( name, SIOCGIFMTU, ifr ):
        result = ifr.ifr_ifru.ifru_mtu
    else:
        result = 0


proc net_if_flags*( name: string ): bool =
    ## Inspect NIC flags, returns a bool indicating whether the NIC is running.
    ## References: http://www.i-scream.org/libstatgrab/

    var ifr: ifreq
    if ioctlsocket( name, SIOCGIFFLAGS, ifr ):
        result = (ifr.ifr_ifru.ifru_flags and IFF_UP.cshort) != 0
    else:
        result = false

##
# net_if_stats() macOS/BSD implementation.
##

when bsdPlatform:
    {.compile: "arch/bsd_osx.c".}
    # import segfaults
    import system / ansi_c
    proc psutil_get_nic_speed*(ifm_active:cint):cint {.importc: "psutil_get_nic_speed".}

    type ifmediareq {.importc: "struct ifmediareq", header: "<net/if.h>",
            nodecl,pure.} = object
        ifm_name*:array[IFNAMSIZ,char]  # if name, e.g. "en0"
        ifm_current:cint    # current media options
        ifm_mask:cint    # don't care mask 
        ifm_status:cint    # media status 
        ifm_active:cint    # active options 
        ifm_count:cint    # entries in ifm_ulist array 
        ifm_ulist:ptr cint    # media words 

    const SIOCGIFMEDIA = 0xc0286938'u32
    const IFM_FDX = 0x00100000'u32
    const IFM_HDX = 2097152'u32

    proc net_if_duplex_speed*( nic_name: string ):tuple[ duplex: NicDuplex, speed: int ] =
        var
            sock:int = -1
            ret:int
            duplex:int
            speed:int
            ifr:ifreq
            ifmed:ifmediareq

        sock = socket(posix.AF_INET, posix.SOCK_DGRAM, 0).int
        # if (sock == -1)
        #     return PyErr_SetFromErrno(PyExc_OSError);
        # PSUTIL_STRNCPY(ifr.ifr_name, nic_name, sizeof(ifr.ifr_name));
        # https://github.com/giampaolo/psutil/blob/9efb453e7163690c82226be3440cd8cb6bdffb5b/psutil/_psutil_common.h#L19
        copyMem(ifmed.ifm_name.addr,nic_name.cstring,sizeof(ifr.ifr_ifrn.ifrn_name) - 1)
        ifmed.ifm_name[sizeof(ifr.ifr_ifrn.ifrn_name) - 1] = '\0'
        # speed / duplex
        c_memset(cast[pointer](ifmed.addr), 0, sizeof( ifmediareq).csize_t);
        # strlcpy(ifmed.ifm_name, nic_name, sizeof(ifmed.ifm_name));
        copyMem(ifmed.ifm_name.addr,nic_name.cstring,sizeof(ifmed.ifm_name))
        ret = ioctl(sock.FileHandle, SIOCGIFMEDIA, ifmed.addr)
        if ret == -1:
            debugEcho ret
            speed = 0
            duplex = 0
        else:
            speed = psutil_get_nic_speed(ifmed.ifm_active)
            if ((ifmed.ifm_active or IFM_FDX.cint) == ifmed.ifm_active):
                duplex = 2
            elif ((ifmed.ifm_active or IFM_HDX.cint) == ifmed.ifm_active):
                duplex = 1
            else:
                duplex = 0
        discard close(sock.SocketHandle)
        return  (duplex.NicDuplex, speed)

