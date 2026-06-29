# Appendix D: errno Reference

## Overview

When a system call or library function fails, it typically returns -1 (for integer returns) or NULL (for pointer returns) and sets the global variable `errno` to indicate the specific error. This appendix lists all standard errno values defined by POSIX and Linux-specific extensions.

---

## 1. Standard POSIX errno Values

| Value | Name | Description | Common Causes |
|-------|------|-------------|---------------|
| 1 | `EPERM` | Operation not permitted | Attempting privileged operation without sufficient permissions (e.g., `chmod` as non-owner, `kill` to another user's process) |
| 2 | `ENOENT` | No such file or directory | File or directory does not exist; broken symlink; incorrect path |
| 3 | `ESRCH` | No such process | Process or process group does not exist (e.g., `kill` with invalid PID) |
| 4 | `EINTR` | Interrupted system call | Signal delivered during blocking syscall; must retry or handle |
| 5 | `EIO` | I/O error | Hardware I/O error; filesystem corruption; failed disk read/write |
| 6 | `ENXIO` | No such device or address | Device does not exist; attempting I/O on device not configured |
| 7 | `E2BIG` | Argument list too long | `execve()` argument list or environment exceeds `ARG_MAX` |
| 8 | `ENOEXEC` | Exec format error | Invalid executable format; missing shebang; corrupted binary |
| 9 | `EBADF` | Bad file descriptor | Using closed or invalid fd; fd not open for requested operation |
| 10 | `ECHILD` | No child processes | `wait()` called when no children exist; `SIGCHLD` set to `SIG_IGN` |
| 11 | `EAGAIN` | Resource temporarily unavailable | Non-blocking I/O would block; no more processes; try again later |
| 12 | `ENOMEM` | Out of memory | `malloc()` failed; `mmap()` failed; insufficient memory for operation |
| 13 | `EACCES` | Permission denied | File permissions deny access; missing execute permission on directory |
| 14 | `EFAULT` | Bad address | Invalid pointer passed to syscall; unmapped memory address |
| 15 | `ENOTBLK` | Block device required | Block device operation attempted on non-block device |
| 16 | `EBUSY` | Device or resource busy | Mount point in use; file opened by another process; device busy |
| 17 | `EEXIST` | File exists | `O_CREAT | O_EXCL` specified but file already exists; `mkdir` on existing dir |
| 18 | `EXDEV` | Cross-device link | `rename()` across filesystems; hard link across devices |
| 19 | `ENODEV` | No such device | Device does not exist; driver not loaded |
| 20 | `ENOTDIR` | Not a directory | Expected directory but found file; path component is not a directory |
| 21 | `EISDIR` | Is a directory | Attempted write/open-for-write on a directory |
| 22 | `EINVAL` | Invalid argument | Invalid flag, option, or parameter to syscall |
| 23 | `ENFILE` | Too many open files in system | System-wide file descriptor limit reached |
| 24 | `EMFILE` | Too many open files | Process file descriptor limit reached (`ulimit -n`) |
| 25 | `ENOTTY` | Inappropriate ioctl for device | `ioctl()` on non-terminal or inappropriate fd |
| 26 | `ETXTBSY` | Text file busy | Attempting to write to executable file that is currently running |
| 27 | `EFBIG` | File too large | File size exceeds maximum allowed by filesystem or `RLIMIT_FSIZE` |
| 28 | `ENOSPC` | No space left on device | Disk full; inode exhaustion |
| 29 | `ESPIPE` | Illegal seek | `lseek()` on pipe, socket, or FIFO |
| 30 | `EROFS` | Read-only filesystem | Attempting write on read-only mounted filesystem |
| 31 | `EMLINK` | Too many links | Hard link count exceeds maximum (typically 65,000 for ext4) |
| 32 | `EPIPE` | Broken pipe | Write to pipe or socket with no readers; remote end closed connection |
| 33 | `EDOM` | Mathematics argument out of domain | Math function argument outside valid range (e.g., `sqrt(-1)`) |
| 34 | `ERANGE` | Result too large | Math function result cannot be represented; buffer too small |

---

## 2. POSIX.1-2001 / XSI Extended errno Values

| Value | Name | Description | Common Causes |
|-------|------|-------------|---------------|
| 35 | `EDEADLK` | Resource deadlock avoided | Mutex would cause deadlock; file lock conflict |
| 36 | `ENAMETOOLONG` | Filename too long | Filename exceeds `NAME_MAX` (255) or path exceeds `PATH_MAX` (4096) |
| 37 | `ENOLCK` | No locks available | System file locking table full |
| 38 | `ENOSYS` | Function not implemented | Syscall not supported by kernel; stub function called |
| 39 | `ENOTEMPTY` | Directory not empty | `rmdir()` on non-empty directory |
| 40 | `ELOOP` | Too many levels of symbolic links | Symlink loop; symlink chain exceeds `MAXSYMLINKS` |

---

## 3. POSIX.1-2001 Extended errno Values

| Value | Name | Description | Common Causes |
|-------|------|-------------|---------------|
| 42 | `ENOMSG` | No message of desired type | `msgrcv()` with `IPC_NOWAIT` and no matching message |
| 43 | `EIDRM` | Identifier removed | IPC object removed while waiting |
| 44 | `ECHRNG` | Channel number out of range | Linux-specific: invalid channel number |
| 45 | `EL2NSYNC` | Level 2 not synchronized | Linux-specific |
| 46 | `EL3HLT` | Level 3 halted | Linux-specific |
| 47 | `EL3RST` | Level 3 reset | Linux-specific |
| 48 | `ELNRNG` | Link number out of range | Linux-specific |
| 49 | `EUNATCH` | Protocol driver not attached | Linux-specific |
| 50 | `ENOCSI` | No CSI structure available | Linux-specific |
| 51 | `EL2HLT` | Level 2 halted | Linux-specific |
| 52 | `EBADE` | Invalid exchange | Linux-specific |
| 53 | `EBADR` | Invalid request descriptor | Linux-specific |
| 54 | `EXFULL` | Exchange full | Linux-specific |
| 55 | `ENOANO` | No anode | Linux-specific |
| 56 | `EBADRQC` | Invalid request code | Linux-specific |
| 57 | `EBADSLT` | Invalid slot | Linux-specific |
| 59 | `EBFONT` | Bad font file format | Linux-specific |
| 60 | `ENOSTR` | Device not a stream | Linux-specific |
| 61 | `ENODATA` | No data available | Linux-specific: no data on stream device |
| 62 | `ETIME` | Timer expired | Linux-specific: stream ioctl timeout |
| 63 | `ENOSR` | Out of streams resources | Linux-specific |
| 64 | `ENONET` | Machine is not on the network | Linux-specific |
| 65 | `ENOPKG` | Package not installed | Linux-specific |
| 66 | `EREMOTE` | Object is remote | Linux-specific |
| 67 | `ENOLINK` | Link has been severed | Linux-specific |
| 68 | `EADV` | Advertise error | Linux-specific |
| 69 | `ESRMNT` | Srmount error | Linux-specific |
| 70 | `ECOMM` | Communication error on send | Linux-specific |
| 71 | `EPROTO` | Protocol error | Linux-specific: protocol violation |
| 72 | `EMULTIHOP` | Multihop attempted | Linux-specific |
| 73 | `EDOTDOT` | RFS specific error | Linux-specific |
| 74 | `EBADMSG` | Not a data message | Linux-specific |
| 75 | `EOVERFLOW` | Value too large for defined data type | 32-bit overflow on 64-bit value |
| 76 | `ENOTUNIQ` | Name not unique on network | Linux-specific |
| 77 | `EBADFD` | File descriptor in bad state | Linux-specific |
| 78 | `EREMCHG` | Remote address changed | Linux-specific |
| 79 | `ELIBACC` | Can not access a needed shared library | Linux-specific |
| 80 | `ELIBBAD` | Accessing a corrupted shared library | Linux-specific |
| 81 | `ELIBSCN` | .lib section in a.out corrupted | Linux-specific |
| 82 | `ELIBMAX` | Attempting to link in too many shared libraries | Linux-specific |
| 83 | `ELIBEXEC` | Cannot exec a shared library directly | Linux-specific |
| 84 | `EILSEQ` | Invalid or incomplete multibyte or wide character | Invalid UTF-8 sequence; encoding error |
| 85 | `ERESTART` | Interrupted system call should be restarted | Linux-specific (kernel internal) |
| 86 | `ESTRPIPE` | Streams pipe error | Linux-specific |
| 87 | `EUSERS` | Too many users | Linux-specific |
| 88 | `ENOTSOCK` | Socket operation on non-socket | Using socket syscall on non-socket fd |
| 89 | `EDESTADDRREQ` | Destination address required | `send()` without `connect()` on unconnected socket |
| 90 | `EMSGSIZE` | Message too long | Datagram exceeds maximum socket buffer size |
| 91 | `EPROTOTYPE` | Protocol wrong type for socket | Protocol not supported by socket type |
| 92 | `ENOPROTOOPT` | Protocol not available | Invalid socket protocol option |
| 93 | `EPROTONOSUPPORT` | Protocol not supported | Protocol not supported by address family |
| 94 | `ESOCKTNOSUPPORT` | Socket type not supported | Socket type not supported by address family |
| 95 | `ENOTSUP` / `EOPNOTSUPP` | Operation not supported | Operation not supported on socket type |
| 96 | `EPFNOSUPPORT` | Protocol family not supported | Protocol family not supported |
| 97 | `EAFNOSUPPORT` | Address family not supported by protocol | IPv6 on IPv4-only socket |
| 98 | `EADDRINUSE` | Address already in use | Port already bound; socket address in use |
| 99 | `EADDRNOTAVAIL` | Cannot assign requested address | Address not available; binding to non-local address |
| 100 | `ENETDOWN` | Network is down | Network interface down |
| 101 | `ENETUNREACH` | Network is unreachable | No route to destination |
| 102 | `ENETRESET` | Network dropped connection on reset | Connection reset by network |
| 103 | `ECONNABORTED` | Software caused connection abort | Connection aborted by local host |
| 104 | `ECONNRESET` | Connection reset by peer | Remote host closed connection forcibly |
| 105 | `ENOBUFS` | No buffer space available | Socket buffer full; system buffer space exhausted |
| 106 | `EISCONN` | Socket is already connected | `connect()` on already-connected socket |
| 107 | `ENOTCONN` | Socket is not connected | `send()` on unconnected socket |
| 108 | `ESHUTDOWN` | Cannot send after transport endpoint shutdown | `send()` after `shutdown()` |
| 109 | `ETOOMANYREFS` | Too many references: cannot splice | Linux-specific |
| 110 | `ETIMEDOUT` | Connection timed out | TCP connection timeout; server not responding |
| 111 | `ECONNREFUSED` | Connection refused | No process listening on target port |
| 112 | `EHOSTDOWN` | Host is down | Remote host is down |
| 113 | `EHOSTUNREACH` | No route to host | Host unreachable |
| 114 | `EALREADY` | Operation already in progress | Non-blocking `connect()` already in progress |
| 115 | `EINPROGRESS` | Operation now in progress | Non-blocking `connect()` initiated |
| 116 | `ESTALE` | Stale file handle | NFS file handle no longer valid |
| 117 | `EUCLEAN` | Structure needs cleaning | Linux-specific |
| 118 | `ENAMETOOLONG` | File name too long | Linux-specific (duplicate) |
| 119 | `ENOTNAM` | Not a XENIX named type file | Linux-specific |
| 120 | `ENAVAIL` | No XENIX semaphores available | Linux-specific |
| 121 | `EISNAM` | Is a named type file | Linux-specific |
| 122 | `EREMOTEIO` | Remote I/O error | Linux-specific |
| 123 | `EDQUOT` | Disk quota exceeded | User or group disk quota exceeded |
| 125 | `ECANCELED` | Operation canceled | Async I/O canceled |
| 126 | `ENOKEY` | Required key not available | Linux-specific: encryption key not available |
| 127 | `EKEYEXPIRED` | Key has expired | Linux-specific |
| 128 | `EKEYREVOKED` | Key has been revoked | Linux-specific |
| 129 | `EKEYREJECTED` | Key was rejected by service | Linux-specific |
| 130 | `EOWNERDEAD` | Owner died | Robust mutex owner terminated |
| 131 | `ENOTRECOVERABLE` | State not recoverable | Robust mutex state unrecoverable |
| 132 | `ERFKILL` | Operation not possible due to RF-kill | Wireless disabled by hardware switch |
| 133 | `EHWPOISON` | Memory page has hardware error | Hardware memory error |

---

## 4. Using errno Correctly

### Checking errno

```c
#include <errno.h>
#include <stdio.h>
#include <string.h>

int fd = open("/nonexistent", O_RDONLY);
if (fd == -1) {
    printf("Error: %s (errno=%d)\n", strerror(errno), errno);

    // More detailed error info
    perror("open");

    // Specific error handling
    switch (errno) {
    case ENOENT:
        printf("File does not exist\n");
        break;
    case EACCES:
        printf("Permission denied\n");
        break;
    case EINTR:
        printf("Interrupted by signal, retrying...\n");
        break;
    default:
        printf("Unexpected error\n");
        break;
    }
}
```

### errno Threading

```c
// errno is thread-local in modern systems (glibc >= 2.3)
// Each thread has its own errno

// In glibc, errno is actually a macro:
// #define errno (*__errno_location())

// This makes it safe in multithreaded programs
```

### errno After Successful Calls

```c
// IMPORTANT: errno is only meaningful AFTER a function returns an error
// Successful calls do NOT clear errno

// WRONG:
open("/etc/passwd", O_RDONLY);
if (errno != 0) { /* This is unreliable! */ }

// CORRECT:
if (open("/etc/passwd", O_RDONLY) == -1) {
    // Now errno is meaningful
    perror("open");
}
```

### EINTR Handling

```c
// Many blocking calls can be interrupted by signals
// Must check for EINTR and retry

ssize_t safe_read(int fd, void *buf, size_t count) {
    ssize_t ret;
    do {
        ret = read(fd, buf, count);
    } while (ret == -1 && errno == EINTR);
    return ret;
}

ssize_t safe_write(int fd, const void *buf, size_t count) {
    ssize_t ret;
    const char *p = buf;
    size_t remaining = count;

    while (remaining > 0) {
        ret = write(fd, p, remaining);
        if (ret == -1) {
            if (errno == EINTR) continue;
            return -1;
        }
        p += ret;
        remaining -= ret;
    }
    return count;
}
```

---

## 5. errno and Common Library Functions

### Standard I/O

| Function | Returns on Error | Sets errno |
|----------|-----------------|------------|
| `fopen()` | `NULL` | Yes |
| `fclose()` | `EOF` | Yes |
| `fread()` | Items read < count | Yes |
| `fwrite()` | Items written < count | Yes |
| `fseek()` | `-1` | Yes |
| `ftell()` | `-1L` | Yes |
| `fflush()` | `EOF` | Yes |
| `fgets()` | `NULL` | Yes |
| `fputs()` | `EOF` on error | Yes |
| `printf()` | Negative on error | Yes |
| `scanf()` | `EOF` or items matched | Yes |

### Memory Allocation

| Function | Returns on Error | Sets errno |
|----------|-----------------|------------|
| `malloc()` | `NULL` | `ENOMEM` |
| `calloc()` | `NULL` | `ENOMEM` |
| `realloc()` | `NULL` (original block unchanged) | `ENOMEM` |
| `mmap()` | `MAP_FAILED` | Yes |
| `brk()` | `-1` | Yes |
| `sbrk()` | `(void *)-1` | Yes |

### String Functions

| Function | Returns on Error | Sets errno |
|----------|-----------------|------------|
| `strtol()` | `0` or `LONG_MIN`/`LONG_MAX` | `EINVAL` or `ERANGE` |
| `strtoul()` | `0` or `ULONG_MAX` | `EINVAL` or `ERANGE` |
| `strtod()` | `0` or `HUGE_VAL` | `EINVAL` or `ERANGE` |
| `strerror()` | Pointer to error string | No |
| `strtok()` | `NULL` (no more tokens) | No |

---

## 6. Error Reporting Best Practices

### Using `perror()`

```c
#include <stdio.h>

FILE *f = fopen("/nonexistent", "r");
if (!f) {
    perror("fopen");
    // Output: "fopen: No such file or directory"
}
```

### Using `strerror()`

```c
#include <string.h>
#include <stdio.h>

int ret = some_operation();
if (ret < 0) {
    fprintf(stderr, "Operation failed: %s\n", strerror(errno));
}
```

### Using `strerror_r()` (Thread-Safe)

```c
#include <string.h>

char buf[256];
if (strerror_r(errno, buf, sizeof(buf)) == 0) {
    printf("Error: %s\n", buf);
}
```

### Custom Error Reporting

```c
#include <errno.h>
#include <stdio.h>
#include <stdarg.h>

void log_error(const char *fmt, ...) {
    int saved_errno = errno;

    va_list args;
    va_start(args, fmt);
    fprintf(stderr, "ERROR: ");
    vfprintf(stderr, fmt, args);
    fprintf(stderr, ": %s (errno=%d)\n", strerror(saved_errno), saved_errno);
    va_end(args);

    errno = saved_errno;
}
```

---

## 7. errno Values Quick Lookup

```
  1 EPERM            2 ENOENT           3 ESRCH            4 EINTR
  5 EIO              6 ENXIO            7 E2BIG            8 ENOEXEC
  9 EBADF           10 ECHILD          11 EAGAIN          12 ENOMEM
 13 EACCES          14 EFAULT          15 ENOTBLK         16 EBUSY
 17 EEXIST          18 EXDEV           19 ENODEV          20 ENOTDIR
 21 EISDIR          22 EINVAL          23 ENFILE          24 EMFILE
 25 ENOTTY          26 ETXTBSY         27 EFBIG           28 ENOSPC
 29 ESPIPE          30 EROFS           31 EMLINK          32 EPIPE
 33 EDOM            34 ERANGE          35 EDEADLK         36 ENAMETOOLONG
 37 ENOLCK          38 ENOSYS          39 ENOTEMPTY       40 ELOOP
 42 ENOMSG          43 EIDRM           84 EILSEQ          88 ENOTSOCK
 90 EMSGSIZE        95 ENOTSUP         98 EADDRINUSE      99 EADDRNOTAVAIL
100 ENETDOWN       101 ENETUNREACH    103 ECONNABORTED   104 ECONNRESET
105 ENOBUFS        106 EISCONN        107 ENOTCONN       110 ETIMEDOUT
111 ECONNREFUSED   113 EHOSTUNREACH   115 EINPROGRESS    116 ESTALE
123 EDQUOT         125 ECANCELED      130 EOWNERDEAD     131 ENOTRECOVERABLE
```

---

## 8. Linux-Specific errno Notes

### Commonly Confused Pairs

| Pair | Difference |
|------|------------|
| `EAGAIN` vs `EWOULDBLOCK` | Same value on Linux (11); POSIX allows different |
| `ECONNREFUSED` vs `EHOSTUNREACH` | Refused means port closed; unreachable means no route |
| `ETIMEDOUT` vs `ECONNREFUSED` | Timeout means no response; refused means active rejection |
| `ENOMEM` vs `ENOBUFS` | Memory vs network buffer space |
| `ENOSPC` vs `EDQUOT` | Disk full vs quota exceeded |
| `EPERM` vs `EACCES` | Not permitted (privilege) vs denied (permissions) |

### errno in Kernel Space

In kernel code, errors are returned as negative values:

```c
// Kernel function returning error
static int my_func(void) {
    if (error_condition)
        return -EINVAL;  // Note: negative value
    return 0;
}

// Using ERR_PTR/IS_ERR/PTR_ERR for pointer returns
#include <linux/err.h>

struct device *my_create(void) {
    if (error)
        return ERR_PTR(-ENOMEM);
    return dev;
}

// Checking in caller
struct device *dev = my_create();
if (IS_ERR(dev)) {
    int err = PTR_ERR(dev);
    pr_err("Failed: %d\n", err);
}
```

---

*For the authoritative list, see `/usr/include/asm-generic/errno-base.h` and `/usr/include/asm-generic/errno.h`. Consult `man 3 errno` for POSIX details.*
