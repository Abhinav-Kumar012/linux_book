# Chapter 127: File Descriptor Syscalls

## 1. Introduction

File descriptors are the universal handle for I/O in Linux. This chapter covers the syscalls that manipulate file descriptors themselves — duplicating them, creating pipes, modifying their properties with `fcntl`, performing device-specific operations with `ioctl`, and multiplexing I/O with `poll` and `select`.

---

## 2. dup / dup2 / dup3

### 2.1 Purpose

These syscalls duplicate a file descriptor, creating a new fd number that refers to the same underlying `struct file` (same file description, same file position).

### 2.2 Prototype

```c
#include <unistd.h>
int dup(int oldfd);
int dup2(int oldfd, int newfd);
int dup3(int oldfd, int newfd, int flags);
```

### 2.3 Arguments

- **`oldfd`**: The file descriptor to duplicate
- **`newfd`** (`dup2`/`dup3`): The desired new file descriptor number
- **`flags`** (`dup3` only): `O_CLOEXEC` (set close-on-exec on the new fd)

### 2.4 Return Values

- **Success**: The new file descriptor
- **Failure**: -1 with `errno` set

### 2.5 Differences

| Syscall | Behavior |
|---------|----------|
| `dup` | Returns the lowest available fd number |
| `dup2` | Returns exactly `newfd` (closing it first if open) |
| `dup3` | Like `dup2` but with flags (Linux 2.6.27+) |

### 2.6 Kernel Implementation

```c
SYSCALL_DEFINE1(dup, unsigned int, fildes)
{
    int ret = -EBADF;
    struct file *file = fget(fildes);
    if (file) {
        ret = get_unused_fd_flags(0);
        if (ret >= 0)
            fd_install(ret, file);
        else
            fput(file);
    }
    return ret;
}

SYSCALL_DEFINE2(dup2, unsigned int, oldfd, unsigned int, newfd)
{
    if (oldfd == newfd)
        return newfd;  // POSIX requires this check
    
    // If newfd is open, close it atomically
    return ksys_dup3(oldfd, newfd, 0);
}
```

### 2.7 Atomicity of dup2

`dup2` is atomic: if `newfd` is already open, it is closed first, then `oldfd` is duplicated to `newfd`. There is no window where `newfd` is invalid.

```c
// NOT equivalent to dup2:
close(newfd);        // ← newfd is invalid here (race!)
dup(oldfd);          // ← might not get newfd
```

### 2.8 Common Use: Redirecting stdin/stdout/stderr

```c
// Redirect stdout to a file
int fd = open("output.txt", O_WRONLY | O_CREAT | O_TRUNC, 0644);
dup2(fd, STDOUT_FILENO);  // STDOUT_FILENO now points to output.txt
close(fd);  // Close original fd (stdout still works)

// Classic Unix trick: redirect stdin/stdout/stderr
int devnull = open("/dev/null", O_RDWR);
dup2(devnull, STDIN_FILENO);
dup2(devnull, STDOUT_FILENO);
dup2(devnull, STDERR_FILENO);
close(devnull);
```

### 2.9 Shared File Offset

Duplicated file descriptors share the same file offset:

```c
int fd1 = open("test.txt", O_RDWR | O_CREAT | O_TRUNC, 0644);
int fd2 = dup(fd1);

write(fd1, "Hello", 5);
write(fd2, " World", 6);
// File contains "Hello World" because fd2 continued from offset 5

lseek(fd1, 0, SEEK_SET);
// fd2's offset is also reset to 0!
```

### 2.10 Common Bugs

```c
// BUG: Not checking dup2 return value
dup2(fd, STDOUT_FILENO);  // Might fail!
// FIX: Check return value
if (dup2(fd, STDOUT_FILENO) < 0) { perror("dup2"); }

// BUG: Forgetting close-on-exec with dup
int new_fd = dup(old_fd);  // No O_CLOEXEC!
// FIX: Use dup3
int new_fd = dup3(old_fd, desired_fd, O_CLOEXEC);
```

---

## 3. pipe / pipe2

### 3.1 Purpose

`pipe` creates a unidirectional data channel (pipe) consisting of two file descriptors: one for reading and one for writing.

### 3.2 Prototype

```c
#include <unistd.h>
int pipe(int pipefd[2]);
int pipe2(int pipefd[2], int flags);
```

### 3.3 Arguments

- **`pipefd[0]`**: Read end of the pipe
- **`pipefd[1]`**: Write end of the pipe
- **`flags`** (`pipe2` only): `O_CLOEXEC`, `O_NONBLOCK`, `O_DIRECT`

### 3.4 Return Values

- **Success**: 0 (pipefd array filled)
- **Failure**: -1 with `errno` set

### 3.5 Kernel Implementation

```c
SYSCALL_DEFINE1(pipe, int __user *, fildes)
{
    return do_pipe2(fildes, 0);
}

SYSCALL_DEFINE2(pipe2, int __user *, fildes, int, flags)
{
    return do_pipe2(fildes, flags);
}

static int do_pipe2(int __user *fildes, int flags)
{
    struct file *files[2];
    int fd[2];
    
    // Create pipe inode and two file objects
    int error = __do_pipe_flags(fd, files, flags);
    
    // Install fd[0] (read end) and fd[1] (write end)
    fd_install(fd[0], files[0]);
    fd_install(fd[1], files[1]);
    
    // Copy to user space
    if (copy_to_user(fildes, fd, 2 * sizeof(int)))
        goto err;
    
    return 0;
}
```

### 3.6 Pipe Semantics

- **Read on empty pipe**: Blocks until data available (or `EAGAIN` if `O_NONBLOCK`)
- **Read with closed write end**: Returns 0 (EOF)
- **Write on full pipe**: Blocks until space available (or `EAGAIN`/`EPIPE`)
- **Write with closed read end**: `SIGPIPE` + `EPIPE`
- **Pipe capacity**: Default 64KB (adjustable via `fcntl(fd, F_SETPIPE_SZ, size)`)

### 3.7 `O_DIRECT` Mode (Linux 3.4+)

With `O_DIRECT`, pipes operate in "packet" mode:
- Each `write` is a separate packet
- Each `read` returns exactly one packet
- Useful for message-oriented IPC

### 3.8 Example

```c
#include <unistd.h>
#include <stdio.h>
#include <string.h>
#include <sys/wait.h>

int main(void)
{
    int pipefd[2];
    pipe2(pipefd, O_CLOEXEC);
    
    if (fork() == 0) {
        // Child: write to pipe
        close(pipefd[0]);
        const char *msg = "Hello from child!";
        write(pipefd[1], msg, strlen(msg));
        close(pipefd[1]);
        _exit(0);
    }
    
    // Parent: read from pipe
    close(pipefd[1]);
    char buf[256];
    ssize_t n = read(pipefd[0], buf, sizeof(buf) - 1);
    if (n > 0) {
        buf[n] = '\0';
        printf("Received: %s\n", buf);
    }
    close(pipefd[0]);
    wait(NULL);
    return 0;
}
```

### 3.9 Common Bugs

```c
// BUG: Not closing unused ends (causes deadlock)
int pipefd[2];
pipe(pipefd);
if (fork() == 0) {
    // Child reads, but write end not closed!
    // Parent's read will never get EOF
    close(pipefd[1]);  // MUST close write end in reader
    read(pipefd[0], buf, sizeof(buf));
}

// BUG: Not handling SIGPIPE
write(pipefd[1], data, len);  // Reader closed → SIGPIPE kills process!
// FIX: Ignore SIGPIPE
signal(SIGPIPE, SIG_IGN);
// Or use MSG_NOSIGNAL with send()
```

---

## 4. fcntl

### 4.1 Purpose

`fcntl` (file control) is a multipurpose syscall for manipulating file descriptor properties. It handles a wide range of operations that don't warrant separate syscalls.

### 4.2 Prototype

```c
#include <fcntl.h>
int fcntl(int fd, int cmd, ... /* arg */);
```

### 4.3 Commands

| Command | Description |
|---------|-------------|
| `F_DUPFD` | Duplicate fd to lowest available >= arg |
| `F_DUPFD_CLOEXEC` | Like `F_DUPFD` but set `O_CLOEXEC` |
| `F_GETFD` | Get file descriptor flags |
| `F_SETFD` | Set file descriptor flags (e.g., `FD_CLOEXEC`) |
| `F_GETFL` | Get file status flags (`O_RDONLY`, `O_NONBLOCK`, etc.) |
| `F_SETFL` | Set file status flags (only some can be changed) |
| `F_GETOWN` | Get process/group for SIGIO |
| `F_SETOWN` | Set process/group for SIGIO |
| `F_GETLK` | Get first lock that blocks a lock request |
| `F_SETLK` | Set or clear a file lock (non-blocking) |
| `F_SETLKW` | Set or clear a file lock (blocking) |
| `F_GETSIG` | Get signal sent on I/O readiness |
| `F_SETSIG` | Set signal sent on I/O readiness |
| `F_SETPIPE_SZ` | Set pipe buffer size |
| `F_GETPIPE_SZ` | Get pipe buffer size |
| `F_ADD_SEALS` | Add seals to a memfd |
| `F_GET_SEALS` | Get seals on a memfd |
| `F_GET_RW_HINT` | Get read/write life hint |
| `F_SET_RW_HINT` | Set read/write life hint |

### 4.4 File Descriptor Flags vs File Status Flags

**File descriptor flags** (per-fd, `F_GETFD`/`F_SETFD`):
- `FD_CLOEXEC` — close on exec

**File status flags** (per-file-description, shared by dup'd fds, `F_GETFL`/`F_SETFL`):
- `O_RDONLY`, `O_WRONLY`, `O_RDWR` — access mode (read-only after open)
- `O_APPEND` — append mode
- `O_NONBLOCK` — non-blocking mode
- `O_ASYNC` — async I/O (SIGIO)
- `O_DIRECT` — direct I/O
- `O_NOATIME` — don't update atime

### 4.5 File Locking

```c
// Advisory file locking
struct flock fl = {
    .l_type = F_WRLCK,      // Write lock
    .l_whence = SEEK_SET,
    .l_start = 0,            // From beginning
    .l_len = 0,              // Lock entire file (0 = to EOF)
};

// Non-blocking: fail immediately if can't lock
if (fcntl(fd, F_SETLK, &fl) < 0) {
    if (errno == EAGAIN || errno == EACCES)
        printf("File is locked by another process\n");
}

// Blocking: wait until lock is available
fcntl(fd, F_SETLKW, &fl);  // Blocks until lock acquired

// Release lock
fl.l_type = F_UNLCK;
fcntl(fd, F_SETLK, &fl);
```

### 4.6 Changing O_NONBLOCK

```c
// Get current flags
int flags = fcntl(fd, F_GETFL);
if (flags < 0) { perror("fcntl F_GETFL"); return -1; }

// Set O_NONBLOCK
flags |= O_NONBLOCK;
if (fcntl(fd, F_SETFL, flags) < 0) { perror("fcntl F_SETFL"); return -1; }
```

### 4.7 Kernel Implementation

```c
SYSCALL_DEFINE3(fcntl, unsigned int, fd, unsigned int, cmd, unsigned long, arg)
{
    struct fd f = fdget_raw(fd);
    if (!f.file)
        return -EBADF;
    
    // Switch on cmd
    switch (cmd) {
    case F_DUPFD:
        return f_dupfd(arg, f.file, 0);
    case F_GETFD:
        return get_close_on_exec(fd) ? FD_CLOEXEC : 0;
    case F_SETFD:
        return set_close_on_exec(fd, arg & FD_CLOEXEC);
    case F_GETFL:
        return f.file->f_flags;
    case F_SETFL:
        // Only certain flags can be changed after open
        return setfl(fd, f.file, arg);
    case F_GETLK:
        return fcntl_getlk(fd, f.file, (struct flock __user *)arg);
    case F_SETLK:
    case F_SETLKW:
        return fcntl_setlk(fd, f.file, cmd, (struct flock __user *)arg);
    // ... many more cases
    }
}
```

### 4.8 Common Bugs

```c
// BUG: Race between F_GETFL and F_SETFL
int flags = fcntl(fd, F_GETFL);
// Another thread could change flags here!
fcntl(fd, F_SETFL, flags | O_NONBLOCK);

// BUG: Trying to change access mode
fcntl(fd, F_SETFL, O_RDWR);  // Can't change access mode after open!
// Access mode (O_RDONLY/O_WRONLY/O_RDWR) is set at open() time only
```

---

## 5. ioctl

### 5.1 Purpose

`ioctl` (I/O control) is the catch-all syscall for device-specific and filesystem-specific operations that don't fit into the standard read/write model.

### 5.2 Prototype

```c
#include <sys/ioctl.h>
int ioctl(int fd, unsigned long request, ...);
```

### 5.3 Common ioctl Requests

**Terminal I/O:**
```c
struct winsize ws;
ioctl(fd, TIOCGWINSZ, &ws);  // Get terminal size
ioctl(fd, TIOCSWINSZ, &ws);  // Set terminal size
ioctl(fd, TIOCSCTTY, 0);      // Set controlling terminal
```

**Network interfaces:**
```c
struct ifreq ifr;
strncpy(ifr.ifr_name, "eth0", IFNAMSIZ);
ioctl(sockfd, SIOCGIFADDR, &ifr);   // Get interface address
ioctl(sockfd, SIOCGIFMTU, &ifr);    // Get MTU
ioctl(sockfd, SIOCSIFFLAGS, &ifr);  // Set interface flags
```

**Block devices:**
```c
unsigned long size;
ioctl(fd, BLKGETSIZE, &size);       // Get size in 512-byte sectors
ioctl(fd, BLKFLSBUF);               // Flush buffer cache
ioctl(fd, BLKDISCARD, &range);      // Discard blocks (TRIM)
```

**File-specific:**
```c
ioctl(fd, FIONREAD, &bytes);  // Bytes available for reading
ioctl(fd, FIOCLEX);           // Set close-on-exec
ioctl(fd, FIONBIO, &on);      // Set non-blocking
```

### 5.4 Kernel Implementation

```c
SYSCALL_DEFINE3(ioctl, unsigned int, fd, unsigned int, cmd, unsigned long, arg)
{
    struct fd f = fdget(fd);
    if (!f.file)
        return -EBADF;
    
    // Route to the file's ioctl method
    ret = do_vfs_ioctl(f.file, fd, cmd, arg);
    fdput(f);
    return ret;
}

static int do_vfs_ioctl(struct file *filp, unsigned int fd, unsigned int cmd, unsigned long arg)
{
    switch (cmd) {
    case FIONREAD:
        return ioctl_fionread(filp, arg);
    case FIONBIO:
        return ioctl_fionbio(filp, arg);
    case FIOCLEX:
        set_close_on_exec(fd, 1);
        return 0;
    default:
        // Call filesystem/device-specific ioctl
        if (filp->f_op->unlocked_ioctl)
            return filp->f_op->unlocked_ioctl(filp, cmd, arg);
        return -ENOTTY;
    }
}
```

### 5.5 Security Implications

- `ioctl` is the #1 source of kernel vulnerabilities. The argument is often a pointer to a user-space structure that the kernel must carefully validate.
- Use `_IOR`, `_IOW`, `_IOWR`, `_IO` macros to define ioctl numbers with embedded size and direction information.
- Modern drivers should use `copy_from_user`/`copy_to_user` for all ioctl data.

---

## 6. poll / ppoll

### 6.1 Purpose

`poll` monitors multiple file descriptors for I/O readiness. It's an alternative to `select` with a cleaner interface.

### 6.2 Prototype

```c
#include <poll.h>
int poll(struct pollfd *fds, nfds_t nfds, int timeout);
int ppoll(struct pollfd *fds, nfds_t nfds, const struct timespec *tmo_p,
          const sigset_t *sigmask);
```

### 6.3 The `pollfd` Structure

```c
struct pollfd {
    int   fd;         // File descriptor to monitor
    short events;     // Events to watch for (input)
    short revents;    // Events that occurred (output)
};
```

### 6.4 Events

| Event | Description |
|-------|-------------|
| `POLLIN` | Data available for reading |
| `POLLPRI` | Urgent data available |
| `POLLOUT` | Writing will not block |
| `POLLERR` | Error condition |
| `POLLHUP` | Hang up |
| `POLLNVAL` | Invalid fd |
| `POLLRDHUP` | Stream socket peer closed connection |

### 6.5 Return Values

- **Success**: Number of fds with events (0 = timeout, positive = events)
- **Failure**: -1 with `errno` set

### 6.6 Kernel Implementation

```c
SYSCALL_DEFINE3(poll, struct pollfd __user *, ufds, unsigned int, nfds, int, timeout)
{
    return do_sys_poll(ufds, nfds, to);
}
```

The kernel iterates through all file descriptors, calling each fd's `poll` method to check readiness, then sleeps using a wait queue if no fd is ready.

### 6.7 Example

```c
#include <poll.h>
#include <unistd.h>
#include <stdio.h>

int main(void)
{
    struct pollfd fds[2] = {
        { .fd = STDIN_FILENO, .events = POLLIN },
        { .fd = STDOUT_FILENO, .events = POLLOUT },
    };
    
    int ret = poll(fds, 2, 5000);  // 5 second timeout
    if (ret < 0) {
        perror("poll");
        return 1;
    }
    if (ret == 0) {
        printf("Timeout!\n");
        return 0;
    }
    
    if (fds[0].revents & POLLIN)
        printf("stdin is readable\n");
    if (fds[1].revents & POLLOUT)
        printf("stdout is writable\n");
    
    return 0;
}
```

### 6.8 Performance

`poll` has O(n) complexity — the kernel must check every fd on each call. For large numbers of fds (thousands), `epoll` (Chapter 140) is much more efficient with O(1) notification.

---

## 7. select / pselect

### 7.1 Purpose

`select` is the original I/O multiplexing syscall. It monitors three sets of file descriptors for read, write, and exception readiness.

### 7.2 Prototype

```c
#include <sys/select.h>
int select(int nfds, fd_set *readfds, fd_set *writefds, fd_set *exceptfds,
           struct timeval *timeout);
int pselect(int nfds, fd_set *readfds, fd_set *writefds, fd_set *exceptfds,
            const struct timespec *timeout, const sigset_t *sigmask);
```

### 7.3 fd_set Operations

```c
fd_set readfds;
FD_ZERO(&readfds);        // Clear all
FD_SET(fd, &readfds);     // Add fd
FD_CLR(fd, &readfds);     // Remove fd
if (FD_ISSET(fd, &readfds))  // Check if fd is set
```

### 7.4 Limitations

- `FD_SETSIZE` is typically 1024 — can't monitor more than 1024 fds
- Three separate fd sets (read/write/except) — wasteful
- Sets are modified in-place (must rebuild on each call)
- O(n) complexity like `poll`

### 7.5 Example

```c
#include <sys/select.h>
#include <unistd.h>
#include <stdio.h>

int main(void)
{
    fd_set readfds;
    struct timeval tv = { .tv_sec = 5, .tv_usec = 0 };
    
    FD_ZERO(&readfds);
    FD_SET(STDIN_FILENO, &readfds);
    
    int ret = select(STDIN_FILENO + 1, &readfds, NULL, NULL, &tv);
    if (ret > 0 && FD_ISSET(STDIN_FILENO, &readfds)) {
        char buf[256];
        ssize_t n = read(STDIN_FILENO, buf, sizeof(buf));
        if (n > 0) write(STDOUT_FILENO, buf, n);
    }
    return 0;
}
```

### 7.6 select vs poll vs epoll

| Feature | select | poll | epoll |
|---------|--------|------|-------|
| Max fds | FD_SETSIZE (1024) | Unlimited | Unlimited |
| Complexity | O(n) | O(n) | O(1) notification |
| fd sets | 3 fd_sets | 1 pollfd array | Persistent interest |
| Edge-triggered | No | No | Yes |
| Signal-based | pselect | ppoll | No |

---

## 8. Security Implications

- **`dup` fd leakage**: Always use `O_CLOEXEC` (or `FD_CLOEXEC`) to prevent fd leakage to child processes after `exec`.
- **Pipe fd leaks**: Forgetting to close unused pipe ends can cause hangs and resource exhaustion.
- **`ioctl` attack surface**: `ioctl` is a major kernel attack vector. Minimize ioctl usage in unprivileged contexts.
- **File locks are advisory**: `fcntl` locks are only effective if all processes cooperate. No security guarantee.
- **`select` FD_SETSIZE overflow**: Adding an fd >= FD_SETSIZE to an `fd_set` causes buffer overflow.

---

## 9. Common Bugs Summary

```c
// BUG: select modifies fd_sets — must rebuild each time
fd_set readfds;
FD_ZERO(&readfds);
FD_SET(fd, &readfds);
while (1) {
    select(fd + 1, &readfds, NULL, NULL, NULL);  // readfds is stale after first call!
}

// FIX: Rebuild fd_set before each select call
while (1) {
    fd_set rfds = readfds;  // Copy from master set
    select(fd + 1, &rfds, NULL, NULL, NULL);
    if (FD_ISSET(fd, &rfds)) { /* handle */ }
}

// BUG: poll with negative timeout (blocks forever, might not be intended)
poll(fds, nfds, -1);  // Blocks indefinitely!
// Use 0 for non-blocking, positive for timeout
```

---

## 10. Kernel Source References

- **`dup`/`dup2`/`dup3`**: `fs/file.c`
- **`pipe`/`pipe2`**: `fs/pipe.c`
- **`fcntl`**: `fs/fcntl.c`
- **`ioctl`**: `fs/ioctl.c`
- **`poll`/`ppoll`**: `fs/select.c`
- **`select`/`pselect`**: `fs/select.c`
- **fd table management**: `fs/file.c`, `include/linux/fdtable.h`
- **File locking**: `fs/locks.c`

---

## 11. Summary

File descriptor manipulation syscalls are the building blocks of I/O management:
- **`dup`/`dup2`/`dup3`**: Duplicate fds for I/O redirection
- **`pipe`/`pipe2`**: Create unidirectional channels for IPC
- **`fcntl`**: Swiss-army knife for fd properties and file locking
- **`ioctl`**: Device-specific control operations
- **`poll`/`select`**: I/O multiplexing (use `epoll` for high-fd-count scenarios)

---

## 13. Detailed File Descriptor Internals

### 13.1 The File Descriptor Table

Each process has a file descriptor table managed by `struct files_struct`:

```c
struct files_struct {
    atomic_t count;
    struct fdtable __rcu *fdt;           // Current fdtable
    struct fdtable fdtab;                // Embedded fdtable (small files)
    spinlock_t file_lock;
    unsigned int next_fd;                // Hint for next fd allocation
    unsigned long close_on_exec_init[1]; // Close-on-exec bitmap (inline)
    unsigned long open_fds_init[1];      // Open fds bitmap (inline)
    unsigned long full_fds_bits_init[1]; // Full fds bitmap (inline)
    struct file __rcu *fd_array[NR_OPEN_DEFAULT]; // Inline file array (64 entries)
};

struct fdtable {
    unsigned int max_fds;
    struct file __rcu **fd;              // File pointer array
    unsigned long *close_on_exec;        // Close-on-exec bitmap
    unsigned long *open_fds;             // Open fds bitmap
    unsigned long *full_fds_bits;        // Full fds bitmap
};
```

**fd allocation algorithm:**
```c
static int __alloc_fd(struct files_struct *files, unsigned start, unsigned end, unsigned flags)
{
    // Start from next_fd hint
    // Find first zero bit in open_fds bitmap
    // Set the bit
    // Update next_fd hint
    // Return the fd number
}
```

### 13.2 The struct file Reference Counting

```c
struct file {
    union {
        struct llist_node fu_llist;
        struct rcu_head fu_rcuhead;
    } f_u;
    struct path f_path;                  // Dentry + mount
    struct inode *f_inode;
    const struct file_operations *f_op;  // Operations vtable
    spinlock_t f_lock;
    atomic_long_t f_count;               // Reference count
    unsigned int f_flags;                // O_RDONLY, O_NONBLOCK, etc.
    fmode_t f_mode;                      // FMODE_READ, FMODE_WRITE
    loff_t f_pos;                        // Current position
    struct fown_struct f_owner;          // Owner for SIGIO
    void *private_data;                  // Driver-specific data
    struct address_space *f_mapping;     // Page cache mapping
    // ...
};
```

**Reference count lifecycle:**
1. `open()`: f_count = 1
2. `dup()`: f_count++
3. `fork()`: f_count++ (child inherits fd table)
4. `close()`: f_count--; if 0 → free the file

### 13.3 Pipe Internals

```c
struct pipe_inode_info {
    struct mutex mutex;
    wait_queue_head_t rd_wait;     // Reader wait queue
    wait_queue_head_t wr_wait;     // Writer wait queue
    unsigned int nrbufs;           // Number of filled buffers
    unsigned int curbuf;           // Current buffer index
    unsigned int buffers;          // Total number of buffers
    unsigned int readers;          // Number of readers
    unsigned int writers;          // Number of writers
    unsigned int files;            // Number of file descriptors
    unsigned int r_counter;        // Reader counter
    unsigned int w_counter;        // Writer counter
    struct page *tmp_page;         // Temporary page for copying
    struct pipe_buffer *bufs;      // Buffer array
    struct user_struct *user;      // User who created the pipe
};

struct pipe_buffer {
    struct page *page;             // Physical page
    unsigned int offset;           // Offset within page
    unsigned int len;              // Data length
    const struct pipe_buf_operations *ops;
    unsigned int flags;            // PIPE_BUF_FLAG_*
};
```

**Pipe capacity:**
Default is 16 buffers × 4KB pages = 64KB. Can be increased with `fcntl(F_SETPIPE_SZ)` up to `/proc/sys/fs/pipe-max-size` (default 1MB).

### 13.4 ioctl Internals

```c
// ioctl command encoding (Linux convention):
// Bits 31-30: Direction (00=none, 01=write, 10=read, 11=read/write)
// Bits 29-16: Size of the argument
// Bits 15-8:  Type (magic number, e.g., 'T' for terminal)
// Bits 7-0:   Command number

#define _IOC(dir, type, nr, size) \
    (((dir) << 30) | ((size) << 16) | ((type) << 8) | (nr))

#define _IO(type, nr)           _IOC(0, type, nr, 0)
#define _IOR(type, nr, size)    _IOC(1, type, nr, sizeof(size))
#define _IOW(type, nr, size)    _IOC(2, type, nr, sizeof(size))
#define _IOWR(type, nr, size)   _IOC(3, type, nr, sizeof(size))
```

### 13.5 poll/select Internals

```c
// Each file descriptor has a poll method:
typedef __poll_t (*poll_t)(struct file *, struct poll_table_struct *);

// The poll table is used to register wait queues
struct poll_table_struct {
    poll_queue_proc _qproc;
    __poll_t _key;
};

// When a file is polled:
__poll_t sock_poll(struct file *file, poll_table *wait)
{
    struct socket *sock = file->private_data;
    // Register the current process on the socket's wait queue
    poll_wait(file, &sock->wait, wait);
    // Return current readiness mask
    return sock->ops->poll(file, sock, wait);
}
```

### 13.6 close-on-exec Implementation

```c
// During execve:
static int do_close_on_exec(struct files_struct *files)
{
    unsigned long *bitmap = files->close_on_exec;
    int fd;
    
    for_each_set_bit(fd, bitmap, files->fdt->max_fds) {
        // Close the file descriptor
        filp_close(files->fdt->fd[fd], files);
        // Clear the fd in the open_fds bitmap
        __clear_bit(fd, files->fdt->open_fds);
        files->fdt->fd[fd] = NULL;
    }
    
    // Clear the close_on_exec bitmap
    memset(bitmap, 0, ...);
}
```

### 13.7 File Lock Internals

POSIX file locks are managed by the lock manager:

```c
struct file_lock {
    struct file_lock *fl_next;
    struct list_head fl_list;
    struct hlist_node fl_link;
    struct list_head fl_block;
    fl_owner_t fl_owner;
    unsigned int fl_flags;
    unsigned char fl_type;      // F_RDLCK, F_WRLCK, F_UNLCK
    unsigned int fl_pid;
    struct file *fl_file;
    loff_t fl_start;            // Lock start offset
    loff_t fl_end;              // Lock end offset
    struct fasync_struct *fl_fasync;
    unsigned long fl_break_time;
    // ...
};
```

**Advisory vs mandatory locks:**
- Advisory: Only effective if all processes cooperate (check with `fcntl`)
- Mandatory: Enforced by the kernel (mount with `-o mand`)

### 13.8 The fdget/fdput Pattern

The kernel uses a reference-counting pattern for safe fd access:

```c
struct fd {
    struct file *file;
    unsigned int flags;
};

struct fd fdget(unsigned int fd)
{
    struct fd f;
    struct files_struct *files = current->files;
    
    rcu_read_lock();
    f.file = rcu_dereference(files->fdt->fd[fd]);
    if (f.file) {
        // Increment reference count
        f.flags = ...;
    }
    rcu_read_unlock();
    
    return f;
}

void fdput(struct fd f)
{
    if (f.file) {
        // Decrement reference count
        fput(f.file);
    }
}
```

This pattern ensures that the file structure isn't freed while the syscall is using it.

### 13.9 fd Passing via Unix Sockets

File descriptors can be passed between processes via Unix domain sockets using `SCM_RIGHTS` ancillary data:

```c
// Sending:
struct msghdr msg = {0};
struct iovec iov = { .iov_base = "x", .iov_len = 1 };
char cmsg_buf[CMSG_SPACE(sizeof(int))];
struct cmsghdr *cmsg;

msg.msg_iov = &iov;
msg.msg_iovlen = 1;
msg.msg_control = cmsg_buf;
msg.msg_controllen = sizeof(cmsg_buf);

cmsg = CMSG_FIRSTHDR(&msg);
cmsg->cmsg_level = SOL_SOCKET;
cmsg->cmsg_type = SCM_RIGHTS;
cmsg->cmsg_len = CMSG_LEN(sizeof(int));
*(int *)CMSG_DATA(cmsg) = fd_to_pass;

sendmsg(unix_socket, &msg, 0);

// Receiving:
recvmsg(unix_socket, &msg, 0);
cmsg = CMSG_FIRSTHDR(&msg);
if (cmsg->cmsg_type == SCM_RIGHTS) {
    int received_fd = *(int *)CMSG_DATA(cmsg);
    // received_fd now refers to the same file as the sender's fd
}
```

The kernel increments the file's reference count and adds a new entry in the receiving process's fd table.
