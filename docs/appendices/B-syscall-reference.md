# Appendix B: Syscall Quick Reference

## Overview

This appendix provides a reference of major Linux system calls organized by category. Each entry includes the function signature, brief description, and relevant header files. System calls are the fundamental interface between user-space applications and the kernel.

---

## 1. Process Management

| Syscall | Signature | Description |
|---------|-----------|-------------|
| `fork` | `pid_t fork(void)` | Create a child process (copy of parent) |
| `vfork` | `pid_t vfork(void)` | Create child process, shares parent's memory until exec |
| `clone` | `int clone(fn, stack, flags, arg, ...)` | Create child process with fine-grained control over sharing |
| `execve` | `int execve(const char *path, char *const argv[], char *const envp[])` | Execute a program |
| `exit` | `void exit(int status)` | Terminate the calling process |
| `exit_group` | `void exit_group(int status)` | Terminate all threads in the process |
| `wait4` | `pid_t wait4(pid_t pid, int *status, int options, struct rusage *rusage)` | Wait for process state change |
| `waitpid` | `pid_t waitpid(pid_t pid, int *status, int options)` | Wait for specific child process |
| `waitid` | `int waitid(idtype_t idtype, id_t id, siginfo_t *info, int options)` | Wait for process state change (POSIX) |
| `getpid` | `pid_t getpid(void)` | Get process ID |
| `getppid` | `pid_t getppid(void)` | Get parent process ID |
| `gettid` | `pid_t gettid(void)` | Get thread ID |
| `setsid` | `pid_t setsid(void)` | Create new session, set process group ID |
| `getsid` | `pid_t getsid(pid_t pid)` | Get session ID |
| `setpgid` | `int setpgid(pid_t pid, pid_t pgid)` | Set process group ID |
| `getpgid` | `pid_t getpgid(pid_t pid)` | Get process group ID |
| `getpgrp` | `pid_t getpgrp(void)` | Get process group ID of calling process |
| `kill` | `int kill(pid_t pid, int sig)` | Send signal to process |
| `tgkill` | `int tgkill(int tgid, int tid, int sig)` | Send signal to specific thread |
| `prctl` | `int prctl(int option, ...)` | Process control operations |
| `personality` | `unsigned long personality(unsigned long persona)` | Set the execution domain |
| `arch_prctl` | `int arch_prctl(int code, unsigned long addr)` | Set architecture-specific thread state |

### Example: Creating a Child Process

```c
#include <unistd.h>
#include <sys/wait.h>
#include <stdio.h>

int main(void) {
    pid_t pid = fork();
    if (pid == 0) {
        // Child
        printf("Child PID: %d\n", getpid());
        _exit(0);
    } else if (pid > 0) {
        // Parent
        int status;
        waitpid(pid, &status, 0);
        printf("Child %d exited with status %d\n", pid, WEXITSTATUS(status));
    } else {
        perror("fork");
    }
    return 0;
}
```

---

## 2. File Operations

| Syscall | Signature | Description |
|---------|-----------|-------------|
| `open` | `int open(const char *path, int flags, ...)` | Open a file |
| `openat` | `int openat(int dirfd, const char *path, int flags, ...)` | Open file relative to directory |
| `creat` | `int creat(const char *path, mode_t mode)` | Create a file (equivalent to `open` with O_CREAT\|O_WRONLY\|O_TRUNC) |
| `close` | `int close(int fd)` | Close a file descriptor |
| `read` | `ssize_t read(int fd, void *buf, size_t count)` | Read from file descriptor |
| `write` | `ssize_t write(int fd, const void *buf, size_t count)` | Write to file descriptor |
| `pread64` | `ssize_t pread64(int fd, void *buf, size_t count, off64_t offset)` | Read at offset without changing file position |
| `pwrite64` | `ssize_t pwrite64(int fd, const void *buf, size_t count, off64_t offset)` | Write at offset without changing file position |
| `lseek` | `off_t lseek(int fd, off_t offset, int whence)` | Reposition file offset |
| `dup` | `int dup(int oldfd)` | Duplicate file descriptor |
| `dup2` | `int dup2(int oldfd, int newfd)` | Duplicate to specific fd number |
| `dup3` | `int dup3(int oldfd, int newfd, int flags)` | Duplicate fd with flags (e.g., O_CLOEXEC) |
| `fcntl` | `int fcntl(int fd, int cmd, ...)` | File control operations |
| `ioctl` | `int ioctl(int fd, unsigned long request, ...)` | Device-specific I/O control |
| `stat` | `int stat(const char *path, struct stat *buf)` | Get file status |
| `lstat` | `int lstat(const char *path, struct stat *buf)` | Get file status (don't follow symlinks) |
| `fstat` | `int fstat(int fd, struct stat *buf)` | Get file status by fd |
| `statx` | `int statx(int dirfd, const char *path, int flags, unsigned int mask, struct statx *buf)` | Extended file status |
| `access` | `int access(const char *path, int mode)` | Check file accessibility |
| `faccessat` | `int faccessat(int dirfd, const char *path, int mode, int flags)` | Check accessibility relative to dir |
| `truncate` | `int truncate(const char *path, off_t length)` | Truncate file to specified length |
| `ftruncate` | `int ftruncate(int fd, off_t length)` | Truncate file by fd |
| `link` | `int link(const char *oldpath, const char *newpath)` | Create hard link |
| `unlink` | `int unlink(const char *path)` | Remove a file |
| `rename` | `int rename(const char *oldpath, const char *newpath)` | Rename a file |
| `symlink` | `int symlink(const char *target, const char *linkpath)` | Create symbolic link |
| `readlink` | `ssize_t readlink(const char *path, char *buf, size_t bufsiz)` | Read value of symbolic link |
| `mkdir` | `int mkdir(const char *path, mode_t mode)` | Create directory |
| `rmdir` | `int rmdir(const char *path)` | Remove directory |
| `getcwd` | `char *getcwd(char *buf, size_t size)` | Get current working directory |
| `chdir` | `int chdir(const char *path)` | Change working directory |
| `fchdir` | `int fchdir(int fd)` | Change working directory by fd |
| `chmod` | `int chmod(const char *path, mode_t mode)` | Change file permissions |
| `fchmod` | `int fchmod(int fd, mode_t mode)` | Change permissions by fd |
| `chown` | `int chown(const char *path, uid_t uid, gid_t gid)` | Change file ownership |
| `fchown` | `int fchown(int fd, uid_t uid, gid_t gid)` | Change ownership by fd |
| `lchown` | `int lchown(const char *path, uid_t uid, gid_t gid)` | Change ownership (don't follow symlinks) |
| `umask` | `mode_t umask(mode_t mask)` | Set file creation mask |
| `mknod` | `int mknod(const char *path, mode_t mode, dev_t dev)` | Create filesystem node |
| `statfs` | `int statfs(const char *path, struct statfs *buf)` | Get filesystem statistics |
| `fstatfs` | `int fstatfs(int fd, struct statfs *buf)` | Get filesystem stats by fd |

### Example: Reading a File

```c
#include <fcntl.h>
#include <unistd.h>
#include <stdio.h>

int main(void) {
    int fd = open("/etc/hostname", O_RDONLY);
    if (fd < 0) { perror("open"); return 1; }

    char buf[256];
    ssize_t n;
    while ((n = read(fd, buf, sizeof(buf) - 1)) > 0) {
        buf[n] = '\0';
        printf("%s", buf);
    }
    close(fd);
    return 0;
}
```

---

## 3. Memory Management

| Syscall | Signature | Description |
|---------|-----------|-------------|
| `mmap` | `void *mmap(void *addr, size_t len, int prot, int flags, int fd, off_t off)` | Map files or devices into memory |
| `munmap` | `int munmap(void *addr, size_t len)` | Unmap memory region |
| `mprotect` | `int mprotect(void *addr, size_t len, int prot)` | Set protection on memory region |
| `mlock` | `int mlock(const void *addr, size_t len)` | Lock pages in memory |
| `munlock` | `int munlock(const void *addr, size_t len)` | Unlock pages |
| `mlockall` | `int mlockall(int flags)` | Lock all pages of calling process |
| `munlockall` | `int munlockall(void)` | Unlock all pages |
| `madvise` | `int madvise(void *addr, size_t len, int advice)` | Advise kernel about memory usage |
| `mremap` | `void *mremap(void *old_addr, size_t old_size, size_t new_size, int flags, ...)` | Remap a virtual memory address |
| `brk` | `int brk(void *addr)` | Change data segment size |
| `sbrk` | `void *sbrk(intptr_t increment)` | Change data segment size (incremental) |
| `msync` | `int msync(void *addr, size_t len, int flags)` | Synchronize memory with storage |
| `mincore` | `int mincore(void *addr, size_t len, unsigned char *vec)` | Determine residency of memory pages |
| `mmap2` | `void *mmap2(void *addr, size_t len, int prot, int flags, int fd, off_t pgoffset)` | Map files (page-granular offset) |

### mmap Flags

| Flag | Description |
|------|-------------|
| `MAP_SHARED` | Share changes with other processes |
| `MAP_PRIVATE` | Private copy-on-write mapping |
| `MAP_FIXED` | Interpret addr exactly |
| `MAP_ANONYMOUS` | No file backing (anonymous memory) |
| `MAP_NORESERVE` | Don't reserve swap space |
| `MAP_POPULATE` | Prefault page tables |
| `MAP_STACK` | Suitable for stack |
| `MAP_HUGETLB` | Use huge pages |

---

## 4. IPC (Inter-Process Communication)

### Pipes and FIFOs

| Syscall | Signature | Description |
|---------|-----------|-------------|
| `pipe` | `int pipe(int pipefd[2])` | Create pipe |
| `pipe2` | `int pipe2(int pipefd[2], int flags)` | Create pipe with flags |

### Message Queues

| Syscall | Signature | Description |
|---------|-----------|-------------|
| `msgget` | `int msgget(key_t key, int flags)` | Get/create message queue |
| `msgsnd` | `int msgsnd(int msqid, const void *msgp, size_t msgsz, int flags)` | Send message |
| `msgrcv` | `ssize_t msgrcv(int msqid, void *msgp, size_t msgsz, long msgtyp, int flags)` | Receive message |
| `msgctl` | `int msgctl(int msqid, int cmd, struct msqid_ds *buf)` | Message queue control |

### Semaphores

| Syscall | Signature | Description |
|---------|-----------|-------------|
| `semget` | `int semget(key_t key, int nsems, int flags)` | Get/create semaphore set |
| `semop` | `int semop(int semid, struct sembuf *sops, size_t nsops)` | Semaphore operations |
| `semctl` | `int semctl(int semid, int semnum, int cmd, ...)` | Semaphore control |

### Shared Memory

| Syscall | Signature | Description |
|---------|-----------|-------------|
| `shmget` | `int shmget(key_t key, size_t size, int flags)` | Get/create shared memory segment |
| `shmat` | `void *shmat(int shmid, const void *shmaddr, int flags)` | Attach shared memory |
| `shmdt` | `int shmdt(const void *shmaddr)` | Detach shared memory |
| `shmctl` | `int shmctl(int shmid, int cmd, struct shmid_ds *buf)` | Shared memory control |

### POSIX IPC

| Syscall | Signature | Description |
|---------|-----------|-------------|
| `shm_open` | `int shm_open(const char *name, int oflag, mode_t mode)` | Open/create POSIX shared memory |
| `shm_unlink` | `int shm_unlink(const char *name)` | Remove POSIX shared memory |
| `mq_open` | `mqd_t mq_open(const char *name, int oflag, ...)` | Open/create POSIX message queue |
| `mq_send` | `int mq_send(mqd_t mqdes, const char *msg_ptr, size_t msg_len, unsigned msg_prio)` | Send message to queue |
| `mq_receive` | `ssize_t mq_receive(mqd_t mqdes, char *msg_ptr, size_t msg_len, unsigned *msg_prio)` | Receive message from queue |

### UNIX Domain Sockets

| Syscall | Signature | Description |
|---------|-----------|-------------|
| `socket` | `int socket(int domain, int type, int protocol)` | Create socket |
| `socketpair` | `int socketpair(int domain, int type, int protocol, int sv[2])` | Create pair of connected sockets |
| `bind` | `int bind(int sockfd, const struct sockaddr *addr, socklen_t addrlen)` | Bind socket to address |
| `listen` | `int listen(int sockfd, int backlog)` | Listen for connections |
| `accept` | `int accept(int sockfd, struct sockaddr *addr, socklen_t *addrlen)` | Accept connection |
| `connect` | `int connect(int sockfd, const struct sockaddr *addr, socklen_t addrlen)` | Initiate connection |
| `send` | `ssize_t send(int sockfd, const void *buf, size_t len, int flags)` | Send message on socket |
| `recv` | `ssize_t recv(int sockfd, void *buf, size_t len, int flags)` | Receive message from socket |
| `sendto` | `ssize_t sendto(int sockfd, const void *buf, size_t len, int flags, const struct sockaddr *dest_addr, socklen_t addrlen)` | Send to address |
| `recvfrom` | `ssize_t recvfrom(int sockfd, void *buf, size_t len, int flags, struct sockaddr *src_addr, socklen_t *addrlen)` | Receive from address |

---

## 5. Signal Handling

| Syscall | Signature | Description |
|---------|-----------|-------------|
| `signal` | `void (*signal(int sig, void (*handler)(int)))(int)` | Simple signal handler (deprecated) |
| `sigaction` | `int sigaction(int sig, const struct sigaction *act, struct sigaction *oldact)` | Examine/change signal action |
| `sigprocmask` | `int sigprocmask(int how, const sigset_t *set, sigset_t *oldset)` | Examine/change signal mask |
| `sigpending` | `int sigpending(sigset_t *set)` | Examine pending signals |
| `sigsuspend` | `int sigsuspend(const sigset_t *mask)` | Wait for signal |
| `sigwaitinfo` | `int sigwaitinfo(const sigset_t *set, siginfo_t *info)` | Wait for signal (real-time) |
| `sigtimedwait` | `int sigtimedwait(const sigset_t *set, siginfo_t *info, const struct timespec *timeout)` | Wait for signal with timeout |
| `sigaltstack` | `int sigaltstack(const stack_t *ss, stack_t *oldss)` | Set/get signal alternate stack |
| `signalfd` | `int signalfd(int fd, const sigset_t *mask, int flags)` | Create fd for signal reception |
| `rt_sigaction` | `int rt_sigaction(int sig, const struct sigaction *act, struct sigaction *oldact, size_t sigsetsize)` | Real-time signal action |
| `rt_sigprocmask` | `int rt_sigprocmask(int how, const sigset_t *set, sigset_t *oldset, size_t sigsetsize)` | Real-time signal mask |
| `rt_sigpending` | `int rt_sigpending(sigset_t *set, size_t sigsetsize)` | Real-time pending signals |
| `rt_sigsuspend` | `int rt_sigsuspend(const sigset_t *mask, size_t sigsetsize)` | Real-time signal suspend |

---

## 6. Timer and Clock

| Syscall | Signature | Description |
|---------|-----------|-------------|
| `gettimeofday` | `int gettimeofday(struct timeval *tv, struct timezone *tz)` | Get wall clock time (deprecated) |
| `clock_gettime` | `int clock_gettime(clockid_t clk_id, struct timespec *tp)` | Get clock time |
| `clock_settime` | `int clock_settime(clockid_t clk_id, const struct timespec *tp)` | Set clock time |
| `clock_getres` | `int clock_getres(clockid_t clk_id, struct timespec *res)` | Get clock resolution |
| `clock_nanosleep` | `int clock_nanosleep(clockid_t clockid, int flags, const struct timespec *request, struct timespec *remain)` | High-resolution sleep |
| `nanosleep` | `int nanosleep(const struct timespec *req, struct timespec *rem)` | Sleep for nanoseconds |
| `alarm` | `unsigned int alarm(unsigned int seconds)` | Set alarm clock |
| `setitimer` | `int setitimer(int which, const struct itimerval *new_value, struct itimerval *old_value)` | Set interval timer |
| `getitimer` | `int getitimer(int which, struct itimerval *curr_value)` | Get interval timer |
| `timer_create` | `int timer_create(clockid_t clockid, struct sigevent *sevp, timer_t *timerid)` | Create POSIX timer |
| `timer_settime` | `int timer_settime(timer_t timerid, int flags, const struct itimerspec *new_value, struct itimerspec *old_value)` | Arm/disarm timer |
| `timer_gettime` | `int timer_gettime(timer_t timerid, struct itimerspec *curr_value)` | Get timer remaining time |
| `timer_delete` | `int timer_delete(timer_t timerid)` | Delete POSIX timer |
| `timerfd_create` | `int timerfd_create(int clockid, int flags)` | Create timer fd |
| `timerfd_settime` | `int timerfd_settime(int fd, int flags, const struct itimerspec *new_value, struct itimerspec *old_value)` | Arm/disarm timer fd |

---

## 7. Networking

| Syscall | Signature | Description |
|---------|-----------|-------------|
| `socket` | `int socket(int domain, int type, int protocol)` | Create communication endpoint |
| `socketpair` | `int socketpair(int domain, int type, int protocol, int sv[2])` | Create connected socket pair |
| `bind` | `int bind(int sockfd, const struct sockaddr *addr, socklen_t addrlen)` | Bind name to socket |
| `listen` | `int listen(int sockfd, int backlog)` | Listen for connections |
| `accept` | `int accept(int sockfd, struct sockaddr *addr, socklen_t *addrlen)` | Accept connection |
| `accept4` | `int accept4(int sockfd, struct sockaddr *addr, socklen_t *addrlen, int flags)` | Accept with flags |
| `connect` | `int connect(int sockfd, const struct sockaddr *addr, socklen_t addrlen)` | Initiate connection |
| `shutdown` | `int shutdown(int sockfd, int how)` | Shut down socket (full/half close) |
| `getsockname` | `int getsockname(int sockfd, struct sockaddr *addr, socklen_t *addrlen)` | Get socket local address |
| `getpeername` | `int getpeername(int sockfd, struct sockaddr *addr, socklen_t *addrlen)` | Get peer address |
| `getsockopt` | `int getsockopt(int sockfd, int level, int optname, void *optval, socklen_t *optlen)` | Get socket option |
| `setsockopt` | `int setsockopt(int sockfd, int level, int optname, const void *optval, socklen_t optlen)` | Set socket option |
| `send` | `ssize_t send(int sockfd, const void *buf, size_t len, int flags)` | Send message |
| `recv` | `ssize_t recv(int sockfd, void *buf, size_t len, int flags)` | Receive message |
| `sendto` | `ssize_t sendto(int sockfd, const void *buf, size_t len, int flags, const struct sockaddr *dest_addr, socklen_t addrlen)` | Send to address |
| `recvfrom` | `ssize_t recvfrom(int sockfd, void *buf, size_t len, int flags, struct sockaddr *src_addr, socklen_t *addrlen)` | Receive from address |
| `sendmsg` | `ssize_t sendmsg(int sockfd, const struct msghdr *msg, int flags)` | Send message (advanced) |
| `recvmsg` | `ssize_t recvmsg(int sockfd, struct msghdr *msg, int flags)` | Receive message (advanced) |
| `sendmmsg` | `int sendmmsg(int sockfd, struct mmsghdr *msgvec, unsigned int vlen, int flags)` | Send multiple messages |
| `recvmmsg` | `int recvmmsg(int sockfd, struct mmsghdr *msgvec, unsigned int vlen, int flags, struct timespec *timeout)` | Receive multiple messages |
| `select` | `int select(int nfds, fd_set *readfds, fd_set *writefds, fd_set *exceptfds, struct timeval *timeout)` | Synchronous I/O multiplexing |
| `pselect` | `int pselect(int nfds, fd_set *readfds, fd_set *writefds, fd_set *exceptfds, const struct timespec *timeout, const sigset_t *sigmask)` | Select with signal mask |
| `poll` | `int poll(struct pollfd *fds, nfds_t nfds, int timeout)` | Wait for events on fds |
| `ppoll` | `int ppoll(struct pollfd *fds, nfds_t nfds, const struct timespec *tmo_p, const sigset_t *sigmask)` | Poll with signal mask |
| `epoll_create` | `int epoll_create(int size)` | Create epoll instance |
| `epoll_create1` | `int epoll_create1(int flags)` | Create epoll instance with flags |
| `epoll_ctl` | `int epoll_ctl(int epfd, int op, int fd, struct epoll_event *event)` | Control epoll interest list |
| `epoll_wait` | `int epoll_wait(int epfd, struct epoll_event *events, int maxevents, int timeout)` | Wait for epoll events |
| `epoll_pwait` | `int epoll_pwait(int epfd, struct epoll_event *events, int maxevents, int timeout, const sigset_t *sigmask)` | Epoll wait with signal mask |

### Socket Domains

| Domain | Description |
|--------|-------------|
| `AF_UNIX` / `AF_LOCAL` | Local/UNIX domain sockets |
| `AF_INET` | IPv4 Internet protocols |
| `AF_INET6` | IPv6 Internet protocols |
| `AF_NETLINK` | Kernel user interface device |
| `AF_PACKET` | Low-level packet interface |

### Socket Types

| Type | Description |
|------|-------------|
| `SOCK_STREAM` | Sequenced, reliable, connection-based (TCP) |
| `SOCK_DGRAM` | Connectionless, unreliable messages (UDP) |
| `SOCK_RAW` | Raw network protocol access |
| `SOCK_SEQPACKET` | Sequenced, reliable, connection-based, message boundaries |

---

## 8. Threading (futex-based)

| Syscall | Signature | Description |
|---------|-----------|-------------|
| `futex` | `int futex(int *uaddr, int futex_op, int val, ...)` | Fast user-space locking |
| `set_robust_list` | `int set_robust_list(struct robust_list_head *head, size_t len)` | Register robust futex list |
| `get_robust_list` | `int get_robust_list(int pid, struct robust_list_head **head_ptr, size_t *len)` | Get robust futex list |

### futex Operations

| Operation | Description |
|-----------|-------------|
| `FUTEX_WAIT` | If `*uaddr == val`, wait |
| `FUTEX_WAKE` | Wake up to `val` waiters |
| `FUTEX_WAIT_BITSET` | Wait with bitset |
| `FUTEX_WAKE_BITSET` | Wake with bitset |
| `FUTEX_LOCK_PI` | Priority-inheritance aware lock |
| `FUTEX_UNLOCK_PI` | Priority-inheritance aware unlock |
| `FUTEX_CMP_REQUEUE` | Requeue waiters with comparison |

---

## 9. Epoll, io_uring, and Async I/O

| Syscall | Signature | Description |
|---------|-----------|-------------|
| `epoll_create1` | `int epoll_create1(int flags)` | Create epoll fd |
| `epoll_ctl` | `int epoll_ctl(int epfd, int op, int fd, struct epoll_event *event)` | Add/modify/delete fd from epoll |
| `epoll_wait` | `int epoll_wait(int epfd, struct epoll_event *events, int maxevents, int timeout)` | Wait for events |
| `io_uring_setup` | `int io_uring_setup(unsigned entries, struct io_uring_params *p)` | Setup io_uring instance |
| `io_uring_enter` | `int io_uring_enter(int fd, unsigned to_submit, unsigned min_complete, unsigned flags, sigset_t *sig)` | Submit and wait for io_uring completions |
| `io_uring_register` | `int io_uring_register(int fd, unsigned opcode, void *arg, unsigned nr_args` | Register buffers/files with io_uring |
| `eventfd` | `int eventfd(unsigned int initval, int flags)` | Create event fd |
| `eventfd2` | `int eventfd2(unsigned int initval, int flags)` | Create event fd with flags |

---

## 10. Scheduling

| Syscall | Signature | Description |
|---------|-----------|-------------|
| `sched_yield` | `int sched_yield(void)` | Yield the processor |
| `sched_setscheduler` | `int sched_setscheduler(pid_t pid, int policy, const struct sched_param *param)` | Set scheduling policy |
| `sched_getscheduler` | `int sched_getscheduler(pid_t pid)` | Get scheduling policy |
| `sched_setparam` | `int sched_setparam(pid_t pid, const struct sched_param *param)` | Set scheduling parameters |
| `sched_getparam` | `int sched_getparam(pid_t pid, struct sched_param *param)` | Get scheduling parameters |
| `sched_setaffinity` | `int sched_setaffinity(pid_t pid, size_t cpusetsize, const cpu_set_t *mask)` | Set CPU affinity |
| `sched_getaffinity` | `int sched_getaffinity(pid_t pid, size_t cpusetsize, cpu_set_t *mask)` | Get CPU affinity |
| `sched_get_priority_max` | `int sched_get_priority_max(int policy)` | Get maximum priority |
| `sched_get_priority_min` | `int sched_get_priority_min(int policy)` | Get minimum priority |

### Scheduling Policies

| Policy | Description |
|--------|-------------|
| `SCHED_OTHER` | Default time-sharing policy |
| `SCHED_BATCH` | Batch scheduling |
| `SCHED_IDLE` | Very low priority |
| `SCHED_FIFO` | First-in, first-out real-time |
| `SCHED_RR` | Round-robin real-time |
| `SCHED_DEADLINE` | Deadline scheduling |

---

## 11. Namespace and Container Operations

| Syscall | Signature | Description |
|---------|-----------|-------------|
| `unshare` | `int unshare(int flags)` | Disassociate parts of execution context |
| `setns` | `int setns(int fd, int nstype)` | Join namespace |
| `clone` | `int clone(fn, stack, flags, arg, ...)` | Create process in new namespace (with flags) |

### Namespace Types

| Flag | Description |
|------|-------------|
| `CLONE_NEWNS` | Mount namespace |
| `CLONE_NEWUTS` | UTS namespace (hostname) |
| `CLONE_NEWIPC` | IPC namespace |
| `CLONE_NEWUSER` | User namespace |
| `CLONE_NEWPID` | PID namespace |
| `CLONE_NEWNET` | Network namespace |
| `CLONE_NEWCGROUP` | Cgroup namespace |

---

## 12. Syscall Numbers (x86_64)

For reference, the syscall number is passed in the `rax` register on x86_64. Common numbers:

| Number | Name | Number | Name |
|--------|------|--------|------|
| 0 | `read` | 1 | `write` |
| 2 | `open` | 3 | `close` |
| 4 | `stat` | 5 | `fstat` |
| 6 | `lstat` | 7 | `poll` |
| 8 | `lseek` | 9 | `mmap` |
| 10 | `mprotect` | 11 | `munmap` |
| 12 | `brk` | 13 | `rt_sigaction` |
| 35 | `nanosleep` | 39 | `getpid` |
| 56 | `clone` | 57 | `fork` |
| 59 | `execve` | 60 | `exit` |
| 61 | `wait4` | 62 | `kill` |
| 231 | `exit_group` | 257 | `openat` |
| 292 | `dup3` | 302 | `prlimit64` |

A complete list can be found in `/usr/include/asm/unistd_64.h` or via `ausyscall --dump`.

---

*For detailed information on any syscall, consult the corresponding man page (e.g., `man 2 open`) or the Linux kernel source.*
