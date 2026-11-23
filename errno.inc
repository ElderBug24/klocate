if ~ definite __ERRNO_H
__ERRNO_H equ 1

EPERM equ 1
ENOENT equ 2
ESRCH equ 3
EINTR equ 4
EIO equ 5
ENXIO equ 6
E2BIG equ 7
ENOEXEC equ 8
EBADF equ 9
ECHILD equ 10
EAGAIN equ 11
ENOMEM equ 12
EACCES equ 13
EFAULT equ 14
ENOTBLK equ 15
EBUSY equ 16
EEXIST equ 17
EXDEV equ 18
ENODEV equ 19
ENOTDIR equ 20
EISDIR equ 21
EINVAL equ 22
ENFILE equ 23
EMFILE equ 24
ENOTTY equ 25
ETXTBSY equ 26
EFBIG equ 27
ENOSPC equ 28
ESPIPE equ 29
EROFS equ 30
EMLINK equ 31
EPIPE equ 32
EDOM equ 33
ERANGE equ 34
EDEADLK equ 35
ENAMETOOLONG equ 36
ENOLCK equ 37
ENOSYS equ 38
ENOTEMPTY equ 39
ELOOP equ 40
EWOULDBLOCK equ EAGAIN
ENOMSG equ 42
EIDRM equ 43
ECHRNG equ 44
EL2NSYNC equ 45
EL3HLT equ 46
EL3RST equ 47
ELNRNG equ 48
EUNATCH equ 49
ENOCSI equ 50
EL2HLT equ 51
EBADE equ 52
EBADR equ 53
EXFULL equ 54
ENOANO equ 55
EBADRQC equ 56
EBADSLT equ 57
EDEADLOCK equ EDEADLK
EBFONT equ 59
ENOSTR equ 60
ENODATA equ 61
ETIME equ 62
ENOSR equ 63
ENONET equ 64
ENOPKG equ 65
EREMOTE equ 66
ENOLINK equ 67
EADV equ 68
ESRMNT equ 69
ECOMM equ 70
EPROTO equ 71
EMULTIHOP equ 72
EDOTDOT equ 73
EBADMSG equ 74
EOVERFLOW equ 75
ENOTUNIQ equ 76
EBADFD equ 77
EREMCHG equ 78
ELIBACC equ 79
ELIBBAD equ 80
ELIBSCN equ 81
ELIBMAX equ 82
ELIBEXEC equ 83
EILSEQ equ 84
ERESTART equ 85
ESTRPIPE equ 86
EUSERS equ 87
ENOTSOCK equ 88
EDESTADDRREQ equ 89
EMSGSIZE equ 90
EPROTOTYPE equ 91
ENOPROTOOPT equ 92
EPROTONOSUPPORT equ 93
ESOCKTNOSUPPORT equ 94
EOPNOTSUPP equ 95
EPFNOSUPPORT equ 96
EAFNOSUPPORT equ 97
EADDRINUSE equ 98
EADDRNOTAVAIL equ 99
ENETDOWN equ 100
ENETUNREACH equ 101
ENETRESET equ 102
ECONNABORTED equ 103
ECONNRESET equ 104
ENOBUFS equ 105
EISCONN equ 106
ENOTCONN equ 107
ESHUTDOWN equ 108
ETOOMANYREFS equ 109
ETIMEDOUT equ 110
ECONNREFUSED equ 111
EHOSTDOWN equ 112
EHOSTUNREACH equ 113
EALREADY equ 114
EINPROGRESS equ 115
ESTALE equ 116
EUCLEAN equ 117
ENOTNAM equ 118
ENAVAIL equ 119
EISNAM equ 120
EREMOTEIO equ 121
EDQUOT equ 122
ENOMEDIUM equ 123
EMEDIUMTYPE equ 124
ECANCELED equ 125
ENOKEY equ 126
EKEYEXPIRED equ 127
EKEYREVOKED equ 128
EKEYREJECTED equ 129
EOWNERDEAD equ 130
ENOTRECOVERABLE equ 131
ERFKILL equ 132
EHWPOISON equ 133

if used _errno_table

  segment readable

    label _errno_table byte at $

    if ~ defined _strip_errno | _strip_errno = 0

      db "Success", 0
      db "Operation not permitted", 0
      db "No such file or directory", 0
      db "No such process", 0
      db "Interrupted system call", 0
      db "Input/output error", 0
      db "No such device or address", 0
      db "Argument list too long", 0
      db "Exec format error", 0
      db "Bad file descriptor", 0
      db "No child processes", 0
      db "Resource temporarily unavailable", 0
      db "Cannot allocate memory", 0
      db "Permission denied", 0
      db "Bad address", 0
      db "Block device required", 0
      db "Device or resource busy", 0
      db "File exists", 0
      db "Invalid cross-device link", 0
      db "No such device", 0
      db "Not a directory", 0
      db "Is a directory", 0
      db "Invalid argument", 0
      db "Too many open files in system", 0
      db "Too many open files", 0
      db "Inappropriate ioctl for device", 0
      db "Text file busy", 0
      db "File too large", 0
      db "No space left on device", 0
      db "Illegal seek", 0
      db "Read-only file system", 0
      db "Too many links", 0
      db "Broken pipe", 0
      db "Numerical argument out of domain", 0
      db "Numerical result out of range", 0
      db "Resource deadlock avoided", 0
      db "File name too long", 0
      db "No locks available", 0
      db "Function not implemented", 0
      db "Directory not empty", 0
      db "Too many levels of symbolic links", 0
      db "Unknown error 41", 0
      db "No message of desired type", 0
      db "Identifier removed", 0
      db "Channel number out of range", 0
      db "Level 2 not synchronized", 0
      db "Level 3 halted", 0
      db "Level 3 reset", 0
      db "Link number out of range", 0
      db "Protocol driver not attached", 0
      db "No CSI structure available", 0
      db "Level 2 halted", 0
      db "Invalid exchange", 0
      db "Invalid request descriptor", 0
      db "Exchange full", 0
      db "No anode", 0
      db "Invalid request code", 0
      db "Invalid slot", 0
      db "Unknown error 58", 0
      db "Bad font file format", 0
      db "Device not a stream", 0
      db "No data available", 0
      db "Timer expired", 0
      db "Out of streams resources", 0
      db "Machine is not on the network", 0
      db "Package not installed", 0
      db "Object is remote", 0
      db "Link has been severed", 0
      db "Advertise error", 0
      db "Srmount error", 0
      db "Communication error on send", 0
      db "Protocol error", 0
      db "Multihop attempted", 0
      db "RFS specific error", 0
      db "Bad message", 0
      db "Value too large for defined data type", 0
      db "Name not unique on network", 0
      db "File descriptor in bad state", 0
      db "Remote address changed", 0
      db "Can not access a needed shared library", 0
      db "Accessing a corrupted shared library", 0
      db ".lib section in a.out corrupted", 0
      db "Attempting to link in too many shared libraries", 0
      db "Cannot exec a shared library directly", 0
      db "Invalid or incomplete multibyte or wide character", 0
      db "Interrupted system call should be restarted", 0
      db "Streams pipe error", 0
      db "Too many users", 0
      db "Socket operation on non-socket", 0
      db "Destination address required", 0
      db "Message too long", 0
      db "Protocol wrong type for socket", 0
      db "Protocol not available", 0
      db "Protocol not supported", 0
      db "Socket type not supported", 0
      db "Operation not supported", 0
      db "Protocol family not supported", 0
      db "Address family not supported by protocol", 0
      db "Address already in use", 0
      db "Cannot assign requested address", 0
      db "Network is down", 0
      db "Network is unreachable", 0
      db "Network dropped connection on reset", 0
      db "Software caused connection abort", 0
      db "Connection reset by peer", 0
      db "No buffer space available", 0
      db "Transport endpoint is already connected", 0
      db "Transport endpoint is not connected", 0
      db "Cannot send after transport endpoint shutdown", 0
      db "Too many references: cannot splice", 0
      db "Connection timed out", 0
      db "Connection refused", 0
      db "Host is down", 0
      db "No route to host", 0
      db "Operation already in progress", 0
      db "Operation now in progress", 0
      db "Stale file handle", 0
      db "Structure needs cleaning", 0
      db "Not a XENIX named type file", 0
      db "No XENIX semaphores available", 0
      db "Is a named type file", 0
      db "Remote I/O error", 0
      db "Disk quota exceeded", 0
      db "No medium found", 0
      db "Wrong medium type", 0
      db "Operation canceled", 0
      db "Required key not available", 0
      db "Key has expired", 0
      db "Key has been revoked", 0
      db "Key was rejected by service", 0
      db "Owner died", 0
      db "State not recoverable", 0
      db "Operation not possible due to RF-kill", 0
      db "Memory page has hardware error", 0

    else

      db "SUCCESS", 0
      db "EPERM", 0
      db "ENOENT", 0
      db "ESRCH", 0
      db "EINTR", 0
      db "EIO", 0
      db "ENXIO", 0
      db "E2BIG", 0
      db "ENOEXEC", 0
      db "EBADF", 0
      db "ECHILD", 0
      db "EAGAIN", 0
      db "ENOMEM", 0
      db "EACCES", 0
      db "EFAULT", 0
      db "ENOTBLK", 0
      db "EBUSY", 0
      db "EEXIST", 0
      db "EXDEV", 0
      db "ENODEV", 0
      db "ENOTDIR", 0
      db "EISDIR", 0
      db "EINVAL", 0
      db "ENFILE", 0
      db "EMFILE", 0
      db "ENOTTY", 0
      db "ETXTBSY", 0
      db "EFBIG", 0
      db "ENOSPC", 0
      db "ESPIPE", 0
      db "EROFS", 0
      db "EMLINK", 0
      db "EPIPE", 0
      db "EDOM", 0
      db "ERANGE", 0
      db "EDEADLK", 0
      db "ENAMETOOLONG", 0
      db "ENOLCK", 0
      db "ENOSYS", 0
      db "ENOTEMPTY", 0
      db "ELOOP", 0
      db "UNKNOWN", 0
      db "ENOMSG", 0
      db "EIDRM", 0
      db "ECHRNG", 0
      db "EL2NSYNC", 0
      db "EL3HLT", 0
      db "EL3RST", 0
      db "ELNRNG", 0
      db "EUNATCH", 0
      db "ENOCSI", 0
      db "EL2HLT", 0
      db "EBADE", 0
      db "EBADR", 0
      db "EXFULL", 0
      db "ENOANO", 0
      db "EBADRQC", 0
      db "EBADSLT", 0
      db "UNKNOWN", 0
      db "EBFONT", 0
      db "ENOSTR", 0
      db "ENODATA", 0
      db "ETIME", 0
      db "ENOSR", 0
      db "ENONET", 0
      db "ENOPKG", 0
      db "EREMOTE", 0
      db "ENOLINK", 0
      db "EADV", 0
      db "ESRMNT", 0
      db "ECOMM", 0
      db "EPROTO", 0
      db "EMULTIHOP", 0
      db "EDOTDOT", 0
      db "EBADMSG", 0
      db "EOVERFLOW", 0
      db "ENOTUNIQ", 0
      db "EBADFD", 0
      db "EREMCHG", 0
      db "ELIBACC", 0
      db "ELIBBAD", 0
      db "ELIBSCN", 0
      db "ELIBMAX", 0
      db "ELIBEXEC", 0
      db "EILSEQ", 0
      db "ERESTART", 0
      db "ESTRPIPE", 0
      db "EUSERS", 0
      db "ENOTSOCK", 0
      db "EDESTADDRREQ", 0
      db "EMSGSIZE", 0
      db "EPROTOTYPE", 0
      db "ENOPROTOOPT", 0
      db "EPROTONOSUPPORT", 0
      db "ESOCKTNOSUPPORT", 0
      db "EOPNOTSUPP", 0
      db "EPFNOSUPPORT", 0
      db "EAFNOSUPPORT", 0
      db "EADDRINUSE", 0
      db "EADDRNOTAVAIL", 0
      db "ENETDOWN", 0
      db "ENETUNREACH", 0
      db "ENETRESET", 0
      db "ECONNABORTED", 0
      db "ECONNRESET", 0
      db "ENOBUFS", 0
      db "EISCONN", 0
      db "ENOTCONN", 0
      db "ESHUTDOWN", 0
      db "ETOOMANYREFS", 0
      db "ETIMEDOUT", 0
      db "ECONNREFUSED", 0
      db "EHOSTDOWN", 0
      db "EHOSTUNREACH", 0
      db "EALREADY", 0
      db "EINPROGRESS", 0
      db "ESTALE", 0
      db "EUCLEAN", 0
      db "ENOTNAM", 0
      db "ENAVAIL", 0
      db "EISNAM", 0
      db "EREMOTEIO", 0
      db "EDQUOT", 0
      db "ENOMEDIUM", 0
      db "EMEDIUMTYPE", 0
      db "ECANCELED", 0
      db "ENOKEY", 0
      db "EKEYEXPIRED", 0
      db "EKEYREVOKED", 0
      db "EKEYREJECTED", 0
      db "EOWNERDEAD", 0
      db "ENOTRECOVERABLE", 0
      db "ERFKILL", 0
      db "EHWPOISON", 0

    end if

end if

end if

