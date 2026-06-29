# Chapter 136: Namespace Syscalls

## 1. Introduction

Linux namespaces provide the kernel mechanism for isolating system resources. They are the foundation of containers (Docker, LXC, Kubernetes pods). This chapter covers `unshare`, `setns`, and `clone` with `CLONE_NEW*` flags — the syscalls that create and manage namespaces.

---

## 2. Overview of Namespace Types

| Namespace | Flag | Isolates | Since |
|-----------|------|----------|-------|
| Mount | `CLONE_NEWNS` | Mount points | 2.4.19 |
| UTS | `CLONE_NEWUTS` | Hostname, domainname | 2.6.19 |
| IPC | `CLONE_NEWIPC` | System V IPC, POSIX message queues | 2.6.19 |
| PID | `CLONE_NEWPID` | Process IDs | 2.6.24 |
| Network | `CLONE_NEWNET` | Network devices, stacks, ports | 2.6.29 |
| User | `CLONE_NEWUSER` | User/group IDs | 3.8 |
| Cgroup | `CLONE_NEWCGROUP` | Cgroup root directory | 4.6 |
| Time | `CLONE_NEWTIME` | Boot and monotonic clocks | 5.6 |

---

## 3. unshare

### 3.1 Purpose

`unshare` disassociates parts of the calling process's execution context, creating new namespaces without creating a new process.

### 3.2 Prototype

```c
#define _GNU_SOURCE
#include <sched.h>
int unshare(int flags);
```

### 3.3 Arguments

Same `CLONE_NEW*` flags as `clone`.

### 3.4 Behavior

After `unshare`, the calling process has new private copies of the specified resources. For PID namespace, a new process (via `fork`) is needed to get a PID 1 in the new namespace.

### 3.5 Example: Network Namespace

```c
#define _GNU_SOURCE
#include <sched.h>
#include <stdio.h>
#include <sys/wait.h>
#include <unistd.h>

int main(void)
{
    printf("Before unshare: PID=%d\n", getpid());
    
    // Create new network namespace
    if (unshare(CLONE_NEWNET) < 0) {
        perror("unshare");
        return 1;
    }
    
    // Now in a new network namespace
    system("ip link show");  // Only has loopback
    
    return 0;
}
```

### 3.6 Example: PID Namespace

```c
#define _GNU_SOURCE
#include <sched.h>
#include <stdio.h>
#include <sys/wait.h>
#include <unistd.h>

int main(void)
{
    // Create new PID namespace
    if (unshare(CLONE_NEWPID) < 0) {
        perror("unshare");
        return 1;
    }
    
    // Fork to get PID 1 in new namespace
    pid_t pid = fork();
    if (pid == 0) {
        // This is PID 1 in the new PID namespace
        printf("New PID namespace: my PID is %d\n", getpid());
        
        // Fork another process
        pid_t child = fork();
        if (child == 0) {
            printf("Child: PID=%d, PPID=%d\n", getpid(), getppid());
            _exit(0);
        }
        wait(NULL);
        _exit(0);
    }
    
    wait(NULL);
    return 0;
}
```

### 3.7 Example: User Namespace

```c
#define _GNU_SOURCE
#include <sched.h>
#include <stdio.h>
#include <sys/wait.h>
#include <unistd.h>

int main(void)
{
    printf("Before: UID=%d, GID=%d\n", getuid(), getgid());
    
    if (unshare(CLONE_NEWUSER) < 0) {
        perror("unshare");
        return 1;
    }
    
    // Map current UID/GID to root in new namespace
    // Write to /proc/self/uid_map and /proc/self/gid_map
    FILE *f = fopen("/proc/self/uid_map", "w");
    fprintf(f, "0 %d 1\n", getuid());
    fclose(f);
    
    // For gid_map, first deny setgroups
    f = fopen("/proc/self/setgroups", "w");
    fprintf(f, "deny\n");
    fclose(f);
    
    f = fopen("/proc/self/gid_map", "w");
    fprintf(f, "0 %d 1\n", getgid());
    fclose(f);
    
    // Now we're root in the new user namespace
    printf("After: UID=%d, GID=%d\n", getuid(), getgid());
    
    return 0;
}
```

### 3.8 Kernel Implementation

```c
SYSCALL_DEFINE1(unshare, unsigned long, unshare_flags)
{
    return ksys_unshare(unshare_flags);
}
```

The kernel creates new namespace structures and updates the task's namespace references.

---

## 4. setns

### 4.1 Purpose

`setns` allows a process to join an existing namespace. The namespace is referenced by a file descriptor (obtained from `/proc/[pid]/ns/*`).

### 4.2 Prototype

```c
#define _GNU_SOURCE
#include <sched.h>
int setns(int fd, int nstype);
```

### 4.3 Arguments

- **`fd`**: File descriptor referring to a namespace (from `/proc/[pid]/ns/*`)
- **`nstype`**: Namespace type (0 = any, or `CLONE_NEW*` to verify type)

### 4.4 Namespace File Descriptors

Each process's namespaces are represented as files in `/proc/[pid]/ns/`:

```bash
$ ls -la /proc/1/ns/
lrwxrwxrwx 1 root root 0 ... cgroup -> 'cgroup:[4026531835]'
lrwxrwxrwx 1 root root 0 ... ipc -> 'ipc:[4026531839]'
lrwxrwxrwx 1 root root 0 ... mnt -> 'mnt:[4026531840]'
lrwxrwxrwx 1 root root 0 ... net -> 'net:[4026531969]'
lrwxrwxrwx 1 root root 0 ... pid -> 'pid:[4026531836]'
lrwxrwxrwx 1 root root 0 ... user -> 'user:[4026531837]'
lrwxrwxrwx 1 root root 0 ... uts -> 'uts:[4026531838]'
```

Opening these files returns a file descriptor that can be used with `setns`.

### 4.5 Example: Enter Existing Network Namespace

```c
#define _GNU_SOURCE
#include <sched.h>
#include <fcntl.h>
#include <stdio.h>

int main(int argc, char *argv[])
{
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <pid>\n", argv[0]);
        return 1;
    }
    
    // Open the target process's network namespace
    char path[256];
    snprintf(path, sizeof(path), "/proc/%s/ns/net", argv[1]);
    int fd = open(path, O_RDONLY | O_CLOEXEC);
    if (fd < 0) { perror("open"); return 1; }
    
    // Join the namespace
    if (setns(fd, CLONE_NEWNET) < 0) {
        perror("setns");
        return 1;
    }
    
    // Now in the same network namespace as the target process
    system("ip link show");
    
    return 0;
}
```

### 4.6 Kernel Implementation

```c
SYSCALL_DEFINE2(setns, int, fd, int, nstype)
{
    struct file *file;
    struct ns_common *ns;
    
    file = fget(fd);
    ns = get_proc_ns(file->private_data);
    
    // Verify namespace type if specified
    if (nstype && ns->ops->type != nstype)
        return -EINVAL;
    
    // Switch to the new namespace
    return switch_task_namespaces(current, ns);
}
```

---

## 5. clone with CLONE_NEW* Flags

### 5.1 Purpose

`clone` can create a new process in new namespaces simultaneously. This is the most common way to create containers.

### 5.2 Example: Container-like Setup

```c
#define _GNU_SOURCE
#include <sched.h>
#include <stdio.h>
#include <sys/wait.h>
#include <unistd.h>
#include <sys/mount.h>
#include <sys/syscall.h>

#define STACK_SIZE (1024 * 1024)

static int container_func(void *arg)
{
    // Set hostname
    sethostname("container", 9);
    
    // Mount proc filesystem
    mount("proc", "/proc", "proc", 0, NULL);
    
    // Show isolated view
    printf("Hostname: ");
    system("hostname");
    printf("Processes:\n");
    system("ps aux");
    
    umount("/proc");
    return 0;
}

int main(void)
{
    char *stack = malloc(STACK_SIZE);
    
    int flags = CLONE_NEWPID | CLONE_NEWNS | CLONE_NEWUTS | CLONE_NEWIPC | SIGCHLD;
    
    pid_t pid = clone(container_func, stack + STACK_SIZE, flags, NULL);
    if (pid < 0) { perror("clone"); return 1; }
    
    waitpid(pid, NULL, 0);
    free(stack);
    return 0;
}
```

### 5.3 Combining Multiple Namespaces

```c
// Create a process with full container isolation
int flags = CLONE_NEWPID    // New PID namespace
          | CLONE_NEWNS     // New mount namespace
          | CLONE_NEWNET    // New network namespace
          | CLONE_NEWUTS    // New UTS namespace (hostname)
          | CLONE_NEWIPC    // New IPC namespace
          | CLONE_NEWUSER   // New user namespace
          | CLONE_NEWCGROUP // New cgroup namespace
          | SIGCHLD;        // Signal on child exit

pid_t pid = clone(container_main, stack + STACK_SIZE, flags, NULL);
```

---

## 6. User Namespaces

### 6.1 User Namespace Mapping

User namespaces allow unprivileged users to create isolated environments where they appear as root. The mapping is configured via `/proc/[pid]/uid_map` and `/proc/[pid]/gid_map`.

**Format:** `ID-inside-ns ID-outside-ns count`

```
# Map UID 0 (root) inside namespace to UID 1000 outside
0 1000 1
```

### 6.2 Security Properties

- User namespaces grant all capabilities inside the namespace
- But the user is still unprivileged outside
- Filesystem access is checked against the outside UID
- Network operations require `CLONE_NEWNET` as well

### 6.3 Security Risks

User namespaces have been controversial because they expose kernel attack surface:
- Many kernel bugs become exploitable with user namespaces
- Some distributions disable unprivileged user namespaces
- `/proc/sys/kernel/unprivileged_userns_clone` controls this (Debian)

---

## 7. Mount Namespaces

### 7.1 Purpose

Mount namespaces isolate the set of filesystem mount points. Changes in one namespace don't affect others.

### 7.2 Propagation Types

| Type | Description |
|------|-------------|
| `MS_SHARED` | Mount events propagate to/from peers |
| `MS_PRIVATE` | No propagation |
| `MS_SLAVE` | Receives propagation from master, doesn't propagate back |
| `MS_UNBINDABLE` | Can't be bind mounted |

### 7.3 Example

```c
// Create private mount namespace
unshare(CLONE_NEWNS);

// Make all mounts private (prevent propagation)
mount(NULL, "/", NULL, MS_REC | MS_PRIVATE, NULL);

// Mount overlayfs for root filesystem
mount("overlay", "/new_root", "overlay", 0,
      "lowerdir=/lower,upperdir=/upper,workdir=/work");

// pivot_root to the new root
```

---

## 8. Network Namespaces

### 8.1 Purpose

Network namespaces provide isolated network stacks — each namespace has its own interfaces, routing tables, firewall rules, and port numbers.

### 8.2 Virtual Ethernet (veth) Pairs

```bash
# Create veth pair connecting two namespaces
ip link add veth0 type veth peer name veth1
ip link set veth1 netns <pid>

# Configure addresses
ip addr add 10.0.0.1/24 dev veth0
ip link set veth0 up
```

### 8.3 Programmatic Setup

```c
#define _GNU_SOURCE
#include <sched.h>
#include <sys/socket.h>
#include <linux/netlink.h>
#include <linux/rtnetlink.h>

// Use netlink to create veth pairs and configure networking
// This is how Docker/libnetwork sets up container networking
```

---

## 9. PID Namespaces

### 9.1 Properties

- PID namespace creates a new set of PIDs
- The first process in a PID namespace gets PID 1
- PID 1 has special responsibilities (reaping orphans)
- Processes in different namespaces can have the same PID
- `/proc/[pid]/ns/pid` shows the namespace inode

### 9.2 PID 1 Responsibilities

```c
// In PID 1 of a new namespace
while (1) {
    pid_t pid = waitpid(-1, &status, 0);
    if (pid < 0) break;
    // Reap children — PID 1 must do this or zombies accumulate
}
```

---

## 10. Security Implications

- **Namespace escape**: Properly securing namespaces requires mount namespace + pivot_root + seccomp
- **User namespace risks**: Can escalate to real root via kernel vulnerabilities
- **PID namespace**: PID 1 can be killed from outside with SIGKILL
- **Network namespace**: Requires CAP_NET_ADMIN for full configuration
- **Namespace file descriptors**: Holding an ns fd keeps the namespace alive

---

## 11. Common Bugs

```c
// BUG: Not making mounts private after unshare
unshare(CLONE_NEWNS);
// Mount changes propagate to parent namespace!
// FIX:
mount(NULL, "/", NULL, MS_REC | MS_PRIVATE, NULL);

// BUG: Forgetting PID namespace needs a fork
unshare(CLONE_NEWPID);
printf("My PID: %d\n", getpid());  // Still old PID!
// FIX: fork() after unshare to get PID 1

// BUG: Not handling PID 1 signal responsibilities
// PID 1 must reap children or use PR_SET_CHILD_SUBREAPER
```

---

## 12. Kernel Source References

- **Namespaces**: `kernel/nsproxy.c`
- **User namespaces**: `kernel/user_namespace.c`
- **PID namespaces**: `kernel/pid_namespace.c`
- **Mount namespaces**: `fs/namespace.c`
- **Network namespaces**: `net/core/net_namespace.c`
- **`unshare`**: `kernel/fork.c`
- **`setns`**: `kernel/nsproxy.c`
- **Namespace structures**: `include/linux/nsproxy.h`

---

## 13. Summary

Namespace syscalls are the kernel foundation for containerization:
- **`unshare`**: Create new namespaces for the current process
- **`setns`**: Join existing namespaces via file descriptors
- **`clone` with `CLONE_NEW*`**: Create new process in new namespaces

Together with cgroups (resource limits), capabilities, and seccomp, namespaces form the complete container isolation model used by Docker, Kubernetes, and other container runtimes.

---

## 14. Detailed Namespace Internals

### 14.1 The nsproxy Structure

Each process has a `nsproxy` structure pointing to its namespace objects:

```c
struct nsproxy {
    struct uts_namespace *uts_ns;    // Hostname
    struct ipc_namespace *ipc_ns;   // IPC resources
    struct mnt_namespace *mnt_ns;   // Mount points
    struct pid_namespace *pid_ns_for_children; // PID ns for children
    struct net *net_ns;             // Network stack
    struct time_namespace *time_ns; // Time offsets
    struct cgroup_namespace *cgroup_ns; // Cgroup root
    struct user_namespace *user_ns; // User/group ID mapping
};
```

When `unshare` or `clone` creates a new namespace, a new namespace object is allocated and the `nsproxy` is updated.

### 14.2 Namespace Lifecycle

Namespaces are reference-counted. They are destroyed when the last reference is released:

```c
struct uts_namespace {
    struct kref kref;           // Reference count
    struct new_utsname name;    // Hostname, domainname
    struct user_namespace *user_ns;
    struct ucounts *ucounts;
    struct ns_common ns;
};
```

**References are held by:**
- Processes (via `task->nsproxy`)
- Namespace file descriptors (`/proc/[pid]/ns/*`)
- Bind mounts to namespace files

### 14.3 PID Namespace Hierarchy

PID namespaces form a hierarchy:

```c
struct pid_namespace {
    struct kref kref;
    struct pidmap pidmap[PIDMAP_ENTRIES]; // Bitmap of allocated PIDs
    struct pid_namespace *parent;         // Parent namespace
    unsigned int level;                   // Nesting level (0 = host)
    struct pid_namespace *child_ns;       // Child namespace
    // ...
};
```

- PID 1 in a child namespace is mapped to a regular PID in the parent
- The parent namespace can see all processes in child namespaces
- The child namespace can only see its own PIDs
- Signals can be sent from parent to child, but not the reverse

### 14.4 User Namespace Capabilities

Inside a user namespace, the user has all capabilities:

```c
// Capability check:
bool has_capability(struct task_struct *t, int cap)
{
    // Check the task's user namespace
    struct user_namespace *ns = current_user_ns();
    
    // If we're root in our user namespace → has all capabilities
    if (uid_eq(current_euid(), ns->owner))
        return true;
    
    // Otherwise check the capability sets
    return cap_raised(t->cred->cap_effective, cap);
}
```

This means an unprivileged user who creates a user namespace is "root" inside that namespace — but still unprivileged outside.

### 14.5 Network Namespace Internals

Each network namespace has its own complete network stack:

```c
struct net {
    refcount_t passive;
    spinlock_t rules_mod_lock;
    struct list_head list;
    struct list_head cleanup_list;
    struct list_head exit_list;
    
    struct net_device *loopback_dev;    // Loopback device
    struct list_head dev_base_head;     // All network devices
    
    struct sock *rtnl;                  // RTNL socket
    struct sock *genl_sock;             // Generic netlink socket
    
    // Per-namespace proc/sys entries
    struct proc_dir_entry *proc_net;
    struct proc_dir_entry *proc_net_stat;
    
    // Netfilter, routing, etc.
    struct netns_ipv4 ipv4;
    struct netns_ipv6 ipv6;
    struct netns_mib mib;
    // ...
};
```

### 14.6 Mount Namespace Propagation

Mount namespaces interact through propagation:

```c
struct mount {
    struct hlist_node mnt_hash;
    struct mount *mnt_parent;
    struct dentry *mnt_mountpoint;
    struct vfsmount mnt;
    struct mnt_namespace *mnt_ns;
    struct mountpoint *mnt_mp;
    
    // Propagation
    struct list_head mnt_list;
    struct list_head mnt_child;
    struct list_head mnt_mounts;
    struct mount *mnt_master;       // Master mount (for slave propagation)
    struct list_head mnt_slave_list;
    struct list_head mnt_slave;
    struct list_head mnt_share;     // Shared peer group
    // ...
};
```

**Propagation rules:**
- **Shared**: Events propagate to all mounts in the peer group
- **Slave**: Receives events from master, doesn't propagate back
- **Private**: No propagation
- **Unbindable**: Cannot be bind-mounted

### 14.7 Cgroup Namespace

Cgroup namespaces virtualize the cgroup view:

```c
struct cgroup_namespace {
    struct ns_common ns;
    struct user_namespace *user_ns;
    struct ucounts *ucounts;
    struct css_set *root_cset;  // Cgroup set at namespace root
};
```

Inside a cgroup namespace, the process appears to be at the root of the cgroup hierarchy. This is useful for containers that need a clean view of their cgroup subtree.

### 14.8 Time Namespace Details

Time namespaces offset `CLOCK_MONOTONIC` and `CLOCK_BOOTTIME`:

```c
struct timens_offsets {
    struct timespec64 monotonic;
    struct timespec64 boottime;
};

struct time_namespace {
    struct kref kref;
    struct user_namespace *user_ns;
    struct ucounts *ucounts;
    struct ns_common ns;
    struct timens_offsets offsets;
    struct vsyscall_page *vvar_page;
};
```

The offsets are applied in the vDSO for fast access. On context switch, the kernel updates the vDSO page to reflect the current namespace's offsets.

### 14.9 Namespace File Descriptors

Opening `/proc/[pid]/ns/*` returns a namespace file descriptor:

```c
// The inode operations for namespace files
static const struct file_operations ns_file_operations = {
    .read = ns_file_read,
    .poll = ns_file_poll,
    .release = ns_file_release,
    .get_unmapped_area = ns_get_unmapped_area,
};
```

These file descriptors can be used with `setns` to join namespaces, with `poll`/`epoll` to detect namespace changes, and can be passed between processes via Unix sockets.

### 14.10 Container Namespace Configuration

A typical container uses all available namespaces:

```bash
# Docker creates these namespaces for each container:
- PID namespace: Isolated process tree
- Network namespace: Separate network stack
- Mount namespace: Isolated mount points
- UTS namespace: Container hostname
- IPC namespace: Isolated IPC resources
- User namespace: UID mapping (optional, for rootless containers)
- Cgroup namespace: Virtualized cgroup view
```

The combination of namespaces, cgroups, capabilities, and seccomp provides defense-in-depth container isolation.

### 14.11 Namespace Interaction with Security

Namespaces interact with several security mechanisms:

**Capabilities and user namespaces:**
- A user namespace grants all capabilities within the namespace
- But the user is still unprivileged outside
- This allows unprivileged users to perform operations that normally require root

**Seccomp and namespaces:**
- Seccomp filters are inherited across namespace boundaries
- Filters can be installed in child namespaces
- Container runtimes typically install seccomp filters after namespace creation

**LSM and namespaces:**
- SELinux labels apply across namespace boundaries
- AppArmor profiles restrict namespace operations
- Landlock rules are per-process, not per-namespace

### 14.12 Namespace File Descriptors and Container Migration

Namespace file descriptors enable container checkpoint/restore:

```c
// Checkpoint: save namespace references
int netns_fd = open("/proc/[pid]/ns/net", O_RDONLY);
int mntns_fd = open("/proc/[pid]/ns/mnt", O_RDONLY);
int pidns_fd = open("/proc/[pid]/ns/pid", O_RDONLY);
// Save these file descriptors (e.g., to a file via SCM_RIGHTS)

// Restore: rejoin namespaces
setns(netns_fd, CLONE_NEWNET);
setns(mntns_fd, CLONE_NEWNS);
// Note: PID namespace can't be changed after creation
```

### 14.13 Namespace Limitations

- **PID namespace**: Can't be changed after process creation
- **Mount namespace**: Complex interactions with propagation
- **User namespace**: Security risks from unprivileged creation
- **Network namespace**: Requires veth pairs for connectivity
- **Cgroup namespace**: Only virtualizes the view, doesn't change actual cgroup

### 14.14 Checking Current Namespaces

```c
// Read namespace IDs from /proc/self/ns/*
// Each namespace has a unique inode number

#include <sys/stat.h>

int get_namespace_id(const char *ns_name) {
    char path[256];
    snprintf(path, sizeof(path), "/proc/self/ns/%s", ns_name);
    struct stat st;
    if (stat(path, &st) < 0) return -1;
    return st.st_ino;
}

// Compare namespace IDs to check if two processes share a namespace
int my_net_ns = get_namespace_id("net");
int other_net_ns = get_namespace_id_for_pid(other_pid, "net");
bool same_namespace = (my_net_ns == other_net_ns);
```

### 14.15 Namespace Creation Order

When creating a container, the order of namespace creation matters:

```c
// Recommended order:
1. unshare(CLONE_NEWUSER)   // First: get capabilities in new user ns
2. Write uid_map/gid_map    // Map UIDs
3. unshare(CLONE_NEWNS)     // Mount namespace
4. pivot_root               // New root filesystem
5. unshare(CLONE_NEWPID)    // PID namespace
6. unshare(CLONE_NEWNET)    // Network namespace
7. unshare(CLONE_NEWUTS)    // Hostname
8. unshare(CLONE_NEWIPC)    // IPC
```

This order ensures that each namespace has the necessary capabilities for setup.

### 14.16 Namespace Creation with clone3

The `clone3` syscall provides a cleaner interface for namespace creation:

```c
struct clone_args args = {
    .flags = CLONE_NEWPID | CLONE_NEWNS | CLONE_NEWNET | CLONE_NEWUSER,
    .pidfd = (unsigned long)&pidfd,
    .exit_signal = SIGCHLD,
    .stack = (unsigned long)(stack + STACK_SIZE),
    .stack_size = STACK_SIZE,
};

pid_t pid = syscall(__NR_clone3, &args, sizeof(args));
if (pid == 0) {
    // Child process in new namespaces
    // ...
}
```

### 14.17 Namespace Best Practices

1. **Always use `CLONE_NEWUSER`** for unprivileged containers
2. **Mount namespaces require `MS_REC | MS_PRIVATE`** to prevent propagation leaks
3. **PID namespaces need a `fork()`** after `unshare()` to get PID 1
4. **Network namespaces need veth pairs** for connectivity
5. **User namespaces have security implications** — consider disabling on production systems
6. **Namespace file descriptors** can be passed between processes for dynamic namespace joining
7. **Always handle namespace setup errors** — they're common with insufficient privileges
