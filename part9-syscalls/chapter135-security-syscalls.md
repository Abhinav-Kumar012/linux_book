# Chapter 135: Security Syscalls

## 1. Introduction

Linux provides several syscalls for enforcing security policies, restricting capabilities, and confining processes. This chapter covers `seccomp`, `seccomp_unotify`, `landlock_*`, `capset`/`capget`, and `prctl` — the building blocks of Linux process security.

---

## 2. seccomp

### 2.1 Purpose

`seccomp` (Secure Computing Mode) restricts which syscalls a process can make. Originally designed for running untrusted code, it's now used by Chrome, Docker, Android, and many other projects.

### 2.2 Prototype

```c
#include <linux/seccomp.h>
int seccomp(unsigned int operation, unsigned int flags, void *args);
```

### 2.3 Operations

| Operation | Description |
|-----------|-------------|
| `SECCOMP_SET_MODE_STRICT` | Only allow read/write/exit/sigreturn |
| `SECCOMP_SET_MODE_FILTER` | Install BPF filter program |
| `SECCOMP_GET_ACTION_AVAIL` | Check if action is supported |
| `SECCOMP_GET_NOTIF_SIZES` | Get notification structure sizes |

### 2.4 Strict Mode

```c
seccomp(SECCOMP_SET_MODE_STRICT, 0, NULL);
// Now only read(), write(), exit(), sigreturn() are allowed
// Everything else kills the process
```

### 2.5 Filter Mode

```c
#include <linux/seccomp.h>
#include <linux/filter.h>
#include <linux/audit.h>
#include <sys/prctl.h>

struct sock_filter filter[] = {
    // Load syscall number
    BPF_STMT(BPF_LD | BPF_W | BPF_ABS, offsetof(struct seccomp_data, nr)),
    
    // Allow read (0)
    BPF_JUMP(BPF_JMP | BPF_JEQ | BPF_K, __NR_read, 0, 1),
    BPF_STMT(BPF_RET | BPF_K, SECCOMP_RET_ALLOW),
    
    // Allow write (1)
    BPF_JUMP(BPF_JMP | BPF_JEQ | BPF_K, __NR_write, 0, 1),
    BPF_STMT(BPF_RET | BPF_K, SECCOMP_RET_ALLOW),
    
    // Allow exit (60)
    BPF_JUMP(BPF_JMP | BPF_JEQ | BPF_K, __NR_exit, 0, 1),
    BPF_STMT(BPF_RET | BPF_K, SECCOMP_RET_ALLOW),
    
    // Allow exit_group (231)
    BPF_JUMP(BPF_JMP | BPF_JEQ | BPF_K, __NR_exit_group, 0, 1),
    BPF_STMT(BPF_RET | BPF_K, SECCOMP_RET_ALLOW),
    
    // Kill everything else
    BPF_STMT(BPF_RET | BPF_K, SECCOMP_RET_KILL_PROCESS),
};

struct sock_fprog prog = {
    .len = ARRAY_SIZE(filter),
    .filter = filter,
};

// Install filter
prctl(PR_SET_NO_NEW_PRIVS, 1, 0, 0, 0);  // Required before filter
seccomp(SECCOMP_SET_MODE_FILTER, 0, &prog);
```

### 2.6 Using libseccomp (Recommended)

```c
#include <seccomp.h>

int main(void)
{
    scmp_filter_ctx ctx = seccomp_init(SCMP_ACT_KILL_PROCESS);
    
    // Allow specific syscalls
    seccomp_rule_add(ctx, SCMP_ACT_ALLOW, SCMP_SYS(read), 0);
    seccomp_rule_add(ctx, SCMP_ACT_ALLOW, SCMP_SYS(write), 0);
    seccomp_rule_add(ctx, SCMP_ACT_ALLOW, SCMP_SYS(exit), 0);
    seccomp_rule_add(ctx, SCMP_ACT_ALLOW, SCMP_SYS(exit_group), 0);
    
    // Allow open only for reading
    seccomp_rule_add(ctx, SCMP_ACT_ALLOW, SCMP_SYS(open), 1,
        SCMP_A1(SCMP_CMP_EQ, O_RDONLY));
    
    // Load and apply
    seccomp_load(ctx);
    seccomp_release(ctx);
    
    // Now restricted
    return 0;
}
```

### 2.7 Return Actions

| Action | Description |
|--------|-------------|
| `SECCOMP_RET_KILL_PROCESS` | Kill entire process (SIGSYS) |
| `SECCOMP_RET_KILL_THREAD` | Kill calling thread |
| `SECCOMP_RET_TRAP` | Send SIGSYS to thread |
| `SECCOMP_RET_ERRNO` | Return specified errno |
| `SECCOMP_RET_USER_NOTIF` | Notify supervisor via fd |
| `SECCOMP_RET_TRACE` | Notify ptrace tracer |
| `SECCOMP_RET_LOG` | Allow and log |
| `SECCOMP_RET_ALLOW` | Allow |

### 2.8 Performance

- No filter: 0 overhead
- Simple filter: ~10-50 ns per syscall
- Complex filter: ~50-200 ns per syscall
- User notification: ~1-10 μs (context switch to supervisor)

---

## 3. seccomp_unotify (User Notification)

### 3.1 Purpose

`SECCOMP_RET_USER_NOTIF` allows a supervisor process to handle syscalls on behalf of a sandboxed process. The supervisor receives notifications via a file descriptor and can decide to allow or deny each syscall.

### 3.2 Creating a Notification FD

```c
int notify_fd = seccomp_notify_fd(ctx);  // After seccomp_init with SECCOMP_RET_USER_NOTIF

// Or using the syscall directly:
// seccomp(SECCOMP_GET_NOTIF_SIZES, 0, &sizes);
// seccomp(SECCOMP_SET_MODE_FILTER, SECCOMP_FILTER_FLAG_NEW_LISTENER, &prog);
```

### 3.3 Receiving Notifications

```c
struct seccomp_notif *req;
struct seccomp_notif_resp *resp;

seccomp_notify_alloc(&req, &resp);

while (1) {
    // Wait for notification
    if (seccomp_notify_receive(notify_fd, req) < 0)
        break;
    
    // Inspect the syscall
    printf("Syscall %llu from PID %d\n", req->data.nr, req->pid);
    
    // Handle the syscall
    resp->id = req->id;
    resp->val = 0;  // Return value
    resp->error = 0; // No error
    resp->flags = SECCOMP_USER_NOTIF_FLAG_CONTINUE; // Let kernel handle it
    
    seccomp_notify_respond(notify_fd, resp);
}

seccomp_notify_free(req, resp);
```

### 3.4 Use Cases

- **Container runtimes**: Intercept `mount`, `pivot_root` etc. for rootless containers
- **Sandboxing**: File access mediation
- **Testing**: Mock syscall results

---

## 4. landlock_* (Linux 5.13+)

### 4.1 Purpose

Landlock is an unprivileged security module that allows processes to restrict their own filesystem and network access. Unlike seccomp, it's designed to be composable and doesn't require BPF programming.

### 4.2 Syscalls

```c
int landlock_create_ruleset(const struct landlock_ruleset_attr *attr, size_t size, __u32 flags);
int landlock_add_rule(int ruleset_fd, enum landlock_rule_type rule_type,
                      const void *rule_attr, __u32 flags);
int landlock_restrict_self(int ruleset_fd, __u32 flags);
```

### 4.3 Example

```c
#include <linux/landlock.h>
#include <sys/syscall.h>
#include <fcntl.h>

int main(void)
{
    // Create ruleset with filesystem access rights
    struct landlock_ruleset_attr attr = {
        .handled_access_fs = LANDLOCK_ACCESS_FS_READ_FILE |
                             LANDLOCK_ACCESS_FS_WRITE_FILE |
                             LANDLOCK_ACCESS_FS_EXECUTE |
                             LANDLOCK_ACCESS_FS_READ_DIR |
                             LANDLOCK_ACCESS_FS_REMOVE_FILE |
                             LANDLOCK_ACCESS_FS_MAKE_REG |
                             LANDLOCK_ACCESS_FS_MAKE_DIR,
    };
    
    int ruleset_fd = syscall(__NR_landlock_create_ruleset, &attr, sizeof(attr), 0);
    
    // Allow read access to /usr
    struct landlock_path_beneath_attr path_attr = {
        .allowed_access = LANDLOCK_ACCESS_FS_READ_FILE |
                          LANDLOCK_ACCESS_FS_READ_DIR,
        .parent_fd = open("/usr", O_PATH | O_CLOEXEC),
    };
    
    syscall(__NR_landlock_add_rule, ruleset_fd, LANDLOCK_RULE_PATH_BENEATH,
            &path_attr, 0);
    
    // Allow read/write to /tmp
    path_attr.allowed_access = LANDLOCK_ACCESS_FS_READ_FILE |
                               LANDLOCK_ACCESS_FS_WRITE_FILE |
                               LANDLOCK_ACCESS_FS_READ_DIR |
                               LANDLOCK_ACCESS_FS_MAKE_REG;
    path_attr.parent_fd = open("/tmp", O_PATH | O_CLOEXEC);
    syscall(__NR_landlock_add_rule, ruleset_fd, LANDLOCK_RULE_PATH_BENEATH,
            &path_attr, 0);
    
    // Apply restrictions
    prctl(PR_SET_NO_NEW_PRIVS, 1, 0, 0, 0);
    syscall(__NR_landlock_restrict_self, ruleset_fd, 0);
    
    close(ruleset_fd);
    
    // Now restricted:
    // - Can read /usr/*
    // - Can read/write /tmp/*
    // - Cannot access anything else
    
    return 0;
}
```

### 4.4 Access Rights

**Filesystem:**
- `LANDLOCK_ACCESS_FS_READ_FILE` — Read files
- `LANDLOCK_ACCESS_FS_WRITE_FILE` — Write files
- `LANDLOCK_ACCESS_FS_EXECUTE` — Execute files
- `LANDLOCK_ACCESS_FS_READ_DIR` — List directories
- `LANDLOCK_ACCESS_FS_REMOVE_FILE` — Delete files
- `LANDLOCK_ACCESS_FS_MAKE_REG` — Create regular files
- `LANDLOCK_ACCESS_FS_MAKE_DIR` — Create directories
- `LANDLOCK_ACCESS_FS_MAKE_SOCK` — Create sockets
- `LANDLOCK_ACCESS_FS_MAKE_FIFO` — Create FIFOs
- `LANDLOCK_ACCESS_FS_MAKE_BLOCK` — Create block devices
- `LANDLOCK_ACCESS_FS_MAKE_SYM` — Create symlinks
- `LANDLOCK_ACCESS_FS_REFER` — Link/rename across directories (v2)

**Network (v2):**
- `LANDLOCK_ACCESS_NET_BIND_TCP` — Bind TCP sockets
- `LANDLOCK_ACCESS_NET_CONNECT_TCP` — Connect TCP sockets

### 4.5 Advantages

- **Unprivileged**: No root or capabilities needed
- **Composable**: Multiple layers of restrictions
- **Persistent**: Restrictions survive `exec`
- **No BPF**: Simple API, no filter programming

---

## 5. capset / capget

### 5.1 Purpose

These syscalls get and set thread capabilities — the fine-grained privilege model that replaces setuid-root.

### 5.2 Prototype

```c
#include <sys/capability.h>
int capget(cap_user_header_t hdrp, cap_user_data_t datap);
int capset(cap_user_header_t hdrp, const cap_user_data_t datap);
```

### 5.3 Capability Sets

Each thread has three capability sets:
- **Permitted (`CAP_PERMITTED`)**: Capabilities the thread may assume
- **Effective (`CAP_EFFECTIVE`)**: Capabilities currently in effect
- **Inheritable (`CAP_INHERITABLE`)**: Capabilities preserved across `exec`

### 5.4 Common Capabilities

| Capability | Description |
|------------|-------------|
| `CAP_NET_BIND_SERVICE` | Bind to ports < 1024 |
| `CAP_NET_RAW` | Use raw sockets |
| `CAP_SYS_ADMIN` | Wide-ranging admin operations |
| `CAP_SYS_PTRACE` | Trace other processes |
| `CAP_SYS_TIME` | Set system clock |
| `CAP_DAC_OVERRIDE` | Bypass file permission checks |
| `CAP_CHOWN` | Change file ownership |
| `CAP_KILL` | Send signals to any process |
| `CAP_SYS_NICE` | Change scheduling priorities |
| `CAP_MKNOD` | Create device files |
| `CAP_SETUID`/`CAP_SETGID` | Change UID/GID |

### 5.5 Example: Drop Privileges

```c
#include <sys/capability.h>
#include <sys/prctl.h>

int drop_capabilities(void)
{
    // Read current capabilities
    struct __user_cap_header_struct hdr = { _LINUX_CAPABILITY_VERSION_3, 0 };
    struct __user_cap_data_struct data[2] = {};
    
    if (capget(&hdr, data) < 0) return -1;
    
    // Keep only what we need
    data[0].permitted = (1 << CAP_NET_BIND_SERVICE);
    data[0].effective = (1 << CAP_NET_BIND_SERVICE);
    data[1].permitted = 0;
    data[1].effective = 0;
    
    if (capset(&hdr, data) < 0) return -1;
    
    // Lock capabilities (prevent regaining)
    prctl(PR_SET_SECUREBITS, SECBIT_NOROOT | SECBIT_NOROOT_LOCKED);
    
    return 0;
}
```

### 5.6 libcap

The recommended library for capability manipulation:

```c
#include <sys/capability.h>

cap_t caps = cap_get_proc();
cap_value_t cap_list[] = { CAP_NET_BIND_SERVICE };
cap_set_flag(caps, CAP_EFFECTIVE, 1, cap_list, CAP_SET);
cap_set_flag(caps, CAP_PERMITTED, 1, cap_list, CAP_SET);
cap_set_proc(caps);
cap_free(caps);
```

---

## 6. prctl

### 6.1 Purpose

`prctl` (process control) is a multipurpose syscall for various process operations, many security-related.

### 6.2 Prototype

```c
#include <sys/prctl.h>
int prctl(int option, unsigned long arg2, unsigned long arg3,
          unsigned long arg4, unsigned long arg5);
```

### 6.3 Security-Related Operations

| Option | Description |
|--------|-------------|
| `PR_SET_NO_NEW_PRIVS` | Prevent privilege gain from exec |
| `PR_GET_NO_NEW_PRIVS` | Check no_new_privs flag |
| `PR_SET_SECUREBITS` | Set secure bits (capability restrictions) |
| `PR_GET_SECUREBITS` | Get secure bits |
| `PR_SET_SECCOMP` | Enable seccomp mode |
| `PR_SET_DUMPABLE` | Enable/disable core dumps |
| `PR_SET_NAME` | Set process name |
| `PR_SET_PTRACER` | Allow specific PID to ptrace |
| `PR_SET_MM_MAP` | Set memory map info |
| `PR_SET_TIMERSLACK` | Set timer slack (nanoseconds) |
| `PR_SET_CHILD_SUBREAPER` | Become subreaper for orphaned children |

### 6.4 PR_SET_NO_NEW_PRIVS

This is critical for security — it prevents a process from gaining privileges through `execve` (e.g., setuid binaries):

```c
prctl(PR_SET_NO_NEW_PRIVS, 1, 0, 0, 0);
// Now execve of setuid binaries won't grant extra privileges
// Required before installing seccomp filters
```

### 6.5 PR_SET_SECUREBITS

```c
// Prevent root from gaining capabilities
prctl(PR_SET_SECUREBITS,
      SECBIT_NOROOT |           // setuid-root doesn't grant caps
      SECBIT_NOROOT_LOCKED |    // Can't change NOROOT
      SECBIT_NO_SETUID_FIXUP |  // setuid doesn't change caps
      SECBIT_NO_SETUID_FIXUP_LOCKED);
```

---

## 7. Security Architecture

### 7.1 Defense in Depth

A typical secure application uses multiple layers:

```
┌─────────────────────────────────────────┐
│         Application Code                 │
├─────────────────────────────────────────┤
│  PR_SET_NO_NEW_PRIVS = 1                │
├─────────────────────────────────────────┤
│  Landlock (filesystem restrictions)      │
├─────────────────────────────────────────┤
│  seccomp filter (syscall restrictions)   │
├─────────────────────────────────────────┤
│  Capability drop (capset)                │
├─────────────────────────────────────────┤
│  Namespace isolation (CLONE_NEW*)        │
├─────────────────────────────────────────┤
│  Kernel                                 │
└─────────────────────────────────────────┘
```

### 7.2 Order of Operations

1. `prctl(PR_SET_NO_NEW_PRIVS, 1)` — Prevent privilege escalation
2. `landlock_restrict_self()` — Restrict filesystem/network access
3. `seccomp()` — Install syscall filter
4. `capset()` — Drop unnecessary capabilities

---

## 8. Common Bugs

```c
// BUG: Not setting no_new_privs before seccomp
seccomp(SECCOMP_SET_MODE_FILTER, 0, &prog);  // EPERM!
// FIX: Set no_new_privs first
prctl(PR_SET_NO_NEW_PRIVS, 1, 0, 0, 0);
seccomp(SECCOMP_SET_MODE_FILTER, 0, &prog);

// BUG: Forgetting to allow exit in seccomp filter
// Process can't terminate and hangs forever!
// FIX: Always allow exit and exit_group

// BUG: Landlock without no_new_privs
landlock_restrict_self(ruleset_fd, 0);  // EPERM!
// FIX: Set no_new_privs first
```

---

## 9. Kernel Source References

- **seccomp**: `kernel/seccomp.c`
- **Landlock**: `security/landlock/`
- **Capabilities**: `kernel/capability.c`, `security/commoncap.c`
- **prctl**: `kernel/sys.c`
- **Securebits**: `include/linux/securebits.h`

---

## 10. Summary

Security syscalls provide the building blocks for process confinement:
- **`seccomp`**: Restrict syscalls via BPF filters
- **`seccomp_unotify`**: Supervisor-mediated syscall handling
- **`landlock_*`**: Unprivileged filesystem/network restrictions
- **`capset`/`capget`**: Fine-grained capability management
- **`prctl`**: Process control (no_new_privs, securebits, etc.)

Combining these mechanisms provides defense-in-depth security for containerized and sandboxed applications.

---

## 11. Detailed Security Internals

### 11.1 Linux Security Modules (LSM) Framework

The syscall security hooks are implemented through the LSM framework. Every security-related syscall passes through LSM hooks:

```c
// In the syscall path:
static inline int security_file_open(struct file *file)
{
    return call_int_hook(file_open, file);
}

// LSM hook chain
#define call_int_hook(FUNC, ...) ({                        \
    int RC = 0;                                            \
    do {                                                   \
        struct security_hook_list *P;                      \
        hlist_for_each_entry(P, &security_hook_heads.FUNC, list) { \
            RC = P->hook.FUNC(__VA_ARGS__);               \
            if (RC != 0)                                  \
                break;                                     \
        }                                                  \
        RC;                                                \
    })
```

Active LSMs include SELinux, AppArmor, Smack, TOMOYO, and Landlock. Multiple LSMs can be stacked (LSM stacking, Linux 5.1+).

### 11.2 Capability Checking in Detail

When the kernel checks capabilities:

```c
bool capable(int cap)
{
    struct user_namespace *ns = current_user_ns();
    
    // Check if the task has the capability in its effective set
    if (security_capable(current_cred(), ns, cap, CAP_OPT_NONE) != 0)
        return false;
    
    // Audit the capability use
    audit_cap(cap, true);
    return true;
}
```

**Three capability sets in detail:**

- **Permitted**: The limiting superset. A thread can never gain capabilities beyond its permitted set.
- **Effective**: The capabilities actually used for permission checks. Can be toggled on/off within the permitted set.
- **Inheritable**: Capabilities preserved across `execve`. Combined with the file's inheritable set.

**Capability transformation during exec:**
```
P'(permitted)   = (P(inheritable) & F(inheritable)) | (F(permitted) & P(bounding)) | P'(ambient)
P'(effective)   = F(effective) ? P'(permitted) : P'(ambient)
P'(inheritable) = P(inheritable)
```

### 11.3 Seccomp BPF Filter Optimization

The kernel optimizes seccomp BPF filters:

```c
// BPF JIT compilation for seccomp
// Filters are compiled to native code for faster evaluation
// This happens on first use (lazy compilation)
```

**Filter ordering:**
Filters are evaluated in reverse order (most recently installed first). This allows layered security:

```c
// Layer 1 (installed first): Basic restrictions
// Layer 2 (installed later): Additional restrictions
// Evaluation: Layer 2 → Layer 1
```

### 11.4 seccomp User Notification Deep Dive

The user notification mechanism allows a supervisor process to intercept syscalls:

```c
// Supervisor side:
struct seccomp_notif *req;
struct seccomp_notif_resp *resp;

// Receive notification
ioctl(notify_fd, SECCOMP_IOCTL_NOTIF_RECV, req);

// The notification contains:
// - req->pid: PID of the target process
// - req->data.nr: Syscall number
// - req->data.args[6]: Syscall arguments
// - req->data.arch: Architecture
// - req->data.instruction_pointer: Where the syscall was made

// Respond (allow/deny)
resp->id = req->id;
resp->error = 0;  // or -EPERM to deny
resp->val = 0;    // Return value
ioctl(notify_fd, SECCOMP_IOCTL_NOTIF_SEND, resp);
```

### 11.5 Landlock Internals

Landlock uses a layered access control model:

```c
struct landlock_ruleset {
    struct rb_root root;           // Rules indexed by hierarchy
    u32 num_rules;
    u33 num_layers;               // Number of rule layers
    u32 access_masks[];           // Access rights per layer
};

struct landlock_rule {
    struct rb_node node;
    struct landlock_layer *layers;
    u32 num_layers;
    struct path fs_path;          // Filesystem path
};
```

Layers are additive: access is granted if ANY layer allows it. This means child processes can add more restrictive layers but cannot remove existing restrictions.

### 11.6 The securebits Mechanism

Securebits control capability inheritance across UID changes:

```c
#define SECBIT_NOROOT           (1 << 0)  // setuid-root doesn't grant caps
#define SECBIT_NOROOT_LOCKED    (1 << 1)  // Can't change NOROOT
#define SECBIT_NO_SETUID_FIXUP  (1 << 2)  // setuid doesn't change caps
#define SECBIT_NO_SETUID_FIXUP_LOCKED (1 << 3)
#define SECBIT_KEEP_CAPS        (1 << 4)  // Keep caps across setuid
#define SECBIT_KEEP_CAPS_LOCKED (1 << 5)
```

**Typical secure container setup:**
```c
prctl(PR_SET_SECUREBITS,
      SECBIT_NOROOT |
      SECBIT_NOROOT_LOCKED |
      SECBIT_NO_SETUID_FIXUP |
      SECBIT_NO_SETUID_FIXUP_LOCKED |
      SECBIT_KEEP_CAPS |
      SECBIT_KEEP_CAPS_LOCKED);
```

### 11.7 Ambient Capabilities

Ambient capabilities (Linux 4.3+) are preserved across `execve` without requiring file capabilities:

```c
// Set ambient capabilities
prctl(PR_CAP_AMBIENT, PR_CAP_AMBIENT_RAISE, CAP_NET_BIND_SERVICE, 0, 0);

// Requirements:
// - Must be in the permitted and inheritable sets
// - Must have no_new_privs set (or be root in the user namespace)
```

### 11.8 Seccomp and ptrace Interaction

When a process is being traced with ptrace, seccomp notifications can be intercepted:

```c
// With PTRACE_O_TRACESECCOMP:
ptrace(PTRACE_SETOPTIONS, child, 0, PTRACE_O_TRACESECCOMP);

// Seccomp events will stop the child with PTRACE_EVENT_SECCOMP
// The tracer can inspect the syscall and modify the return value
```

This is used by tools like `strace` and container runtimes to intercept and mediate syscalls.

### 11.9 BPF LSM (BPF-based Security)

Linux 5.7+ allows attaching BPF programs to LSM hooks:

```c
SEC("lsm/bprm_creds_from_file")
int BPF_PROG(restrict_exec, struct linux_binprm *bprm, struct file *file)
{
    // Check if the binary is allowed to execute
    char comm[16];
    bpf_get_current_comm(comm, sizeof(comm));
    
    // Block execution of certain binaries
    if (comm[0] == 's' && comm[1] == 'h')
        return -EPERM;
    
    return 0;
}
```

BPF LSM provides programmable security policy without kernel module development.

### 11.10 Security Audit Framework

The Linux Audit framework provides security event logging:

```c
// Audit rules for syscalls
// /etc/audit/audit.rules or via auditctl

// Log all file opens
auditctl -a always,exit -F arch=b64 -S open -S openat -k file_access

// Log all failed permission checks
auditctl -a always,exit -F arch=b64 -S access -F success=0 -k access_fail

// Log capability use
auditctl -a always,exit -F arch=b64 -S capset -k capability_change
```

**Audit record structure:**
```c
struct audit_context {
    int dummy;
    enum audit_state state;
    enum audit_state current_state;
    unsigned int serial;
    struct timespec ctime;
    // ...
};
```

### 11.11 Yama Security Module

Yama restricts ptrace access:

```bash
# /proc/sys/kernel/yama/ptrace_scope
# 0: No restrictions (classic behavior)
# 1: Restricted (only parent can ptrace child)
# 2: Admin-only (only CAP_SYS_PTRACE can ptrace)
# 3: No ptrace at all
```

This prevents processes from debugging or inspecting other processes owned by different users.

### 11.12 Capability Bounding Set

The capability bounding set limits which capabilities can be gained through setuid:

```c
// Drop CAP_SYS_ADMIN from the bounding set
prctl(PR_CAP_BSET_DROP, CAP_SYS_ADMIN, 0, 0, 0);

// Once dropped, it cannot be regained (even by root)
// This is permanent for the lifetime of the process
```

**Common practice for containers:**
```c
// Drop dangerous capabilities from bounding set
prctl(PR_CAP_BSET_DROP, CAP_SYS_ADMIN, 0, 0, 0);
prctl(PR_CAP_BSET_DROP, CAP_SYS_MODULE, 0, 0, 0);
prctl(PR_CAP_BSET_DROP, CAP_SYS_RAWIO, 0, 0, 0);
prctl(PR_CAP_BSET_DROP, CAP_SYS_PTRACE, 0, 0, 0);
prctl(PR_CAP_BSET_DROP, CAP_NET_ADMIN, 0, 0, 0);
```

### 11.13 Secure Attention Key (SAK)

SAK provides a secure way to ensure you're talking to the real login prompt:

```bash
# Enable SAK (SysRq + k)
echo 1 > /proc/sys/kernel/sysrq
# Press Alt+SysRq+k to kill all processes on the current terminal
```

This prevents keylogger attacks on login prompts.

### 11.14 Filesystem Capabilities (Extended Attributes)

File capabilities are stored as extended attributes:

```bash
# Set file capabilities
setcap cap_net_bind_service=ep /usr/bin/myserver

# Get file capabilities
getcap /usr/bin/myserver
# /usr/bin/myserver = cap_net_bind_service+ep

# Capability format:
# cap_name=flags
# e: effective (enabled on exec)
# p: permitted (in permitted set on exec)
# i: inheritable (in inheritable set on exec)
```

### 11.15 Security Module Stacking

Linux 5.1+ supports stacking multiple LSMs:

```bash
# Check active LSMs
cat /sys/kernel/security/lsm
# "lockdown,capability,yama,apparmor,landlock"

# Each LSM provides different protections:
# capability: Basic capability checks
# yama: ptrace restrictions
# apparmor: Path-based access control
# landlock: Unprivileged filesystem restrictions
# selinux: Label-based mandatory access control
```

### 11.16 seccomp Notify with Container Escape Prevention

When using seccomp user notification for container runtimes:

```c
// Supervisor process:
// 1. Install seccomp filter with SECCOMP_RET_USER_NOTIF
// 2. Receive notifications for sensitive syscalls
// 3. Validate the request against container policy
// 4. Respond with allow/deny

// Critical: The supervisor must validate:
// - Syscall arguments (file paths, flags, etc.)
// - Process identity (PID, UID, capabilities)
// - Namespace context
// - File descriptors (prevent fd-based escapes)
```

### 11.17 The lockdown LSM

The lockdown LSM (Linux 5.4+) restricts kernel self-modification:

```bash
# Enable lockdown
echo integrity > /sys/kernel/security/lockdown
# Or: echo confidentiality

# Restricts:
# - Loading unsigned kernel modules
# - kexec of unsigned kernels
# - hibernation with unsigned kernel
# - Access to /dev/mem, /dev/kmem
# - BPF that can read kernel memory
# - Kernel image modifications
```

### 11.18 Security Best Practices Summary

1. **Always set `no_new_privs`** before installing seccomp filters
2. **Drop capabilities** as early as possible in process initialization
3. **Use Landlock** for filesystem restrictions (simpler than SELinux)
4. **Stack security mechanisms**: capabilities + seccomp + namespaces
5. **Audit security events** in production environments
6. **Keep seccomp filters simple** to avoid performance overhead
7. **Test seccomp filters thoroughly** — they can break applications
8. **Use `PR_SET_SECUREBITS`** to prevent capability inheritance
9. **Set `PR_SET_DUMPABLE` to 0** to prevent core dumps of sensitive data
10. **Consider Yama** for ptrace restrictions in multi-user systems
