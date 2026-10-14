if ~ definite __ERRNO_H
__ERRNO_H = 1

EPERM = 1
ENOENT = 2
ESRCH = 3
EINTR = 4
EIO = 5
ENXIO = 6
E2BIG = 7
ENOEXEC = 8
EBADF = 9
ECHILD = 10
EAGAIN = 11
ENOMEM = 12
EACCES = 13
EFAULT = 14
ENOTBLK = 15
EBUSY = 16
EEXIST = 17
EXDEV = 18
ENODEV = 19
ENOTDIR = 20
EISDIR = 21
EINVAL = 22
ENFILE = 23
EMFILE = 24
ENOTTY = 25
ETXTBSY = 26
EFBIG = 27
ENOSPC = 28
ESPIPE = 29
EROFS = 30
EMLINK = 31
EPIPE = 32
EDOM = 33
ERANGE = 34
EDEADLK = 35
ENAMETOOLONG = 36
ENOLCK = 37
ENOSYS = 38
ENOTEMPTY = 39
ELOOP = 40
EWOULDBLOCK = EAGAIN
ENOMSG = 42
EIDRM = 43
ECHRNG = 44
EL2NSYNC = 45
EL3HLT = 46
EL3RST = 47
ELNRNG = 48
EUNATCH = 49
ENOCSI = 50
EL2HLT = 51
EBADE = 52
EBADR = 53
EXFULL = 54
ENOANO = 55
EBADRQC = 56
EBADSLT = 57
EDEADLOCK = EDEADLK
EBFONT = 59
ENOSTR = 60
ENODATA = 61
ETIME = 62
ENOSR = 63
ENONET = 64
ENOPKG = 65
EREMOTE = 66
ENOLINK = 67
EADV = 68
ESRMNT = 69
ECOMM = 70
EPROTO = 71
EMULTIHOP = 72
EDOTDOT = 73
EBADMSG = 74
EOVERFLOW = 75
ENOTUNIQ = 76
EBADFD = 77
EREMCHG = 78
ELIBACC = 79
ELIBBAD = 80
ELIBSCN = 81
ELIBMAX = 82
ELIBEXEC = 83
EILSEQ = 84
ERESTART = 85
ESTRPIPE = 86
EUSERS = 87
ENOTSOCK = 88
EDESTADDRREQ = 89
EMSGSIZE = 90
EPROTOTYPE = 91
ENOPROTOOPT = 92
EPROTONOSUPPORT = 93
ESOCKTNOSUPPORT = 94
EOPNOTSUPP = 95
EPFNOSUPPORT = 96
EAFNOSUPPORT = 97
EADDRINUSE = 98
EADDRNOTAVAIL = 99
ENETDOWN = 100
ENETUNREACH = 101
ENETRESET = 102
ECONNABORTED = 103
ECONNRESET = 104
ENOBUFS = 105
EISCONN = 106
ENOTCONN = 107
ESHUTDOWN = 108
ETOOMANYREFS = 109
ETIMEDOUT = 110
ECONNREFUSED = 111
EHOSTDOWN = 112
EHOSTUNREACH = 113
EALREADY = 114
EINPROGRESS = 115
ESTALE = 116
EUCLEAN = 117
ENOTNAM = 118
ENAVAIL = 119
EISNAM = 120
EREMOTEIO = 121
EDQUOT = 122
ENOMEDIUM = 123
EMEDIUMTYPE = 124
ECANCELED = 125
ENOKEY = 126
EKEYEXPIRED = 127
EKEYREVOKED = 128
EKEYREJECTED = 129
EOWNERDEAD = 130
ENOTRECOVERABLE = 131
ERFKILL = 132
EHWPOISON = 133

if used _errno_table_msg

  segment readable

    align 4

    _errno_table_msg dd _errno_0_msg, _errno_1_msg, _errno_2_msg, _errno_3_msg, _errno_4_msg, _errno_5_msg, _errno_6_msg, _errno_7_msg, _errno_8_msg, _errno_9_msg, _errno_10_msg, _errno_11_msg, _errno_12_msg, _errno_13_msg, _errno_14_msg, _errno_15_msg, _errno_16_msg, _errno_17_msg, _errno_18_msg, _errno_19_msg, _errno_20_msg, _errno_21_msg, _errno_22_msg, _errno_23_msg, _errno_24_msg, _errno_25_msg, _errno_26_msg, _errno_27_msg, _errno_28_msg, _errno_29_msg, _errno_30_msg, _errno_31_msg, _errno_32_msg, _errno_33_msg, _errno_34_msg, _errno_35_msg, _errno_36_msg, _errno_37_msg, _errno_38_msg, _errno_39_msg, _errno_40_msg, _errno_41_msg, _errno_42_msg, _errno_43_msg, _errno_44_msg, _errno_45_msg, _errno_46_msg, _errno_47_msg, _errno_48_msg, _errno_49_msg, _errno_50_msg, _errno_51_msg, _errno_52_msg, _errno_53_msg, _errno_54_msg, _errno_55_msg, _errno_56_msg, _errno_57_msg, _errno_58_msg, _errno_59_msg, _errno_60_msg, _errno_61_msg, _errno_62_msg, _errno_63_msg, _errno_64_msg, _errno_65_msg, _errno_66_msg, _errno_67_msg, _errno_68_msg, _errno_69_msg, _errno_70_msg, _errno_71_msg, _errno_72_msg, _errno_73_msg, _errno_74_msg, _errno_75_msg, _errno_76_msg, _errno_77_msg, _errno_78_msg, _errno_79_msg, _errno_80_msg, _errno_81_msg, _errno_82_msg, _errno_83_msg, _errno_84_msg, _errno_85_msg, _errno_86_msg, _errno_87_msg, _errno_88_msg, _errno_89_msg, _errno_90_msg, _errno_91_msg, _errno_92_msg, _errno_93_msg, _errno_94_msg, _errno_95_msg, _errno_96_msg, _errno_97_msg, _errno_98_msg, _errno_99_msg, _errno_100_msg, _errno_101_msg, _errno_102_msg, _errno_103_msg, _errno_104_msg, _errno_105_msg, _errno_106_msg, _errno_107_msg, _errno_108_msg, _errno_109_msg, _errno_110_msg, _errno_111_msg, _errno_112_msg, _errno_113_msg, _errno_114_msg, _errno_115_msg, _errno_116_msg, _errno_117_msg, _errno_118_msg, _errno_119_msg, _errno_120_msg, _errno_121_msg, _errno_122_msg, _errno_123_msg, _errno_124_msg, _errno_125_msg, _errno_126_msg, _errno_127_msg, _errno_128_msg, _errno_129_msg, _errno_130_msg, _errno_131_msg, _errno_132_msg, _errno_133_msg

    if (_errno_compact = 1)

      _errno_0_msg db "SUCCESS"
      _errno_0_len = $ - _errno_0_msg
      _errno_1_msg db "EPERM"
      _errno_1_len = $ - _errno_1_msg
      _errno_2_msg db "ENOENT"
      _errno_2_len = $ - _errno_2_msg
      _errno_3_msg db "ESRCH"
      _errno_3_len = $ - _errno_3_msg
      _errno_4_msg db "EINTR"
      _errno_4_len = $ - _errno_4_msg
      _errno_5_msg db "EIO"
      _errno_5_len = $ - _errno_5_msg
      _errno_6_msg db "ENXIO"
      _errno_6_len = $ - _errno_6_msg
      _errno_7_msg db "E2BIG"
      _errno_7_len = $ - _errno_7_msg
      _errno_8_msg db "ENOEXEC"
      _errno_8_len = $ - _errno_8_msg
      _errno_9_msg db "EBADF"
      _errno_9_len = $ - _errno_9_msg
      _errno_10_msg db "ECHILD"
      _errno_10_len = $ - _errno_10_msg
      _errno_11_msg db "EAGAIN"
      _errno_11_len = $ - _errno_11_msg
      _errno_12_msg db "ENOMEM"
      _errno_12_len = $ - _errno_12_msg
      _errno_13_msg db "EACCES"
      _errno_13_len = $ - _errno_13_msg
      _errno_14_msg db "EFAULT"
      _errno_14_len = $ - _errno_14_msg
      _errno_15_msg db "ENOTBLK"
      _errno_15_len = $ - _errno_15_msg
      _errno_16_msg db "EBUSY"
      _errno_16_len = $ - _errno_16_msg
      _errno_17_msg db "EEXIST"
      _errno_17_len = $ - _errno_17_msg
      _errno_18_msg db "EXDEV"
      _errno_18_len = $ - _errno_18_msg
      _errno_19_msg db "ENODEV"
      _errno_19_len = $ - _errno_19_msg
      _errno_20_msg db "ENOTDIR"
      _errno_20_len = $ - _errno_20_msg
      _errno_21_msg db "EISDIR"
      _errno_21_len = $ - _errno_21_msg
      _errno_22_msg db "EINVAL"
      _errno_22_len = $ - _errno_22_msg
      _errno_23_msg db "ENFILE"
      _errno_23_len = $ - _errno_23_msg
      _errno_24_msg db "EMFILE"
      _errno_24_len = $ - _errno_24_msg
      _errno_25_msg db "ENOTTY"
      _errno_25_len = $ - _errno_25_msg
      _errno_26_msg db "ETXTBSY"
      _errno_26_len = $ - _errno_26_msg
      _errno_27_msg db "EFBIG"
      _errno_27_len = $ - _errno_27_msg
      _errno_28_msg db "ENOSPC"
      _errno_28_len = $ - _errno_28_msg
      _errno_29_msg db "ESPIPE"
      _errno_29_len = $ - _errno_29_msg
      _errno_30_msg db "EROFS"
      _errno_30_len = $ - _errno_30_msg
      _errno_31_msg db "EMLINK"
      _errno_31_len = $ - _errno_31_msg
      _errno_32_msg db "EPIPE"
      _errno_32_len = $ - _errno_32_msg
      _errno_33_msg db "EDOM"
      _errno_33_len = $ - _errno_33_msg
      _errno_34_msg db "ERANGE"
      _errno_34_len = $ - _errno_34_msg
      _errno_35_msg db "EDEADLK"
      _errno_35_len = $ - _errno_35_msg
      _errno_36_msg db "ENAMETOOLONG"
      _errno_36_len = $ - _errno_36_msg
      _errno_37_msg db "ENOLCK"
      _errno_37_len = $ - _errno_37_msg
      _errno_38_msg db "ENOSYS"
      _errno_38_len = $ - _errno_38_msg
      _errno_39_msg db "ENOTEMPTY"
      _errno_39_len = $ - _errno_39_msg
      _errno_40_msg db "ELOOP"
      _errno_40_len = $ - _errno_40_msg
      _errno_41_msg db "UNKNOWN"
      _errno_41_len = $ - _errno_41_msg
      _errno_42_msg db "ENOMSG"
      _errno_42_len = $ - _errno_42_msg
      _errno_43_msg db "EIDRM"
      _errno_43_len = $ - _errno_43_msg
      _errno_44_msg db "ECHRNG"
      _errno_44_len = $ - _errno_44_msg
      _errno_45_msg db "EL2NSYNC"
      _errno_45_len = $ - _errno_45_msg
      _errno_46_msg db "EL3HLT"
      _errno_46_len = $ - _errno_46_msg
      _errno_47_msg db "EL3RST"
      _errno_47_len = $ - _errno_47_msg
      _errno_48_msg db "ELNRNG"
      _errno_48_len = $ - _errno_48_msg
      _errno_49_msg db "EUNATCH"
      _errno_49_len = $ - _errno_49_msg
      _errno_50_msg db "ENOCSI"
      _errno_50_len = $ - _errno_50_msg
      _errno_51_msg db "EL2HLT"
      _errno_51_len = $ - _errno_51_msg
      _errno_52_msg db "EBADE"
      _errno_52_len = $ - _errno_52_msg
      _errno_53_msg db "EBADR"
      _errno_53_len = $ - _errno_53_msg
      _errno_54_msg db "EXFULL"
      _errno_54_len = $ - _errno_54_msg
      _errno_55_msg db "ENOANO"
      _errno_55_len = $ - _errno_55_msg
      _errno_56_msg db "EBADRQC"
      _errno_56_len = $ - _errno_56_msg
      _errno_57_msg db "EBADSLT"
      _errno_57_len = $ - _errno_57_msg
      _errno_58_msg db "UNKNOWN"
      _errno_58_len = $ - _errno_58_msg
      _errno_59_msg db "EBFONT"
      _errno_59_len = $ - _errno_59_msg
      _errno_60_msg db "ENOSTR"
      _errno_60_len = $ - _errno_60_msg
      _errno_61_msg db "ENODATA"
      _errno_61_len = $ - _errno_61_msg
      _errno_62_msg db "ETIME"
      _errno_62_len = $ - _errno_62_msg
      _errno_63_msg db "ENOSR"
      _errno_63_len = $ - _errno_63_msg
      _errno_64_msg db "ENONET"
      _errno_64_len = $ - _errno_64_msg
      _errno_65_msg db "ENOPKG"
      _errno_65_len = $ - _errno_65_msg
      _errno_66_msg db "EREMOTE"
      _errno_66_len = $ - _errno_66_msg
      _errno_67_msg db "ENOLINK"
      _errno_67_len = $ - _errno_67_msg
      _errno_68_msg db "EADV"
      _errno_68_len = $ - _errno_68_msg
      _errno_69_msg db "ESRMNT"
      _errno_69_len = $ - _errno_69_msg
      _errno_70_msg db "ECOMM"
      _errno_70_len = $ - _errno_70_msg
      _errno_71_msg db "EPROTO"
      _errno_71_len = $ - _errno_71_msg
      _errno_72_msg db "EMULTIHOP"
      _errno_72_len = $ - _errno_72_msg
      _errno_73_msg db "EDOTDOT"
      _errno_73_len = $ - _errno_73_msg
      _errno_74_msg db "EBADMSG"
      _errno_74_len = $ - _errno_74_msg
      _errno_75_msg db "EOVERFLOW"
      _errno_75_len = $ - _errno_75_msg
      _errno_76_msg db "ENOTUNIQ"
      _errno_76_len = $ - _errno_76_msg
      _errno_77_msg db "EBADFD"
      _errno_77_len = $ - _errno_77_msg
      _errno_78_msg db "EREMCHG"
      _errno_78_len = $ - _errno_78_msg
      _errno_79_msg db "ELIBACC"
      _errno_79_len = $ - _errno_79_msg
      _errno_80_msg db "ELIBBAD"
      _errno_80_len = $ - _errno_80_msg
      _errno_81_msg db "ELIBSCN"
      _errno_81_len = $ - _errno_81_msg
      _errno_82_msg db "ELIBMAX"
      _errno_82_len = $ - _errno_82_msg
      _errno_83_msg db "ELIBEXEC"
      _errno_83_len = $ - _errno_83_msg
      _errno_84_msg db "EILSEQ"
      _errno_84_len = $ - _errno_84_msg
      _errno_85_msg db "ERESTART"
      _errno_85_len = $ - _errno_85_msg
      _errno_86_msg db "ESTRPIPE"
      _errno_86_len = $ - _errno_86_msg
      _errno_87_msg db "EUSERS"
      _errno_87_len = $ - _errno_87_msg
      _errno_88_msg db "ENOTSOCK"
      _errno_88_len = $ - _errno_88_msg
      _errno_89_msg db "EDESTADDRREQ"
      _errno_89_len = $ - _errno_89_msg
      _errno_90_msg db "EMSGSIZE"
      _errno_90_len = $ - _errno_90_msg
      _errno_91_msg db "EPROTOTYPE"
      _errno_91_len = $ - _errno_91_msg
      _errno_92_msg db "ENOPROTOOPT"
      _errno_92_len = $ - _errno_92_msg
      _errno_93_msg db "EPROTONOSUPPORT"
      _errno_93_len = $ - _errno_93_msg
      _errno_94_msg db "ESOCKTNOSUPPORT"
      _errno_94_len = $ - _errno_94_msg
      _errno_95_msg db "EOPNOTSUPP"
      _errno_95_len = $ - _errno_95_msg
      _errno_96_msg db "EPFNOSUPPORT"
      _errno_96_len = $ - _errno_96_msg
      _errno_97_msg db "EAFNOSUPPORT"
      _errno_97_len = $ - _errno_97_msg
      _errno_98_msg db "EADDRINUSE"
      _errno_98_len = $ - _errno_98_msg
      _errno_99_msg db "EADDRNOTAVAIL"
      _errno_99_len = $ - _errno_99_msg
      _errno_100_msg db "ENETDOWN"
      _errno_100_len = $ - _errno_100_msg
      _errno_101_msg db "ENETUNREACH"
      _errno_101_len = $ - _errno_101_msg
      _errno_102_msg db "ENETRESET"
      _errno_102_len = $ - _errno_102_msg
      _errno_103_msg db "ECONNABORTED"
      _errno_103_len = $ - _errno_103_msg
      _errno_104_msg db "ECONNRESET"
      _errno_104_len = $ - _errno_104_msg
      _errno_105_msg db "ENOBUFS"
      _errno_105_len = $ - _errno_105_msg
      _errno_106_msg db "EISCONN"
      _errno_106_len = $ - _errno_106_msg
      _errno_107_msg db "ENOTCONN"
      _errno_107_len = $ - _errno_107_msg
      _errno_108_msg db "ESHUTDOWN"
      _errno_108_len = $ - _errno_108_msg
      _errno_109_msg db "ETOOMANYREFS"
      _errno_109_len = $ - _errno_109_msg
      _errno_110_msg db "ETIMEDOUT"
      _errno_110_len = $ - _errno_110_msg
      _errno_111_msg db "ECONNREFUSED"
      _errno_111_len = $ - _errno_111_msg
      _errno_112_msg db "EHOSTDOWN"
      _errno_112_len = $ - _errno_112_msg
      _errno_113_msg db "EHOSTUNREACH"
      _errno_113_len = $ - _errno_113_msg
      _errno_114_msg db "EALREADY"
      _errno_114_len = $ - _errno_114_msg
      _errno_115_msg db "EINPROGRESS"
      _errno_115_len = $ - _errno_115_msg
      _errno_116_msg db "ESTALE"
      _errno_116_len = $ - _errno_116_msg
      _errno_117_msg db "EUCLEAN"
      _errno_117_len = $ - _errno_117_msg
      _errno_118_msg db "ENOTNAM"
      _errno_118_len = $ - _errno_118_msg
      _errno_119_msg db "ENAVAIL"
      _errno_119_len = $ - _errno_119_msg
      _errno_120_msg db "EISNAM"
      _errno_120_len = $ - _errno_120_msg
      _errno_121_msg db "EREMOTEIO"
      _errno_121_len = $ - _errno_121_msg
      _errno_122_msg db "EDQUOT"
      _errno_122_len = $ - _errno_122_msg
      _errno_123_msg db "ENOMEDIUM"
      _errno_123_len = $ - _errno_123_msg
      _errno_124_msg db "EMEDIUMTYPE"
      _errno_124_len = $ - _errno_124_msg
      _errno_125_msg db "ECANCELED"
      _errno_125_len = $ - _errno_125_msg
      _errno_126_msg db "ENOKEY"
      _errno_126_len = $ - _errno_126_msg
      _errno_127_msg db "EKEYEXPIRED"
      _errno_127_len = $ - _errno_127_msg
      _errno_128_msg db "EKEYREVOKED"
      _errno_128_len = $ - _errno_128_msg
      _errno_129_msg db "EKEYREJECTED"
      _errno_129_len = $ - _errno_129_msg
      _errno_130_msg db "EOWNERDEAD"
      _errno_130_len = $ - _errno_130_msg
      _errno_131_msg db "ENOTRECOVERABLE"
      _errno_131_len = $ - _errno_131_msg
      _errno_132_msg db "ERFKILL"
      _errno_132_len = $ - _errno_132_msg
      _errno_133_msg db "EHWPOISON"
      _errno_133_len = $ - _errno_133_msg

    else

      _errno_0_msg db "Success"
      _errno_0_len = $ - _errno_0_msg
      _errno_1_msg db "Operation not permitted"
      _errno_1_len = $ - _errno_1_msg
      _errno_2_msg db "No such file or directory"
      _errno_2_len = $ - _errno_2_msg
      _errno_3_msg db "No such process"
      _errno_3_len = $ - _errno_3_msg
      _errno_4_msg db "Interrupted system call"
      _errno_4_len = $ - _errno_4_msg
      _errno_5_msg db "Input/output error"
      _errno_5_len = $ - _errno_5_msg
      _errno_6_msg db "No such device or address"
      _errno_6_len = $ - _errno_6_msg
      _errno_7_msg db "Argument list too long"
      _errno_7_len = $ - _errno_7_msg
      _errno_8_msg db "Exec format error"
      _errno_8_len = $ - _errno_8_msg
      _errno_9_msg db "Bad file descriptor"
      _errno_9_len = $ - _errno_9_msg
      _errno_10_msg db "No child processes"
      _errno_10_len = $ - _errno_10_msg
      _errno_11_msg db "Resource temporarily unavailable"
      _errno_11_len = $ - _errno_11_msg
      _errno_12_msg db "Cannot allocate memory"
      _errno_12_len = $ - _errno_12_msg
      _errno_13_msg db "Permission denied"
      _errno_13_len = $ - _errno_13_msg
      _errno_14_msg db "Bad address"
      _errno_14_len = $ - _errno_14_msg
      _errno_15_msg db "Block device required"
      _errno_15_len = $ - _errno_15_msg
      _errno_16_msg db "Device or resource busy"
      _errno_16_len = $ - _errno_16_msg
      _errno_17_msg db "File exists"
      _errno_17_len = $ - _errno_17_msg
      _errno_18_msg db "Invalid cross-device link"
      _errno_18_len = $ - _errno_18_msg
      _errno_19_msg db "No such device"
      _errno_19_len = $ - _errno_19_msg
      _errno_20_msg db "Not a directory"
      _errno_20_len = $ - _errno_20_msg
      _errno_21_msg db "Is a directory"
      _errno_21_len = $ - _errno_21_msg
      _errno_22_msg db "Invalid argument"
      _errno_22_len = $ - _errno_22_msg
      _errno_23_msg db "Too many open files in system"
      _errno_23_len = $ - _errno_23_msg
      _errno_24_msg db "Too many open files"
      _errno_24_len = $ - _errno_24_msg
      _errno_25_msg db "Inappropriate ioctl for device"
      _errno_25_len = $ - _errno_25_msg
      _errno_26_msg db "Text file busy"
      _errno_26_len = $ - _errno_26_msg
      _errno_27_msg db "File too large"
      _errno_27_len = $ - _errno_27_msg
      _errno_28_msg db "No space left on device"
      _errno_28_len = $ - _errno_28_msg
      _errno_29_msg db "Illegal seek"
      _errno_29_len = $ - _errno_29_msg
      _errno_30_msg db "Read-only file system"
      _errno_30_len = $ - _errno_30_msg
      _errno_31_msg db "Too many links"
      _errno_31_len = $ - _errno_31_msg
      _errno_32_msg db "Broken pipe"
      _errno_32_len = $ - _errno_32_msg
      _errno_33_msg db "Numerical argument out of domain"
      _errno_33_len = $ - _errno_33_msg
      _errno_34_msg db "Numerical result out of range"
      _errno_34_len = $ - _errno_34_msg
      _errno_35_msg db "Resource deadlock avoided"
      _errno_35_len = $ - _errno_35_msg
      _errno_36_msg db "File name too long"
      _errno_36_len = $ - _errno_36_msg
      _errno_37_msg db "No locks available"
      _errno_37_len = $ - _errno_37_msg
      _errno_38_msg db "Function not implemented"
      _errno_38_len = $ - _errno_38_msg
      _errno_39_msg db "Directory not empty"
      _errno_39_len = $ - _errno_39_msg
      _errno_40_msg db "Too many levels of symbolic links"
      _errno_40_len = $ - _errno_40_msg
      _errno_41_msg db "Unknown error 41"
      _errno_41_len = $ - _errno_41_msg
      _errno_42_msg db "No message of desired type"
      _errno_42_len = $ - _errno_42_msg
      _errno_43_msg db "Identifier removed"
      _errno_43_len = $ - _errno_43_msg
      _errno_44_msg db "Channel number out of range"
      _errno_44_len = $ - _errno_44_msg
      _errno_45_msg db "Level 2 not synchronized"
      _errno_45_len = $ - _errno_45_msg
      _errno_46_msg db "Level 3 halted"
      _errno_46_len = $ - _errno_46_msg
      _errno_47_msg db "Level 3 reset"
      _errno_47_len = $ - _errno_47_msg
      _errno_48_msg db "Link number out of range"
      _errno_48_len = $ - _errno_48_msg
      _errno_49_msg db "Protocol driver not attached"
      _errno_49_len = $ - _errno_49_msg
      _errno_50_msg db "No CSI structure available"
      _errno_50_len = $ - _errno_50_msg
      _errno_51_msg db "Level 2 halted"
      _errno_51_len = $ - _errno_51_msg
      _errno_52_msg db "Invalid exchange"
      _errno_52_len = $ - _errno_52_msg
      _errno_53_msg db "Invalid request descriptor"
      _errno_53_len = $ - _errno_53_msg
      _errno_54_msg db "Exchange full"
      _errno_54_len = $ - _errno_54_msg
      _errno_55_msg db "No anode"
      _errno_55_len = $ - _errno_55_msg
      _errno_56_msg db "Invalid request code"
      _errno_56_len = $ - _errno_56_msg
      _errno_57_msg db "Invalid slot"
      _errno_57_len = $ - _errno_57_msg
      _errno_58_msg db "Unknown error 58"
      _errno_58_len = $ - _errno_58_msg
      _errno_59_msg db "Bad font file format"
      _errno_59_len = $ - _errno_59_msg
      _errno_60_msg db "Device not a stream"
      _errno_60_len = $ - _errno_60_msg
      _errno_61_msg db "No data available"
      _errno_61_len = $ - _errno_61_msg
      _errno_62_msg db "Timer expired"
      _errno_62_len = $ - _errno_62_msg
      _errno_63_msg db "Out of streams resources"
      _errno_63_len = $ - _errno_63_msg
      _errno_64_msg db "Machine is not on the network"
      _errno_64_len = $ - _errno_64_msg
      _errno_65_msg db "Package not installed"
      _errno_65_len = $ - _errno_65_msg
      _errno_66_msg db "Object is remote"
      _errno_66_len = $ - _errno_66_msg
      _errno_67_msg db "Link has been severed"
      _errno_67_len = $ - _errno_67_msg
      _errno_68_msg db "Advertise error"
      _errno_68_len = $ - _errno_68_msg
      _errno_69_msg db "Srmount error"
      _errno_69_len = $ - _errno_69_msg
      _errno_70_msg db "Communication error on send"
      _errno_70_len = $ - _errno_70_msg
      _errno_71_msg db "Protocol error"
      _errno_71_len = $ - _errno_71_msg
      _errno_72_msg db "Multihop attempted"
      _errno_72_len = $ - _errno_72_msg
      _errno_73_msg db "RFS specific error"
      _errno_73_len = $ - _errno_73_msg
      _errno_74_msg db "Bad message"
      _errno_74_len = $ - _errno_74_msg
      _errno_75_msg db "Value too large for defined data type"
      _errno_75_len = $ - _errno_75_msg
      _errno_76_msg db "Name not unique on network"
      _errno_76_len = $ - _errno_76_msg
      _errno_77_msg db "File descriptor in bad state"
      _errno_77_len = $ - _errno_77_msg
      _errno_78_msg db "Remote address changed"
      _errno_78_len = $ - _errno_78_msg
      _errno_79_msg db "Can not access a needed shared library"
      _errno_79_len = $ - _errno_79_msg
      _errno_80_msg db "Accessing a corrupted shared library"
      _errno_80_len = $ - _errno_80_msg
      _errno_81_msg db ".lib section in a.out corrupted"
      _errno_81_len = $ - _errno_81_msg
      _errno_82_msg db "Attempting to link in too many shared libraries"
      _errno_82_len = $ - _errno_82_msg
      _errno_83_msg db "Cannot exec a shared library directly"
      _errno_83_len = $ - _errno_83_msg
      _errno_84_msg db "Invalid or incomplete multibyte or wide character"
      _errno_84_len = $ - _errno_84_msg
      _errno_85_msg db "Interrupted system call should be restarted"
      _errno_85_len = $ - _errno_85_msg
      _errno_86_msg db "Streams pipe error"
      _errno_86_len = $ - _errno_86_msg
      _errno_87_msg db "Too many users"
      _errno_87_len = $ - _errno_87_msg
      _errno_88_msg db "Socket operation on non-socket"
      _errno_88_len = $ - _errno_88_msg
      _errno_89_msg db "Destination address required"
      _errno_89_len = $ - _errno_89_msg
      _errno_90_msg db "Message too long"
      _errno_90_len = $ - _errno_90_msg
      _errno_91_msg db "Protocol wrong type for socket"
      _errno_91_len = $ - _errno_91_msg
      _errno_92_msg db "Protocol not available"
      _errno_92_len = $ - _errno_92_msg
      _errno_93_msg db "Protocol not supported"
      _errno_93_len = $ - _errno_93_msg
      _errno_94_msg db "Socket type not supported"
      _errno_94_len = $ - _errno_94_msg
      _errno_95_msg db "Operation not supported"
      _errno_95_len = $ - _errno_95_msg
      _errno_96_msg db "Protocol family not supported"
      _errno_96_len = $ - _errno_96_msg
      _errno_97_msg db "Address family not supported by protocol"
      _errno_97_len = $ - _errno_97_msg
      _errno_98_msg db "Address already in use"
      _errno_98_len = $ - _errno_98_msg
      _errno_99_msg db "Cannot assign requested address"
      _errno_99_len = $ - _errno_99_msg
      _errno_100_msg db "Network is down"
      _errno_100_len = $ - _errno_100_msg
      _errno_101_msg db "Network is unreachable"
      _errno_101_len = $ - _errno_101_msg
      _errno_102_msg db "Network dropped connection on reset"
      _errno_102_len = $ - _errno_102_msg
      _errno_103_msg db "Software caused connection abort"
      _errno_103_len = $ - _errno_103_msg
      _errno_104_msg db "Connection reset by peer"
      _errno_104_len = $ - _errno_104_msg
      _errno_105_msg db "No buffer space available"
      _errno_105_len = $ - _errno_105_msg
      _errno_106_msg db "Transport endpoint is already connected"
      _errno_106_len = $ - _errno_106_msg
      _errno_107_msg db "Transport endpoint is not connected"
      _errno_107_len = $ - _errno_107_msg
      _errno_108_msg db "Cannot send after transport endpoint shutdown"
      _errno_108_len = $ - _errno_108_msg
      _errno_109_msg db "Too many references: cannot splice"
      _errno_109_len = $ - _errno_109_msg
      _errno_110_msg db "Connection timed out"
      _errno_110_len = $ - _errno_110_msg
      _errno_111_msg db "Connection refused"
      _errno_111_len = $ - _errno_111_msg
      _errno_112_msg db "Host is down"
      _errno_112_len = $ - _errno_112_msg
      _errno_113_msg db "No route to host"
      _errno_113_len = $ - _errno_113_msg
      _errno_114_msg db "Operation already in progress"
      _errno_114_len = $ - _errno_114_msg
      _errno_115_msg db "Operation now in progress"
      _errno_115_len = $ - _errno_115_msg
      _errno_116_msg db "Stale file handle"
      _errno_116_len = $ - _errno_116_msg
      _errno_117_msg db "Structure needs cleaning"
      _errno_117_len = $ - _errno_117_msg
      _errno_118_msg db "Not a XENIX named type file"
      _errno_118_len = $ - _errno_118_msg
      _errno_119_msg db "No XENIX semaphores available"
      _errno_119_len = $ - _errno_119_msg
      _errno_120_msg db "Is a named type file"
      _errno_120_len = $ - _errno_120_msg
      _errno_121_msg db "Remote I/O error"
      _errno_121_len = $ - _errno_121_msg
      _errno_122_msg db "Disk quota exceeded"
      _errno_122_len = $ - _errno_122_msg
      _errno_123_msg db "No medium found"
      _errno_123_len = $ - _errno_123_msg
      _errno_124_msg db "Wrong medium type"
      _errno_124_len = $ - _errno_124_msg
      _errno_125_msg db "Operation canceled"
      _errno_125_len = $ - _errno_125_msg
      _errno_126_msg db "Required key not available"
      _errno_126_len = $ - _errno_126_msg
      _errno_127_msg db "Key has expired"
      _errno_127_len = $ - _errno_127_msg
      _errno_128_msg db "Key has been revoked"
      _errno_128_len = $ - _errno_128_msg
      _errno_129_msg db "Key was rejected by service"
      _errno_129_len = $ - _errno_129_msg
      _errno_130_msg db "Owner died"
      _errno_130_len = $ - _errno_130_msg
      _errno_131_msg db "State not recoverable"
      _errno_131_len = $ - _errno_131_msg
      _errno_132_msg db "Operation not possible due to RF-kill"
      _errno_132_len = $ - _errno_132_msg
      _errno_133_msg db "Memory page has hardware error"
      _errno_133_len = $ - _errno_133_msg

    end if

end if

if used _errno_table_len

  segment readable

    _errno_table_len db _errno_0_len, _errno_1_len, _errno_2_len, _errno_3_len, _errno_4_len, _errno_5_len, _errno_6_len, _errno_7_len, _errno_8_len, _errno_9_len, _errno_10_len, _errno_11_len, _errno_12_len, _errno_13_len, _errno_14_len, _errno_15_len, _errno_16_len, _errno_17_len, _errno_18_len, _errno_19_len, _errno_20_len, _errno_21_len, _errno_22_len, _errno_23_len, _errno_24_len, _errno_25_len, _errno_26_len, _errno_27_len, _errno_28_len, _errno_29_len, _errno_30_len, _errno_31_len, _errno_32_len, _errno_33_len, _errno_34_len, _errno_35_len, _errno_36_len, _errno_37_len, _errno_38_len, _errno_39_len, _errno_40_len, _errno_41_len, _errno_42_len, _errno_43_len, _errno_44_len, _errno_45_len, _errno_46_len, _errno_47_len, _errno_48_len, _errno_49_len, _errno_50_len, _errno_51_len, _errno_52_len, _errno_53_len, _errno_54_len, _errno_55_len, _errno_56_len, _errno_57_len, _errno_58_len, _errno_59_len, _errno_60_len, _errno_61_len, _errno_62_len, _errno_63_len, _errno_64_len, _errno_65_len, _errno_66_len, _errno_67_len, _errno_68_len, _errno_69_len, _errno_70_len, _errno_71_len, _errno_72_len, _errno_73_len, _errno_74_len, _errno_75_len, _errno_76_len, _errno_77_len, _errno_78_len, _errno_79_len, _errno_80_len, _errno_81_len, _errno_82_len, _errno_83_len, _errno_84_len, _errno_85_len, _errno_86_len, _errno_87_len, _errno_88_len, _errno_89_len, _errno_90_len, _errno_91_len, _errno_92_len, _errno_93_len, _errno_94_len, _errno_95_len, _errno_96_len, _errno_97_len, _errno_98_len, _errno_99_len, _errno_100_len, _errno_101_len, _errno_102_len, _errno_103_len, _errno_104_len, _errno_105_len, _errno_106_len, _errno_107_len, _errno_108_len, _errno_109_len, _errno_110_len, _errno_111_len, _errno_112_len, _errno_113_len, _errno_114_len, _errno_115_len, _errno_116_len, _errno_117_len, _errno_118_len, _errno_119_len, _errno_120_len, _errno_121_len, _errno_122_len, _errno_123_len, _errno_124_len, _errno_125_len, _errno_126_len, _errno_127_len, _errno_128_len, _errno_129_len, _errno_130_len, _errno_131_len, _errno_132_len, _errno_133_len

end if

end if

