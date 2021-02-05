#include <netdb.h>
#include <netinet/in.h>
#include <net/if_dl.h>
#include <sys/sockio.h>
#include <net/if_media.h>
#include <net/if.h>

int psutil_get_nic_speed(int ifm_active) {
    // Determine NIC speed. Taken from:
    // http://www.i-scream.org/libstatgrab/
    // Assuming only ETHER devices
    switch(IFM_TYPE(ifm_active)) {
        case IFM_ETHER:
            switch(IFM_SUBTYPE(ifm_active)) {
#if defined(IFM_HPNA_1) && ((!defined(IFM_10G_LR)) \
    || (IFM_10G_LR != IFM_HPNA_1))
                // HomePNA 1.0 (1Mb/s)
                case(IFM_HPNA_1):
                    return 1;
#endif
                // 10 Mbit
                case(IFM_10_T):  // 10BaseT - RJ45
                case(IFM_10_2):  // 10Base2 - Thinnet
                case(IFM_10_5):  // 10Base5 - AUI
                case(IFM_10_STP):  // 10BaseT over shielded TP
                case(IFM_10_FL):  // 10baseFL - Fiber
                    return 10;
                // 100 Mbit
                case(IFM_100_TX):  // 100BaseTX - RJ45
                case(IFM_100_FX):  // 100BaseFX - Fiber
                case(IFM_100_T4):  // 100BaseT4 - 4 pair cat 3
                case(IFM_100_VG):  // 100VG-AnyLAN
                case(IFM_100_T2):  // 100BaseT2
                    return 100;
                // 1000 Mbit
                case(IFM_1000_SX):  // 1000BaseSX - multi-mode fiber
                case(IFM_1000_LX):  // 1000baseLX - single-mode fiber
                case(IFM_1000_CX):  // 1000baseCX - 150ohm STP
#if defined(IFM_1000_TX) && !defined(PSUTIL_OPENBSD)
                // FreeBSD 4 and others (but NOT OpenBSD) -> #define IFM_1000_T in net/if_media.h
                case(IFM_1000_TX):
#endif
#ifdef IFM_1000_FX
                case(IFM_1000_FX):
#endif
#ifdef IFM_1000_T
                case(IFM_1000_T):
#endif
                    return 1000;
#if defined(IFM_10G_SR) || defined(IFM_10G_LR) || defined(IFM_10G_CX4) \
         || defined(IFM_10G_T)
#ifdef IFM_10G_SR
                case(IFM_10G_SR):
#endif
#ifdef IFM_10G_LR
                case(IFM_10G_LR):
#endif
#ifdef IFM_10G_CX4
                case(IFM_10G_CX4):
#endif
#ifdef IFM_10G_TWINAX
                case(IFM_10G_TWINAX):
#endif
#ifdef IFM_10G_TWINAX_LONG
                case(IFM_10G_TWINAX_LONG):
#endif
#ifdef IFM_10G_T
                case(IFM_10G_T):
#endif
                    return 10000;
#endif
#if defined(IFM_2500_SX)
#ifdef IFM_2500_SX
                case(IFM_2500_SX):
#endif
                    return 2500;
#endif // any 2.5GBit stuff...
                // We don't know what it is
                default:
                    return 0;
            }
            break;

#ifdef IFM_TOKEN
        case IFM_TOKEN:
            switch(IFM_SUBTYPE(ifm_active)) {
                case IFM_TOK_STP4:  // Shielded twisted pair 4m - DB9
                case IFM_TOK_UTP4:  // Unshielded twisted pair 4m - RJ45
                    return 4;
                case IFM_TOK_STP16:  // Shielded twisted pair 16m - DB9
                case IFM_TOK_UTP16:  // Unshielded twisted pair 16m - RJ45
                    return 16;
#if defined(IFM_TOK_STP100) || defined(IFM_TOK_UTP100)
#ifdef IFM_TOK_STP100
                case IFM_TOK_STP100:  // Shielded twisted pair 100m - DB9
#endif
#ifdef IFM_TOK_UTP100
                case IFM_TOK_UTP100:  // Unshielded twisted pair 100m - RJ45
#endif
                    return 100;
#endif
                // We don't know what it is
                default:
                    return 0;
            }
            break;
#endif

#ifdef IFM_FDDI
        case IFM_FDDI:
            switch(IFM_SUBTYPE(ifm_active)) {
                // We don't know what it is
                default:
                    return 0;
            }
            break;
#endif
        case IFM_IEEE80211:
            switch(IFM_SUBTYPE(ifm_active)) {
                case IFM_IEEE80211_FH1:  // Frequency Hopping 1Mbps
                case IFM_IEEE80211_DS1:  // Direct Sequence 1Mbps
                    return 1;
                case IFM_IEEE80211_FH2:  // Frequency Hopping 2Mbps
                case IFM_IEEE80211_DS2:  // Direct Sequence 2Mbps
                    return 2;
                case IFM_IEEE80211_DS5:  // Direct Sequence 5Mbps
                    return 5;
                case IFM_IEEE80211_DS11:  // Direct Sequence 11Mbps
                    return 11;
                case IFM_IEEE80211_DS22:  // Direct Sequence 22Mbps
                    return 22;
                // We don't know what it is
                default:
                    return 0;
            }
            break;

        default:
            return 0;
    }
}