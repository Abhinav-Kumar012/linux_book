# Chapter 130: Signal Syscalls

## 1. Introduction

Signals are the oldest IPC mechanism in Unix — asynchronous notifications sent to processes to indicate events like illegal memory access, user interrupt (Ctrl+C), or child process termination. This chapter covers the signal-related syscalls: `kill`, `tkill`, `tgkill`, `sigaction`, `sigprocmask`, `signalfd4`, and the `rt_sig*` variants.

---

## 2. kill

### 2.1 Purpose

`kill` sends a signal to a process or process group.

### 2.2 Prototype

```c
#include <signal.h>
int kill(pid_t pid, int sig);
```

### 2.3 Arguments

**`pid`**:
| Value | Target |
|-------|--------|
| `> 0` | Process with PID = pid |
| `0` | All processes in the same process group |
| `-1` | All processes the sender has permission to signal (except init) |
| `< -1` | All processes in process group abs(pid) |

**`sig`**: Signal number (e.g., `SIGTERM`, `SIGKILL`, `SIGUSR1`), or 0 for error checking (no signal sent).

### 2.4 Return Values

- **Success**: 0
- **Failure**: -1 with `errno` set

### 2.5 Error Codes

| Error | Description |
|-------|-------------|
| `EINVAL` | Invalid signal number |
| `EPERM` | No permission to signal the target |
| `ESRCH` | No such process |

### 2.6 Kernel Implementation

```c
SYSCALL_DEFINE2(kill, pid_t, pid, int, sig)
{
    struct kernel_siginfo info;
    prepare_kill_siginfo(sig, &info, PIDTYPE_TGID);
    return kill_something_info(sig, &info, pid);
}
```

**Permission checks:**
- The sender must have `CAP_KILL`, or
- Real or effective UID of sender must match real or saved-set UID of target, or
- The signal is `SIGCONT` and the processes share a session

### 2.7 Example

```c
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>

int main(int argc, char *argv[])
{
    if (argc != 3) {
        fprintf(stderr, "Usage: %s <pid> <signal>\n", argv[0]);
        return 1;
    }
    
    pid_t pid = atoi(argv[1]);
    int sig = atoi(argv[2]);
    
    if (kill(pid, sig) < 0) {
        perror("kill");
        return 1;
    }
    
    printf("Sent signal %d to process %d\n", sig, pid);
    return 0;
}
```

### 2.8 Signal 0 (Error Check)

```c
if (kill(pid, 0) == 0) {
    printf("Process %d exists\n", pid);
} else if (errno == EPERM) {
    printf("Process %d exists but we can't signal it\n", pid);
} else if (errno == ESRCH) {
    printf("Process %d does not exist\n", pid);
}
```

---

## 3. tkill / tgkill

### 3.1 Purpose

`tkill` sends a signal to a specific thread. `tgkill` sends a signal to a specific thread in a specific thread group (more precise).

### 3.2 Prototype

```c
#include <signal.h>
int tkill(int tid, int sig);
int tgkill(int tgid, int tid, int sig);
```

### 3.3 Difference from kill

| Syscall | Target |
|---------|--------|
| `kill(pid, sig)` | Sends to the **process** (thread group), delivered to any thread |
| `tkill(tid, sig)` | Sends to a specific **thread** |
| `tgkill(tgid, tid, sig)` | Sends to a specific thread in a specific process (safer) |

### 3.4 Kernel Implementation

```c
SYSCALL_DEFINE2(tkill, int, pid, int, sig)
{
    return do_tkill(0, pid, sig);
}

SYSCALL_DEFINE3(tgkill, pid_t, tgid, pid_t, pid, int, sig)
{
    if (tgid < 0 || pid < 0)
        return -EINVAL;
    return do_tkill(tgid, pid, sig);
}
```

### 3.5 Use Case

`tgkill` is used by glibc's thread implementation to deliver signals to specific threads (e.g., for thread cancellation or `pthread_kill`).

---

## 4. sigaction / rt_sigaction

### 4.1 Purpose

`sigaction` examines and changes the action taken by a process on receipt of a specific signal.

### 4.2 Prototype

```c
#include <signal.h>
int sigaction(int signum, const struct sigaction *act, struct sigaction *oldact);
```

### 4.3 The `sigaction` Structure

```c
struct sigaction {
    void     (*sa_handler)(int);       // Signal handler (or SIG_IGN, SIG_DFL)
    void     (*sa_sigaction)(int, siginfo_t *, void *);  // Extended handler
    sigset_t   sa_mask;                // Signals to block during handler
    int        sa_flags;               // Flags
    void     (*sa_restorer)(void);     // Kernel use only
};
```

### 4.4 Flags

| Flag | Description |
|------|-------------|
| `SA_NOCLDSTOP` | Don't notify parent on child stop |
| `SA_NOCLDWAIT` | Don't create zombies |
| `SA_SIGINFO` | Use `sa_sigaction` instead of `sa_handler` |
| `SA_ONSTACK` | Use alternate signal stack |
| `SA_RESTART` | Restart interrupted syscalls |
| `SA_NODEFER` | Don't block signal during handler |
| `SA_RESETHAND` | Reset handler to `SIG_DFL` after delivery |

### 4.5 Example

```c
#include <signal.h>
#include <stdio.h>
#include <unistd.h>

static volatile sig_atomic_t got_signal = 0;

void handler(int sig)
{
    got_signal = sig;
}

int main(void)
{
    struct sigaction sa = {
        .sa_handler = handler,
        .sa_flags = SA_RESTART,
    };
    sigemptyset(&sa.sa_mask);
    
    sigaction(SIGINT, &sa, NULL);
    sigaction(SIGTERM, &sa, NULL);
    
    while (!got_signal) {
        pause();  // Wait for signal
    }
    
    printf("Received signal %d\n", got_signal);
    return 0;
}
```

### 4.6 Kernel Implementation

```c
SYSCALL_DEFINE4(rt_sigaction, int, sig, const struct sigaction __user *, act,
                struct sigaction __user *, oact, size_t, sigsetsize)
{
    if (sigsetsize != sizeof(sigset_t))
        return -EINVAL;
    
    // Get old action
    if (oact) {
        copy_to_user(oact, &k_sig, sizeof(k_sig));
    }
    
    // Set new action
    if (act) {
        copy_from_user(&new_ka, act, sizeof(new_ka));
        // Special signals can't be caught
        if (sig == SIGKILL || sig == SIGSTOP) return -EINVAL;
        // Install new handler
        spin_lock_irq(&sighand->siglock);
        *k = new_ka;
        spin_unlock_irq(&sighand->siglock);
    }
    return 0;
}
```

---

## 5. sigprocmask / rt_sigprocmask

### 5.1 Purpose

`sigprocmask` examines and changes the signal mask — the set of signals that are blocked (not delivered) for the calling thread.

### 5.2 Prototype

```c
#include <signal.h>
int sigprocmask(int how, const sigset_t *set, sigset_t *oldset);
```

### 5.3 How Values

| How | Description |
|-----|-------------|
| `SIG_BLOCK` | Add signals to mask (block them) |
| `SIG_UNBLOCK` | Remove signals from mask (unblock them) |
| `SIG_SETMASK` | Set mask to exact set |

### 5.4 Example

```c
#include <signal.h>
#include <stdio.h>

int main(void)
{
    sigset_t mask, oldmask;
    
    // Block SIGINT and SIGTERM
    sigemptyset(&mask);
    sigaddset(&mask, SIGINT);
    sigaddset(&mask, SIGTERM);
    sigprocmask(SIG_BLOCK, &mask, &oldmask);
    
    printf("SIGINT and SIGTERM are now blocked\n");
    printf("Press Enter to unblock...\n");
    getchar();
    
    // Restore old mask
    sigprocmask(SIG_SETMASK, &oldmask, NULL);
    printf("Signals unblocked\n");
    
    return 0;
}
```

### 5.5 Multithreading Note

In multithreaded programs, use `pthread_sigmask` instead of `sigprocmask`. `sigprocmask` behavior is unspecified in multithreaded programs.

---

## 6. signalfd4 / signalfd

### 6.1 Purpose

`signalfd` creates a file descriptor for receiving signals. Instead of installing signal handlers, you can read signals from an fd — integrating signals into an event loop.

### 6.2 Prototype

```c
#include <sys/signalfd.h>
int signalfd(int fd, const sigset_t *mask, int flags);
```

### 6.3 Arguments

- **`fd`**: -1 for new fd, or existing fd to update
- **`mask`**: Signals to watch for
- **`flags`**: `SFD_NONBLOCK`, `SFD_CLOEXEC`

### 6.4 Example

```c
#include <sys/signalfd.h>
#include <signal.h>
#include <unistd.h>
#include <stdio.h>

int main(void)
{
    sigset_t mask;
    sigemptyset(&mask);
    sigaddset(&mask, SIGINT);
    sigaddset(&mask, SIGTERM);
    
    // Block signals (so they don't default-kill us)
    sigprocmask(SIG_BLOCK, &mask, NULL);
    
    // Create signalfd
    int sfd = signalfd(-1, &mask, SFD_CLOEXEC);
    
    // Read signals from fd
    struct signalfd_siginfo si;
    ssize_t n = read(sfd, &si, sizeof(si));
    if (n == sizeof(si)) {
        printf("Received signal %d from PID %d\n", si.ssi_signo, si.ssi_pid);
    }
    
    close(sfd);
    return 0;
}
```

### 6.5 Advantages Over Signal Handlers

- Signals become file descriptors (can use with `poll`/`epoll`)
- No async-signal-safety concerns
- Signal info available in a structured format
- Deterministic control over signal delivery order

---

## 7. Real-time Signals

Linux supports real-time signals (`SIGRTMIN` to `SIGRTMAX`, typically 34-64). They differ from standard signals:

- **Queued**: Multiple instances of the same signal are queued (not lost)
- **Ordered**: Lower-numbered signals are delivered first
- **Data**: Can carry an integer or pointer value via `sigqueue`

### 7.1 sigqueue

```c
#include <signal.h>
int sigqueue(pid_t pid, int sig, const union sigval value);
```

```c
union sigval {
    int    sival_int;
    void  *sival_ptr;
};

// Send a real-time signal with data
sigqueue(pid, SIGRTMIN, (union sigval){.sival_int = 42});
```

---

## 8. Signal Delivery in the Kernel

When a signal is delivered, the kernel:

1. Checks pending signals against the signal mask
2. If a handler is installed, sets up a signal frame on the user stack
3. The frame contains saved registers and the signal info
4. Execution jumps to the handler (via `sa_handler` or `sa_sigaction`)
5. When the handler returns, `sigreturn` restores the original context

The `rt_sigreturn` syscall is called automatically by the signal trampoline code.

---

## 9. Security Implications

- **`SIGKILL`/`SIGSTOP` cannot be caught**: This ensures processes can always be terminated.
- **Signal injection**: Unprivileged users can only signal their own processes (or processes with matching UIDs).
- **Race conditions with signal handlers**: Handlers run asynchronously. Use `volatile sig_atomic_t` for shared variables.
- **`signalfd` and `SIG_IGN`**: Signals that are `SIG_IGN`'d won't appear on signalfd. Must be blocked instead.

---

## 10. Common Bugs

```c
// BUG: Using non-async-signal-safe functions in handler
void handler(int sig) {
    printf("Got signal %d\n", sig);  // NOT safe!
    malloc(100);                       // NOT safe!
}
// FIX: Use write() or set a flag
volatile sig_atomic_t flag = 0;
void handler(int sig) { flag = sig; }

// BUG: Not blocking signals before signalfd
int sfd = signalfd(-1, &mask, 0);
// Signal arrives and default handler kills us!
// FIX: Block signals first
sigprocmask(SIG_BLOCK, &mask, NULL);
int sfd = signalfd(-1, &mask, 0);
```

---

## 11. Kernel Source References

- **`kill`/`tkill`/`tgkill`**: `kernel/signal.c`
- **`sigaction`/`rt_sigaction`**: `kernel/signal.c`
- **`sigprocmask`/`rt_sigprocmask`**: `kernel/signal.c`
- **`signalfd`**: `fs/signalfd.c`
- **Signal delivery**: `arch/x86/kernel/signal.c`
- **`sigqueue`**: `kernel/signal.c`
- **Signal structures**: `include/linux/signal_types.h`

---

## 12. Summary

Signal syscalls provide asynchronous process notification:
- **`kill`**: Send signal to process/group
- **`tgkill`**: Send signal to specific thread
- **`sigaction`**: Install/examine signal handlers
- **`sigprocmask`**: Block/unblock signals
- **`signalfd`**: Convert signals to file descriptor events
- **`sigqueue`**: Send real-time signals with data

For modern applications, `signalfd` integrated with `epoll` is the preferred approach over traditional signal handlers.

---

## 13. Detailed Signal Internals

### 13.1 Signal Data Structures

Each thread has a signal-related set of structures:

```c
struct signal_struct {
    atomic_t sigcnt;              // Signal count
    struct list_head thread_head; // Threads in this group
    wait_queue_head_t shared_pending_wait; // Wait for shared signals
    struct sigpending shared_pending;      // Shared (process-level) pending signals
    // ...
};

struct sighand_struct {
    spinlock_t siglock;
    refcount_t count;
    struct k_sigaction action[_NSIG];  // Signal handlers
};

struct sigpending {
    struct list_head list;   // Queue of siginfo structures
    sigset_t signal;         // Bitmask of pending signals
};
```

### 13.2 Signal Queuing

Standard signals (1-31) are not queued — if multiple instances of the same signal are pending, only one is delivered. Real-time signals (34-64) are fully queued.

```c
struct sigqueue {
    struct list_head list;
    int flags;
    kernel_siginfo_t info;
    struct ucounts *ucounts;
};
```

The kernel limits the number of queued signals per process:
```
/proc/sys/kernel/threads-max  (total system limit)
RLIMIT_SIGPENDING             (per-process limit)
```

### 13.3 Signal Delivery Path

When the kernel delivers a signal, the path is:

```
1. do_signal() or get_signal() — called on return to user space
2. Check pending signals against the signal mask
3. For each pending signal:
   a. If handler is SIG_DFL → take default action
   b. If handler is SIG_IGN → discard
   c. If handler is a function → set up signal frame
4. setup_frame() or setup_rt_frame() — build user-space stack frame
5. Return to user space, jumping to signal handler
6. Handler executes
7. sigreturn() — restore original context
```

### 13.4 Signal Stack Frame

The kernel builds a signal frame on the user stack:

```c
struct sigframe {
    char __user *pretcode;     // Return address (points to sigreturn)
    int sig;                   // Signal number
    struct sigcontext sc;      // Saved register context
    struct _fpstate fpstate;   // Floating-point state
    unsigned long extramask[_NSIG_WORDS-1];
    char retcode[8];           // sigreturn instruction
};

struct rt_sigframe {
    char __user *pretcode;
    int sig;
    struct siginfo __user *pinfo;
    void __user *puc;
    struct siginfo info;
    struct ucontext uc;
    char retcode[8];
};
```

### 13.5 Signal Inheritance Across fork and exec

**Across fork:**
- Signal handlers are inherited (same function pointers)
- Pending signals are NOT inherited (cleared in child)
- Signal mask is inherited

**Across exec:**
- Signals with `SIG_DFL` remain `SIG_DFL`
- Signals with handlers are reset to `SIG_DFL` (prevents running code from old binary)
- Signal mask is preserved
- Pending signals are preserved

**Special cases:**
- `SIG_IGN` is preserved across exec
- `SIG_DFL` for `SIGCHLD` may be reset depending on `SA_NOCLDSTOP`

### 13.6 Interrupted System Call Restart

When a signal interrupts a blocking syscall, the kernel must decide whether to restart:

```c
// In the syscall exit path:
if (syscall_exit_work(regs)) {
    // Check if we need to restart the syscall
    switch (regs->ax) {
    case -ERESTARTSYS:
        // Restart if SA_RESTART flag is set
        if (sa_flags & SA_RESTART)
            regs->ax = regs->orig_ax;  // Restart
        else
            regs->ax = -EINTR;  // Return EINTR
        break;
    case -ERESTARTNOINTR:
        // Always restart
        regs->ax = regs->orig_ax;
        break;
    case -ERESTARTNOHAND:
        // Restart only if no handler
        regs->ax = -EINTR;
        break;
    case -ERESTART_RESTARTBLOCK:
        // Use restart block (for nanosleep, etc.)
        regs->ax = -EINTR;
        break;
    }
}
```

### 13.7 Signal Groups and Thread Selection

When `kill(pid, sig)` is sent to a process (thread group), the kernel must choose which thread receives it:

```c
// Selection logic:
1. If signal is fatal (SIGKILL, SIGSEGV, etc.) → send to all threads
2. Find a thread that doesn't have the signal blocked
3. Prefer threads that don't have any signals pending
4. If no thread can receive → signal remains pending
```

For `tkill(tid, sig)` and `tgkill(tgid, tid, sig)`, the signal goes directly to the specified thread.

### 13.8 Signal-related prctl Operations

```c
// Set signal mask for the calling thread
prctl(PR_SET_SIGMASK, &mask, sizeof(mask));

// Get/set signal stack
prctl(PR_SET_SS, ...);  // Deprecated, use sigaltstack()

// Set PID to receive signals (for init-like processes in PID namespaces)
prctl(PR_SET_CHILD_SUBREAPER, 1);
```

### 13.9 Async-Signal-Safe Functions

POSIX specifies a list of functions that are safe to call from signal handlers. These include:

- `_exit()`, `abort()`
- `read()`, `write()` (but not `stdio`)
- `sigaction()`, `sigprocmask()`
- `kill()`, `getpid()`
- `mmap()`, `munmap()`
- `futex()` (private, non-error paths)

**NOT safe:** `malloc()`, `free()`, `printf()`, `pthread_mutex_lock()`, any function that acquires locks.

### 13.10 Core Dumps

When a signal with default action "core" is delivered (SIGQUIT, SIGABRT, SIGSEGV, etc.), the kernel generates a core dump:

```c
// In do_coredump():
1. Create core file (core.PID or via core_pattern)
2. Write ELF core format:
   - ELF header
   - Program headers (one per memory mapping)
   - Thread info (register state)
   - Memory contents
3. Apply RLIMIT_CORE resource limit
4. Apply coredump_filter (which memory regions to dump)
```

**coredump_filter** controls what's included:
```bash
cat /proc/self/coredump_filter
# Bit 0: Anonymous private mappings
# Bit 1: Anonymous shared mappings
# Bit 2: File-backed private mappings
# Bit 3: File-backed shared mappings
# Bit 4: ELF header
# Bit 5: Private huge pages
# Bit 7: Private DAX pages
```

### 13.11 Signal-related /proc Files

```bash
/proc/[pid]/status    # Shows signal mask, pending signals
/proc/[pid]/sigmask   # Hex representation of signal mask
/proc/[pid]/sigpending # Hex representation of pending signals
/proc/[pid]/comm      # Process name (settable via prctl)
/proc/[pid]/wchan     # Wait channel (what the process is waiting for)
```

### 13.12 Signal Stacks

Each thread can have an alternate signal stack for handling signals:

```c
#include <signal.h>

// Allocate alternate signal stack
stack_t ss;
ss.ss_sp = malloc(SIGSTKSZ);
ss.ss_size = SIGSTKSZ;
ss.ss_flags = 0;
sigaltstack(&ss, NULL);

// Install handler with SA_ONSTACK
struct sigaction sa = {
    .sa_handler = handler,
    .sa_flags = SA_ONSTACK,
};
sigaction(SIGSEGV, &sa, NULL);
```

**Why alternate signal stacks matter:**
- Stack overflow detection: If the main stack overflows, the signal handler runs on the alternate stack
- Real-time signals: Prevent signal handling from consuming the main stack
- Thread safety: Each thread needs its own signal stack

### 13.13 Signal Mask Manipulation Helpers

```c
sigset_t set;

// Initialize
sigemptyset(&set);       // Empty set
sigfillset(&set);        // Full set (all signals)

// Individual signals
sigaddset(&set, SIGINT); // Add SIGINT
sigdelset(&set, SIGINT); // Remove SIGINT

// Check membership
if (sigismember(&set, SIGINT)) { /* SIGINT is in set */ }

// Bulk operations
sigset_t newset, oldset;
sigemptyset(&newset);
sigaddset(&newset, SIGINT);
sigaddset(&newset, SIGTERM);
sigprocmask(SIG_BLOCK, &newset, &oldset);  // Block SIGINT and SIGTERM
// ... critical section ...
sigprocmask(SIG_SETMASK, &oldset, NULL);   // Restore old mask
```

### 13.14 Real-time Signal Example with sigwaitinfo

```c
#include <signal.h>
#include <stdio.h>

int main(void)
{
    sigset_t mask;
    sigemptyset(&mask);
    sigaddset(&mask, SIGRTMIN);
    sigprocmask(SIG_BLOCK, &mask, NULL);
    
    while (1) {
        siginfo_t info;
        int sig = sigwaitinfo(&mask, &info);
        if (sig < 0) continue;
        
        printf("Signal %d from PID %d, value %d\n",
               sig, info.si_pid, info.si_value.sival_int);
    }
    return 0;
}
```

### 13.15 Signal Coalescing

Standard signals (1-31) are coalesced — if multiple instances are pending, only one is delivered:

```c
// If SIGINT is sent 10 times while blocked:
// When unblocked, only ONE SIGINT is delivered
// The other 9 are lost

// Real-time signals (34-64) are queued:
// If SIGRTMIN is sent 10 times while blocked:
// When unblocked, ALL 10 are delivered in order
```

This is why `signalfd` reports the count of queued signals in `ssi_overrun`.

### 13.16 Signal-related System Calls Summary

| Syscall | Purpose |
|---------|---------|
| `kill` | Send signal to process/group |
| `tkill` | Send signal to specific thread |
| `tgkill` | Send signal to thread in specific group |
| `sigaction` | Install/examine signal handler |
| `sigprocmask` | Block/unblock signals |
| `sigpending` | Check pending signals |
| `sigsuspend` | Atomically set mask and suspend |
| `sigwaitinfo` | Wait for signal (extended info) |
| `sigtimedwait` | Wait for signal with timeout |
| `sigqueue` | Send signal with data |
| `signalfd` | Create fd for signal delivery |
| `rt_sigaction` | Real-time signal action |
| `rt_sigprocmask` | Real-time signal mask |
| `rt_sigpending` | Real-time pending signals |
| `rt_sigsuspend` | Real-time suspend |
| `rt_sigqueueinfo` | Real-time signal queue |
| `rt_sigtimedwait` | Real-time timed wait |
| `sigaltstack` | Set alternate signal stack |
| `restart_syscall` | Restart interrupted syscall |

### 13.17 Signal Safety and Best Practices

```c
// 1. Always use volatile sig_atomic_t for shared variables
volatile sig_atomic_t flag = 0;

// 2. Keep signal handlers short
void handler(int sig) {
    flag = 1;  // Just set a flag
    // Don't call non-async-signal-safe functions
}

// 3. Use sigaction instead of signal()
// signal() has undefined behavior regarding signal reset
// sigaction() provides SA_RESTART and other fine-grained control

// 4. Block signals before fork, unblock in child
sigset_t mask, oldmask;
sigfillset(&mask);
sigprocmask(SIG_BLOCK, &mask, &oldmask);
pid_t pid = fork();
if (pid == 0) {
    sigprocmask(SIG_SETMASK, &oldmask, NULL);  // Child: unblock
    // ...
}

// 5. Use signalfd for event-loop-based applications
// Avoids async-signal-safety issues entirely
```
