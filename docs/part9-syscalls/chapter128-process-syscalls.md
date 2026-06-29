# Chapter 128: Process Syscalls

## 1. Introduction

Process management is one of the most fundamental capabilities of an operating system. Linux provides a rich set of syscalls for creating, executing, and terminating processes. This chapter covers `fork`, `vfork`, `clone`/`clone3`, `execve`, `exit`, and `wait4`/`waitpid` — the syscalls that form the foundation of process lifecycle management.

---

## 2. fork

### 2.1 Purpose

`fork` creates a new process by duplicating the calling process. The new process (child) is an almost exact copy of the parent — same memory, same file descriptors, same execution point. The only differences are the return value and the PID.

### 2.2 Prototype

```c
#include <unistd.h>
pid_t fork(void);
```

### 2.3 Arguments

None.

### 2.4 Return Values

- **In the parent**: PID of the child (> 0)
- **In the child**: 0
- **On error**: -1 with `errno` set (no child created)

### 2.5 Error Codes

| Error | Description |
|-------|-------------|
| `EAGAIN` | Limit on total processes/threads reached, or RLIMIT_NPROC exceeded |
| `ENOMEM` | Insufficient memory |
| `ENOSYS` | fork not supported (some architectures) |

### 2.6 Kernel Implementation

```c
SYSCALL_DEFINE0(fork)
{
    return _do_fork(SIGCHLD, 0, 0, NULL, NULL);
}

long _do_fernel _do_fork(unsigned long clone_flags, unsigned long stack_start,
                         unsigned long stack_size, int __user *parent_tidptr,
                         int __user *child_tidptr)
{
    struct task_struct *p;
    struct pid *pid;
    
    // Copy the entire process
    p = copy_process(clone_flags, stack_start, stack_size,
                     child_tidptr, NULL, trace);
    
    // Wake up the new process
    wake_up_new_task(p);
    
    return pid_vnr(pid);  // Return child PID to parent
}
```

**`copy_process`** performs:
1. Allocate a new `task_struct`
2. Copy the process's memory space (`copy_mm`) — uses COW (Copy-on-Write)
3. Copy file descriptors (`copy_files`)
4. Copy signal handlers (`copy_sighand`)
5. Copy filesystem info (`copy_fs`)
6. Generate a new PID
7. Set up the child's kernel stack

### 2.7 Copy-on-Write (COW)

After `fork`, parent and child share the same physical memory pages. Pages are marked read-only in both processes' page tables. When either process writes to a page, a page fault occurs, and the kernel copies the page (making it writable for the writer).

```
Before fork:
  Parent: VA 0x1000 → PA 0x5000 (RW)

After fork:
  Parent: VA 0x1000 → PA 0x5000 (R/O, COW)
  Child:  VA 0x1000 → PA 0x5000 (R/O, COW)

After child writes to 0x1000:
  Parent: VA 0x1000 → PA 0x5000 (R/O, COW)
  Child:  VA 0x1000 → PA 0x7000 (RW)  ← New copy!
```

### 2.8 Example

```c
#include <unistd.h>
#include <stdio.h>
#include <sys/wait.h>

int main(void)
{
    pid_t pid = fork();
    
    if (pid < 0) {
        perror("fork");
        return 1;
    }
    
    if (pid == 0) {
        // Child process
        printf("Child: PID=%d, PPID=%d\n", getpid(), getppid());
        return 42;
    } else {
        // Parent process
        printf("Parent: child PID=%d\n", pid);
        int status;
        waitpid(pid, &status, 0);
        if (WIFEXITED(status))
            printf("Child exited with status %d\n", WEXITSTATUS(status));
    }
    
    return 0;
}
```

### 2.9 What's Inherited and What's Not

**Inherited (shared via COW or reference):**
- Memory contents (COW)
- File descriptors (shared `struct file`)
- File mode creation mask (`umask`)
- Current working directory
- Signal handlers
- Environment variables
- Nice value, scheduling policy

**Not inherited (new for child):**
- PID (new unique PID)
- PPID (set to caller's PID)
- Pending signals (cleared)
- File locks (not inherited)
- Timer alarms (not inherited)

### 2.10 Performance

`fork` is expensive because it must copy the page table (not the pages themselves, thanks to COW, but the page table entries). For a process with 1GB of mapped memory, the page table itself may be several MB. Typical `fork` time: 100-500 microseconds.

---

## 3. vfork

### 3.1 Purpose

`vfork` creates a new process without copying the parent's address space. The child shares the parent's memory until it calls `execve` or `_exit`. The parent is suspended until the child does one of these.

### 3.2 Prototype

```c
#include <unistd.h>
pid_t vfork(void);
```

### 3.3 Dangers

`vfork` is inherently dangerous:
- The child must NOT return from the function that called `vfork` (would corrupt parent's stack)
- The child must NOT modify any data (shared with parent)
- The child must call `execve` or `_exit` quickly

### 3.4 Modern Usage

Modern glibc's `posix_spawn` uses `vfork` internally for performance. The kernel implements `vfork` as `clone(CLONE_VFORK | CLONE_VM | SIGCHLD)`.

**Recommendation**: Use `posix_spawn` or `fork` + `exec`. Avoid raw `vfork`.

---

## 4. clone / clone3

### 4.1 Purpose

`clone` is the most flexible process/thread creation syscall. `fork` and `vfork` are implemented as special cases of `clone`. `clone3` (Linux 5.3+) provides a cleaner extensible interface.

### 4.2 Prototype

```c
#include <sched.h>
int clone(int (*fn)(void *), void *stack, int flags, void *arg, ...);
int clone3(struct clone_args *cl_args, size_t size);
```

### 4.3 clone3 Arguments

```c
struct clone_args {
    __aligned_u64 flags;        // Flags for what to share
    __aligned_u64 pidfd;        // Where to store pidfd
    __aligned_u64 child_tid;    // Where to store child TID
    __aligned_u64 parent_tid;   // Where to store parent TID
    __aligned_u64 exit_signal;  // Signal to send on exit (e.g., SIGCHLD)
    __aligned_u64 stack;        // Child stack pointer
    __aligned_u64 stack_size;   // Child stack size
    __aligned_u64 tls;          // Child TLS pointer
    __aligned_u64 set_tid;      // Array of TIDs to assign
    __aligned_u64 set_tid_size; // Size of set_tid array
    __aligned_u64 cgroup;       // Cgroup fd for CLONE_INTO_CGROUP
};
```

### 4.4 CLONE Flags

| Flag | Description |
|------|-------------|
| `CLONE_VM` | Share address space (threads) |
| `CLONE_FS` | Share filesystem info |
| `CLONE_FILES` | Share file descriptor table |
| `CLONE_SIGHAND` | Share signal handlers |
| `CLONE_THREAD` | Same thread group (same tgid) |
| `CLONE_NEWNS` | New mount namespace |
| `CLONE_NEWPID` | New PID namespace |
| `CLONE_NEWNET` | New network namespace |
| `CLONE_NEWUSER` | New user namespace |
| `CLONE_NEWCGROUP` | New cgroup namespace |
| `CLONE_NEWUTS` | New UTS namespace |
| `CLONE_NEWIPC` | New IPC namespace |
| `CLONE_VFORK` | Parent waits for child exec/exit |
| `CLONE_PARENT` | Child has same parent as caller |
| `CLONE_PIDFD` | Return a pidfd (Linux 5.2+) |
| `CLONE_INTO_CGROUP` | Place child in specific cgroup (Linux 5.7+) |

### 4.5 Creating Threads with clone

```c
#define _GNU_SOURCE
#include <sched.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/wait.h>

#define STACK_SIZE (1024 * 1024)

static int thread_func(void *arg)
{
    printf("Thread: arg=%p\n", arg);
    printf("Thread: PID=%d, TID=%d\n", getpid(), gettid());
    return 0;
}

int main(void)
{
    char *stack = malloc(STACK_SIZE);
    if (!stack) { perror("malloc"); return 1; }
    
    // clone with shared address space, file descriptors, signal handlers
    pid_t pid = clone(thread_func,
                      stack + STACK_SIZE,  // Stack grows down
                      CLONE_VM | CLONE_FS | CLONE_FILES | CLONE_SIGHAND | CLONE_THREAD | SIGCHLD,
                      NULL);
    
    if (pid < 0) { perror("clone"); return 1; }
    
    printf("Parent: PID=%d, child TID=%d\n", getpid(), pid);
    
    // Wait for thread (using waitpid with __WCLONE)
    waitpid(pid, NULL, __WCLONE);
    
    free(stack);
    return 0;
}
```

### 4.6 Kernel Implementation

```c
SYSCALL_DEFINE5(clone, unsigned long, clone_flags, unsigned long, newsp,
                int __user *, parent_tidptr, int __user *, child_tidptr,
                unsigned long, tls)
{
    return kernel_clone(&(struct kernel_clone_args){
        .flags = clone_flags,
        .stack = newsp,
        .parent_tid = parent_tidptr,
        .child_tid = child_tidptr,
        .tls = tls,
    });
}

// clone3
SYSCALL_DEFINE2(clone3, struct clone_args __user *, uargs, size_t, size)
{
    struct clone_args args;
    copy_from_user(&args, uargs, min(size, sizeof(args)));
    return kernel_clone(&(struct kernel_clone_args){
        .flags = args.flags,
        .pidfd = u64_to_user_ptr(args.pidfd),
        .child_tid = u64_to_user_ptr(args.child_tid),
        .parent_tid = u64_to_user_ptr(args.parent_tid),
        .exit_signal = args.exit_signal,
        .stack = args.stack,
        .stack_size = args.stack_size,
        .tls = args.tls,
    });
}
```

### 4.7 What Creates What

| Call | Equivalent clone flags |
|------|----------------------|
| `fork()` | `clone(SIGCHLD)` |
| `vfork()` | `clone(CLONE_VFORK | CLONE_VM | SIGCHLD)` |
| `pthread_create()` | `clone(CLONE_VM | CLONE_FS | CLONE_FILES | CLONE_SIGHAND | CLONE_THREAD | CLONE_SYSVSEM | CLONE_SETTLS | CLONE_PARENT_SETTID | CLONE_CHILD_CLEARTID)` |

---

## 5. execve

### 5.1 Purpose

`execve` replaces the current process's image with a new program. The process ID doesn't change, but the memory, registers, and code are completely replaced.

### 5.2 Prototype

```c
#include <unistd.h>
int execve(const char *pathname, char *const argv[], char *const envp[]);
```

### 5.3 Arguments

- **`pathname`**: Path to the executable
- **`argv`**: Argument list (NULL-terminated). `argv[0]` is conventionally the program name.
- **`envp`**: Environment variables (NULL-terminated)

### 5.4 Return Values

`execve` only returns on error (the process is replaced on success).

- **Success**: Does not return
- **Failure**: -1 with `errno` set

### 5.5 Error Codes

| Error | Description |
|-------|-------------|
| `E2BIG` | Argument list or environment too long |
| `EACCES` | Permission denied (not executable, or directory search denied) |
| `ELOOP` | Too many symbolic links |
| `EMFILE` | Process has too many open files |
| `ENAMETOOLONG` | Filename too long |
| `ENOENT` | File does not exist |
| `ENOEXEC` | Not a valid executable format |
| `ENOMEM` | Insufficient memory |
| `ETXTBSY` | File is open for writing by another process |

### 5.6 Kernel Implementation

```c
SYSCALL_DEFINE3(execve, const char __user *, filename,
                const char __user *const __user *, argv,
                const char __user *const __user *, envp)
{
    return do_execve(getname(filename), argv, envp);
}

static int do_execve(struct filename *filename, ...)
{
    struct linux_binprm *bprm;
    
    // Allocate binary parameters structure
    bprm = kzalloc(sizeof(*bprm), GFP_KERNEL);
    
    // Open the executable file
    bprm->file = do_open_execat(filename);
    
    // Read the first 128 bytes (for format detection)
    kernel_read(bprm->file, bprm->buf, BINPRM_BUF_SIZE, &pos);
    
    // Search for a handler (ELF, script, etc.)
    // This calls the appropriate binary format handler
    retval = exec_binprm(bprm);
    
    // On success, execution never reaches here
    // The new program starts at its entry point
}
```

### 5.7 Binary Formats

The kernel supports multiple binary formats via `struct linux_binfmt`:

- **ELF** (`fs/binfmt_elf.c`): The standard Linux binary format
- **Script** (`fs/binfmt_script.c`): `#!/path/to/interpreter` scripts
- **Misc** (`fs/binfmt_misc.c`): User-registered formats (Wine, Java, etc.)
- **Flat** (`fs/binfmt_flat.c`): Embedded systems format

### 5.8 What's Preserved Across exec

**Preserved:**
- PID, PPID
- Open file descriptors (unless `FD_CLOEXEC` is set)
- Process signal mask
- Pending signals
- Current working directory
- Root directory
- Nice value

**Reset/replaced:**
- Memory mappings (all replaced)
- Signal handlers (reset to `SIG_DFL` for caught signals)
- Close-on-exec file descriptors (closed)
- `AT_SECURE` (setuid/setgid flag)

### 5.9 Example

```c
#include <unistd.h>
#include <stdio.h>
#include <sys/wait.h>

int main(void)
{
    pid_t pid = fork();
    
    if (pid == 0) {
        // Child: exec ls
        char *args[] = { "ls", "-la", "/tmp", NULL };
        char *env[] = { "PATH=/usr/bin:/bin", NULL };
        execve("/usr/bin/ls", args, env);
        perror("execve");  // Only reached on error
        _exit(1);
    }
    
    int status;
    waitpid(pid, &status, 0);
    if (WIFEXITED(status))
        printf("ls exited with %d\n", WEXITSTATUS(status));
    
    return 0;
}
```

### 5.10 exec Family

glibc provides several wrappers:

```c
// Full path + arrays
int execve(const char *path, char *const argv[], char *const envp[]);

// Uses PATH variable
int execlp(const char *file, const char *arg, ...);
int execvp(const char *file, char *const argv[]);

// Explicit environment
int execle(const char *path, const char *arg, ..., char *const envp[]);

// Array form
int execv(const char *path, char *const argv[]);

// Modern: execveat (Linux 3.19+)
int execveat(int dirfd, const char *pathname, char *const argv[],
             char *const envp[], int flags);
```

---

## 6. exit / exit_group

### 6.1 Purpose

`exit` terminates the calling thread. `exit_group` terminates all threads in the process.

### 6.2 Prototype

```c
#include <unistd.h>
void _exit(int status);
void _Exit(int status);

// C library
#include <stdlib.h>
void exit(int status);
```

### 6.3 Differences

| Function | Behavior |
|----------|----------|
| `exit()` | Calls `atexit()` handlers, flushes stdio buffers, then calls `_exit()` |
| `_exit()` | Terminates immediately (syscall wrapper) |
| `_Exit()` | Same as `_exit()` (C99 standard name) |

### 6.4 Kernel Implementation

```c
SYSCALL_DEFINE1(exit, int, error_code)
{
    do_exit((error_code & 0xff) << 8);  // Exit status in upper byte
}

void __noreturn do_exit(long code)
{
    // 1. Set PF_EXITING flag
    // 2. Release resources:
    //    - Exit robust futexes
    //    - Exit PI futexes
    //    - Release mm (address space)
    //    - Release files
    //    - Release fs
    //    - Release signal handlers
    // 3. Notify parent via SIGCHLD
    // 4. Reparent children to init
    // 5. Call schedule() — never returns
}
```

### 6.5 Exit Status

The exit status is a 16-bit value:
- **Bits 15-8**: Exit status (from `_exit(status)` or `return status`)
- **Bits 7-0**: Signal number (if killed by signal)
- **Bit 6**: Core dump flag

Use macros to extract:
```c
WEXITSTATUS(status)  // Exit status (bits 15-8)
WTERMSIG(status)     // Signal number (bits 7-0)
WCOREDUMP(status)    // Core dump flag (bit 6)
WIFEXITED(status)    // True if normal exit
WIFSIGNALED(status)  // True if killed by signal
```

### 6.6 `exit_group` (Thread Exit)

```c
SYSCALL_DEFINE1(exit_group, int, error_code)
{
    do_group_exit((error_code & 0xff) << 8);
}
```

`exit_group` sends `SIGKILL` to all other threads in the thread group, then calls `do_exit`. This is what glibc's `exit()` calls (not `exit`).

---

## 7. wait4 / waitpid / waitid

### 7.1 Purpose

These syscalls wait for a child process to change state (exit, be killed by signal, stop, or continue).

### 7.2 Prototype

```c
#include <sys/wait.h>
pid_t wait(int *wstatus);
pid_t waitpid(pid_t pid, int *wstatus, int options);
int waitid(idtype_t idtype, id_t id, siginfo_t *infop, int options);
```

### 7.3 waitpid Arguments

**`pid`**:
| Value | Meaning |
|-------|---------|
| `> 0` | Wait for specific PID |
| `-1` | Wait for any child |
| `0` | Wait for any child in same process group |
| `< -1` | Wait for any child in process group abs(pid) |

**`options`** (OR'd):
| Option | Description |
|--------|-------------|
| `WNOHANG` | Return immediately if no child exited |
| `WUNTRACED` | Report stopped children |
| `WCONTINUED` | Report continued children |
| `__WCLONE` | Wait for clone children (not just direct children) |

### 7.4 Return Values

- **Success**: PID of the child that changed state
- **With WNOHANG**: 0 if no child has changed state
- **Failure**: -1 with `errno` set

### 7.5 Kernel Implementation

```c
SYSCALL_DEFINE4(wait4, pid_t, upid, int __user *, stat_addr,
                int, options, struct rusage __user *, ru)
{
    return kernel_wait4(upid, stat_addr, options, ru);
}
```

The kernel checks the process's children list. If a child has exited, it collects the exit status and releases the child's `task_struct`. If no child has exited and `WNOHANG` is not set, the parent sleeps until a child changes state.

### 7.6 Example

```c
#include <sys/wait.h>
#include <unistd.h>
#include <stdio.h>

int main(void)
{
    for (int i = 0; i < 3; i++) {
        pid_t pid = fork();
        if (pid == 0) {
            sleep(i + 1);
            _exit(i);
        }
    }
    
    // Wait for all children
    int status;
    pid_t pid;
    while ((pid = waitpid(-1, &status, 0)) > 0) {
        if (WIFEXITED(status))
            printf("Child %d exited with status %d\n", pid, WEXITSTATUS(status));
    }
    
    return 0;
}
```

### 7.7 Zombie Processes

When a child exits but the parent hasn't called `wait`, the child becomes a zombie — a `task_struct` with minimal resource usage, but still consuming a PID slot. If the parent also exits, zombies are reparented to `init` (PID 1), which calls `wait` to clean them up.

**Preventing zombies:**
1. Always `wait` for your children
2. Use `signal(SIGCHLD, SIG_IGN)` (Linux-specific, auto-reaps children)
3. Double `fork` — grandchild is reparented to init
4. Use `waitid` with `WNOWAIT` to peek without consuming

---

## 8. Security Implications

- **`fork` bomb**: Unlimited `fork` can exhaust system resources. Use `RLIMIT_NPROC` and cgroups to limit.
- **`execve` and setuid**: Setuid binaries are security-critical. The kernel resets certain capabilities and signal handlers.
- **`clone` namespaces**: `CLONE_NEWUSER` allows unprivileged users to create user namespaces, which is a powerful but controversial feature (container escape vectors).
- **`vfork` dangers**: Shared memory between parent and child is inherently dangerous. Use only in controlled contexts.

---

## 9. Common Bugs

```c
// BUG: Not checking fork return value
fork();
// Both parent and child continue here!

// FIX: Check all three paths
pid_t pid = fork();
if (pid < 0) { /* error */ }
else if (pid == 0) { /* child */ }
else { /* parent */ }

// BUG: Using exit() in signal handler
void handler(int sig) {
    exit(1);  // exit() is NOT async-signal-safe!
}
// FIX: Use _exit() or _Exit()
void handler(int sig) {
    _exit(1);
}

// BUG: Ignoring EINTR in waitpid
waitpid(pid, &status, 0);  // Might be interrupted by signal!

// FIX: Retry on EINTR
do {
    pid = waitpid(child, &status, 0);
} while (pid < 0 && errno == EINTR);
```

---

## 10. Kernel Source References

- **`fork`/`vfork`**: `kernel/fork.c`
- **`clone`/`clone3`**: `kernel/fork.c`
- **`execve`**: `fs/exec.c`
- **`exit`/`exit_group`**: `kernel/exit.c`
- **`wait4`/`waitpid`**: `kernel/exit.c`
- **COW implementation**: `mm/memory.c` (`do_wp_page`)
- **Binary formats**: `fs/binfmt_elf.c`, `fs/binfmt_script.c`

---

## 11. Summary

Process syscalls are the foundation of multitasking in Linux:
- **`fork`**: Create a child process (COW copy)
- **`vfork`**: Create a child sharing memory (dangerous, use sparingly)
- **`clone`/`clone3`**: Flexible process/thread creation with fine-grained sharing
- **`execve`**: Replace process image with a new program
- **`exit`/`exit_group`**: Terminate process/threads
- **`wait4`/`waitpid`**: Reap child processes and collect exit status

Understanding these syscalls is essential for process management, containerization, and systems programming in Linux.

---

## 13. Detailed Process Syscall Internals

### 13.1 The task_struct

The `task_struct` is the kernel's representation of a process or thread:

```c
struct task_struct {
    // Scheduling
    unsigned int __state;           // TASK_RUNNING, TASK_INTERRUPTIBLE, etc.
    int prio;                       // Dynamic priority
    int static_prio;                // Static priority (from nice)
    int normal_prio;                // Normal priority
    unsigned int rt_priority;       // RT priority (0-99)
    const struct sched_class *sched_class;
    struct sched_entity se;
    struct sched_rt_entity rt;
    struct sched_dl_entity dl;
    
    // Process relationships
    struct task_struct __rcu *real_parent;
    struct task_struct __rcu *parent;
    struct list_head children;
    struct list_head sibling;
    struct task_struct *group_leader;
    
    // Identifiers
    pid_t pid;                      // Process ID (thread-level)
    pid_t tgid;                     // Thread group ID (process-level)
    
    // Credentials
    const struct cred __rcu *cred;  // Current credentials
    const struct cred __rcu *real_cred;
    
    // Memory
    struct mm_struct *mm;           // Address space (NULL for kernel threads)
    struct mm_struct *active_mm;
    
    // File system
    struct fs_struct *fs;           // Root and current directories
    struct files_struct *files;     // File descriptor table
    
    // Signals
    struct signal_struct *signal;
    struct sighand_struct *sighand;
    sigset_t blocked;
    sigset_t real_blocked;
    struct sigpending pending;
    
    // Namespace
    struct nsproxy *nsproxy;
    
    // Cgroup
    struct css_set __rcu *cgroups;
    
    // Stack
    void *stack;                    // Kernel stack pointer
    // ...
};
```

### 13.2 fork Implementation Details

The `fork` syscall goes through several stages:

```c
// kernel/fork.c
static __latent_entropy struct task_struct *copy_process(
    unsigned long clone_flags,
    unsigned long stack_start,
    unsigned long stack_size,
    int __user *child_tidptr,
    struct pid *pid,
    int trace)
{
    struct task_struct *p;
    int retval;
    
    // 1. Allocate task_struct
    p = dup_task_struct(current, node);
    
    // 2. Copy security context
    copy_creds(p, clone_flags);
    
    // 3. Initialize scheduler
    sched_fork(clone_flags, p);
    
    // 4. Copy all process components
    copy_files(clone_flags, p);       // File descriptor table
    copy_fs(clone_flags, p);          // Root/current directory
    copy_sighand(clone_flags, p);     // Signal handlers
    copy_signal(clone_flags, p);      // Signal state
    copy_mm(clone_flags, p);          // Address space (COW)
    copy_namespaces(clone_flags, p);  // Namespaces
    copy_io(clone_flags, p);          // I/O context
    
    // 5. Allocate PID
    pid = alloc_pid(p->nsproxy->pid_ns_for_children);
    p->pid = pid_nr(pid);
    
    // 6. Set up child stack
    copy_thread(p, stack_start, stack_size);
    
    // 7. Link into process tree
    p->parent = current;
    list_add(&p->sibling, &current->children);
    
    // 8. Wake up the new process
    wake_up_new_task(p);
    
    return p;
}
```

### 13.3 execve Implementation Details

The `execve` syscall replaces the process image:

```c
// fs/exec.c
static int do_execveat_common(int fd, struct filename *filename, ...)
{
    struct linux_binprm *bprm;
    
    // 1. Allocate binary parameters
    bprm = kzalloc(sizeof(*bprm), GFP_KERNEL);
    
    // 2. Open the executable
    bprm->file = do_open_execat(fd, filename, &flags);
    
    // 3. Read the first bytes (for format detection)
    retval = kernel_read(bprm->file, bprm->buf, BINPRM_BUF_SIZE, &pos);
    
    // 4. Copy arguments and environment from user space
    retval = copy_strings(bprm->argc, argv, bprm);
    retval = copy_strings(bprm->envc, envp, bprm);
    
    // 5. Search for binary format handler
    retval = search_binary_handler(bprm);
    // This iterates through registered formats:
    // - ELF (binfmt_elf.c)
    // - Script (binfmt_script.c) - #! lines
    // - Misc (binfmt_misc.c) - user-registered
    // - Flat (binfmt_flat.c) - embedded
    
    return retval;
}

// For ELF:
static int load_elf_binary(struct linux_binprm *bprm)
{
    // 1. Parse ELF header
    // 2. Load program headers
    // 3. Create new memory mappings for each PT_LOAD segment
    // 4. Set up the auxiliary vector (AT_PHDR, AT_ENTRY, etc.)
    // 5. Set up the user stack
    // 6. Set the instruction pointer to the ELF entry point
    // 7. Release old mm
}
```

### 13.4 Zombie Process Details

A zombie process is a terminated process whose parent hasn't called `wait()`:

```c
// In do_exit():
static void do_exit(long code)
{
    // 1. Release most resources
    exit_mm();           // Release address space
    exit_sem(tsk);       // Release semaphores
    exit_files(tsk);     // Release file descriptors
    exit_fs(tsk);        // Release filesystem info
    
    // 2. Notify parent
    tsk->exit_code = code;
    do_notify_parent(tsk, sig);  // Send SIGCHLD
    
    // 3. Become a zombie
    tsk->__state = TASK_ZOMBIE;
    
    // 4. Schedule — the task_struct remains until parent calls wait()
    schedule();
}
```

**Zombie cleanup:**
```c
// In waitpid/wait4:
static int wait_task_zombie(struct wait_opts *wo, struct task_struct *p)
{
    // Get exit status
    // Release the task_struct
    // Remove from process tree
    release_task(p);
}
```

### 13.5 Process Credentials

```c
struct cred {
    atomic_t usage;
    kuid_t uid;              // Real UID
    kgid_t gid;              // Real GID
    kuid_t suid;             // Saved UID
    kgid_t sgid;             // Saved GID
    kuid_t euid;             // Effective UID
    kgid_t egid;             // Effective GID
    kuid_t fsuid;            // Filesystem UID
    kgid_t fsgid;            // Filesystem GID
    unsigned securebits;
    kernel_cap_t cap_inheritable;
    kernel_cap_t cap_permitted;
    kernel_cap_t cap_effective;
    kernel_cap_t cap_bset;
    kernel_cap_t cap_ambient;
    // ...
};
```

**Credential checks:**
```c
// File access check
bool inode_owner_or_capable(struct inode *inode)
{
    if (uid_eq(current_fsuid(), inode->i_uid))
        return true;
    if (capable(CAP_FOWNER))
        return true;
    return false;
}
```

### 13.6 Process Groups and Sessions

```c
// Session: A collection of process groups
// Process group: A collection of related processes
// Used for job control in shells

struct signal_struct {
    struct pid *tty_old_pgrp;     // Previous foreground pgrp
    struct pid *pgrp;             // Process group
    struct pid *session;          // Session
    // ...
};
```

**Job control:**
```bash
# Background: process group gets its own PGID
command &

# Foreground: shell gives terminal to the process group
fg %1

# Stop: SIGTSTP (Ctrl+Z)
# Continue: SIGCONT
```

### 13.7 Process Resource Limits

```c
struct rlimit {
    unsigned long rlim_cur;  // Soft limit
    unsigned long rlim_max;  // Hard limit
};

// RLIMIT_AS: Maximum virtual memory
// RLIMIT_CORE: Maximum core dump size
// RLIMIT_CPU: Maximum CPU time
// RLIMIT_DATA: Maximum data segment size
// RLIMIT_FSIZE: Maximum file size
// RLIMIT_NOFILE: Maximum open files
// RLIMIT_NPROC: Maximum processes per user
// RLIMIT_STACK: Maximum stack size
// RLIMIT_MEMLOCK: Maximum locked memory
// RLIMIT_SIGPENDING: Maximum queued signals
// RLIMIT_RTTIME: Maximum real-time CPU time
```

### 13.8 The/proc/[pid] Filesystem

The proc filesystem exposes process information:

```bash
/proc/[pid]/cmdline    # Command line
/proc/[pid]/cwd        # Current working directory (symlink)
/proc/[pid]/environ    # Environment variables
/proc/[pid]/exe        # Executable (symlink)
/proc/[pid]/fd/        # Open file descriptors
/proc/[pid]/maps       # Memory mappings
/proc/[pid]/mem        # Process memory (read/write)
/proc/[pid]/status     # Process status
/proc/[pid]/stat       # Detailed status
/proc/[pid]/ns/        # Namespace symlinks
/proc/[pid]/cgroup     # Cgroup membership
/proc/[pid]/oom_score  # OOM killer score
```

Each entry is implemented by the kernel's proc filesystem code, which reads directly from the `task_struct` and related structures.
