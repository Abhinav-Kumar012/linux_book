# Chapter 140: Modern FD Syscalls

## 1. Introduction

Linux continues to evolve its file descriptor-based interfaces. This chapter covers modern FD-related syscalls that extend the "everything is a file" philosophy to new domains: `epoll` for scalable I/O multiplexing, `eventfd` for event notification, `signalfd` for signal-as-fd, `memfd_create` for anonymous memory files, `pidfd_open`/`pidfd_send_signal` for process file descriptors, and `userfaultfd` for user-space page fault handling.

---

## 2. epoll_create1 / epoll_ctl / epoll_wait

### 2.1 Purpose

`epoll` is a scalable I/O event notification mechanism. Unlike `poll`/`select` which are O(n) per call, `epoll` is O(1) for event notification — only ready events are returned.

### 2.2 Prototype

```c
#include <sys/epoll.h>
int epoll_create1(int flags);
int epoll_ctl(int epfd, int op, int fd, struct epoll_event *event);
int epoll_wait(int epfd, struct epoll_event *events, int maxevents, int timeout);
int epoll_pwait(int epfd, struct epoll_event *events, int maxevents,
                int timeout, const sigset_t *sigmask);
int epoll_pwait2(int epfd, struct epoll_event *events, int maxevents,
                 const struct timespec *timeout, const sigset_t *sigmask);
```

### 2.3 epoll_create1

```c
int epfd = epoll_create1(EPOLL_CLOEXEC);
```

**Flags:** `EPOLL_CLOEXEC` (close-on-exec)

### 2.4 epoll_ctl Operations

| Op | Description |
|----|-------------|
| `EPOLL_CTL_ADD` | Add fd to interest set |
| `EPOLL_CTL_MOD` | Modify events for fd |
| `EPOLL_CTL_DEL` | Remove fd from interest set |

### 2.5 Events

| Event | Description |
|-------|-------------|
| `EPOLLIN` | Data available for reading |
| `EPOLLOUT` | Writing possible |
| `EPOLLRDHUP` | Stream socket peer closed |
| `EPOLLPRI` | Urgent data |
| `EPOLLERR` | Error condition |
| `EPOLLHUP` | Hang up |
| `EPOLLET` | Edge-triggered (vs level-triggered) |
| `EPOLLONESHOT` | One-shot (auto-disable after event) |
| `EPOLLEXCLUSIVE` | Wake only one waiter (Linux 4.5+) |
| `EPOLWAKEUP` | Prevent suspend while event pending |

### 2.6 Level-Triggered vs Edge-Triggered

**Level-triggered (default):**
- Reports readiness as long as the condition holds
- If data is available, `epoll_wait` returns immediately (even without new data)
- Simpler to use

**Edge-triggered (`EPOLLET`):**
- Reports only on state transitions (new data arrives)
- Must read/write until `EAGAIN`
- More efficient for high-throughput
- Requires non-blocking fds

### 2.7 Example: TCP Server

```c
#include <sys/epoll.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>
#include <stdio.h>

#define MAX_EVENTS 64

int main(void)
{
    int server_fd = socket(AF_INET, SOCK_STREAM | SOCK_NONBLOCK | SOCK_CLOEXEC, 0);
    
    struct sockaddr_in addr = {
        .sin_family = AF_INET,
        .sin_port = htons(8080),
        .sin_addr.s_addr = INADDR_ANY,
    };
    bind(server_fd, (struct sockaddr *)&addr, sizeof(addr));
    listen(server_fd, 128);
    
    int epfd = epoll_create1(EPOLL_CLOEXEC);
    
    struct epoll_event ev = {
        .events = EPOLLIN,
        .data.fd = server_fd,
    };
    epoll_ctl(epfd, EPOLL_CTL_ADD, server_fd, &ev);
    
    struct epoll_event events[MAX_EVENTS];
    
    while (1) {
        int nfds = epoll_wait(epfd, events, MAX_EVENTS, -1);
        
        for (int i = 0; i < nfds; i++) {
            if (events[i].data.fd == server_fd) {
                // Accept new connection
                int client_fd = accept4(server_fd, NULL, NULL,
                                        SOCK_NONBLOCK | SOCK_CLOEXEC);
                if (client_fd >= 0) {
                    ev.events = EPOLLIN | EPOLLET;
                    ev.data.fd = client_fd;
                    epoll_ctl(epfd, EPOLL_CTL_ADD, client_fd, &ev);
                }
            } else {
                // Handle client data
                char buf[4096];
                ssize_t n = read(events[i].data.fd, buf, sizeof(buf));
                if (n <= 0) {
                    close(events[i].data.fd);
                    epoll_ctl(epfd, EPOLL_CTL_DEL, events[i].data.fd, NULL);
                } else {
                    write(events[i].data.fd, buf, n);  // Echo
                }
            }
        }
    }
    
    close(epfd);
    close(server_fd);
    return 0;
}
```

### 2.8 Kernel Implementation

```c
SYSCALL_DEFINE1(epoll_create1, int, flags)
{
    return do_epoll_create(flags);
}

SYSCALL_DEFINE4(epoll_ctl, int, epfd, int, op, int, fd, struct epoll_event __user *, event)
{
    struct eventpoll *ep = epfd_to_eventpoll(epfd);
    struct epitem *epi;
    
    switch (op) {
    case EPOLL_CTL_ADD:
        epi = ep_insert(ep, &epds, tfile, fd);
        break;
    case EPOLL_CTL_DEL:
        ep_remove(ep, epi);
        break;
    case EPOLL_CTL_MOD:
        ep_modify(ep, epi, &epds);
        break;
    }
}

SYSCALL_DEFINE4(epoll_wait, int, epfd, struct epoll_event __user *, events,
                int, maxevents, int, timeout)
{
    return ep_poll(ep, events, maxevents, timeout);
}
```

### 2.9 Performance

| Mechanism | Complexity | 100K connections |
|-----------|-----------|-----------------|
| `select` | O(n) | Very slow |
| `poll` | O(n) | Slow |
| `epoll` | O(1) notification | Fast |

For 10,000+ concurrent connections, `epoll` is orders of magnitude faster than `poll`/`select`.

### 2.10 `epoll_pwait2` (Linux 5.11+)

Like `epoll_pwait` but with nanosecond timeout precision:

```c
struct timespec timeout = { .tv_sec = 0, .tv_nsec = 500000 };  // 500μs
int nfds = epoll_pwait2(epfd, events, MAX_EVENTS, &timeout, NULL);
```

---

## 3. eventfd2

### 3.1 Purpose

`eventfd` creates a file descriptor for event notification. It's a simple counter that can be read/written and used with `poll`/`epoll`.

### 3.2 Prototype

```c
#include <sys/eventfd.h>
int eventfd(unsigned int initval, int flags);
int eventfd2(unsigned int initval, int flags);  // Syscall name
```

### 3.3 Flags

| Flag | Description |
|------|-------------|
| `EFD_SEMAPHORE` | Semaphore mode (read decrements by 1) |
| `EFD_NONBLOCK` | Non-blocking |
| `EFD_CLOEXEC` | Close-on-exec |

### 3.4 Semantics

- **Write**: Adds the 8-byte value to the counter. Must be 8 bytes, native endian.
- **Read**: Returns the counter value and resets it to 0 (or decrements by 1 in semaphore mode). Blocks if counter is 0.
- **poll/epoll**: Readable when counter > 0.

### 3.5 Example: Thread Notification

```c
#include <sys/eventfd.h>
#include <unistd.h>
#include <stdint.h>
#include <pthread.h>
#include <stdio.h>

static int efd;

void *worker(void *arg)
{
    // Simulate work
    sleep(1);
    
    // Signal completion
    uint64_t val = 1;
    write(efd, &val, sizeof(val));
    return NULL;
}

int main(void)
{
    efd = eventfd(0, EFD_CLOEXEC | EFD_NONBLOCK);
    
    pthread_t tid;
    pthread_create(&tid, NULL, worker, NULL);
    
    // Wait for notification
    uint64_t val;
    read(efd, &val, sizeof(val));
    printf("Worker completed (%lu signals)\n", val);
    
    pthread_join(tid, NULL);
    close(efd);
    return 0;
}
```

### 3.6 Example: Event Loop Integration

```c
// Use eventfd with epoll for thread-safe event notification
int efd = eventfd(0, EFD_CLOEXEC | EFD_NONBLOCK);
struct epoll_event ev = { .events = EPOLLIN, .data.fd = efd };
epoll_ctl(epfd, EPOLL_CTL_ADD, efd, &ev);

// From any thread:
uint64_t val = 1;
write(efd, &val, sizeof(val));

// In event loop:
epoll_wait(epfd, events, MAX_EVENTS, -1);
if (events[i].data.fd == efd) {
    uint64_t val;
    read(efd, &val, sizeof(val));
    // Handle notification
}
```

### 3.7 Kernel Implementation

```c
SYSCALL_DEFINE2(eventfd2, unsigned int, count, int, flags)
{
    return do_eventfd(count, flags);
}
```

The kernel maintains a 64-bit counter in the `eventfd_ctx` structure. Reads and writes use atomic operations.

---

## 4. timerfd_create / timerfd_settime / timerfd_gettime

### 4.1 Purpose

`timerfd` creates a file descriptor for receiving timer events. (Covered in detail in Chapter 134.)

### 4.2 Quick Example

```c
#include <sys/timerfd.h>
#include <unistd.h>
#include <stdint.h>

int tfd = timerfd_create(CLOCK_MONOTONIC, TFD_CLOEXEC | TFD_NONBLOCK);

struct itimerspec its = {
    .it_interval = { 0, 100000000 },  // 100ms interval
    .it_value = { 1, 0 },              // 1s initial
};
timerfd_settime(tfd, 0, &its, NULL);

// In event loop (with epoll):
uint64_t expirations;
read(tfd, &expirations, sizeof(expirations));
printf("Timer expired %lu times\n", expirations);
```

---

## 5. signalfd4

### 5.1 Purpose

`signalfd` creates a file descriptor for receiving signals. (Covered in detail in Chapter 130.)

### 5.2 Quick Example

```c
#include <sys/signalfd.h>
#include <signal.h>
#include <unistd.h>

sigset_t mask;
sigemptyset(&mask);
sigaddset(&mask, SIGINT);
sigaddset(&mask, SIGTERM);
sigprocmask(SIG_BLOCK, &mask, NULL);

int sfd = signalfd(-1, &mask, SFD_CLOEXEC | SFD_NONBLOCK);

// In event loop:
struct signalfd_siginfo si;
read(sfd, &si, sizeof(si));
printf("Signal %d from PID %d\n", si.ssi_signo, si.ssi_pid);
```

---

## 6. memfd_create

### 6.1 Purpose

`memfd_create` creates an anonymous file in RAM (tmpfs). The file has no directory entry and can't be accessed by other processes unless the fd is shared.

### 6.2 Prototype

```c
#include <sys/mman.h>
int memfd_create(const char *name, unsigned int flags);
```

### 6.3 Flags

| Flag | Description |
|------|-------------|
| `MFD_CLOEXEC` | Close-on-exec |
| `MFD_ALLOW_SEALING` | Allow file sealing |
| `MFD_HUGETLB` | Use huge pages |
| `MFD_HUGE_2MB` | 2MB huge pages |
| `MFD_HUGE_1GB` | 1GB huge pages |

### 6.4 File Sealing

Sealing prevents certain modifications to a file:

| Seal | Description |
|------|-------------|
| `F_SEAL_SEAL` | Prevent further sealing |
| `F_SEAL_SHRINK` | Prevent file from shrinking |
| `F_SEAL_GROW` | Prevent file from growing |
| `F_SEAL_WRITE` | Prevent writing |

### 6.5 Example: Anonymous Shared Memory

```c
#include <sys/mman.h>
#include <unistd.h>
#include <string.h>

// Create anonymous file in memory
int fd = memfd_create("my_shared_data", MFD_CLOEXEC);

// Set size
ftruncate(fd, 4096);

// Map it
void *p = mmap(NULL, 4096, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);

// Use it
strcpy(p, "Hello from memfd!");

// Share fd with child process (via fork, Unix socket SCM_RIGHTS, etc.)
// After fork, child can mmap the same fd and see the data

// Seal it (prevent modifications)
fcntl(fd, F_ADD_SEALS, F_SEAL_WRITE | F_SEAL_SHRINK | F_SEAL_GROW);
// Now the file is immutable
```

### 6.6 Use Cases

- **Shared memory**: IPC without filesystem entry
- **File sealing**: Secure content distribution (Firefox uses this for its JIT code)
- **Huge page backing**: Large anonymous allocations with huge pages
- **Dynamic libraries**: Loading code without touching the filesystem
- **D-Bus**: Passing fds between processes

### 6.7 Kernel Implementation

```c
SYSCALL_DEFINE2(memfd_create, const char __user *, uname, unsigned int, flags)
{
    // Create a tmpfs file
    file = shmem_file_setup(name, 0, VM_NORESERVE);
    
    // Apply flags
    if (flags & MFD_ALLOW_SEALING)
        seals = F_SEAL_SEAL;  // Allow sealing
    
    return fd;
}
```

---

## 7. pidfd_open / pidfd_send_signal / pidfd_getfd

### 7.1 Purpose

`pidfd` is a file descriptor that refers to a process. It solves the PID reuse problem — a pidfd is guaranteed to refer to the specific process instance, even if the PID is recycled.

### 7.2 Prototype

```c
#include <sys/syscall.h>
#include <unistd.h>

int pidfd_open(pid_t pid, unsigned int flags);
int pidfd_send_signal(int pidfd, int sig, siginfo_t *info, unsigned int flags);
int pidfd_getfd(int pidfd, int targetfd, unsigned int flags);
```

### 7.3 pidfd_open

```c
int pidfd = pidfd_open(target_pid, 0);
if (pidfd < 0) { perror("pidfd_open"); return; }

// Now pidfd refers to the specific process
// Can use with poll/epoll to detect process exit
struct pollfd pfd = { .fd = pidfd, .events = POLLIN };
poll(&pfd, 1, -1);
if (pfd.revents & POLLIN)
    printf("Process exited\n");

close(pidfd);
```

### 7.4 pidfd_send_signal

```c
// Send signal via pidfd (no PID reuse race)
int pidfd = pidfd_open(pid, 0);
pidfd_send_signal(pidfd, SIGTERM, NULL, 0);
close(pidfd);
```

### 7.5 pidfd_getfd (Linux 5.6+)

```c
// Get a file descriptor from another process
int remote_fd = pidfd_getfd(pidfd, target_fd, 0);
// Now remote_fd refers to the same file as target_fd in the other process
```

### 7.6 clone with CLONE_PIDFD

```c
pid_t pid;
int pidfd;
struct clone_args args = {
    .flags = CLONE_PIDFD,
    .pidfd = (unsigned long)&pidfd,
    .exit_signal = SIGCHLD,
};
pid = syscall(__NR_clone3, &args, sizeof(args));
// pidfd now refers to the child process
```

### 7.7 Use Cases

- **Process monitoring**: Detect exit without `waitpid` races
- **Signal delivery**: No PID reuse race condition
- **Container runtimes**: Track container init processes
- **Supervision**: Monitor child processes reliably
- **fd passing**: Get file descriptors from other processes

### 7.8 Example: Reliable Process Monitoring

```c
#include <sys/syscall.h>
#include <sys/epoll.h>
#include <unistd.h>
#include <stdio.h>

int main(void)
{
    pid_t pid = fork();
    if (pid == 0) {
        sleep(5);
        _exit(42);
    }
    
    int pidfd = pidfd_open(pid, 0);
    int epfd = epoll_create1(EPOLL_CLOEXEC);
    
    struct epoll_event ev = { .events = EPOLLIN, .data.fd = pidfd };
    epoll_ctl(epfd, EPOLL_CTL_ADD, pidfd, &ev);
    
    struct epoll_event events[1];
    epoll_wait(epfd, events, 1, -1);
    
    printf("Child process exited\n");
    
    int status;
    waitpid(pid, &status, 0);
    printf("Exit status: %d\n", WEXITSTATUS(status));
    
    close(pidfd);
    close(epfd);
    return 0;
}
```

---

## 8. userfaultfd

### 8.1 Purpose

`userfaultfd` allows user-space code to handle page faults. This is used for live migration, garbage collectors, and distributed shared memory.

### 8.2 Prototype

```c
#include <linux/userfaultfd.h>
#include <sys/syscall.h>
int userfaultfd(int flags);
```

### 8.3 Flags

| Flag | Description |
|------|-------------|
| `O_CLOEXEC` | Close-on-exec |
| `O_NONBLOCK` | Non-blocking |

### 8.4 Usage Flow

1. Create userfaultfd
2. Register memory regions via `UFFDIO_REGISTER`
3. Create a handler thread that reads page fault events
4. When a fault occurs, the handler reads the event, provides the page, and wakes the faulting thread

### 8.5 Example

```c
#include <linux/userfaultfd.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <sys/syscall.h>
#include <unistd.h>
#include <pthread.h>
#include <stdio.h>

static int uffd;

static void *fault_handler(void *arg)
{
    for (;;) {
        struct uffd_msg msg;
        ssize_t n = read(uffd, &msg, sizeof(msg));
        if (n != sizeof(msg)) continue;
        
        if (msg.event == UFFD_EVENT_PAGEFAULT) {
            void *addr = (void *)(msg.arg.pagefault.address & ~(4096 - 1));
            
            // Provide a page
            void *page = mmap(NULL, 4096, PROT_READ | PROT_WRITE,
                              MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
            
            struct uffdio_copy copy = {
                .dst = (unsigned long)addr,
                .src = (unsigned long)page,
                .len = 4096,
                .mode = 0,
            };
            ioctl(uffd, UFFDIO_COPY, &copy);
            
            printf("Handled page fault at %p\n", addr);
        }
    }
    return NULL;
}

int main(void)
{
    // Create userfaultfd
    uffd = syscall(__NR_userfaultfd, O_CLOEXEC | O_NONBLOCK);
    
    // Enable UFFD
    struct uffdio_api api = { .api = UFFD_API };
    ioctl(uffd, UFFDIO_API, &api);
    
    // Create anonymous mapping
    void *addr = mmap(NULL, 4096 * 10, PROT_READ | PROT_WRITE,
                      MAP_PRIVATE | MAP_ANONYMOUS | MAP_NORESERVE, -1, 0);
    
    // Register with userfaultfd
    struct uffdio_register reg = {
        .range = {
            .start = (unsigned long)addr,
            .len = 4096 * 10,
        },
        .mode = UFFDIO_REGISTER_MODE_MISSING,
    };
    ioctl(uffd, UFFDIO_REGISTER, &reg);
    
    // Start fault handler
    pthread_t tid;
    pthread_create(&tid, NULL, fault_handler, NULL);
    
    // Access memory — triggers userfaultfd
    char *p = (char *)addr;
    p[0] = 'A';  // Page fault handled by our thread!
    printf("Value: %c\n", p[0]);
    
    return 0;
}
```

### 8.6 Use Cases

- **Live migration**: Transfer VM memory pages on demand
- **Garbage collection**: Handle reads on unmapped pages
- **Distributed shared memory**: Fetch remote pages on fault
- **Memory snapshots**: Copy-on-write at page granularity
- **Postcopy migration**: Start VM before all memory is transferred

### 8.7 Security

- Requires `CAP_SYS_PTRACE` or being in the same user namespace
- Can be used for process memory manipulation
- Used by QEMU/KVM for live migration

---

## 9. Other Modern FD Syscalls

### 9.1 pidfd_open for Process Exit Detection

```c
int pidfd = pidfd_open(pid, 0);
// Use with epoll to detect exit
// poll() returns POLLIN when process exits
```

### 9.2 close_range (Linux 5.9)

```c
int close_range(unsigned int first, unsigned int last, int flags);
```

Efficiently close a range of file descriptors. Flags: `CLOSE_RANGE_UNSHARE` (unshare fd table first).

### 9.3 fsconfig / fsmount (New Mount API)

(See Chapter 137 for the new mount API.)

---

## 10. Integrating Modern FDs in Event Loops

The power of these FDs comes from combining them with `epoll`:

```c
int epfd = epoll_create1(EPOLL_CLOEXEC);

// Network socket
int sock_fd = socket(AF_INET, SOCK_STREAM | SOCK_NONBLOCK, 0);
struct epoll_event ev = { .events = EPOLLIN | EPOLLET, .data.fd = sock_fd };
epoll_ctl(epfd, EPOLL_CTL_ADD, sock_fd, &ev);

// Timer
int timer_fd = timerfd_create(CLOCK_MONOTONIC, TFD_NONBLOCK | TFD_CLOEXEC);
struct itimerspec its = { .it_value = { 5, 0 } };
timerfd_settime(timer_fd, 0, &its, NULL);
ev.data.fd = timer_fd;
epoll_ctl(epfd, EPOLL_CTL_ADD, timer_fd, &ev);

// Signal
sigset_t mask;
sigemptyset(&mask);
sigaddset(&mask, SIGINT);
sigprocmask(SIG_BLOCK, &mask, NULL);
int signal_fd = signalfd(-1, &mask, SFD_NONBLOCK | SFD_CLOEXEC);
ev.data.fd = signal_fd;
epoll_ctl(epfd, EPOLL_CTL_ADD, signal_fd, &ev);

// Event notification
int event_fd = eventfd(0, EFD_NONBLOCK | EFD_CLOEXEC);
ev.data.fd = event_fd;
epoll_ctl(epfd, EPOLL_CTL_ADD, event_fd, &ev);

// Process monitoring
int pid_fd = pidfd_open(child_pid, 0);
ev.data.fd = pid_fd;
epoll_ctl(epfd, EPOLL_CTL_ADD, pid_fd, &ev);

// Single event loop handles everything
struct epoll_event events[64];
while (1) {
    int n = epoll_wait(epfd, events, 64, -1);
    for (int i = 0; i < n; i++) {
        if (events[i].data.fd == sock_fd) { /* network I/O */ }
        else if (events[i].data.fd == timer_fd) { /* timer expired */ }
        else if (events[i].data.fd == signal_fd) { /* signal received */ }
        else if (events[i].data.fd == event_fd) { /* thread notification */ }
        else if (events[i].data.fd == pid_fd) { /* process exited */ }
    }
}
```

---

## 11. Performance Summary

| FD Type | Creation Cost | Per-Event Cost | Scalability |
|---------|--------------|----------------|-------------|
| `epoll` | ~1 μs | ~100 ns | O(1) |
| `eventfd` | ~200 ns | ~50 ns | O(1) |
| `timerfd` | ~500 ns | ~100 ns | O(1) |
| `signalfd` | ~300 ns | ~200 ns | O(1) |
| `memfd_create` | ~1 μs | N/A | N/A |
| `pidfd_open` | ~1 μs | ~100 ns | O(1) |
| `userfaultfd` | ~1 μs | ~1-10 μs | O(1) |

---

## 12. Security Implications

- **`epoll`**: No special privileges required
- **`eventfd`**: No special privileges required
- **`memfd_create`**: No special privileges, but sealing requires `MFD_ALLOW_SEALING`
- **`pidfd_open`**: Requires same user or `CAP_SYS_PTRACE` (or ptrace access)
- **`pidfd_getfd`**: Requires `CAP_SYS_PTRACE`
- **`userfaultfd`**: Requires `CAP_SYS_PTRACE` or same user namespace
- **`close_range`**: No special privileges

---

## 13. Common Bugs

```c
// BUG: Using epoll_wait with closed fd
epoll_ctl(epfd, EPOLL_CTL_ADD, fd, &ev);
close(fd);  // Auto-removed from epoll, but events might be stale

// BUG: Not using non-blocking fds with EPOLLET
ev.events = EPOLLIN | EPOLLET;
epoll_ctl(epfd, EPOLL_CTL_ADD, fd, &ev);
// Must read until EAGAIN with edge-triggered!

// BUG: pidfd_open on zombie process
int pidfd = pidfd_open(zombie_pid, 0);  // Might fail
// Use waitpid first, or check /proc/pid/status

// BUG: userfaultfd without proper registration
mmap(addr, len, ...);
// Access addr without registering → SIGBUS!
// FIX: Register with UFFDIO_REGISTER first
```

---

## 14. Kernel Source References

- **epoll**: `fs/eventpoll.c`
- **eventfd**: `fs/eventfd.c`
- **timerfd**: `fs/timerfd.c`
- **signalfd**: `fs/signalfd.c`
- **memfd_create**: `mm/shmem.c`
- **pidfd**: `kernel/pid.c`
- **userfaultfd**: `fs/userfaultfd.c`
- **close_range**: `fs/file.c`
- **pidfd_getfd**: `kernel/pid.c`

---

## 15. Summary

Modern FD syscalls extend Linux's "everything is a file" philosophy:
- **`epoll`**: Scalable I/O multiplexing for thousands of connections
- **`eventfd`**: Simple event notification between threads/processes
- **`timerfd`**: Timer events as file descriptors
- **`signalfd`**: Signal delivery via file descriptors
- **`memfd_create`**: Anonymous memory-backed files with sealing
- **`pidfd_open`/`pidfd_send_signal`**: Process references via file descriptors
- **`userfaultfd`**: User-space page fault handling

These FDs can all be combined in a single `epoll` event loop, creating a unified, scalable, and elegant I/O model for modern applications. This is the foundation of high-performance servers like Nginx, Envoy, and Tokio-based Rust applications.

---

## 16. Summary of Modern FD Capabilities

The modern FD-based interfaces provide a unified programming model:

| FD Type | Direction | Key Feature |
|---------|-----------|-------------|
| `epoll` | In (events) | Scalable I/O multiplexing |
| `eventfd` | In/Out | Simple counter-based signaling |
| `timerfd` | In (events) | Timer expiration as FD events |
| `signalfd` | In (events) | Signal delivery as FD events |
| `memfd_create` | In/Out | Anonymous memory-backed file |
| `pidfd_open` | In (events) | Process exit detection |
| `userfaultfd` | In (events) | User-space page fault handling |

All of these can be combined in a single `epoll` event loop, creating a clean, scalable, and maintainable I/O architecture.
