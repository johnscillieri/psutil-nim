## A clone of "ifconfig" on UNIX.
## $ nim c -r ifconfig.nim
## lo:
##     stats          : speed=0MB, duplex=?, mtu=65536, up=yes
##     incoming       : bytes=6889336, pkts=84032, errs=0, drops=0
##     outgoing       : bytes=6889336, pkts=84032, errs=0, drops=0
##     IPv4 address   : 127.0.0.1
##          netmask   : 255.0.0.0
##     IPv6 address   : ::1
##          netmask   : ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff
##     MAC  address   : 00:00:00:00:00:00
## vboxnet0:
##     stats          : speed=10MB, duplex=full, mtu=1500, up=yes
##     incoming       : bytes=0, pkts=0, errs=0, drops=0
##     outgoing       : bytes=1622766, pkts=9102, errs=0, drops=0
##     IPv4 address   : 192.168.33.1
##          broadcast : 192.168.33.255
##          netmask   : 255.255.255.0
##     IPv6 address   : fe80::800:27ff:fe00:0%vboxnet0
##          netmask   : ffff:ffff:ffff:ffff::
##     MAC  address   : 0a:00:27:00:00:00
##          broadcast : ff:ff:ff:ff:ff:ff
## eth0:
##     stats          : speed=0MB, duplex=?, mtu=1500, up=yes
##     incoming       : bytes=18905596301, pkts=15178374, errs=0, drops=21
##     outgoing       : bytes=1913720087, pkts=9543981, errs=0, drops=0
##     IPv4 address   : 10.0.0.3
##          broadcast : 10.255.255.255
##          netmask   : 255.0.0.0
##     IPv6 address   : fe80::7592:1dcf:bcb7:98d6%wlp3s0
##          netmask   : ffff:ffff:ffff:ffff::
##     MAC  address   : 48:45:20:59:a4:0c
##          broadcast : ff:ff:ff:ff:ff:ff
import sequtils
import tables
when defined(posix):
    import posix
else:
    import winlean

import stringinterpolation

import psutil


var af_map = {
    AF_INET: "IPv4",
    AF_INET6: "IPv6",
    AF_PACKET.cint: "MAC",
}.toTable()

var duplex_map = {
    NIC_DUPLEX_FULL: "full",
    NIC_DUPLEX_HALF: "half",
    NIC_DUPLEX_UNKNOWN: "?",
}.toTable()


proc main() =
    let stats = psutil.net_if_stats()
    let io_counters = psutil.per_nic_net_io_counters()

    for nic, addrs in psutil.net_if_addrs():
        echo("%s:".format(nic))
        if nic in stats:
            let st = stats[nic]
            stdout.write("    stats          : ")
            echo("speed=%sMB, duplex=%s, mtu=%s, up=%s".format(
                st.speed, duplex_map[st.duplex], st.mtu,
                if st.isup: "yes" else: "no"))
        if nic in io_counters:
            let io = io_counters[nic]
            stdout.write("    incoming       : ")
            echo("bytes=%s, pkts=%s, errs=%s, drops=%s".format(
                io.bytes_recv, io.packets_recv, io.errin, io.dropin))
            stdout.write("    outgoing       : ")
            echo("bytes=%s, pkts=%s, errs=%s, drops=%s".format(
                io.bytes_sent, io.packets_sent, io.errout, io.dropout))
        for addr in addrs:
            if addr.address != nil:
                stdout.write( "    %-4s".format(af_map.mgetOrPut(addr.family.cint, $addr.family)) )
                echo(" address   : %s".format(addr.address))
            if addr.broadcast != nil:
                echo("         broadcast : %s".format(addr.broadcast))
            if addr.netmask != nil:
                echo("         netmask   : %s".format(addr.netmask))
            if addr.ptp != nil:
                echo("         p2p       : %s".format(addr.ptp))
        echo("")


when isMainModule:
    main()
