# Appendix I: POSIX Quick Reference

## Overview

POSIX (Portable Operating System Interface) defines a set of standards for maintaining compatibility between operating systems. This appendix covers POSIX.1 interfaces, feature test macros, and portability notes for Linux developers.

---

## 1. POSIX Standards

| Standard | Name | Description |
|----------|------|-------------|
| POSIX.1 | IEEE Std 1003.1 | Base definitions, system interfaces, shell utilities |
| POSIX.1-2001 | Single UNIX Specification v3 | Combined with SUSv3 |
| POSIX.1-2008 | Single UNIX Specification v4 | Latest major revision (with 2013/2016/2017 amendments) |
| POSIX.1-2017 | — | Consolidated edition including Technical Corrigenda |
| POSIX.1-2024 | — | Latest edition |

### Headers Required by POSIX.1-2008

| Header | Description |
|--------|-------------|
| `<aio.h>` | Asynchronous I/O |
| `<arpa/inet.h>` | Internet address operations |
| `<assert.h>` | Diagnostics |
| `<complex.h>` | Complex arithmetic |
| `<cpio.h>` | cpio archive values |
| `<ctype.h>` | Character handling |
| `<dirent.h>` | Directory entries |
| `<dlfcn.h>` | Dynamic linking |
| `<errno.h>` | Error numbers |
| `<fcntl.h>` | File control |
| `<fenv.h>` | Floating-point environment |
| `<float.h>` | Floating-point limits |
| `<fmtmsg.h>` | Message display structures |
| `<fnmatch.h>` | Filename matching |
| `<ftw.h>` | File tree traversal |
| `<glob.h>` | Pathname pattern matching |
| `<grp.h>` | Group database |
| `<iconv.h>` | Codeset conversion |
| `<inttypes.h>` | Integer types |
| `<iso646.h>` | Alternative operator spellings |
| `<langinfo.h>` | Language information |
| `<libgen.h>` | Pathname functions |
| `<limits.h>` | Implementation limits |
| `<locale.h>` | Locale categories |
| `<math.h>` | Mathematical functions |
| `<monetary.h>` | Monetary types |
| `<mqueue.h>` | Message queues |
| `<ndbm.h>` | Database functions |
| `<net/if.h>` | Socket interfaces |
| `<netdb.h>` | Network database |
| `<netinet/in.h>` | Internet addresses |
| `<netinet/tcp.h>` | TCP definitions |
| `<nl_types.h>` | Message catalogs |
| `<poll.h>` | I/O multiplexing |
| `<pthread.h>` | Threads |
| `<pwd.h>` | Password database |
| `<regex.h>` | Regular expressions |
| `<sched.h>` | Execution scheduling |
| `<search.h>` | Search tables |
| `<semaphore.h>` | Semaphores |
| `<setjmp.h>` | Non-local jumps |
| `<signal.h>` | Signals |
| `<spawn.h>` | Process spawning |
| `<stdarg.h>` | Variable arguments |
| `<stdbool.h>` | Boolean types |
| `<stddef.h>` | Standard definitions |
| `<stdint.h>` | Integer types |
| `<stdio.h>` | Standard I/O |
| `<stdlib.h>` | Standard library |
| `<string.h>` | String operations |
| `<strings.h>` | String operations (BSD) |
| `<stropts.h>` | STREAMS |
| `<sys/ipc.h>` | IPC |
| `<sys/mman.h>` | Memory management |
| `<sys/msg.h>` | Message queues |
| `<sys/resource.h>` | Resource operations |
| `<sys/select.h>` | Select types |
| `<sys/sem.h>` | Semaphore operations |
| `<sys/shm.h>` | Shared memory |
| `<sys/socket.h>` | Socket interfaces |
| `<sys/stat.h>` | File status |
| `<sys/statvfs.h>` | VFS filesystem info |
| `<sys/time.h>` | Time types |
| `<sys/times.h>` | Process times |
| `<sys/types.h>` | System data types |
| `<sys/uio.h>` | Vectored I/O |
| `<sys/un.h>` | UNIX domain sockets |
| `<sys/utsname.h>` | System identification |
| `<sys/wait.h>` | Process termination |
| `<syslog.h>` | System logging |
| `<tar.h>` | tar archive values |
| `<termios.h>` | Terminal I/O |
| `<tgmath.h>` | Type-generic math |
| `<time.h>` | Time types |
| `<trace.h>` | Tracing |
| `<ulimit.h>` | User limits |
| `<unistd.h>` | POSIX operating system API |
| `<utmpx.h>` | User accounting |
| `<wchar.h>` | Wide-character handling |
| `<wctype.h>` | Wide-character classification |
| `<wordexp.h>` | Word expansion |

---

## 2. Feature Test Macros

Feature test macros control which declarations are visible from system headers.

### Usage

```c
#define _GNU_SOURCE
#include <stdio.h>
#include <unistd.h>
```

**Important**: Define before any `#include` statements.

### Available Macros

| Macro | Description | Visible Extensions |
|-------|-------------|-------------------|
| `_POSIX_C_SOURCE=200809L` | POSIX.1-2008 | POSIX.1 functions only |
| `_POSIX_C_SOURCE=200112L` | POSIX.1-2001 | POSIX.1-2001 functions |
| `_XOPEN_SOURCE=700` | SUSv4 | POSIX + XSI extensions |
| `_XOPEN_SOURCE=600` | SUSv3 | POSIX.1-2001 + XSI |
| `_XOPEN_SOURCE=500` | SUSv2 | XPG5 functions |
| `_DEFAULT_SOURCE` | Default definitions | BSD/SVID compatibility |
| `_BSD_SOURCE` (deprecated) | BSD compatibility | Use `_DEFAULT_SOURCE` |
| `_SVID_SOURCE` (deprecated) | SVID compatibility | Use `_DEFAULT_SOURCE` |
| `_GNU_SOURCE` | GNU extensions | All of the above + GNU-specific |

### What Each Macro Enables

```
_POSIX_C_SOURCE=200809L:
  - All POSIX.1-2008 functions
  - No GNU extensions
  - Strict POSIX compliance

_XOPEN_SOURCE=700:
  - POSIX.1-2008
  - XSI extensions (realpath, symlink, mmap, etc.)
  - Wide character functions
  - No GNU extensions

_GNU_SOURCE (default on glibc):
  - Everything above
  - GNU extensions (asprintf, strndup, etc.)
  - Linux-specific functions
  - Additional constants and types
```

### Checking POSIX Compliance

```bash
# Check POSIX version
getconf _POSIX_VERSION
# Output: 200809L

# Check specific feature
getconf _POSIX_THREADS
getconf _POSIX_MAPPED_FILES
getconf _POSIX_REALTIME_SIGNALS

# Compile with strict POSIX
gcc -D_POSIX_C_SOURCE=200809L -pedantic -std=c99 -o prog prog.c
```

---

## 3. POSIX.1 System Interfaces

### Process Management

| Function | Header | Description |
|----------|--------|-------------|
| `fork()` | `<unistd.h>` | Create child process |
| `execve()` | `<unistd.h>` | Execute program |
| `execv()` | `<unistd.h>` | Execute with arg vector |
| `execvp()` | `<unistd.h>` | Execute with PATH search |
| `execl()` | `<unistd.h>` | Execute with arg list |
| `exit()` | `<stdlib.h>` | Terminate process |
| `_exit()` | `<unistd.h>` | Terminate (no cleanup) |
| `wait()` | `<sys/wait.h>` | Wait for child |
| `waitpid()` | `<sys/wait.h>` | Wait for specific child |
| `waitid()` | `<sys/wait.h>` | Wait with siginfo |
| `getpid()` | `<unistd.h>` | Get process ID |
| `getppid()` | `<unistd.h>` | Get parent PID |
| `getuid()` | `<unistd.h>` | Get real user ID |
| `geteuid()` | `<unistd.h>` | Get effective user ID |
| `getgid()` | `<unistd.h>` | Get real group ID |
| `getegid()` | `<unistd.h>` | Get effective group ID |
| `setuid()` | `<unistd.h>` | Set real user ID |
| `seteuid()` | `<unistd.h>` | Set effective user ID |
| `setgid()` | `<unistd.h>` | Set real group ID |
| `setegid()` | `<unistd.h>` | Set effective group ID |
| `setsid()` | `<unistd.h>` | Create session |
| `getpgid()` | `<unistd.h>` | Get process group ID |
| `setpgid()` | `<unistd.h>` | Set process group ID |
| `kill()` | `<signal.h>` | Send signal |
| `raise()` | `<signal.h>` | Send signal to self |

### File Operations

| Function | Header | Description |
|----------|--------|-------------|
| `open()` | `<fcntl.h>` | Open file |
| `creat()` | `<fcntl.h>` | Create file |
| `close()` | `<unistd.h>` | Close file descriptor |
| `read()` | `<unistd.h>` | Read from fd |
| `write()` | `<unistd.h>` | Write to fd |
| `lseek()` | `<unistd.h>` | Reposition fd offset |
| `dup()` | `<unistd.h>` | Duplicate fd |
| `dup2()` | `<unistd.h>` | Duplicate to specific fd |
| `fcntl()` | `<fcntl.h>` | File control |
| `stat()` | `<sys/stat.h>` | Get file status |
| `lstat()` | `<sys/stat.h>` | Get status (no follow) |
| `fstat()` | `<sys/stat.h>` | Get status by fd |
| `access()` | `<unistd.h>` | Check accessibility |
| `chmod()` | `<sys/stat.h>` | Change permissions |
| `chown()` | `<unistd.h>` | Change ownership |
| `truncate()` | `<unistd.h>` | Truncate file |
| `ftruncate()` | `<unistd.h>` | Truncate by fd |
| `link()` | `<unistd.h>` | Create hard link |
| `unlink()` | `<unistd.h>` | Remove file |
| `symlink()` | `<unistd.h>` | Create symbolic link |
| `readlink()` | `<unistd.h>` | Read symlink value |
| `rename()` | `<stdio.h>` | Rename file |
| `mkdir()` | `<sys/stat.h>` | Create directory |
| `rmdir()` | `<unistd.h>` | Remove directory |
| `getcwd()` | `<unistd.h>` | Get current directory |
| `chdir()` | `<unistd.h>` | Change directory |
| `opendir()` | `<dirent.h>` | Open directory |
| `readdir()` | `<dirent.h>` | Read directory entry |
| `closedir()` | `<dirent.h>` | Close directory |

### Standard I/O

| Function | Header | Description |
|----------|--------|-------------|
| `fopen()` | `<stdio.h>` | Open stream |
| `fclose()` | `<stdio.h>` | Close stream |
| `fread()` | `<stdio.h>` | Read from stream |
| `fwrite()` | `<stdio.h>` | Write to stream |
| `fprintf()` | `<stdio.h>` | Formatted output |
| `fscanf()` | `<stdio.h>` | Formatted input |
| `fgets()` | `<stdio.h>` | Get string from stream |
| `fputs()` | `<stdio.h>` | Put string to stream |
| `fgetc()` | `<stdio.h>` | Get character |
| `fputc()` | `<stdio.h>` | Put character |
| `fseek()` | `<stdio.h>` | Seek in stream |
| `ftell()` | `<stdio.h>` | Tell position |
| `fflush()` | `<stdio.h>` | Flush stream |
| `feof()` | `<stdio.h>` | Test end-of-file |
| `ferror()` | `<stdio.h>` | Test stream error |
| `clearerr()` | `<stdio.h>` | Clear stream error |
| `perror()` | `<stdio.h>` | Print error message |
| `printf()` | `<stdio.h>` | Formatted print |
| `scanf()` | `<stdio.h>` | Formatted scan |
| `puts()` | `<stdio.h>` | Put string |
| `gets()` | `<stdio.h>` | Get string (deprecated) |
| `tmpfile()` | `<stdio.h>` | Create temp stream |
| `tmpnam()` | `<stdio.h>` | Generate temp name |
| `setvbuf()` | `<stdio.h>` | Set stream buffering |
| `remove()` | `<stdio.h>` | Remove file |
| `rename()` | `<stdio.h>` | Rename file |

### Memory Management

| Function | Header | Description |
|----------|--------|-------------|
| `malloc()` | `<stdlib.h>` | Allocate memory |
| `calloc()` | `<stdlib.h>` | Allocate zeroed memory |
| `realloc()` | `<stdlib.h>` | Reallocate memory |
| `free()` | `<stdlib.h>` | Free memory |
| `mmap()` | `<sys/mman.h>` | Map memory |
| `munmap()` | `<sys/mman.h>` | Unmap memory |
| `mprotect()` | `<sys/mman.h>` | Set memory protection |
| `mlock()` | `<sys/mman.h>` | Lock pages |
| `munlock()` | `<sys/mman.h>` | Unlock pages |
| `msync()` | `<sys/mman.h>` | Sync memory |
| `madvise()` | `<sys/mman.h>` | Advise on memory use |

### String Operations

| Function | Header | Description |
|----------|--------|-------------|
| `strlen()` | `<string.h>` | String length |
| `strcpy()` | `<string.h>` | Copy string |
| `strncpy()` | `<string.h>` | Copy string (bounded) |
| `strcat()` | `<string.h>` | Concatenate strings |
| `strncat()` | `<string.h>` | Concatenate (bounded) |
| `strcmp()` | `<string.h>` | Compare strings |
| `strncmp()` | `<string.h>` | Compare (bounded) |
| `strchr()` | `<string.h>` | Find character |
| `strrchr()` | `<string.h>` | Find last character |
| `strstr()` | `<string.h>` | Find substring |
| `strtok()` | `<string.h>` | Tokenize string |
| `memcpy()` | `<string.h>` | Copy memory |
| `memmove()` | `<string.h>` | Copy overlapping memory |
| `memset()` | `<string.h>` | Fill memory |
| `memcmp()` | `<string.h>` | Compare memory |
| `strdup()` | `<string.h>` | Duplicate string (POSIX.1-2001) |
| `strndup()` | `<string.h>` | Duplicate n bytes (POSIX.1-2008) |
| `strerror()` | `<string.h>` | Error message string |

### Signal Handling

| Function | Header | Description |
|----------|--------|-------------|
| `signal()` | `<signal.h>` | Set signal handler (simple) |
| `sigaction()` | `<signal.h>` | Set signal handler (advanced) |
| `sigprocmask()` | `<signal.h>` | Set signal mask |
| `sigpending()` | `<signal.h>` | Examine pending signals |
| `sigsuspend()` | `<signal.h>` | Wait for signal |
| `sigwait()` | `<signal.h>` | Wait for signal (synchronous) |
| `sigwaitinfo()` | `<signal.h>` | Wait with siginfo |
| `sigtimedwait()` | `<signal.h>` | Wait with timeout |
| `sigemptyset()` | `<signal.h>` | Initialize empty set |
| `sigfillset()` | `<signal.h>` | Initialize full set |
| `sigaddset()` | `<signal.h>` | Add signal to set |
| `sigdelset()` | `<signal.h>` | Remove signal from set |
| `sigismember()` | `<signal.h>` | Test signal in set |
| `kill()` | `<signal.h>` | Send signal |
| `raise()` | `<signal.h>` | Signal to self |
| `alarm()` | `<unistd.h>` | Set alarm |
| `pause()` | `<unistd.h>` | Wait for signal |

### Thread Functions (POSIX Threads)

| Function | Header | Description |
|----------|--------|-------------|
| `pthread_create()` | `<pthread.h>` | Create thread |
| `pthread_exit()` | `<pthread.h>` | Exit thread |
| `pthread_join()` | `<pthread.h>` | Wait for thread |
| `pthread_detach()` | `<pthread.h>` | Detach thread |
| `pthread_self()` | `<pthread.h>` | Get thread ID |
| `pthread_equal()` | `<pthread.h>` | Compare thread IDs |
| `pthread_once()` | `<pthread.h>` | Execute once |
| `pthread_cancel()` | `<pthread.h>` | Cancel thread |
| `pthread_setcancelstate()` | `<pthread.h>` | Set cancel state |
| `pthread_setcanceltype()` | `<pthread.h>` | Set cancel type |
| `pthread_testcancel()` | `<pthread.h>` | Test for cancellation |
| `pthread_cleanup_push()` | `<pthread.h>` | Push cleanup handler |
| `pthread_cleanup_pop()` | `<pthread.h>` | Pop cleanup handler |

### Mutex Functions

| Function | Header | Description |
|----------|--------|-------------|
| `pthread_mutex_init()` | `<pthread.h>` | Initialize mutex |
| `pthread_mutex_destroy()` | `<pthread.h>` | Destroy mutex |
| `pthread_mutex_lock()` | `<pthread.h>` | Lock mutex |
| `pthread_mutex_trylock()` | `<pthread.h>` | Try lock |
| `pthread_mutex_unlock()` | `<pthread.h>` | Unlock mutex |
| `pthread_mutex_timedlock()` | `<pthread.h>` | Lock with timeout |

### Condition Variable Functions

| Function | Header | Description |
|----------|--------|-------------|
| `pthread_cond_init()` | `<pthread.h>` | Initialize condition |
| `pthread_cond_destroy()` | `<pthread.h>` | Destroy condition |
| `pthread_cond_wait()` | `<pthread.h>` | Wait on condition |
| `pthread_cond_timedwait()` | `<pthread.h>` | Wait with timeout |
| `pthread_cond_signal()` | `<pthread.h>` | Signal one waiter |
| `pthread_cond_broadcast()` | `<pthread.h>` | Signal all waiters |

---

## 4. POSIX Shell and Utilities

### Required Utilities

| Utility | Description |
|---------|-------------|
| `alias` | Define alias |
| `basename` | Strip directory prefix |
| `cat` | Concatenate files |
| `cd` | Change directory |
| `chmod` | Change permissions |
| `chown` | Change ownership |
| `cp` | Copy files |
| `date` | Print date |
| `dd` | Convert and copy |
| `df` | Report disk usage |
| `dirname` | Strip filename |
| `du` | Disk usage |
| `echo` | Display arguments |
| `env` | Set environment |
| `expr` | Evaluate expression |
| `false` | Return false |
| `file` | Determine file type |
| `find` | Find files |
| `grep` | Search patterns |
| `head` | Output first part |
| `hostname` | Print hostname |
| `id` | Print user/group ID |
| `kill` | Send signals |
| `ln` | Create links |
| `ls` | List directory |
| `mkdir` | Create directory |
| `mktemp` | Create temp file |
| `mv` | Move files |
| `nice` | Run with priority |
| `nohup` | Ignore hangups |
| `od` | Octal dump |
| `paste` | Merge lines |
| `printf` | Formatted output |
| `ps` | Process status |
| `pwd` | Print working directory |
| `read` | Read input |
| `rm` | Remove files |
| `rmdir` | Remove directory |
| `sed` | Stream editor |
| `sleep` | Delay execution |
| `sort` | Sort lines |
| `tail` | Output last part |
| `tee` | Read stdin, write to stdout and file |
| `test` | Evaluate conditions |
| `time` | Time command |
| `touch` | Update timestamps |
| `tr` | Translate characters |
| `true` | Return true |
| `uname` | Print system info |
| `uniq` | Report unique lines |
| `wc` | Word count |
| `xargs` | Build command lines |

---

## 5. Portability Notes

### Common Linux-Specific (Non-POSIX) Features

| Feature | POSIX Alternative |
|---------|-------------------|
| `epoll` | `poll()`, `select()` |
| `inotify` | `poll()` on `/proc` (limited) |
| `signalfd` | `sigwaitinfo()` |
| `timerfd_create` | `timer_create()` |
| `eventfd` | `pipe()` |
| `splice()` | `read()` + `write()` |
| `sendfile()` | `read()` + `write()` |
| `clone()` | `fork()` |
| `prctl()` | `sysconf()` |
| `getauxval()` | `sysconf()` |
| `/proc` filesystem | `sysconf()`, `pathconf()` |
| `O_CLOEXEC` | `fcntl(fd, F_SETFD, FD_CLOEXEC)` |
| `accept4()` | `accept()` + `fcntl()` |
| `pipe2()` | `pipe()` + `fcntl()` |
| `dup3()` | `dup2()` |
| `mkostemp()` | `mkstemp()` + `fcntl()` |

### Writing Portable Code

```c
/* 1. Use feature test macros */
#define _POSIX_C_SOURCE 200809L
/* or */
#define _XOPEN_SOURCE 700

/* 2. Check for features at compile time */
#ifdef _POSIX_THREADS
    /* Use pthreads */
#endif

/* 3. Check for features at runtime */
long nprocs = sysconf(_SC_NPROCESSORS_ONLN);
if (nprocs < 1) nprocs = 1;

/* 4. Use POSIX types */
#include <sys/types.h>
pid_t pid;
uid_t uid;
gid_t gid;
off_t offset;
size_t length;
ssize_t bytes;

/* 5. Use portable integer types */
#include <stdint.h>
uint32_t val;
int64_t big;

/* 6. Avoid GNU extensions */
/* Bad:  asprintf(), strndup(), qsort_r() */
/* Good: malloc()+snprintf(), malloc()+strncpy(), qsort() */

/* 7. Use portable path handling */
#include <limits.h>
char path[PATH_MAX];

/* 8. Check errno properly */
#include <errno.h>
if (some_function() == -1) {
    if (errno == ENOTSUP) {
        /* Feature not supported */
    }
}
```

### sysconf() Configuration Values

| Constant | Description |
|----------|-------------|
| `_SC_ARG_MAX` | Max length of args to exec |
| `_SC_CHILD_MAX` | Max child processes per user |
| `_SC_CLK_TCK` | Clock ticks per second |
| `_SC_OPEN_MAX` | Max open files per process |
| `_SC_PAGESIZE` | System page size |
| `_SC_NPROCESSORS_ONLN` | Online processors |
| `_SC_PHYS_PAGES` | Physical pages |
| `_SC_AVPHYS_PAGES` | Available physical pages |
| `_SC_LINE_MAX` | Max length of input line |
| `_SC_HOST_NAME_MAX` | Max hostname length |
| `_SC_LOGIN_NAME_MAX` | Max login name length |
| `_SC_SYMLOOP_MAX` | Max symlink hops |
| `_SC_OPEN_MAX` | Max open file descriptors |
| `_SC_STREAM_MAX` | Max stdio streams |
| `_SC_THREADS` | Threads support |
| `_SC_THREAD_STACK_MIN` | Min thread stack size |

### pathconf() Configuration Values

| Constant | Description |
|----------|-------------|
| `_PC_NAME_MAX` | Max filename length |
| `_PC_PATH_MAX` | Max pathname length |
| `_PC_LINK_MAX` | Max hard links |
| `_PC_MAX_CANON` | Max canonical line length |
| `_PC_MAX_INPUT` | Max input line length |
| `_PC_PIPE_BUF` | Pipe buffer size |
| `_PC_CHOWN_RESTRICTED` | chown restricted |
| `_PC_NO_TRUNC` | Long filenames error |

---

*For the complete POSIX specification, consult the IEEE Std 1003.1 or the Open Group's online documentation at https://pubs.opengroup.org/onlinepubs/9699919799/.*
