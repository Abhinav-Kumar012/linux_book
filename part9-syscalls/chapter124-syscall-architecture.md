# Chapter 124: Syscall Architecture

## 1. Introduction

System calls (syscalls) are the fundamental interface between user-space applications and the Linux kernel. They represent the controlled gateway through which every privileged operation — from reading a file to creating a network socket — must pass. Understanding syscall architecture is essential for systems programmers, kernel developers, and anyone seeking deep knowledge of how Linux operates at the lowest level.

This chapter covers the complete lifecycle of a system call: how user code triggers a transition into kernel mode, how the kernel dispatches the call, how arguments are passed securely, and how the result is returned to user space. We examine the historical evolution from `int 0x80` to the modern `SYSCALL`/`SYSRET` instructions, the syscall table structure, seccomp filtering, and the performance implications of each approach.

---

## 2. The System Call Concept

### 2.1 Purpose

A system call serves as the boundary between the unprivileged user-space execution environment and the privileged kernel space. Without this boundary, any application could directly manipulate hardware, access arbitrary memory, or interfere with other processes — destroying all guarantees of security, stability, and isolation.

The kernel provides approximately 450+ system calls on modern Linux (x86-64), each identified by a unique syscall number. These calls cover:

- **File I/O**: `open`, `read`, `write`, `close`, `lseek`
- **Process management**: `fork`, `execve`, `exit`, `wait`
- **Memory management**: `mmap`, `brk`, `mprotect`
- **Networking**: `socket`, `bind`, `listen`, `accept`, `connect`
- **Signals**: `kill`, `sigaction`, `sigprocmask`
- **Time**: `clock_gettime`, `nanosleep`, `timerfd_create`
- **Security**: `seccomp`, `prctl`, `capset`
- **IPC**: `shmget`, `msgget`, `semget`
- **And many more...**

### 2.2 The Privilege Transition

When a user-space program needs kernel services, it cannot simply call a kernel function — the kernel's code and data reside in a protected memory region accessible only in ring 0 (on x86) or EL1 (on ARM). The transition requires a controlled mechanism that:

1. Saves the current user-space execution state (registers, instruction pointer, flags)
2. Switches to the kernel stack
3. Enters kernel mode with full privileges
4. Validates the syscall number and arguments
5. Dispatches to the appropriate kernel handler
6. Restores user-space state and returns the result

This transition is the most performance-critical path in the entire operating system.

---

## 3. Historical Evolution of Syscall Mechanisms

### 3.1 The `int 0x80` Legacy (i386)

On 32-bit x86 Linux, the traditional mechanism used software interrupt `int 0x80`:

```asm
; 32-bit syscall invocation
mov eax, 4        ; syscall number for write
mov ebx, 1        ; fd = stdout
mov ecx, buffer   ; pointer to data
mov edx, length   ; number of bytes
int 0x80          ; trigger interrupt
; result in eax
```

**How it works:**

1. The processor looks up interrupt descriptor table (IDT) entry 0x80
2. The IDT entry points to `system_call` in the kernel
3. The CPU switches to ring 0, loads the kernel stack pointer from the TSS
4. The kernel saves all user registers on the kernel stack
5. The syscall number in `eax` is validated against `NR_syscalls`
6. The function pointer is looked up in `sys_call_table[eax]`
7. The handler is called with arguments from `ebx`, `ecx`, `edx`, `esi`, `edi`, `ebp`
8. The return value is placed in `eax`
9. `iret` restores the user-space context

**Prototype (32-bit):**

```
int 0x80
  Input:  EAX = syscall number
          EBX, ECX, EDX, ESI, EDI, EBP = arguments (up to 6)
  Output: EAX = return value (negative errno on error)
```

**Performance:** Each `int 0x80` invocation costs approximately 100-200 cycles due to the full IDT lookup, privilege level switch, and `iret` overhead. The interrupt mechanism was designed for general-purpose interrupt handling, not optimized for frequent system call transitions.

**Legacy usage:** While 64-bit kernels still support `int 0x80` for compatibility (via the `IA32_SYSCALL` entry point), it should never be used in 64-bit code. Using `int 0x80` in 64-bit programs truncates all registers to 32 bits, leading to subtle bugs with pointers above 4 GB.

### 3.2 `sysenter`/`sysexit` (Intel Optimization)

Intel introduced `sysenter`/`sysexit` in Pentium II as a faster alternative to `int 0x80`:

```asm
; sysenter-based syscall (32-bit)
mov eax, syscall_number
mov ebx, arg1
mov ecx, arg2
mov edx, arg3
push ecx          ; sysexit needs return address in ecx
push edx
mov ecx, esp      ; user stack pointer
sysenter
```

**Mechanism:** `sysenter` uses model-specific registers (MSRs) to directly load the kernel's code segment, instruction pointer, and stack pointer — bypassing the IDT entirely. This reduces the transition cost to approximately 50-80 cycles.

**Problems:** The `sysenter`/`sysexit` pair has an asymmetric design — `sysexit` requires the return address in `edx` and the stack pointer in `ecx`, making the vDSO implementation complex. AMD's `syscall`/`sysret` proved superior for 64-bit.

### 3.3 `SYSCALL`/`SYSRET` (Modern x86-64)

The current standard for x86-64 uses the `syscall` and `sysret` instructions:

```asm
; x86-64 syscall invocation
mov rax, syscall_number
mov rdi, arg1
mov rsi, arg2
mov rdx, arg3
mov r10, arg4      ; note: r10, not rcx
mov r8, arg5
mov r9, arg6
syscall
; result in rax
```

**How `syscall` works:**

1. The CPU reads `STAR` MSR to get the kernel's code segment and SYSCALL entry point
2. The user's `rip` is saved in `rcx` (this is why `r10` is used for arg4)
3. The user's `rflags` is saved in `r11`
4. `rip` is loaded from `LSTAR` MSR (points to `entry_SYSCALL_64` in the kernel)
5. The CPU switches to ring 0 (CPL 0) using the segment selector from `STAR`
6. Interrupts are disabled (IF flag cleared, per `FMASK` MSR)

**How `sysret` works:**

1. `rip` is restored from `rcx`
2. `rflags` is restored from `r11`
3. The CPU switches back to ring 3 using the segment selector from `STAR`

**Performance:** `syscall`/`sysret` costs approximately 20-50 cycles, making it 3-10x faster than `int 0x80`. The key optimizations:

- No IDT lookup — the entry point is in an MSR
- Minimal state saving — only `rcx` and `r11` are clobbered by hardware
- No segment register manipulation in the fast path
- The kernel uses `SWAPGS` to quickly access per-CPU data

**Prototype (x86-64):**

```
SYSCALL
  Input:  RAX = syscall number
          RDI = arg1, RSI = arg2, RDX = arg3
          R10 = arg4, R8  = arg5, R9  = arg6
  Output: RAX = return value (negative errno on error)
  Clobbered: RCX (saved RIP), R11 (saved RFLAGS)
```

### 3.4 ARM64 `svc` Instruction

On ARM64 (AArch64), the `svc` (Supervisor Call) instruction is used:

```asm
// ARM64 syscall invocation
mov x8, syscall_number
mov x0, arg1
mov x1, arg2
mov x2, arg3
mov x3, arg4
mov x4, arg5
mov x5, arg6
svc #0
// result in x0
```

**Mechanism:** `svc #0` causes a synchronous exception to EL1 (kernel). The kernel's exception vector table entry at `VBAR_EL1 + 0x400` handles the call.

**ARM64 Registers:**
- `x8`: syscall number
- `x0`-`x5`: arguments 1-6
- `x0`: return value
- `x30` (LR): saved by hardware (return address)
- `SPSR_EL1`: saved processor state

---

## 4. The Syscall Table

### 4.1 Structure

The syscall table is a simple array of function pointers, indexed by syscall number. On x86-64, it's defined in `arch/x86/entry/syscalls/syscall_64.tbl`:

```
# <number>  <abi>   <name>              <entry point>
0           common  read                sys_read
1           common  write               sys_write
2           common  open                sys_open
3           common  close               sys_close
...
57          common  fork                sys_fork
59          common  execve              sys_execve
60          common  exit                sys_exit
61          common  wait4               sys_wait4
...
```

The C header `include/uapi/asm-generic/unistd.h` and architecture-specific headers define the syscall numbers. The auto-generated `asm-offsets.h` provides `NR_syscalls` — the total count.

### 4.2 Kernel Implementation

The actual dispatch happens in `arch/x86/entry/entry_64.S`:

```asm
ENTRY(entry_SYSCALL_64)
    /* Entry from userspace */
    swapgs
    mov [gs:cpu_tss_rw.x86_tss.sp2], rsp   /* Save user RSP */
    mov rsp, [gs:cpu_tss_rw.x86_tss.sp0]   /* Load kernel RSP */
    
    /* Save registers */
    push rbp
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    push r8
    push r9
    push r10
    push r11
    push r12
    push r13
    push r14
    push r15
    
    /* Validate syscall number */
    cmp rax, NR_syscalls
    ja bad_syscall
    
    /* Dispatch */
    call [sys_call_table + rax*8]
    
    /* Store return value */
    mov [rsp + 8*REG_AX], rax
    
    /* Restore registers and return */
    /* ... restore sequence ... */
    swapgs
    sysretq
END(entry_SYSCALL_64)
```

### 4.3 The `sys_call_table` Array

```c
// Generated from syscall_64.tbl
asmlinkage const sys_call_ptr_t sys_call_table[__NR_syscalls_max + 1] = {
    [0] = sys_read,
    [1] = sys_write,
    [2] = sys_open,
    [3] = sys_close,
    // ... 400+ entries
};
```

Each entry is a function pointer. The `sys_` prefix handlers are the actual C functions in the kernel. Modern kernels use `SYSCALL_DEFINE` macros to define them:

```c
SYSCALL_DEFINE3(read, unsigned int, fd, char __user *, buf, size_t, count)
{
    struct fd f = fdget_pos(fd);
    // ... implementation
}
```

The `SYSCALL_DEFINE3` macro expands to handle:
- Register saving/restoring
- `copy_from_user`/`copy_to_user` for user-space pointer validation
- Tracing hooks (ftrace, tracepoints)
- Seccomp filtering
- Audit logging

### 4.4 Adding New Syscalls

Adding a new syscall requires:

1. Add entry to `syscall_64.tbl` (and `syscall_32.tbl` if 32-bit compat needed)
2. Add the syscall number to `include/uapi/asm-generic/unistd.h` (for generic syscalls)
3. Implement the handler using `SYSCALL_DEFINEx` macro
4. Add the implementation file to the kernel build system
5. Add the syscall to the seccomp allowlist if applicable
6. Update the man page and glibc wrapper

The kernel's policy is to never remove syscalls (for backward compatibility), but they can be made no-ops. The `sys_ni_syscall` function serves as a placeholder for unimplemented or removed syscalls.

---

## 5. The vDSO and vsyscall

### 5.1 The vDSO (Virtual Dynamic Shared Object)

Not all "system calls" require a privilege transition. The vDSO is a small shared library mapped into every process's address space by the kernel. It contains optimized implementations of certain syscalls that don't actually need kernel privileges:

- `gettimeofday()` — reads the kernel's time data directly from a shared memory page
- `clock_gettime()` — same mechanism
- `getcpu()` — reads the CPU number from a per-CPU data area
- `time()` — legacy time getter

```c
// Typical vDSO usage transparent to the application
struct timeval tv;
gettimeofday(&tv, NULL);  // May not actually enter kernel!
```

**How the vDSO works:**

1. The kernel maps the vDSO (`linux-vdso.so.1`) into every process at a random address
2. glibc's `gettimeofday()` checks if the vDSO provides an implementation
3. If available, it calls the vDSO version which reads from the `vsyscall` page (mapped read-only from kernel data)
4. If not available (e.g., old hardware), it falls back to the real syscall

**Performance:** vDSO calls are essentially free — they're just function calls within user space, reading shared kernel data. A `gettimeofday()` via vDSO costs ~20 nanoseconds vs ~200+ nanoseconds for a real syscall.

### 5.2 The Legacy `vsyscall` Page

Before the vDSO, Linux used a fixed-address `vsyscall` page at `0xffffffffff600000`. This was problematic:

- Fixed address → security risk (ROP gadgets)
- Only 4 entry points (too inflexible)
- Eventually deprecated and replaced by the vDSO

Modern kernels compile with `CONFIG_LEGACY_VSYSCALL_NONE` by default. The `vsyscall` page exists only as a compatibility shim that traps into the kernel (slow path).

---

## 6. Syscall Entry Path in Detail

### 6.1 Preparation Phase

When `syscall` is executed on x86-64:

```c
// Simplified view of entry_SYSCALL_64
void entry_SYSCALL_64(void)
{
    struct pt_regs *regs;
    
    // 1. SWAPGS: Switch to kernel GS base
    //    This gives access to per-CPU data (current task, kernel stack)
    
    // 2. Save user RSP to per-CPU storage
    //    Load kernel RSP from TSS
    
    // 3. Build pt_regs structure on kernel stack
    //    This contains all saved user registers
    
    regs = (struct pt_regs *)current_stack_pointer;
    
    // 4. Sanitize registers (security hardening)
    //    Clear certain bits in RFLAGS
    //    Ensure canonical addresses
    
    // 5. Enable interrupts (sti)
    //    Interrupts are disabled during the initial entry
    
    // 6. Call do_syscall_64(regs)
}
```

### 6.2 Dispatch Phase

```c
static __always_inline void do_syscall_64(struct pt_regs *regs)
{
    unsigned long nr = regs->orig_ax;
    
    // Seccomp filter check (if configured)
    if (static_call(ia32_syscall)(regs) == -1)
        return;
    
    // Syscall tracing (strace, ftrace)
    if (unlikely(test_thread_flag(TIF_SYSCALL_TRACE)))
        tracehook_report_syscall_entry(regs);
    
    // Validate syscall number
    if (likely(nr < NR_syscalls)) {
        regs->ax = sys_call_table[nr](regs->di, regs->si,
                                       regs->dx, regs->r10,
                                       regs->r8, regs->r9);
    } else {
        regs->ax = -ENOSYS;
    }
    
    // Syscall exit tracing
    if (unlikely(test_thread_flag(TIF_SYSCALL_TRACE)))
        tracehook_report_syscall_exit(regs, 0);
}
```

### 6.3 Return Phase

```c
// After do_syscall_64 returns:
// 1. Check for pending work (signals, rescheduling, etc.)
// 2. Restore all user registers from pt_regs
// 3. SWAPGS (switch back to user GS base)
// 4. SYSRETQ (return to user space)
```

### 6.4 The `pt_regs` Structure

```c
struct pt_regs {
    unsigned long r15;
    unsigned long r14;
    unsigned long r13;
    unsigned long r12;
    unsigned long bp;
    unsigned long bx;
    unsigned long r11;
    unsigned long r10;
    unsigned long r9;
    unsigned long r8;
    unsigned long ax;
    unsigned long cx;
    unsigned long dx;
    unsigned long si;
    unsigned long di;
    unsigned long orig_ax;   // Original syscall number (for restart)
    unsigned long ip;        // Saved RIP (not used by hardware for syscall)
    unsigned long cs;
    unsigned long flags;
    unsigned long sp;
    unsigned long ss;
};
```

The kernel stack is 16 KB (4 pages) per CPU on x86-64. The `pt_regs` structure occupies the top of the stack after entry.

---

## 7. Argument Passing and Validation

### 7.1 Register-Based Arguments

All modern Linux syscall interfaces pass arguments in registers:

**x86-64:**
| Argument | Register |
|----------|----------|
| syscall number | `rax` |
| arg1 | `rdi` |
| arg2 | `rsi` |
| arg3 | `rdx` |
| arg4 | `r10` |
| arg5 | `r8` |
| arg6 | `r9` |
| return value | `rax` |

**Note:** `r10` is used instead of `rcx` because `syscall` clobbers `rcx` (saves `rip` there).

**ARM64:**
| Argument | Register |
|----------|----------|
| syscall number | `x8` |
| arg1-arg6 | `x0`-`x5` |
| return value | `x0` |

### 7.2 User-Space Pointer Validation

The kernel must never blindly dereference user-space pointers. The `copy_from_user()` and `copy_to_user()` functions perform careful validation:

```c
SYSCALL_DEFINE3(read, unsigned int, fd, char __user *, buf, size_t, count)
{
    // buf is a user-space pointer — must be validated
    struct fd f = fdget_pos(fd);
    if (!f.file)
        return -EBADF;
    
    // This internally checks that buf is in user-space address range
    // and handles page faults gracefully
    ret = vfs_read(f.file, buf, count, &pos);
    fdput_pos(f);
    return ret;
}
```

**`access_ok()` checks:**
- The pointer is in the user-space address range (below `TASK_SIZE`)
- The address is canonical (on x86-64, bits 48-63 must be copies of bit 47)
- The memory region is properly mapped (handled by page fault during copy)

**SMAP/SMEP (Supervisor Mode Access/Execution Prevention):**
Modern CPUs prevent the kernel from accidentally accessing user-space memory:
- **SMAP**: Prevents kernel from reading/writing user pages (unless explicitly allowed via `stac`/`clac`)
- **SMEP**: Prevents kernel from executing user-space code

### 7.3 Argument Count and Types

Syscalls can take 0 to 6 arguments. The `SYSCALL_DEFINEx` macros handle each count:

```c
SYSCALL_DEFINE0(getpid)           // 0 args
SYSCALL_DEFINE1(exit, int, code)  // 1 arg
SYSCALL_DEFINE3(read, ...)        // 3 args
SYSCALL_DEFINE6(mmap, ...)        // 6 args (rare)
```

For more than 6 arguments (exceedingly rare), a struct pointer is passed as one of the 6 arguments. The `socketcall` syscall used this pattern before individual socket syscalls were added.

---

## 8. Seccomp Filters

### 8.1 Overview

Seccomp (Secure Computing Mode) allows processes to restrict which syscalls they can make. Originally designed for running untrusted code, it's now widely used in browsers, container runtimes, and sandboxed applications.

### 8.2 Seccomp Modes

**SECCOMP_MODE_STRICT (mode 1):**
Only allows `read`, `write`, `exit`, and `sigreturn`. Everything else kills the process.

```c
prctl(PR_SET_SECCOMP, SECCOMP_MODE_STRICT);
```

**SECCOMP_MODE_FILTER (mode 2):**
Allows user-defined BPF (Berkeley Packet Filter) programs to examine syscall arguments and decide: allow, deny (return errno), kill, trace, or notify.

```c
struct sock_filter filter[] = {
    BPF_STMT(BPF_LD | BPF_W | BPF_ABS, offsetof(struct seccomp_data, nr)),
    BPF_JUMP(BPF_JMP | BPF_JEQ | BPF_K, __NR_write, 0, 1),
    BPF_STMT(BPF_RET | BPF_K, SECCOMP_RET_ALLOW),
    BPF_STMT(BPF_RET | BPF_K, SECCOMP_RET_KILL_PROCESS),
};
struct sock_fprog prog = {
    .len = ARRAY_SIZE(filter),
    .filter = filter,
};
prctl(PR_SET_SECCOMP, SECCOMP_MODE_FILTER, &prog);
```

### 8.3 Seccomp Return Values

| Return Value | Behavior |
|-------------|----------|
| `SECCOMP_RET_KILL_PROCESS` | Kill the entire process (SIGSYS) |
| `SECCOMP_RET_KILL_THREAD` | Kill the calling thread |
| `SECCOMP_RET_TRAP` | Send SIGSYS to the thread |
| `SECCOMP_RET_ERRNO` | Return the specified errno |
| `SECCOMP_RET_USER_NOTIF` | Notify a supervisor via fd |
| `SECCOMP_RET_TRACE` | Notify a ptrace tracer |
| `SECCOMP_RET_LOG` | Allow but log the syscall |
| `SECCOMP_RET_ALLOW` | Allow the syscall |

### 8.4 Seccomp Filter Evaluation

The kernel evaluates seccomp filters in `__seccomp_filter()`:

```c
static int __seccomp_filter(int this_syscall, const struct seccomp_data *sd,
                            const bool recheck_after_trace)
{
    u32 ret = BPF_PROG_RUN(current->seccomp.filter->prog, sd);
    
    switch (ret & SECCOMP_RET_ACTION) {
    case SECCOMP_RET_KILL_PROCESS:
        do_exit(SIGSYS);
    case SECCOMP_RET_ERRNO:
        return -((int)(ret & SECCOMP_RET_DATA));
    case SECCOMP_RET_USER_NOTIF:
        // Forward to supervisor process
        return seccomp_notify_user(sd, ret);
    case SECCOMP_RET_ALLOW:
        return 0;
    // ...
    }
}
```

### 8.5 Performance Impact

Seccomp filters add overhead to every syscall:
- **No filter**: 0 additional cycles
- **Simple allow filter**: ~10-50 cycles per syscall
- **Complex filter**: ~50-200 cycles per syscall
- **User notification**: Context switch to supervisor process (thousands of cycles)

The `SECCOMP_FLAG_SPEC_ALLOW` flag (Linux 4.17+) disables the `SIGSYS` trap on speculation-based bypasses, important for Spectre mitigations.

### 8.6 Practical Examples

**Docker container seccomp profile:**
Docker uses seccomp to block approximately 44 of ~450 syscalls in containers, including:
- `reboot` — obviously dangerous
- `kexec_load` — load a new kernel
- `mount` — mount filesystems (use `bind` mount instead)
- `ptrace` — can be used to escape
- `userfaultfd` — can be exploited

**Chrome's sandbox:**
Chrome uses a multi-layer sandbox:
1. `fork()` a child with `CLONE_NEWPID | CLONE_NEWUSER`
2. Apply a restrictive seccomp filter
3. The child process can only use: `read`, `write`, `exit`, `exit_group`, `futex`, and a few others

---

## 9. Syscall Restart

### 9.1 The Restart Mechanism

When a syscall is interrupted by a signal, it may need to be restarted. The kernel uses the `orig_ax` field in `pt_regs` to track this:

```c
// In the syscall exit path:
if (syscall_exit_work(regs, step)) {
    // Check if syscall should be restarted
    if (regs->orig_ax != -1) {
        // Syscall was interrupted
        if (signal_restart_syscall(regs)) {
            regs->ax = regs->orig_ax;  // Restore syscall number
            regs->ip -= 2;  // Back up to re-execute syscall instruction
        }
    }
}
```

The `-ERESTARTSYS`, `-ERESTARTNOINTR`, `-ERESTARTNOHAND`, and `-ERESTART_RESTARTBLOCK` error codes are used internally to communicate restart decisions:

| Code | Meaning |
|------|---------|
| `-ERESTARTSYS` | Restart if no signal handler; otherwise return `-EINTR` |
| `-ERESTARTNOINTR` | Always restart (even if signal delivered) |
| `-ERESTARTNOHAND` | Restart only if no signal handler; otherwise return `-EINTR` |
| `-ERESTART_RESTARTBLOCK` | Use a different restart function (for complex cases like `nanosleep`) |

### 9.2 The `restart_block` Structure

For syscalls that need a different restart path (like `nanosleep` which needs to compute remaining time):

```c
struct restart_block {
    long (*fn)(struct restart_block *);
    union {
        struct { nanosleep args; } nanosleep;
        struct { futex args; } futex;
        // ...
    };
};
```

---

## 10. Syscall Tracing and Auditing

### 10.1 strace

`strace` uses `ptrace` to intercept syscalls:

```bash
$ strace ls
execve("/usr/bin/ls", ["ls"], 0x7ffd9a3b0b40 /* 52 vars */) = 0
brk(NULL)                               = 0x5590c7a3f000
access("/etc/ld.so.preload", R_OK)      = -1 ENOENT
openat(AT_FDCWD, "/etc/ld.so.cache", O_RDONLY|O_CLOEXEC) = 3
fstat(3, {st_mode=S_IFREG|0644, st_size=52749, ...}) = 0
mmap(NULL, 52749, PROT_READ, MAP_PRIVATE, 3, 0) = 0x7f8a8b2c0000
close(3)                                = 0
```

### 10.2 ftrace

The kernel's ftrace framework can trace syscalls without ptrace overhead:

```bash
# Trace all open syscalls
echo 1 > /sys/kernel/debug/tracing/events/syscalls/sys_enter_open/enable
cat /sys/kernel/debug/tracing/trace_pipe
```

### 10.3 Audit Subsystem

The Linux Audit framework logs syscalls for security compliance:

```bash
# Audit all file open syscalls
auditctl -a always,exit -F arch=b64 -S open -S openat
```

Audit adds significant overhead (~5-15% for syscall-heavy workloads) and is typically used only in compliance environments.

---

## 11. Performance Considerations

### 11.1 Syscall Overhead

| Mechanism | Approximate Cost | Notes |
|-----------|-----------------|-------|
| `int 0x80` | 100-200 cycles | Legacy 32-bit |
| `sysenter` | 50-80 cycles | 32-bit Intel optimization |
| `syscall` | 20-50 cycles | x86-64 standard |
| `svc #0` | 30-60 cycles | ARM64 |
| vDSO call | ~1-5 cycles | No kernel transition |

### 11.2 Minimizing Syscall Overhead

**Batching:** `io_uring` (Chapter 139) allows submitting multiple I/O operations with a single syscall, amortizing the transition cost.

**vDSO:** Use vDSO-backed functions where available (`gettimeofday`, `clock_gettime`).

**Avoid unnecessary syscalls:** Cache file descriptors, use `sendfile` instead of `read`+`write`, use `epoll` instead of `poll` for many file descriptors.

**Syscall user dispatch (Linux 5.11):** Allows user-space to handle certain syscalls without entering the kernel, used by Wine for Windows syscall emulation.

### 11.3 Speculation Barriers

After Spectre/Meltdown, syscall entry/exit includes additional barriers:

```asm
# On entry (mitigation for Meltdown):
# KPTI (Kernel Page Table Isolation) switches page tables
# This costs ~100-300 additional cycles per syscall

# On entry (Spectre mitigation):
# IBRS/IBPB/STIBP barriers may be applied
# Cost varies by CPU and mitigation level
```

---

## 12. Security Implications

### 12.1 Attack Surface

Each syscall is a potential attack vector. The kernel must:
- Validate all user pointers (`copy_from_user`/`copy_to_user`)
- Check permissions (capabilities, file permissions, namespace boundaries)
- Prevent integer overflows in size calculations
- Handle concurrent access properly (locking)

### 12.2 Notable Vulnerabilities

**CVE-2016-5195 (Dirty COW):** A race condition in the `madvise`/`write` path allowed unprivileged users to write to read-only files. The vulnerability existed for 9 years.

**CVE-2017-6074 (DCCP double-free):** A use-after-free in the DCCP socket syscall handlers allowed local privilege escalation.

**CVE-2021-4154 (cgroup v1):** A use-after-free in cgroup1 `write` syscall handlers.

### 12.3 Hardening Techniques

- **Stack canaries**: Protect against stack buffer overflows in syscall handlers
- **KASLR**: Kernel Address Space Layout Randomization
- **SMEP/SMAP**: Prevent kernel from executing/accessing user memory
- **KPTI**: Separate kernel/user page tables (Meltdown mitigation)
- **CFI**: Control Flow Integrity (prevents ROP/JOP attacks)
- **Lockdown LSM**: Restrict kernel self-modification

---

## 13. Assembly Calling Conventions

### 13.1 x86-64 Pure Assembly Example

```asm
section .data
    msg db "Hello, Linux!", 10
    len equ $ - msg

section .text
    global _start

_start:
    ; write(1, msg, len)
    mov rax, 1          ; syscall number for write
    mov rdi, 1          ; fd = stdout
    lea rsi, [rel msg]  ; pointer to message
    mov rdx, len        ; message length
    syscall
    
    ; exit(0)
    mov rax, 60         ; syscall number for exit
    xor rdi, rdi        ; exit code 0
    syscall
```

### 13.2 ARM64 Pure Assembly Example

```asm
.data
msg:    .ascii "Hello, Linux!\n"
len =   . - msg

.text
.global _start

_start:
    // write(1, msg, len)
    mov x8, #64         // syscall number for write on ARM64
    mov x0, #1          // fd = stdout
    ldr x1, =msg        // pointer to message
    mov x2, #len        // message length
    svc #0
    
    // exit(0)
    mov x8, #93         // syscall number for exit on ARM64
    mov x0, #0          // exit code
    svc #0
```

### 13.3 Inline Assembly in C (x86-64)

```c
static inline long syscall6(long nr, long a1, long a2, long a3,
                            long a4, long a5, long a6)
{
    long ret;
    register long r10 __asm__("r10") = a4;
    register long r8  __asm__("r8")  = a5;
    register long r9  __asm__("r9")  = a6;
    
    __asm__ volatile (
        "syscall"
        : "=a"(ret)
        : "a"(nr), "D"(a1), "S"(a2), "d"(a3),
          "r"(r10), "r"(r8), "r"(r9)
        : "rcx", "r11", "memory"
    );
    return ret;
}
```

---

## 14. Common Bugs and Pitfalls

### 14.1 Using `int 0x80` in 64-bit Code

```c
// WRONG: Using int 0x80 in 64-bit code
long result;
__asm__("int $0x80" : "=a"(result) : "a"(4), "b"(1), "c"(buf), "d"(len));
// Problem: int 0x80 truncates all registers to 32 bits!
// If buf is above 0xFFFFFFFF, the kernel gets a wrong pointer
```

### 14.2 Forgetting EINTR Handling

```c
// WRONG: Not handling EINTR
ssize_t n = read(fd, buf, sizeof(buf));
if (n < 0) {
    perror("read");  // May fail with EINTR on signal delivery
}

// CORRECT: Retry on EINTR
ssize_t n;
do {
    n = read(fd, buf, sizeof(buf));
} while (n < 0 && errno == EINTR);
```

### 14.3 Missing `-1` Error Check

```c
// WRONG: Checking for specific negative error codes
if (fd == -ENOENT) { ... }

// CORRECT: Check for -1 and use errno
if (fd < 0) {
    if (errno == ENOENT) { ... }
}
```

Syscalls return `-errno` in the raw return value (assembly level), but glibc wrappers convert this: they return `-1` and set `errno` to the positive error code.

### 14.4 TOCTOU (Time-of-Check-Time-of-Use) Races

```c
// WRONG: Check-then-use
if (access(filename, W_OK) == 0) {
    fd = open(filename, O_WRONLY);  // Race! File may have changed
}

// CORRECT: Use O_CREAT|O_EXCL or fstat after open
fd = open(filename, O_WRONLY | O_CREAT | O_EXCL, 0644);
```

---

## 15. Kernel Source References

- **Entry points**: `arch/x86/entry/entry_64.S`
- **Syscall table**: `arch/x86/entry/syscalls/syscall_64.tbl`
- **Syscall dispatch**: `arch/x86/entry/common.c`
- **Seccomp**: `kernel/seccomp.c`
- **vDSO**: `arch/x86/entry/vdso/`
- **ptrace/tracing**: `kernel/ptrace.c`, `include/trace/events/syscalls.h`
- **`SYSCALL_DEFINE` macros**: `include/linux/syscalls.h`
- **ARM64 entry**: `arch/arm64/kernel/entry.S`
- **Generic syscall headers**: `include/uapi/asm-generic/unistd.h`

---

## 16. Related Syscalls

- `syscall()` — glibc wrapper to invoke any syscall by number
- `prctl()` — Process control (used to set seccomp mode)
- `seccomp()` — Direct seccomp syscall (Linux 3.17+)
- `ptrace()` — Process tracing (used by strace)
- `perf_event_open()` — Performance monitoring

---

## 17. Summary

The Linux syscall architecture is a carefully engineered interface that balances performance, security, and compatibility. The evolution from `int 0x80` to `syscall`/`sysret` represents decades of optimization, reducing transition overhead from hundreds of cycles to tens. Modern features like seccomp, the vDSO, and io_uring continue to push the boundaries of what's possible at the user-kernel boundary.

Understanding this architecture is fundamental to:
- Writing high-performance systems code
- Debugging with strace and ftrace
- Implementing security sandboxes
- Kernel development and module writing
- Understanding container isolation mechanisms

The syscall interface is Linux's most stable ABI — the kernel developers take extreme care to never break it, making it a reliable foundation for decades of software.
