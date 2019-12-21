import ./types
const TSI_T_NTIMERS = 4
type vinfo_stat* = object # https://github.com/alecmocatta/socketstat/blob/062fae4f10d673fb447bfc9c5748f14dbd86c46d/src/mac.rs
    vst_dev*:uint32           # [XSI] ID of device containing file */
    vst_mode*:uint16          # [XSI] Mode of file (see below) */
    vst_nlink*:uint16         # [XSI] Number of hard links */
    vst_ino*:uint64           # [XSI] File serial number */
    vst_uid*:uid_t         # [XSI] User ID of the file */
    vst_gid*:gid_t         # [XSI] Group ID of the file */
    vst_atime*:int64         # [XSI] Time of last access */
    vst_atimensec*:int64     # nsec of last access */
    vst_mtime*:int64         # [XSI] Last data modification time */
    vst_mtimensec*:int64     # last data modification nsec */
    vst_ctime*:int64         # [XSI] Time of last status change */
    vst_ctimensec*:int64     # nsec of last status change */
    vst_birthtime*:int64     # File creation time(birth) */
    vst_birthtimensec*:int64 # nsec of File creation time */
    vst_size*:off_t        # [XSI] file size, in bytes */
    vst_blocks*:int64        # [XSI] blocks allocated for file */
    vst_blksize*:int32       # [XSI] optimal blocksize for I/O */
    vst_flags*:uint32         # user defined flags for file */
    vst_gen*:uint32           # file generation number */
    vst_rdev*:uint32          # [XSI] Device ID */
    vst_qspare*:array[2,int64]   # RESERVED*:DO NOT USE! */

type sockbuf_info* = object
    sbi_cc*:uint32
    sbi_hiwat*:uint32 # SO_RCVBUF, SO_SNDBUF */
    sbi_mbcnt*:uint32
    sbi_mbmax*:uint32
    sbi_lowat*:uint32
    sbi_flags*:cshort
    sbi_timeo*:cshort

type insi_v4 = object
    in4_tos*:cuchar # u_char type of service */

type insi_v6 = object
    in6_hlim*:uint8
    in6_cksum*:cint
    in6_ifindex*:cushort
    in6_hops*:cshort


type in_sockinfo* = object
    insi_fport*:cint  # foreign port */
    insi_lport*:cint  # local port */
    insi_gencnt*:uint64 # generation count of this instance */
    insi_flags*:uint32  # generic IP/datagram flags */
    insi_flow*:uint32
    insi_vflag*:uint8  # ini_IPV4 or ini_IPV6 */
    insi_ip_ttl*:uint8 # time to live proto */
    rfu_1*:uint32      # reserved */
    # protocol dependent part */
    insi_faddr*:pointer # foreign host table entry */
    insi_laddr*:pointer # local host table entry */
    insi_v4*:insi_v4
    insi_v6*:insi_v6

type tcp_sockinfo = object
    tcpsi_ini*:in_sockinfo
    tcpsi_state*:cint
    tcpsi_timer*:array[TSI_T_NTIMERS,cint]
    tcpsi_mss*:cint
    tcpsi_flags*:uint32
    rfu_1*:uint32    # reserved */
    tcpsi_tp*:uint64 # opaque handle of TCP protocol control block */

type pri*{.importc:"struct pri",header:"<sys/socket.h>",pure.} = object
    pri_in*:in_sockinfo   # SOCKINFO_IN */
    pri_tcp*:tcp_sockinfo # SOCKINFO_TCP */
    hack_to_avoid_copying_more_structs*:array[ 524 ,uint8]

type socket_info*{.importc:"struct socket_info",header:"<sys/socket.h>",pure.} = object
    soi_stat*:vinfo_stat
    soi_so*:uint64  # opaque handle of socket */
    soi_pcb*:uint64 # opaque handle of protocol control block */
    soi_type*:cint
    soi_protocol*:cint
    soi_family*:cint
    soi_options*:cshort
    soi_linger*:cshort
    soi_state*:cshort
    soi_qlen*:cshort
    soi_incqlen*:cshort
    soi_qlimit*:cshort
    soi_timeo*:cshort
    soi_error*:uint16 #ushort
    soi_oobmark*:uint32
    soi_rcv*:sockbuf_info
    soi_snd*:sockbuf_info
    soi_kind*:cint
    rfu_1*:uint32 # reserved */
    soi_proto*:pri