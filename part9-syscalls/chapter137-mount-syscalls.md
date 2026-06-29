# Chapter 137: Mount Syscalls

## 1. Introduction

Mount syscalls control filesystem attachment to the directory tree. From the classic `mount` and `umount2` to the modern new mount API (`fsopen`/`fsconfig`/`fsmount`), these syscalls are essential for filesystem management, containers, and system administration.

---

## 2. mount

### 2.1 Purpose

`mount` attaches a filesystem to a directory in the mount tree.

### 2.2 Prototype

```c
#include <sys/mount.h>
int mount(const char *source, const char *target, const char *filesystemtype,
          unsigned long mountflags, const void *data);
```

### 2.3 Arguments

- **`source`**: Device or special file (e.g., `/dev/sda1`, `tmpfs`, `proc`)
- **`target`**: Directory to mount on
- **`filesystemtype`**: Filesystem type string (e.g., `ext4`, `tmpfs`, `nfs`)
- **`mountflags`**: Mount options

| Flag | Description |
|------|-------------|
| `MS_RDONLY` | Read-only mount |
| `MS_NOSUID` | Ignore setuid/setgid bits |
| `MS_NODEV` | Don't allow device access |
| `MS_NOEXEC` | Don't allow execution |
| `MS_SYNCHRONOUS` | Synchronous I/O |
| `MS_REMOUNT` | Remount (change options) |
| `MS_BIND` | Bind mount |
| `MS_MOVE` | Move mount point |
| `MS_REC` | Recursive (for bind mounts) |
| `MS_PRIVATE` | Private propagation |
| `MS_SHARED` | Shared propagation |
| `MS_SLAVE` | Slave propagation |
| `MS_UNBINDABLE` | Unbindable |
| `MS_LAZYTIME` | Lazy atime updates |
| `MS_DIRSYNC` | Synchronous directory updates |
| `MS_NOATIME` | Don't update access time |
| `MS_NODIRATIME` | Don't update directory access time |

- **`data`**: Filesystem-specific options string (e.g., `"mode=1777,size=1G"`)

### 2.4 Example

```c
#include <sys/mount.h>
#include <stdio.h>

int main(void)
{
    // Mount tmpfs
    if (mount("tmpfs", "/mnt/ram", "tmpfs", MS_NOSUID | MS_NODEV, "size=1G,mode=1777") < 0) {
        perror("mount");
        return 1;
    }
    
    // Bind mount
    if (mount("/etc/hosts", "/mnt/hosts", NULL, MS_BIND, NULL) < 0) {
        perror("bind mount");
        return 1;
    }
    
    // Remount read-only
    if (mount(NULL, "/mnt/hosts", NULL, MS_REMOUNT | MS_BIND | MS_RDONLY, NULL) < 0) {
        perror("remount");
        return 1;
    }
    
    return 0;
}
```

### 2.5 Bind Mounts

Bind mounts make a file or directory visible at another location:

```c
// Directory bind mount
mount("/data", "/container/data", NULL, MS_BIND, NULL);

// File bind mount
mount("/etc/resolv.conf", "/container/etc/resolv.conf", NULL, MS_BIND, NULL);

// Recursive bind mount (includes submounts)
mount("/host", "/container", NULL, MS_BIND | MS_REC, NULL);
```

### 2.6 Kernel Implementation

```c
SYSCALL_DEFINE5(mount, char __user *, dev_name, char __user *, dir_name,
                char __user *, type, unsigned long, flags, void __user *, data)
{
    int ret;
    char *kernel_type, *kernel_dev, *kernel_data;
    
    kernel_type = copy_mount_string(type);
    kernel_dev = copy_mount_string(dev_name);
    kernel_data = copy_mount_options(data);
    
    ret = do_mount(kernel_dev, dir_name, kernel_type, flags, kernel_data);
    
    kfree(kernel_type);
    kfree(kernel_dev);
    kfree(kernel_data);
    return ret;
}
```

### 2.7 Privilege Requirements

- `mount` requires `CAP_SYS_ADMIN` in the current user namespace
- User namespaces allow unprivileged users to mount within their namespace
- Certain mount types (bind, proc, sysfs) have additional restrictions

---

## 3. umount2

### 3.1 Purpose

`umount2` detaches a filesystem from the mount tree.

### 3.2 Prototype

```c
int umount2(const char *target, int flags);
```

### 3.3 Flags

| Flag | Description |
|------|-------------|
| `MNT_FORCE` | Force unmount (even if busy) — for NFS |
| `MNT_DETACH` | Lazy unmount (detach immediately, cleanup later) |
| `MNT_EXPIRE` | Mark as expired (unmount if not used) |
| `UMOUNT_NOFOLLOW` | Don't follow symlinks |

### 3.4 Example

```c
// Normal unmount
umount2("/mnt/usb", 0);

// Lazy unmount (immediate detach, filesystem cleaned up when not busy)
umount2("/mnt/nfs", MNT_DETACH);

// Force unmount (NFS stale handle)
umount2("/mnt/nfs", MNT_FORCE);
```

### 3.5 Busy Filesystem

A filesystem is "busy" if:
- Files are open
- Processes have current working directory on it
- It's a swap device
- It has submounts

Use `lsof +D /mnt` or `fuser -m /mnt` to find processes using a busy filesystem.

---

## 4. pivot_root

### 4.1 Purpose

`pivot_root` changes the root mount for a process and its children. It's the standard way to set up a new root filesystem in containers.

### 4.2 Prototype

```c
#include <sys/syscall.h>
int pivot_root(const char *new_root, const char *put_old);
```

### 4.3 Arguments

- **`new_root`**: New root filesystem (must be a mount point)
- **`put_old`**: Where to put the old root (must be under new_root)

### 4.4 Example: Container Root Setup

```c
#include <sys/mount.h>
#include <sys/syscall.h>
#include <unistd.h>
#include <stdio.h>

int setup_container_root(const char *rootfs)
{
    // Make all mounts private
    mount(NULL, "/", NULL, MS_REC | MS_PRIVATE, NULL);
    
    // Bind mount rootfs to itself (makes it a mount point)
    mount(rootfs, rootfs, NULL, MS_BIND | MS_REC, NULL);
    
    // Create put_old directory
    char put_old[PATH_MAX];
    snprintf(put_old, sizeof(put_old), "%s/.old_root", rootfs);
    mkdir(put_old, 0755);
    
    // pivot_root
    if (syscall(SYS_pivot_root, rootfs, put_old) < 0) {
        perror("pivot_root");
        return -1;
    }
    
    // Change to new root
    chdir("/");
    
    // Unmount old root
    umount2("/.old_root", MNT_DETACH);
    rmdir("/.old_root");
    
    return 0;
}
```

### 4.5 Why pivot_root over chroot?

| Feature | chroot | pivot_root |
|---------|--------|------------|
| Security | Weak (escape possible) | Strong |
| Filesystem isolation | None | Complete |
| Mount namespace | Not required | Required |
| Escape difficulty | Easy | Hard |

`chroot` can be escaped by a privileged process. `pivot_root` combined with mount namespace provides much stronger isolation.

---

## 5. chroot

### 5.1 Purpose

`chroot` changes the root directory for the calling process. It's weaker than `pivot_root` but simpler.

### 5.2 Prototype

```c
#include <unistd.h>
int chroot(const char *path);
```

### 5.3 Security Limitations

```c
// chroot is NOT a security boundary!
// Escaping chroot:
int fd = open(".", O_RDONLY);
chroot("/tmp");
fchdir(fd);  // Back outside!
// Then cd .. repeatedly to reach real root
```

### 5.4 Proper chroot Usage

```c
// For security, you must:
// 1. chdir to the new root first
// 2. Drop all capabilities
// 3. Use in combination with other restrictions

chdir("/new_root");
chroot("/new_root");
drop_privileges();  // capset, prctl, seccomp
```

---

## 6. New Mount API (Linux 5.2+)

### 6.1 Purpose

The new mount API provides a more extensible and secure way to mount filesystems. Instead of a single `mount` syscall with a complex options string, it uses three steps: create context, configure, mount.

### 6.2 Syscalls

```c
#include <sys/syscall.h>
#include <linux/mount.h>

int fsopen(const char *fs_name, unsigned int flags);
int fsconfig(int fd, unsigned int cmd, const char *key, const void *value, int aux);
int fsmount(int fs_fd, unsigned int flags, unsigned int attr_flags);
int move_mount(int from_dirfd, const char *from_pathname,
               int to_dirfd, const char *to_pathname, unsigned int flags);
int open_tree(int dirfd, const char *pathname, unsigned int flags);
```

### 6.3 fsopen — Create Filesystem Context

```c
int fs_fd = fsopen("ext4", FSOPEN_CLOEXEC);
```

### 6.4 fsconfig — Configure Filesystem

```c
// Set options
fsconfig(fs_fd, FSCONFIG_SET_STRING, "source", "/dev/sda1", 0);
fsconfig(fs_fd, FSCONFIG_SET_STRING, "errors", "remount-ro", 0);
fsconfig(fs_fd, FSCONFIG_SET_FLAG, "ro", NULL, 0);

// Create the superblock
fsconfig(fs_fd, FSCONFIG_CMD_CREATE, NULL, NULL, 0);
```

### 6.5 fsmount — Create Mount Object

```c
int mount_fd = fsmount(fs_fd, FSMOUNT_CLOEXEC, MS_NODEV | MS_NOSUID);
```

### 6.6 move_mount — Attach to Filesystem Tree

```c
move_mount(mount_fd, "", AT_FDCWD, "/mnt/point", MOVE_MOUNT_F_EMPTY_PATH);
```

### 6.7 Complete Example

```c
#include <sys/syscall.h>
#include <linux/mount.h>
#include <fcntl.h>

int main(void)
{
    // Create filesystem context
    int fs_fd = syscall(__NR_fsopen, "tmpfs", FSOPEN_CLOEXEC);
    
    // Configure
    syscall(__NR_fsconfig, fs_fd, FSCONFIG_SET_STRING, "size", "1G", 0);
    syscall(__NR_fsconfig, fs_fd, FSCONFIG_SET_STRING, "mode", "1777", 0);
    syscall(__NR_fsconfig, fs_fd, FSCONFIG_CMD_CREATE, NULL, NULL, 0);
    
    // Create mount
    int mount_fd = syscall(__NR_fsmount, fs_fd, FSMOUNT_CLOEXEC,
                           MS_NODEV | MS_NOSUID | MS_NOEXEC);
    
    // Attach to filesystem tree
    syscall(__NR_move_mount, mount_fd, "", AT_FDCWD, "/mnt/ram",
            MOVE_MOUNT_F_EMPTY_PATH);
    
    return 0;
}
```

### 6.8 Advantages Over Classic mount()

- Options are set individually (no parsing complex strings)
- Filesystem and mount are separate objects (fd-based)
- Better error reporting
- Supports fsinfo() for querying filesystem information
- More secure (no string injection)

### 6.9 fsinfo (Linux 5.8+)

```c
int fsinfo(int dirfd, const char *pathname, struct fsinfo_params *params,
           void *buffer, size_t buf_size);
```

Query information about a mounted filesystem without parsing /proc/mounts.

---

## 7. Mount Propagation

### 7.1 Propagation Types

Mount events (mount/unmount) can propagate between mount namespaces:

| Type | Description |
|------|-------------|
| `MS_SHARED` | Events propagate to all peer groups |
| `MS_PRIVATE` | No propagation |
| `MS_SLAVE` | Receives from master, doesn't propagate back |
| `MS_UNBINDABLE` | Can't be bind mounted |

### 7.2 Example

```c
// Make /mnt shared (events propagate to child namespaces)
mount(NULL, "/mnt", NULL, MS_SHARED, NULL);

// Make /mnt private (no propagation)
mount(NULL, "/mnt", NULL, MS_PRIVATE, NULL);

// Make /mnt slave (receives from master only)
mount(NULL, "/mnt", NULL, MS_SLAVE, NULL);
```

### 7.3 Container Relevance

Containers typically:
1. Make all mounts private (`MS_REC | MS_PRIVATE`)
2. Mount the container rootfs
3. `pivot_root` into the container
4. Unmount the old root

This prevents mount events from leaking between host and container.

---

## 8. /proc/mounts and /proc/self/mountinfo

```bash
$ cat /proc/self/mountinfo
36 35 98:0 /mnt1 /mnt2 rw,noatime master:1 - ext3 /dev/root rw,errors=continue
```

Fields:
1. Mount ID
2. Parent mount ID
3. Major:Minor device numbers
4. Root (path in the filesystem)
5. Mount point
6. Mount options
7. Optional fields (propagation, etc.)
8. Separator (-)
9. Filesystem type
10. Mount source
11. Super options

---

## 9. Security Implications

- **`mount` requires `CAP_SYS_ADMIN`**: Prevents unprivileged filesystem manipulation
- **`MS_NOSUID`/`MS_NODEV`/`MS_NOEXEC`**: Harden mounts against attacks
- **Bind mount attacks**: Bind mounting sensitive files into containers can leak information
- **`pivot_root` vs `chroot`**: Always use `pivot_root` in containers
- **Mount namespace isolation**: Prevents mount events from leaking between namespaces
- **Proc/sysfs restrictions**: `hidepid=2` for `/proc`, `subset=pid` for sysfs

---

## 10. Common Bugs

```c
// BUG: Not checking mount() return value
mount("tmpfs", "/mnt", "tmpfs", 0, NULL);
// Might fail silently!

// BUG: Forgetting MS_REC for recursive operations
mount(NULL, "/", NULL, MS_PRIVATE, NULL);
// Only "/" is private, submounts still propagate!
// FIX:
mount(NULL, "/", NULL, MS_REC | MS_PRIVATE, NULL);

// BUG: Using chroot for security
chroot("/jail");
// Can be escaped!
// FIX: Use pivot_root + mount namespace + seccomp
```

---

## 11. Kernel Source References

- **`mount`**: `fs/namespace.c`
- **`umount2`**: `fs/namespace.c`
- **`pivot_root`**: `fs/namespace.c`
- **`chroot`**: `fs/open.c`
- **New mount API**: `fs/namespace.c` (`fsopen`, `fsconfig`, `fsmount`)
- **Mount propagation**: `fs/pnode.c`
- **Mount structures**: `include/linux/mount.h`

---

## 12. Summary

Mount syscalls control filesystem attachment and isolation:
- **`mount`/`umount2`**: Classic mount/unmount
- **`pivot_root`**: Change root filesystem (for containers)
- **`chroot`**: Simple root change (not secure alone)
- **New mount API** (`fsopen`/`fsconfig`/`fsmount`): Modern, extensible mounting
- **Mount propagation**: Control event propagation between namespaces

For containers, the combination of mount namespaces, `pivot_root`, and proper propagation settings provides robust filesystem isolation.

---

## 13. Detailed Mount Internals

### 13.1 The VFS Mount Tree

The kernel maintains a tree of mount points:

```c
struct mount {
    struct hlist_node mnt_hash;      // Hash table node
    struct mount *mnt_parent;        // Parent mount
    struct dentry *mnt_mountpoint;   // Dentry where mounted
    struct vfsmount mnt;             // VFS mount data
    struct rcu_head mnt_rcu;
    struct mnt_namespace *mnt_ns;    // Owning namespace
    
    // Mount list
    struct list_head mnt_instance;   // Super block instances
    
    // Children
    struct list_head mnt_mounts;     // Child mounts
    struct list_head mnt_child;      // Link in parent's mnt_mounts
    
    // Propagation
    struct list_head mnt_share;      // Shared peer group
    struct list_head mnt_slave_list; // Slave mounts
    struct list_head mnt_slave;      // Link in master's mnt_slave_list
    struct mount *mnt_master;        // Master mount
    
    // Expiration
    struct list_head mnt_expire;     // Link in expire list
    
    struct list_head mnt_list;       // List of all mounts in namespace
    // ...
};
```

### 13.2 The Super Block and Filesystem Registration

Each mounted filesystem has a super block:

```c
struct super_block {
    struct list_head s_list;
    dev_t s_dev;                    // Device identifier
    unsigned char s_blocksize_bits;
    unsigned long s_blocksize;
    loff_t s_maxbytes;
    struct file_system_type *s_type; // Filesystem type
    const struct super_operations *s_op;
    struct dentry *s_root;          // Root dentry
    // ...
};
```

Filesystem types are registered at boot or module load:

```c
struct file_system_type {
    const char *name;
    int fs_flags;
    struct dentry *(*mount)(struct file_system_type *, int, const char *, void *);
    void (*kill_sb)(struct super_block *);
    struct module *owner;
    // ...
};
```

### 13.3 The mount() System Call Flow

```
mount() syscall
  → do_mount()
    → kern_path() - resolve mount point path
    → do_new_mount() or do_loopback() or do_move_mount()
      → For new mount:
        → get_fs_type() - find filesystem type
        → vfs_kern_mount() - create mount structure
          → alloc_vfsmnt() - allocate mount
          → type->mount() - filesystem-specific mount
          → fill super block, root dentry
        → graft_tree() - attach to mount tree
          → attach_recursive_mnt()
            → Check propagation
            → Update mount tree
      → For bind mount:
        → clone_mnt() - create clone of existing mount
        → graft_tree() - attach
```

### 13.4 Mount Options Handling

Mount options are parsed by each filesystem:

```c
// Example: tmpfs mount options
static const match_table_t tokens = {
    { Opt_size, "size=%s" },
    { Opt_nr_blocks, "nr_blocks=%s" },
    { Opt_nr_inodes, "nr_inodes=%s" },
    { Opt_mode, "mode=%o" },
    { Opt_uid, "uid=%s" },
    { Opt_gid, "gid=%s" },
    { Opt_huge, "huge=%s" },
    // ...
};
```

The kernel's `match_token()` function parses option strings into key-value pairs.

### 13.5 The New Mount API in Detail

The new mount API separates concerns:

```c
// Step 1: Create filesystem context
// Calls file_system_type->init_fs_context()
int fs_fd = fsopen("ext4", FSOPEN_CLOEXEC);

// Step 2: Configure (multiple calls)
// Calls fs_context->ops->parse_param()
fsconfig(fs_fd, FSCONFIG_SET_STRING, "source", "/dev/sda1", 0);
fsconfig(fs_fd, FSCONFIG_SET_FLAG, "ro", NULL, 0);

// Step 3: Create mount
// Calls fs_context->ops->get_tree()
fsconfig(fs_fd, FSCONFIG_CMD_CREATE, NULL, NULL, 0);
int mount_fd = fsmount(fs_fd, FSMOUNT_CLOEXEC, 0);

// Step 4: Attach to tree
move_mount(mount_fd, "", AT_FDCWD, "/mnt", MOVE_MOUNT_F_EMPTY_PATH);
```

**`fsconfig` commands:**
| Command | Description |
|---------|-------------|
| `FSCONFIG_SET_FLAG` | Set a boolean option |
| `FSCONFIG_SET_STRING` | Set a string option |
| `FSCONFIG_SET_BINARY` | Set a binary option |
| `FSCONFIG_SET_PATH` | Set a path option (fd-relative) |
| `FSCONFIG_SET_PATH_EMPTY` | Set a path option (empty path = fd itself) |
| `FSCONFIG_SET_FD` | Set a file descriptor option |
| `FSCONFIG_CMD_CREATE` | Create the superblock |
| `FSCONFIG_CMD_RECONFIGURE` | Reconfigure (remount) |

### 13.6 Bind Mount Internals

Bind mounts share the underlying filesystem data:

```c
// When you bind mount /a to /b:
// 1. Clone the mount structure
// 2. Point the new mount to the same super block
// 3. Set the mountpoint to /b
// 4. The dentry tree is shared

struct mount *clone_mnt(struct mount *old, struct dentry *root, int flag)
{
    struct mount *mnt = alloc_vfsmnt(old->mnt_devname);
    mnt->mnt.mnt_flags = old->mnt.mnt_flags;
    mnt->mnt.mnt_sb = old->mnt.mnt_sb;  // Same super block!
    // ...
}
```

### 13.7 Mount Flags That Can Be Changed

Some flags can be changed with `MS_REMOUNT`:
- `MS_RDONLY` — Toggle read-only
- `MS_NOSUID`, `MS_NODEV`, `MS_NOEXEC` — Security flags
- `MS_NOATIME`, `MS_NODIRATIME` — Access time flags
- `MS_SYNCHRONOUS` — Synchronous I/O
- `MS_DIRSYNC` — Synchronous directory updates
- `MS_LAZYTIME` — Lazy time updates

Some flags CANNOT be changed after mount:
- `MS_BIND` — Cannot convert to/from bind mount
- `MS_SHARED`/`MS_PRIVATE`/`MS_SLAVE` — Propagation type (use separate mount operations)

### 13.8 Filesystem-Specific Mount Handlers

Each filesystem implements its own mount logic:

```c
// ext4
static struct dentry *ext4_mount(struct file_system_type *fs_type,
                                  int flags, const char *dev_name, void *data)
{
    return mount_bdev(fs_type, flags, dev_name, data, ext4_fill_super);
}

// tmpfs
static struct dentry *shmem_mount(struct file_system_type *fs_type,
                                   int flags, const char *dev_name, void *data)
{
    return mount_nodev(fs_type, flags, data, shmem_fill_super);
}

// proc
static struct dentry *proc_mount(struct file_system_type *fs_type,
                                  int flags, const char *dev_name, void *data)
{
    return mount_nodev(fs_type, flags, data, proc_fill_super);
}
```

### 13.9 Mount and Security

Mount operations have several security implications:

- **`MS_NOSUID`**: Prevents setuid binaries from gaining privileges
- **`MS_NODEV`**: Prevents access to device files (important for /tmp)
- **`MS_NOEXEC`**: Prevents executing binaries from the mount
- **`MS_RDONLY`**: Prevents modification (important for /usr in secure systems)
- **`hidepid=2`**: Hides other users' processes in /proc

Container security relies heavily on mount flags:
```bash
# Typical container rootfs mount
mount("overlay", "/rootfs", "overlay", MS_NODEV | MS_NOSUID,
      "lowerdir=/base,upperdir=/container/upper,workdir=/container/work");
```

### 13.10 Filesystem-Specific Mount Examples

**tmpfs (RAM-based filesystem):**
```c
mount("tmpfs", "/tmp", "tmpfs",
      MS_NOSUID | MS_NODEV,
      "size=1G,mode=1777,uid=1000,gid=1000");
```

**OverlayFS (layered filesystem):**
```c
mount("overlay", "/merged", "overlay", 0,
      "lowerdir=/base,upperdir=/overlay/upper,workdir=/overlay/work");
```

**procfs (process information):**
```c
mount("proc", "/proc", "proc", MS_NOSUID | MS_NODEV | MS_NOEXEC, NULL);
```

**sysfs (kernel/device information):**
```c
mount("sysfs", "/sys", "sysfs", MS_NOSUID | MS_NODEV | MS_NOEXEC | MS_READONLY, NULL);
```

**devpts (pseudo-terminal devices):**
```c
mount("devpts", "/dev/pts", "devpts", MS_NOSUID | MS_NOEXEC,
      "newinstance,ptmxmode=0666,mode=0620");
```

### 13.11 Mount and Security in Containers

Container runtimes use mounts to provide isolation:

```bash
# Container rootfs (read-only base + writable overlay)
mount("overlay", "/rootfs", "overlay", MS_NODEV | MS_NOSUID,
      "lowerdir=/images/base,upperdir=/containers/$id/upper,workdir=/containers/$id/work")

# Mount proc (restricted)
mount("proc", "/rootfs/proc", "proc",
      MS_NOSUID | MS_NODEV | MS_NOEXEC, "hidepid=2")

# Mount sysfs (read-only, restricted)
mount("sysfs", "/rootfs/sys", "sysfs",
      MS_NOSUID | MS_NODEV | MS_NOEXEC | MS_RDONLY, "subset=pid")

# Bind mount resolv.conf
mount("/etc/resolv.conf", "/rootfs/etc/resolv.conf", NULL, MS_BIND | MS_RDONLY, NULL)

# pivot_root into the container
syscall(SYS_pivot_root, "/rootfs", "/rootfs/.old_root")
umount2("/.old_root", MNT_DETACH)
```

### 13.12 Mount Monitoring

```bash
# List all mounts
cat /proc/self/mounts
cat /proc/self/mountinfo
cat /proc/mounts

# Watch for mount events
cat /proc/self/mounts | inotifywait -m /proc/self/mounts

# Find mounts in a namespace
ls -la /proc/[pid]/ns/mnt
cat /proc/[pid]/mounts

# Mount statistics
cat /proc/self/mountstats
```

### 13.13 The mount API Evolution

The mount API has evolved through several generations:

1. **Classic mount()**: Single syscall with string options (1970s Unix)
2. **mount with MS_* flags**: Structured flags (Linux 2.0+)
3. **New mount API**: Separate concerns (Linux 5.2+)
   - `fsopen()` + `fsconfig()` + `fsmount()` + `move_mount()`
   - Better error handling
   - No string parsing
   - More extensible

The new mount API is recommended for new code but the classic `mount()` remains fully supported.

### 13.14 Mount and Filesystem Interaction

When a filesystem is mounted, the kernel:

1. Creates a super block (if not already mounted)
2. Calls the filesystem's `fill_super` method
3. Creates the root dentry/inode
4. Creates a mount structure
5. Links the mount into the mount tree
6. Updates the mount namespace

**Super block sharing:**
Multiple mounts of the same device share the same super block. This means:
- The same file has the same inode number on all mounts
- Changes are visible across all mounts
- The page cache is shared

### 13.15 The pivot_root vs chroot Security Model

**chroot weaknesses:**
```c
// chroot doesn't change the root directory of the filesystem view
// It only changes the root for path resolution

// Escape techniques:
// 1. Create a file descriptor to a directory outside chroot
int fd = open(".", O_RDONLY);
chroot("/tmp");
fchdir(fd);  // Back outside!

// 2. Use /proc to escape
chdir("/proc/1/root");  // If /proc is mounted
```

**pivot_root strengths:**
```c
// pivot_root requires a mount namespace
// The old root is unmounted after pivot_root
// Combined with CLONE_NEWNS, it provides real isolation

unshare(CLONE_NEWNS);
mount(NULL, "/", NULL, MS_REC | MS_PRIVATE, NULL);
mount("overlay", "/new_root", "overlay", 0, "...");
mkdir("/new_root/.old", 0755);
syscall(SYS_pivot_root, "/new_root", "/new_root/.old");
chdir("/");
umount2("/.old", MNT_DETACH);
rmdir("/.old");
```

### 13.16 Mount-related Resource Limits

```bash
# Maximum number of mounts per namespace
/proc/sys/fs/mount-max  # Default: 100000

# Maximum number of mount propagation peers
/proc/sys/fs/mount-max  # Same limit

# Inotify watch limit (related to filesystem monitoring)
/proc/sys/fs/inotify/max_user_watches
```

These limits prevent mount namespace abuse and resource exhaustion.
