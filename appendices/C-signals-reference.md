# Appendix C: Signals Reference

## Overview

Signals are software interrupts delivered to a process to notify it of events. This appendix lists all standard signals, their default actions, and common usage patterns.

---

## 1. Standard Signals

| Signal | Number | Default Action | Description |
|--------|--------|----------------|-------------|
| `SIGHUP` | 1 | Terminate | Hangup detected on controlling terminal or death of controlling process |
| `SIGINT` | 2 | Terminate | Interrupt from keyboard (Ctrl+C) |
| `SIGQUIT` | 3 | Core dump | Quit from keyboard (Ctrl+\) |
| `SIGILL` | 4 | Core dump | Illegal instruction |
| `SIGTRAP` | 5 | Core dump | Trace/breakpoint trap |
| `SIGABRT` | 6 | Core dump | Abort signal from `abort()` |
| `SIGBUS` | 7 | Core dump | Bus error (bad memory access) |
| `SIGFPE` | 8 | Core dump | Floating-point exception |
| `SIGKILL` | 9 | Terminate | Kill signal (cannot be caught or ignored) |
| `SIGUSR1` | 10 | Terminate | User-defined signal 1 |
| `SIGSEGV` | 11 | Core dump | Invalid memory reference (segmentation fault) |
| `SIGUSR2` | 12 | Terminate | User-defined signal 2 |
| `SIGPIPE` | 13 | Terminate | Broken pipe: write to pipe with no readers |
| `SIGALRM` | 14 | Terminate | Timer signal from `alarm()` |
| `SIGTERM` | 15 | Terminate | Termination signal (graceful) |
| `SIGSTKFLT` | 16 | Terminate | Stack fault on coprocessor (unused on x86_64) |
| `SIGCHLD` | 17 | Ignore | Child stopped or terminated |
| `SIGCONT` | 18 | Continue | Continue if stopped |
| `SIGSTOP` | 19 | Stop | Stop process (cannot be caught or ignored) |
| `SIGTSTP` | 20 | Stop | Stop typed at terminal (Ctrl+Z) |
| `SIGTTIN` | 21 | Stop | Terminal input for background process |
| `SIGTTOU` | 22 | Stop | Terminal output for background process |
| `SIGURG` | 23 | Ignore | Urgent condition on socket |
| `SIGXCPU` | 24 | Core dump | CPU time limit exceeded |
| `SIGXFSZ` | 25 | Core dump | File size limit exceeded |
| `SIGVTALRM` | 26 | Terminate | Virtual timer expired |
| `SIGPROF` | 27 | Terminate | Profiling timer expired |
| `SIGWINCH` | 28 | Ignore | Window resize signal |
| `SIGIO` | 29 | Terminate | I/O now possible (also `SIGPOLL`) |
| `SIGPWR` | 30 | Terminate | Power failure (System V) |
| `SIGSYS` | 31 | Core dump | Bad system call (invalid syscall number) |

---

## 2. Real-Time Signals

Linux supports real-time signals ranging from `SIGRTMIN` (typically 34) to `SIGRTMAX` (typically 64).

| Range | Description |
|-------|-------------|
| `SIGRTMIN` to `SIGRTMAX` | Real-time signals (32 signals on most systems) |

**Key properties of real-time signals:**

- **Queued**: Multiple instances of the same signal can be queued and delivered in order
- **Data**: Can carry an accompanying integer or pointer value via `sigqueue()`
- **Ordering**: Lower-numbered real-time signals are delivered first
- **Default action**: Terminate

### Checking Signal Ranges

```bash
# Check SIGRTMIN and SIGRTMAX values
kill -l RTMIN
kill -l RTMAX

# List all signal names and numbers
kill -l
```

---

## 3. Signal Actions

### Default Actions

| Action | Signals |
|--------|---------|
| **Terminate** | `SIGHUP`, `SIGINT`, `SIGKILL`, `SIGPIPE`, `SIGALRM`, `SIGTERM`, `SIGUSR1`, `SIGUSR2`, `SIGPROF`, `SIGVTALRM`, `SIGSTKFLT`, `SIGIO`, `SIGPWR` |
| **Core dump** | `SIGQUIT`, `SIGILL`, `SIGTRAP`, `SIGABRT`, `SIGBUS`, `SIGFPE`, `SIGSEGV`, `SIGXCPU`, `SIGXFSZ`, `SIGSYS` |
| **Stop** | `SIGSTOP`, `SIGTSTP`, `SIGTTIN`, `SIGTTOU` |
| **Continue** | `SIGCONT` |
| **Ignore** | `SIGCHLD`, `SIGURG`, `SIGWINCH` |

### Special Signals

| Signal | Catchable | Blockable | Notes |
|--------|-----------|-----------|-------|
| `SIGKILL` | No | No | Always terminates the process |
| `SIGSTOP` | No | No | Always stops the process |

---

## 4. Core Dump Generation

Core dumps are generated when a signal with the "Core dump" default action is received and:
- The process's resource limits allow it (`ulimit -c`)
- The `core_pattern` is configured
- The process has write permission to the core dump location

### Core Dump Configuration

```bash
# Check current core file size limit
ulimit -c

# Unlimited core file size
ulimit -c unlimited

# Set core pattern
echo "/var/crash/core.%e.%p.%t" | sudo tee /proc/sys/kernel/core_pattern

# Core pattern format specifiers
# %p - PID
# %u - UID
# %g - GID
# %s - Signal number
# %t - Timestamp
# %h - Hostname
# %e - Executable filename
# %E - Executable path (/ replaced with !)

# Disable core dumps for SUID programs
echo 2 | sudo tee /proc/sys/kernel/suid_dumpable
```

### Core Dump Pattern Variables

| Variable | Description |
|----------|-------------|
| `%c` | Core file size soft resource limit |
| `%d` | Dump mode (same as `suid_dumpable`) |
| `%e` | Executable filename (without path) |
| `%E` | Executable path (`/` replaced with `!`) |
| `%g` | GID of dumped process |
| `%h` | Hostname |
| `%I` | Thread ID of crashing thread |
| `%p` | PID of dumped process |
| `%P` | PID of parent process |
| `%s` | Signal number causing dump |
| `%t` | Timestamp of dump |
| `%u` | UID of dumped process |

---

## 5. Signal Handling in C

### Using `signal()` (Simple)

```c
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>

void handler(int sig) {
    printf("Caught signal %d\n", sig);
}

int main(void) {
    signal(SIGINT, handler);
    signal(SIGTERM, handler);

    while (1) {
        pause();  // Wait for signals
    }
    return 0;
}
```

### Using `sigaction()` (Recommended)

```c
#include <signal.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

volatile sig_atomic_t got_signal = 0;

void handler(int sig, siginfo_t *info, void *context) {
    (void)context;
    printf("Caught signal %d from PID %d\n", sig, info->si_pid);
    got_signal = 1;
}

int main(void) {
    struct sigaction sa;
    memset(&sa, 0, sizeof(sa));
    sa.sa_sigaction = handler;
    sa.sa_flags = SA_SIGINFO;
    sigemptyset(&sa.sa_mask);

    sigaction(SIGINT, &sa, NULL);
    sigaction(SIGTERM, &sa, NULL);

    while (!got_signal) {
        pause();
    }
    printf("Exiting gracefully\n");
    return 0;
}
```

### Signal-Safe Functions

Only async-signal-safe functions may be called from signal handlers. Common safe functions:

| Function | Function | Function |
|----------|----------|----------|
| `write()` | `read()` | `open()` |
| `close()` | `fork()` | `execve()` |
| `_exit()` | `kill()` | `getpid()` |
| `sigaction()` | `sigprocmask()` | `waitpid()` |
| `dup()` | `dup2()` | `fcntl()` |
| `setsockopt()` | `send()` | `recv()` |

**NOT safe** in signal handlers: `printf()`, `malloc()`, `free()`, `fprintf()`, `sprintf()`, `syslog()`, most stdio functions.

---

## 6. Sending Signals

### From the Shell

```bash
# Send SIGTERM (default)
kill 1234
kill -15 1234
kill -TERM 1234

# Send SIGKILL (force kill)
kill -9 1234
kill -KILL 1234

# Send to process group
kill -TERM -1234

# Send to all processes of user
kill -u username

# Kill by name
killall nginx
pkill -f "python server"

# Send specific signal
kill -HUP $(pidof nginx)    # Reload nginx config
kill -USR1 $(pidof dd)      # Send USR1 to dd for progress
```

### From C

```c
#include <signal.h>

// Simple send
kill(pid, SIGTERM);

// With accompanying data (real-time signals)
union sigval value;
value.sival_int = 42;
sigqueue(pid, SIGRTMIN, value);

// Send to thread
tgkill(tgid, tid, SIGTERM);
```

---

## 7. Signal Masks and Blocking

```c
#include <signal.h>

sigset_t mask, oldmask;

// Initialize empty set
sigemptyset(&mask);

// Add signals to set
sigaddset(&mask, SIGINT);
sigaddset(&mask, SIGTERM);

// Block signals (save old mask)
sigprocmask(SIG_BLOCK, &mask, &oldmask);

// ... critical section ...

// Unblock signals (restore old mask)
sigprocmask(SIG_SETMASK, &oldmask, NULL);

// Check for pending signals
sigset_t pending;
sigpending(&pending);
if (sigismember(&pending, SIGINT)) {
    // SIGINT is pending
}

// Atomically unblock and wait for signal
sigsuspend(&oldmask);
```

### sigprocmask Operations

| Operation | Description |
|-----------|-------------|
| `SIG_BLOCK` | Add signals to current mask |
| `SIG_UNBLOCK` | Remove signals from current mask |
| `SIG_SETMASK` | Set mask to given set |

---

## 8. Common Signal Patterns

### Graceful Shutdown

```c
volatile sig_atomic_t running = 1;

void shutdown_handler(int sig) {
    (void)sig;
    running = 0;
}

int main(void) {
    signal(SIGINT, shutdown_handler);
    signal(SIGTERM, shutdown_handler);

    while (running) {
        // Main loop
        do_work();
    }

    // Cleanup
    cleanup();
    return 0;
}
```

### Reload Configuration (SIGHUP)

```c
volatile sig_atomic_t reload_config = 0;

void hup_handler(int sig) {
    (void)sig;
    reload_config = 1;
}

void main_loop(void) {
    while (running) {
        if (reload_config) {
            reload_config = 0;
            load_config();
        }
        process_requests();
    }
}
```

### Progress Reporting (SIGUSR1)

```c
volatile sig_atomic_t show_progress = 0;

void usr1_handler(int sig) {
    (void)sig;
    show_progress = 1;
}

void process_data(void) {
    for (size_t i = 0; i < total; i++) {
        if (show_progress) {
            show_progress = 0;
            report_progress(i, total);
        }
        process_item(data[i]);
    }
}
```

---

## 9. Signal Delivery and Ordering

### Delivery Rules

1. Signals are delivered between instruction boundaries
2. A pending signal is delivered when the process is next scheduled
3. If multiple signals are pending, standard signals have no guaranteed order; real-time signals are delivered lowest-numbered first
4. A signal is "generated" when the event occurs and "delivered" when the action is taken
5. Between generation and delivery, the signal is "pending"

### Signal Queueing

| Signal Type | Queueing Behavior |
|-------------|-------------------|
| Standard signals | Not queued (merged if multiple pending) |
| Real-time signals | Queued (each instance delivered separately) |

---

## 10. Signals and Multithreading

In multithreaded programs:

- Signal handlers are shared across all threads
- Each thread has its own signal mask
- A signal is delivered to any thread that doesn't have it blocked
- `SIGKILL`, `SIGSTOP` affect the entire process
- Use `pthread_sigmask()` instead of `sigprocmask()` in threaded programs

```c
#include <signal.h>
#include <pthread.h>

void *worker(void *arg) {
    (void)arg;

    // Block all signals in worker thread
    sigset_t set;
    sigfillset(&set);
    pthread_sigmask(SIG_BLOCK, &set, NULL);

    // Do work...
    while (1) { work(); }
    return NULL;
}

int main(void) {
    // Create worker threads (they won't receive signals)
    pthread_t thread;
    pthread_create(&thread, NULL, worker, NULL);

    // Main thread handles signals
    sigset_t set;
    sigemptyset(&set);
    sigaddset(&set, SIGINT);
    sigaddset(&set, SIGTERM);
    pthread_sigmask(SIG_UNBLOCK, &set, NULL);

    // Wait for signals
    while (1) { pause(); }
    return 0;
}
```

---

## 11. Troubleshooting Signals

### Common Problems

| Problem | Cause | Solution |
|---------|-------|----------|
| Process killed unexpectedly | `SIGKILL` from OOM killer | Check `dmesg` for OOM messages |
| Segfault at startup | `SIGSEGV` from corrupted binary | Verify binary integrity |
| Broken pipe errors | `SIGPIPE` from closed pipe | Handle `SIGPIPE` or use `MSG_NOSIGNAL` |
| Child zombie processes | `SIGCHLD` not handled | Use `waitpid()` in `SIGCHLD` handler or `signal(SIGCHLD, SIG_IGN)` |
| Random crashes | `SIGBUS` from misaligned access | Check data alignment |

### Debugging Signals with GDB

```
(gdb) info signals                    # Show signal handling table
(gdb) handle SIGINT nostop noprint    # Don't stop on SIGINT
(gdb) handle SIGSEGV stop print      # Stop on SIGSEGV
(gdb) catch signal SIGTERM            # Catch SIGTERM
```

### Debugging Signals with strace

```bash
# Trace signal delivery
strace -e signal ./program

# Trace specific signal
strace -e trace=signal -f ./program

# Show signal masks
strace -v -e signal ./program
```

---

## 12. Quick Reference: Signal Numbers

```
 1 SIGHUP        2 SIGINT        3 SIGQUIT       4 SIGILL
 5 SIGTRAP       6 SIGABRT       7 SIGBUS        8 SIGFPE
 9 SIGKILL      10 SIGUSR1      11 SIGSEGV      12 SIGUSR2
13 SIGPIPE      14 SIGALRM      15 SIGTERM      16 SIGSTKFLT
17 SIGCHLD      18 SIGCONT      19 SIGSTOP      20 SIGTSTP
21 SIGTTIN      22 SIGTTOU      23 SIGURG       24 SIGXCPU
25 SIGXFSZ      26 SIGVTALRM    27 SIGPROF      28 SIGWINCH
29 SIGIO        30 SIGPWR       31 SIGSYS       34-64 SIGRTMIN-SIGRTMAX
```

---

*For detailed information on signal handling, consult `man 7 signal` and `man 2 sigaction`.*
