# Chapter 125: File I/O Syscalls

## 1. Introduction

File I/O is the most fundamental operation in any Unix-like system. The philosophy "everything is a file" means that regular files, directories, devices, pipes, sockets, and even process information (`/proc`) are all accessed through the same set of system calls. This chapter covers the core file I/O syscalls — `open`, `openat`, `read`, `write`, `close`, `lseek`, `stat`, `fstat`, `lstat`, and `access` — with complete details on their implementation, usage, and pitfalls.

---

## 2. open / openat

### 2.1 Purpose

`open` and `openat` open (or create) a file and return a file descriptor. `openat` (Linux 2.6.16+) is the modern replacement that supports relative-to-directory paths and avoids race conditions.

### 2.2 Prototype

```c
#include <fcntl.h>

int open(const char *pathname, int flags, ... /* mode_t mode */);
int openat(int dirfd, const char *pathname, int flags, ... /* mode_t mode */);
```

### 2.3 Arguments

**`pathname`**: The file to open. Can be absolute (`/etc/passwd`) or relative to `dirfd` (for `openat`) or the current working directory (for `open`).

**`dirfd`** (openat only):
- A directory file descriptor for relative paths
- `AT_FDCWD` — use the current working directory (like `open`)
- If `pathname` is absolute, `dirfd` is ignored

**`flags`**: Bitmask of flags, OR'd together:

| Flag | Value | Description |
|------|-------|-------------|
| `O_RDONLY` | 0 | Open for reading only |
| `O_WRONLY` | 1 | Open for writing only |
| `O_RDWR` | 2 | Open for reading and writing |
| `O_CREAT` | 0x40 | Create file if it doesn't exist |
| `O_EXCL` | 0x80 | Fail if file exists (with `O_CREAT`) |
| `O_TRUNC` | 0x200 | Truncate file to zero length |
| `O_APPEND` | 0x400 | Append to file on every write |
| `O_NONBLOCK` | 0x800 | Non-blocking mode |
| `O_DIRECTORY` | 0x10000 | Fail if not a directory |
| `O_NOFOLLOW` | 0x20000 | Don't follow symlinks |
| `O_CLOEXEC` | 0x80000 | Set close-on-exec flag |
| `O_PATH` | 0x1000000 | Obtain a file descriptor for path operations only |
| `O_TMPFILE` | 0x410000 | Create an unnamed temporary file |
| `O_NOATIME` | 0x100000 | Don't update access time |

**`mode`**: File permission bits (only meaningful with `O_CREAT`):
- `0644` — owner read/write, group/other read
- `0755` — owner read/write/execute, group/other read/execute
- Modified by the process's `umask`

### 2.4 Return Values

- **Success**: A non-negative file descriptor (the lowest available number)
- **Failure**: `-1` with `errno` set

### 2.5 Error Codes

| Error | Description |
|-------|-------------|
| `EACCES` | Permission denied |
| `EEXIST` | File exists (`O_CREAT | O_EXCL` specified) |
| `EINTR` | Interrupted by signal |
| `EINVAL` | Invalid flags |
| `EISDIR` | Path is a directory but write access requested |
| `EMFILE` | Process file descriptor limit reached |
| `ENFILE` | System-wide file descriptor limit reached |
| `ENODEV` | Device not found |
| `ENOENT` | File doesn't exist (and `O_CREAT` not set) |
| `ENOSPC` | No space left on device |
| `ENOTDIR` | A component of the path is not a directory |
| `EROFS` | Read-only filesystem |
| `ETXTBSY` | File is a running executable being written |

### 2.6 Kernel Implementation

```c
// fs/open.c
SYSCALL_DEFINE3(open, const char __user *, filename, int, flags, umode_t, mode)
{
    if (force_o_largefile())
        flags |= O_LARGEFILE;
    return do_sys_open(AT_FDCWD, filename, flags, mode);
}

SYSCALL_DEFINE4(openat, int, dfd, const char __user *, filename, int, flags, umode_t, mode)
{
    if (force_o_largefile())
        flags |= O_LARGEFILE;
    return do_sys_open(dfd, filename, flags, mode);
}

static long do_sys_open(int dfd, const char __user *filename, int flags, umode_t mode)
{
    struct filename *tmp;
    tmp = getname(filename);         // Copy pathname from user space
    int fd = get_unused_fd_flags(flags);  // Allocate fd number
    struct file *f = do_filp_open(dfd, tmp, &op);  // Create struct file
    
    // Install fd in process's fd table
    fd_install(fd, f);
    return fd;
}
```

**`do_filp_open`** performs:
1. Path resolution (walk the directory tree)
2. Permission checks
3. Call the filesystem's `open` method
4. Return a `struct file` representing the opened file

### 2.7 glibc Wrapper

```c
// Simplified glibc implementation
int open(const char *pathname, int flags, ...)
{
    mode_t mode = 0;
    if (flags & O_CREAT) {
        va_list ap;
        va_start(ap, flags);
        mode = va_arg(ap, mode_t);
        va_end(ap);
    }
    return INLINE_SYSCALL_CALL(openat, AT_FDCWD, pathname, flags, mode);
}
```

Modern glibc always uses `openat` internally, even for the `open` wrapper.

### 2.8 Assembly Calling Convention

**x86-64:**
```asm
; openat(AT_FDCWD, "/etc/passwd", O_RDONLY)
mov rax, 257          ; __NR_openat
mov rdi, -100         ; AT_FDCWD
lea rsi, [rel path]
mov rdx, 0            ; O_RDONLY
syscall
; fd returned in rax
```

**ARM64:**
```asm
// openat(AT_FDCWD, "/etc/passwd", O_RDONLY)
mov x8, #56           // __NR_openat
mov x0, #-100         // AT_FDCWD
ldr x1, =path
mov x2, #0            // O_RDONLY
svc #0
// fd returned in x0
```

### 2.9 Performance

`open`/`openat` is relatively expensive:
- Path resolution requires multiple `dentry`/`inode` lookups
- Each directory component involves a filesystem `lookup` operation
- The dentry cache (dcache) dramatically speeds up repeated opens
- Typical cost: 1-10 microseconds (cached) to 100+ microseconds (uncached, HDD)

**Optimization tips:**
- Use `openat` with `O_CLOEXEC` to avoid race conditions
- Keep directory file descriptors open for repeated relative opens
- Use `O_PATH` when you only need the fd for `fstat`, `fchmod`, etc.

### 2.10 Security Implications

- **Symlink attacks**: Use `O_NOFOLLOW` to prevent following malicious symlinks
- **Race conditions**: `O_CREAT | O_EXCL` prevents TOCTOU races on file creation
- **`O_CLOEXEC`**: Always use this to prevent fd leakage to child processes
- **`O_NOCTTY`**: Prevents a terminal device from becoming the controlling terminal
- **`O_TMPFILE`**: Creates unnamed files that can't be accessed by other processes (secure temp files)

### 2.11 Related Syscalls

- `creat()` — equivalent to `open(path, O_WRONLY|O_CREAT|O_TRUNC, mode)`
- `open_by_handle_at()` — open file by file handle (NFS)
- `name_to_handle_at()` — get file handle for a path
- `close_range()` — close a range of file descriptors (Linux 5.9)

### 2.12 Common Bugs

```c
// BUG: Forgetting O_CREAT requires mode argument
int fd = open(path, O_WRONLY | O_CREAT);  // mode is undefined!

// FIX: Always specify mode with O_CREAT
int fd = open(path, O_WRONLY | O_CREAT, 0644);

// BUG: Not using O_CLOEXEC (fd leaks to child)
int fd = open(path, O_RDONLY);  // Race with fork()

// FIX: Use O_CLOEXEC
int fd = open(path, O_RDONLY | O_CLOEXEC);

// BUG: TOCTOU race with access() then open()
if (access(path, W_OK) == 0) {  // Check
    fd = open(path, O_WRONLY);   // Use — race!
}

// FIX: Open first, then check with fstat/faccessat
fd = open(path, O_WRONLY | O_NOFOLLOW);
if (fd >= 0) {
    struct stat st;
    fstat(fd, &st);
    // Check st.st_uid, st.st_mode, etc.
}
```

---

## 3. read

### 3.1 Purpose

`read` reads up to `count` bytes from a file descriptor into a buffer.

### 3.2 Prototype

```c
#include <unistd.h>
ssize_t read(int fd, void *buf, size_t count);
```

### 3.3 Arguments

- **`fd`**: File descriptor (must be opened for reading)
- **`buf`**: User-space buffer to receive data
- **`count`**: Maximum number of bytes to read

### 3.4 Return Values

- **Success**: Number of bytes read (0 = EOF, positive = bytes read)
- **Failure**: `-1` with `errno` set

**Important**: `read` may return fewer bytes than requested. This is normal and not an error. Common reasons:
- Not enough data available (pipe, socket, terminal)
- EOF reached
- Interrupted by signal

### 3.5 Error Codes

| Error | Description |
|-------|-------------|
| `EAGAIN` | Non-blocking fd, no data available |
| `EBADF` | Bad file descriptor |
| `EFAULT` | Buffer address is invalid |
| `EINTR` | Interrupted by signal |
| `EINVAL` | fd not suitable for reading |
| `EIO` | I/O error |
| `EISDIR` | fd refers to a directory |

### 3.6 Kernel Implementation

```c
SYSCALL_DEFINE3(read, unsigned int, fd, char __user *, buf, size_t, count)
{
    struct fd f = fdget_pos(fd);  // Get struct file from fd
    if (f.file) {
        loff_t pos = file_pos_read(f.file);
        ret = vfs_read(f.file, buf, count, &pos);
        file_pos_write(f.file, pos);
        fdput_pos(f);
    }
    return ret;
}

ssize_t vfs_read(struct file *file, char __user *buf, size_t count, loff_t *pos)
{
    // Permission check
    if (!(file->f_mode & FMODE_READ))
        return -EBADF;
    
    // Call filesystem-specific read method
    if (file->f_op->read)
        ret = file->f_op->read(file, buf, count, pos);
    else if (file->f_op->read_iter)
        ret = new_sync_read(file, buf, count, pos);
    
    return ret;
}
```

For regular files on ext4, the read path goes through:
1. `vfs_read` → `ext4_file_read_iter`
2. Page cache lookup
3. If page not cached → read from disk (block I/O)
4. Copy data to user buffer via `copy_to_user`

### 3.7 Assembly Calling Convention

**x86-64:**
```asm
mov rax, 0            ; __NR_read
mov rdi, fd
lea rsi, [buf]
mov rdx, count
syscall
; bytes read in rax, or -errno on error
```

### 3.8 Performance

- **Cached reads**: ~100-500 nanoseconds (page cache hit)
- **Uncached reads (SSD)**: ~10-100 microseconds
- **Uncached reads (HDD)**: ~1-10 milliseconds (seek + rotational latency)
- **Pipe/socket reads**: ~1-5 microseconds

**Buffering**: For small, frequent reads, use `stdio` (fread) or `mmap` instead of raw `read`. Each `read` syscall has overhead.

### 3.9 Example

```c
#include <fcntl.h>
#include <unistd.h>
#include <stdio.h>
#include <errno.h>

int main(void)
{
    int fd = open("/etc/passwd", O_RDONLY | O_CLOEXEC);
    if (fd < 0) {
        perror("open");
        return 1;
    }
    
    char buf[4096];
    ssize_t total = 0;
    ssize_t n;
    
    while ((n = read(fd, buf, sizeof(buf))) > 0) {
        write(STDOUT_FILENO, buf, n);
        total += n;
    }
    
    if (n < 0) {
        perror("read");
        close(fd);
        return 1;
    }
    
    fprintf(stderr, "Read %zd bytes\n", total);
    close(fd);
    return 0;
}
```

### 3.10 Common Bugs

```c
// BUG: Not handling short reads
read(fd, buf, 4096);  // Might read fewer than 4096 bytes!

// FIX: Loop until all data is read
ssize_t total = 0;
while (total < 4096) {
    ssize_t n = read(fd, buf + total, 4096 - total);
    if (n < 0) {
        if (errno == EINTR) continue;
        break;  // Error
    }
    if (n == 0) break;  // EOF
    total += n;
}

// BUG: Not checking for EINTR
if (read(fd, buf, count) < 0) {
    perror("read");  // Might be EINTR
}

// FIX: Retry on EINTR
ssize_t n;
do {
    n = read(fd, buf, count);
} while (n < 0 && errno == EINTR);
```

---

## 4. write

### 4.1 Purpose

`write` writes up to `count` bytes from a buffer to a file descriptor.

### 4.2 Prototype

```c
#include <unistd.h>
ssize_t write(int fd, const void *buf, size_t count);
```

### 4.3 Arguments

- **`fd`**: File descriptor (must be opened for writing)
- **`buf`**: User-space buffer containing data to write
- **`count`**: Number of bytes to write

### 4.4 Return Values

- **Success**: Number of bytes written (positive)
- **Failure**: `-1` with `errno` set

**Important**: Like `read`, `write` may write fewer bytes than requested. For regular files, this usually indicates a problem (disk full, etc.), but for pipes and sockets, partial writes are normal.

### 4.5 Error Codes

| Error | Description |
|-------|-------------|
| `EAGAIN` | Non-blocking fd, write would block |
| `EBADF` | Bad file descriptor |
| `EFAULT` | Buffer address is invalid |
| `EFBIG` | File too large |
| `EINTR` | Interrupted by signal |
| `EINVAL` | fd not suitable for writing |
| `EIO` | I/O error |
| `ENOSPC` | No space left on device |
| `EPIPE` | Broken pipe (no readers) |

### 4.6 Kernel Implementation

```c
SYSCALL_DEFINE3(write, unsigned int, fd, const char __user *, buf, size_t, count)
{
    struct fd f = fdget_pos(fd);
    if (f.file) {
        loff_t pos = file_pos_read(f.file);
        ret = vfs_write(f.file, buf, count, &pos);
        file_pos_write(f.file, pos);
        fdput_pos(f);
    }
    return ret;
}
```

For regular files, `vfs_write` goes through:
1. Permission checks
2. Call filesystem's `write_iter` method
3. Data is copied from user space to page cache
4. Pages are marked dirty
5. Data is eventually flushed to disk (by `writeback` or `fsync`)

### 4.7 Buffered vs Unbuffered Writes

**Buffered (default):**
```c
write(fd, data, len);
// Data goes to page cache. Returns quickly.
// Data may not be on disk yet!
```

**Synchronous (O_SYNC):**
```c
fd = open(path, O_WRONLY | O_SYNC);
write(fd, data, len);
// Data + metadata written to disk before write() returns.
// Much slower, but guarantees durability.
```

**`O_DSYNC`**: Only data is synced (not metadata like mtime)
**`O_RSYNC`**: Reads are synchronized (rarely used alone)

### 4.8 Performance

- **Buffered write to page cache**: ~200-500 nanoseconds
- **Synchronous write (O_SYNC) to SSD**: ~50-200 microseconds
- **Synchronous write (O_SYNC) to HDD**: ~1-10 milliseconds

### 4.9 Security Implications

- **Partial writes**: If `write` is interrupted, data may be partially written. Always check the return value.
- **Signal handling**: `EINTR` can occur. Use `TEMP_FAILURE_RETRY` macro or manual retry.
- **`EPIPE` and `SIGPIPE`**: Writing to a broken pipe generates `SIGPIPE` by default. Use `signal(SIGPIPE, SIG_IGN)` or `MSG_NOSIGNAL` to handle gracefully.

---

## 5. close

### 5.1 Purpose

`close` closes a file descriptor, freeing it for reuse and releasing associated kernel resources.

### 5.2 Prototype

```c
#include <unistd.h>
int close(int fd);
```

### 5.3 Arguments

- **`fd`**: The file descriptor to close

### 5.4 Return Values

- **Success**: 0
- **Failure**: `-1` with `errno` set

### 5.5 Error Codes

| Error | Description |
|-------|-------------|
| `EBADF` | fd is not a valid open file descriptor |
| `EINTR` | Interrupted by signal (fd IS closed despite error) |
| `EIO` | I/O error (for NFS and other network filesystems) |

**Critical detail**: If `close` returns `-1` with `EINTR` or `EIO`, the file descriptor is **still closed**. You cannot retry the close. This is a long-standing POSIX design issue.

### 5.6 Kernel Implementation

```c
SYSCALL_DEFINE1(close, unsigned int, fd)
{
    return filp_close(fdtable_lookup_fd(fd), current->files);
}

int filp_close(struct file *filp, fl_owner_t id)
{
    // Flush pending data (for writeback)
    if (filp->f_op->flush)
        retval = filp->f_op->flush(filp, id);
    
    // Remove from fd table
    fput(filp);  // Decrement reference count; free if last
    
    return retval;
}
```

### 5.7 Reference Counting

File descriptors use reference counting (`f_count`). When `close` is called:
1. The fd is removed from the process's file descriptor table
2. The `struct file`'s reference count is decremented
3. If the count reaches 0, the file is actually released (filesystem's `release` method called)

This means `dup`/`dup2` can share a `struct file`, and the file isn't closed until all references are gone.

### 5.8 Common Bugs

```c
// BUG: Double close (undefined behavior, can close wrong fd)
close(fd);
close(fd);  // fd might have been reused!

// FIX: Set fd to -1 after closing
close(fd);
fd = -1;

// BUG: Not closing on error paths
int fd = open(path, O_RDONLY);
if (do_something() < 0) {
    return -1;  // fd leaked!
}

// FIX: Use goto cleanup or close_range
int fd = open(path, O_RDONLY);
if (do_something() < 0) {
    close(fd);
    return -1;
}
```

### 5.9 `close_range` (Linux 5.9)

```c
int close_range(unsigned int first, unsigned int last, int flags);
```

Closes all file descriptors in the range `[first, last]`. Useful for cleaning up after `fork()`:

```c
// Close all fds except stdin/stdout/stderr
close_range(3, ~0U, 0);
```

---

## 6. lseek

### 6.1 Purpose

`lseek` repositions the file offset (the position where the next `read` or `write` will occur).

### 6.2 Prototype

```c
#include <unistd.h>
off_t lseek(int fd, off_t offset, int whence);
```

### 6.3 Arguments

- **`fd`**: Open file descriptor
- **`offset`**: The offset (interpretation depends on `whence`)
- **`whence`**: How to interpret the offset

| Whence | Value | Description |
|--------|-------|-------------|
| `SEEK_SET` | 0 | Offset from beginning of file |
| `SEEK_CUR` | 1 | Offset from current position |
| `SEEK_END` | 2 | Offset from end of file |
| `SEEK_DATA` | 3 | Offset to next data region (Linux 3.1+) |
| `SEEK_HOLE` | 4 | Offset to next hole (Linux 3.1+) |

### 6.4 Return Values

- **Success**: The resulting file offset (from beginning of file)
- **Failure**: `-1` with `errno` set

### 6.5 Error Codes

| Error | Description |
|-------|-------------|
| `EBADF` | fd is not open |
| `EINVAL` | Invalid `whence` or resulting offset is negative |
| `ESPIPE` | fd refers to a pipe, socket, or FIFO |

### 6.6 Kernel Implementation

```c
SYSCALL_DEFINE3(lseek, unsigned int, fd, off_t, offset, unsigned int, whence)
{
    // ... validation ...
    retval = vfs_setpos(f.file, offset, maxsize);
    // or vfs_llseek(f.file, offset, whence)
}
```

### 6.7 Special Behavior

**Files that don't support seeking:**
- Pipes, FIFOs, sockets → `ESPIPE`
- Character devices (terminals) → usually `ESPIPE`
- Regular files, block devices → seekable

**Extending files:**
```c
lseek(fd, 1000000, SEEK_SET);
write(fd, "X", 1);
// File is now 1000001 bytes, with a "hole" of 999999 null bytes
```

**SEEK_DATA and SEEK_HOLE:**
Useful for detecting sparse file regions:
```c
off_t data_start = lseek(fd, 0, SEEK_DATA);  // First data byte
off_t hole_start = lseek(fd, data_start, SEEK_HOLE);  // First hole after data
```

### 6.8 Example

```c
#include <fcntl.h>
#include <unistd.h>
#include <stdio.h>

int main(void)
{
    int fd = open("testfile", O_RDWR | O_CREAT | O_TRUNC, 0644);
    
    // Write "Hello" at offset 0
    write(fd, "Hello", 5);
    
    // Current offset is now 5
    off_t pos = lseek(fd, 0, SEEK_CUR);
    printf("Current offset: %ld\n", (long)pos);  // 5
    
    // Seek to beginning
    lseek(fd, 0, SEEK_SET);
    
    // Read back
    char buf[6] = {};
    read(fd, buf, 5);
    printf("Read: %s\n", buf);  // "Hello"
    
    // Get file size using SEEK_END
    off_t size = lseek(fd, 0, SEEK_END);
    printf("File size: %ld\n", (long)size);  // 5
    
    close(fd);
    return 0;
}
```

### 6.9 Common Bugs

```c
// BUG: Not checking lseek return value
lseek(fd, -10, SEEK_SET);  // Might fail with EINVAL!

// BUG: Using lseek on a pipe
int pipefd[2];
pipe(pipefd);
lseek(pipefd[0], 0, SEEK_SET);  // ESPIPE!

// BUG: Assuming read() returns bytes at the requested offset after lseek
// (for sockets/pipes, lseek doesn't apply)
```

---

## 7. stat / fstat / lstat / newfstatat

### 7.1 Purpose

These syscalls retrieve file metadata (size, permissions, timestamps, ownership, etc.) without opening the file for I/O.

### 7.2 Prototype

```c
#include <sys/stat.h>

int stat(const char *pathname, struct stat *statbuf);
int fstat(int fd, struct stat *statbuf);
int lstat(const char *pathname, struct stat *statbuf);
int fstatat(int dirfd, const char *pathname, struct stat *statbuf, int flags);
```

### 7.3 Differences

| Syscall | Behavior |
|---------|----------|
| `stat` | Follows symlinks |
| `lstat` | Does NOT follow symlinks (reports on the link itself) |
| `fstat` | Operates on an already-open fd |
| `fstatat` | Relative to dirfd; `AT_SYMLINK_NOFOLLOW` to not follow symlinks |

### 7.4 The `struct stat`

```c
struct stat {
    dev_t     st_dev;         // ID of device containing file
    ino_t     st_ino;         // Inode number
    mode_t    st_mode;        // File type and permissions
    nlink_t   st_nlink;       // Number of hard links
    uid_t     st_uid;         // User ID of owner
    gid_t     st_gid;         // Group ID of owner
    dev_t     st_rdev;        // Device ID (if special file)
    off_t     st_size;        // Total size in bytes
    blksize_t st_blksize;     // Block size for filesystem I/O
    blkcnt_t  st_blocks;      // Number of 512B blocks allocated
    struct timespec st_atim;  // Time of last access
    struct timespec st_mtim;  // Time of last modification
    struct timespec st_ctim;  // Time of last status change
};
```

### 7.5 Kernel Implementation

```c
SYSCALL_DEFINE2(stat, const char __user *, filename, struct stat __user *, statbuf)
{
    struct kstat stat;
    int ret = vfs_stat(filename, &stat);
    if (ret)
        return ret;
    return cp_stat(statbuf, &stat);  // Copy to user space
}
```

**Path resolution for `stat`:**
1. Walk the directory tree
2. For each component, call the filesystem's `lookup` method
3. At the final component, call the inode's `getattr` method
4. Fill in the `kstat` structure

### 7.6 Error Codes

| Error | Description |
|-------|-------------|
| `EACCES` | Permission denied (search permission on directory) |
| `EBADF` | Bad file descriptor (fstat) |
| `EFAULT` | Invalid address for statbuf |
| `ELOOP` | Too many symbolic links |
| `ENAMETOOLONG` | Path too long |
| `ENOENT` | File does not exist |
| `ENOTDIR` | Component of path is not a directory |

### 7.7 Example

```c
#include <sys/stat.h>
#include <stdio.h>
#include <time.h>

int main(int argc, char *argv[])
{
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <file>\n", argv[0]);
        return 1;
    }
    
    struct stat st;
    if (lstat(argv[1], &st) < 0) {
        perror("lstat");
        return 1;
    }
    
    printf("File: %s\n", argv[1]);
    printf("Size: %ld bytes\n", (long)st.st_size);
    printf("Inode: %lu\n", (unsigned long)st.st_ino);
    printf("Links: %lu\n", (unsigned long)st.st_nlink);
    printf("Permissions: %o\n", st.st_mode & 07777);
    printf("Owner: %d:%d\n", st.st_uid, st.st_gid);
    printf("Last access: %s", ctime(&st.st_atim.tv_sec));
    printf("Last modify: %s", ctime(&st.st_mtim.tv_sec));
    printf("Last change: %s", ctime(&st.st_ctim.tv_sec));
    
    // File type
    printf("Type: ");
    switch (st.st_mode & S_IFMT) {
    case S_IFREG:  printf("regular file\n"); break;
    case S_IFDIR:  printf("directory\n"); break;
    case S_IFLNK:  printf("symbolic link\n"); break;
    case S_IFBLK:  printf("block device\n"); break;
    case S_IFCHR:  printf("character device\n"); break;
    case S_IFIFO:  printf("FIFO/pipe\n"); break;
    case S_IFSOCK: printf("socket\n"); break;
    default:       printf("unknown\n"); break;
    }
    
    return 0;
}
```

### 7.8 Timestamps

The three timestamps have specific meanings:

- **`st_atim` (access time)**: Updated when the file is read. Can be mounted with `noatime`/`relatime` to reduce writes.
- **`st_mtim` (modification time)**: Updated when file data is modified.
- **`st_ctim` (change time)**: Updated when metadata (permissions, ownership) or data changes. Cannot be set by user.

The `relatime` mount option (default since Linux 2.6.30) updates `atime` only if:
- `atime` < `mtime`
- `atime` < `ctime`
- `atime` is more than 24 hours old

### 7.9 `statx` (Linux 4.11+)

A modern replacement for stat that provides more information:

```c
#include <sys/stat.h>
int statx(int dirfd, const char *pathname, int flags, unsigned int mask, struct statx *statxbuf);
```

Advantages:
- Nanosecond timestamps (already in stat, but statx makes it clearer)
- Birth/creation time (`stx_btime`)
- Extended attributes
- Selective querying (faster when you only need specific fields)

---

## 8. access / faccessat

### 8.1 Purpose

`access` checks whether the calling process can access a file with the specified mode. It uses the **real** user/group IDs (not the effective IDs), making it useful for setuid programs.

### 8.2 Prototype

```c
#include <unistd.h>

int access(const char *pathname, int mode);
int faccessat(int dirfd, const char *pathname, int mode, int flags);
```

### 8.3 Arguments

**`mode`**: Bitmask of access types:

| Mode | Value | Description |
|------|-------|-------------|
| `F_OK` | 0 | File exists |
| `R_OK` | 4 | Read permission |
| `W_OK` | 2 | Write permission |
| `X_OK` | 1 | Execute permission |

### 8.4 Return Values

- **Success**: 0 (access granted)
- **Failure**: -1 with `errno` set

### 8.5 Error Codes

| Error | Description |
|-------|-------------|
| `EACCES` | Permission denied |
| `ELOOP` | Too many symbolic links |
| `ENAMETOOLONG` | Path too long |
| `ENOENT` | File does not exist |
| `ENOTDIR` | Component of path is not a directory |
| `EROFS` | Write requested on read-only filesystem |
| `ETXTBSY` | Write requested on running executable |

### 8.6 Security Warning

**Never use `access()` as a guard before `open()`**. This is a classic TOCTOU (Time-of-Check-Time-of-Use) race condition:

```c
// DANGEROUS: Race condition
if (access(filename, W_OK) == 0) {
    // Between access() and open(), the file could be replaced
    // with a symlink to /etc/shadow
    fd = open(filename, O_WRONLY);
}
```

**Better alternatives:**
- Use `faccessat()` with `AT_EACCESS` and `AT_SYMLINK_NOFOLLOW`
- Open the file first, then use `fstat()` to check permissions
- Use `O_NOFOLLOW` to prevent symlink attacks

### 8.7 Kernel Implementation

```c
SYSCALL_DEFINE2(access, const char __user *, filename, int, mode)
{
    return do_faccessat(AT_FDCWD, filename, mode, 0);
}

static int do_faccessat(int dfd, const char __user *filename, int mode, int flags)
{
    struct path path;
    struct inode *inode;
    
    // Resolve path
    user_path_at(dfd, filename, lookup_flags, &path);
    inode = path.dentry->d_inode;
    
    // Check permissions using REAL uid/gid (not effective)
    if (!(flags & AT_EACCESS)) {
        // Use real IDs
        res = inode_permission(inode, mode, &cred->uid, &cred->gid);
    } else {
        // Use effective IDs
        res = inode_permission(inode, mode, &cred->euid, &cred->egid);
    }
    
    path_put(&path);
    return res;
}
```

### 8.8 `faccessat2` (Linux 5.8)

```c
int faccessat2(int dirfd, const char *pathname, int mode, int flags);
```

Adds the `AT_EACCESS` flag properly (checking effective IDs instead of real IDs).

---

## 9. Scatter/Gather I/O (Brief Note)

While `read` and `write` operate on a single buffer, scatter/gather I/O (covered in Chapter 126) allows reading into or writing from multiple buffers in a single syscall:

- `readv()` — scatter read (one fd → multiple buffers)
- `writev()` — gather write (multiple buffers → one fd)

---

## 10. File Descriptor Lifecycle

Understanding the full lifecycle of a file descriptor:

```
open/openat  →  fd number allocated  →  read/write/lseek  →  close
     │                                        │
     │         dup/dup2/dup3 → new fd          │
     │                                        │
     │         fcntl → modify flags            │
     │                                        │
     └────────────────────────────────────────┘
                  (reference counted)
```

### 10.1 File Descriptor Table

Each process has a file descriptor table (in `struct files_struct`):

```c
struct files_struct {
    struct fdtable __rcu *fdt;    // Pointer to fd table
    struct file __rcu *fd_array[NR_OPEN_DEFAULT]; // Small inline array
};

struct fdtable {
    unsigned int max_fds;
    struct file __rcu **fd;       // Array of file pointers
    unsigned long *close_on_exec; // Close-on-exec bitmap
    unsigned long *open_fds;      // Open fds bitmap
};
```

When a process opens file descriptor 5, the kernel sets `files->fdt->fd[5]` to point to the `struct file`.

### 10.2 The `struct file`

```c
struct file {
    union {
        struct llist_node fu_llist;
        struct rcu_head fu_rcuhead;
    } f_u;
    struct path f_path;           // Dentry + vfsmount
    struct inode *f_inode;
    const struct file_operations *f_op;  // File operations vtable
    spinlock_t f_lock;
    atomic_long_t f_count;        // Reference count
    unsigned int f_flags;         // O_RDONLY, O_NONBLOCK, etc.
    fmode_t f_mode;               // FMODE_READ, FMODE_WRITE
    struct mutex f_pos_lock;
    loff_t f_pos;                 // Current file position
    struct fown_struct f_owner;
    void *private_data;           // Driver-specific data
};
```

---

## 11. Kernel Source References

- **`open`/`openat`**: `fs/open.c`
- **`read`/`write`**: `fs/read_write.c`
- **`close`**: `fs/open.c`
- **`lseek`**: `fs/read_write.c`
- **`stat` family**: `fs/stat.c`
- **`access`**: `fs/open.c`
- **VFS layer**: `fs/namei.c` (path resolution)
- **File descriptor management**: `fs/file.c`, `include/linux/fdtable.h`
- **`struct file`**: `include/linux/fs.h`

---

## 12. Summary

The file I/O syscalls form the backbone of Linux I/O. Every higher-level I/O operation — buffered I/O, memory-mapped files, asynchronous I/O — ultimately relies on these syscalls. Understanding their semantics, error handling, and kernel implementation is essential for writing correct, efficient, and secure systems code.

Key takeaways:
- Always use `openat` with `O_CLOEXEC` and `O_NOFOLLOW` where appropriate
- Handle partial reads/writes and `EINTR`
- Never use `access()` before `open()` (TOCTOU race)
- Use `fstat` instead of `stat` when you already have an fd
- Close file descriptors as soon as possible; use `close_range` for bulk cleanup
- Understand the difference between buffered and synchronous I/O
