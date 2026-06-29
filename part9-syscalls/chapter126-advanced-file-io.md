# Chapter 126: Advanced File I/O

## 1. Introduction

While the basic `read`/`write` syscalls handle most file I/O, they have limitations: they can only read into or write from a single contiguous buffer, they always advance the file position, and copying data between files requires reading into user space and writing back. Advanced file I/O syscalls address these limitations with scatter/gather I/O, zero-copy transfers, and position-independent I/O.

---

## 2. pread / pwrite

### 2.1 Purpose

`pread` and `pwrite` perform positional I/O — they read/write at a specified offset without changing the file descriptor's current position. This avoids the race condition of `lseek` followed by `read`/`write` in multithreaded programs.

### 2.2 Prototype

```c
#include <unistd.h>
ssize_t pread(int fd, void *buf, size_t count, off_t offset);
ssize_t pwrite(int fd, const void *buf, size_t count, off_t offset);
```

### 2.3 Arguments

- **`fd`**: Open file descriptor
- **`buf`**: Buffer for data
- **`count`**: Number of bytes
- **`offset`**: File position to read from/write to

### 2.4 Return Values

- **Success**: Number of bytes read/written
- **Failure**: -1 with `errno` set

### 2.5 Error Codes

Same as `read`/`write`, plus:

| Error | Description |
|-------|-------------|
| `EINVAL` | Offset is negative (on some filesystems) |
| `ESPIPE` | fd refers to a pipe or socket |

### 2.6 Kernel Implementation

```c
SYSCALL_DEFINE4(pread64, unsigned int, fd, char __user *, buf, size_t, count, loff_t, pos)
{
    struct fd f;
    ssize_t ret = -EBADF;
    
    f = fdget(fd);
    if (f.file) {
        ret = -ESPIPE;
        if (f.file->f_mode & FMODE_PREAD)
            ret = vfs_read(f.file, buf, count, &pos);
        fdput(f);
    }
    return ret;
}
```

Key difference from `read`: the `pos` parameter is a local variable, not the file's `f_pos`. The file descriptor's current position is **not modified**.

### 2.7 Thread Safety

```c
// UNSAFE: lseek + read is not atomic
lseek(fd, offset, SEEK_SET);    // Thread A here
                                  // Thread B does lseek to different offset!
read(fd, buf, count);            // Thread A reads from wrong offset!

// SAFE: pread is atomic with respect to the file position
pread(fd, buf, count, offset);  // Always reads from specified offset
```

### 2.8 Example

```c
#include <fcntl.h>
#include <unistd.h>
#include <stdio.h>
#include <string.h>
#include <pthread.h>

#define NUM_THREADS 4
#define BLOCK_SIZE 256

static int fd;

void *reader(void *arg)
{
    long id = (long)arg;
    off_t offset = id * BLOCK_SIZE;
    char buf[BLOCK_SIZE + 1] = {};
    
    ssize_t n = pread(fd, buf, BLOCK_SIZE, offset);
    if (n > 0) {
        printf("Thread %ld (offset %ld): %s\n", id, (long)offset, buf);
    }
    return NULL;
}

int main(void)
{
    fd = open("/etc/services", O_RDONLY);
    if (fd < 0) { perror("open"); return 1; }
    
    pthread_t threads[NUM_THREADS];
    for (long i = 0; i < NUM_THREADS; i++)
        pthread_create(&threads[i], NULL, reader, (void *)i);
    
    for (int i = 0; i < NUM_THREADS; i++)
        pthread_join(threads[i], NULL);
    
    close(fd);
    return 0;
}
```

### 2.9 Limitations

- Not all file types support `pread`/`pwrite`. Pipes and sockets return `ESPIPE`.
- The offset must be non-negative.
- On 32-bit systems, `pread64`/`pwrite64` are needed for large files (>2GB).

---

## 3. readv / writev

### 3.1 Purpose

Scatter/gather I/O allows reading into or writing from multiple non-contiguous buffers in a single syscall. `readv` scatters data from one fd into multiple buffers; `writev` gathers data from multiple buffers into one fd.

### 3.2 Prototype

```c
#include <sys/uio.h>
ssize_t readv(int fd, const struct iovec *iov, int iovcnt);
ssize_t writev(int fd, const struct iovec *iov, int iovcnt);
```

### 3.3 The `iovec` Structure

```c
struct iovec {
    void  *iov_base;    // Starting address of buffer
    size_t iov_len;     // Length of buffer
};
```

### 3.4 Arguments

- **`fd`**: Open file descriptor
- **`iov`**: Array of `iovec` structures
- **`iovcnt`**: Number of elements in the array (max `IOV_MAX`, typically 1024)

### 3.5 Return Values

- **Success**: Total number of bytes read/written
- **Failure**: -1 with `errno` set

### 3.6 Kernel Implementation

```c
SYSCALL_DEFINE3(readv, unsigned long, fd, const struct iovec __user *, vec, unsigned long, vlen)
{
    return vfs_readv(fd, vec, vlen, NULL);
}

SYSCALL_DEFINE3(writev, unsigned long, fd, const struct iovec __user *, vec, unsigned long, vlen)
{
    return vfs_writev(fd, vec, vlen, NULL);
}
```

The kernel calls `copy_from_user` to read the `iovec` array, then iterates through each buffer. For `writev`, the kernel may use the `iov_iter` abstraction to efficiently gather data from multiple buffers.

### 3.7 Performance Benefits

**Without `writev` (3 syscalls):**
```c
write(fd, header, header_len);
write(fd, body, body_len);
write(fd, trailer, trailer_len);
```

**With `writev` (1 syscall):**
```c
struct iovec iov[3] = {
    { .iov_base = header, .iov_len = header_len },
    { .iov_base = body,   .iov_len = body_len },
    { .iov_base = trailer, .iov_len = trailer_len },
};
writev(fd, iov, 3);
```

Benefits:
- Fewer syscall transitions
- Atomic write (for pipes) — data from all buffers is written without interleaving
- The kernel can optimize the copy (e.g., DMA scatter-gather lists)

### 3.8 Atomicity for Pipes

For pipes and sockets, `writev` is atomic: the data from all buffers is written as a single unit. This means another process reading from the pipe will either see all the data or none of it (for a single `read` call).

### 3.9 Example: HTTP Response

```c
#include <sys/uio.h>
#include <string.h>
#include <fcntl.h>

int send_http_response(int client_fd, const char *body, size_t body_len)
{
    char header[512];
    int header_len = snprintf(header, sizeof(header),
        "HTTP/1.1 200 OK\r\n"
        "Content-Length: %zu\r\n"
        "Connection: close\r\n"
        "\r\n", body_len);
    
    struct iovec iov[2] = {
        { .iov_base = header, .iov_len = header_len },
        { .iov_base = (void *)body, .iov_len = body_len },
    };
    
    return writev(client_fd, iov, 2);
}
```

### 3.10 `preadv` / `pwritev` (Linux 2.6.30+)

Positional scatter/gather I/O:

```c
ssize_t preadv(int fd, const struct iovec *iov, int iovcnt, off_t offset);
ssize_t pwritev(int fd, const struct iovec *iov, int iovcnt, off_t offset);
```

### 3.11 `preadv2` / `pwritev2` (Linux 4.6+)

With additional flags:

```c
ssize_t preadv2(int fd, const struct iovec *iov, int iovcnt, off_t offset, int flags);
ssize_t pwritev2(int fd, const struct iovec *iov, int iovcnt, off_t offset, int flags);
```

Flags include `RWF_HIPRI` (high priority I/O), `RWF_DSYNC`, `RWF_SYNC`, `RWF_NOWAIT`.

---

## 4. sendfile

### 4.1 Purpose

`sendfile` transfers data between two file descriptors without copying data through user space. This "zero-copy" approach is critical for high-performance network servers serving static files.

### 4.2 Prototype

```c
#include <sys/sendfile.h>
ssize_t sendfile(int out_fd, int in_fd, off_t *offset, size_t count);
```

### 4.3 Arguments

- **`out_fd`**: Output file descriptor (must be a socket)
- **`in_fd`**: Input file descriptor (must be a file that supports `mmap`-like operations)
- **`offset`**: If non-NULL, file offset to start reading from (updated on return)
- **`count`**: Number of bytes to transfer

### 4.4 Return Values

- **Success**: Number of bytes transferred
- **Failure**: -1 with `errno` set

### 4.5 Kernel Implementation

```c
SYSCALL_DEFINE4(sendfile, int, out_fd, int, in_fd, off_t __user *, offset, size_t, count)
{
    loff_t pos;
    off_t off;
    ssize_t ret;
    
    if (offset) {
        if (copy_from_user(&off, offset, sizeof(off)))
            return -EFAULT;
        pos = off;
    }
    
    ret = do_sendfile(out_fd, in_fd, offset ? &pos : NULL, count, 0);
    
    if (offset && copy_to_user(offset, &pos, sizeof(pos)))
        ret = -EFAULT;
    
    return ret;
}
```

The kernel's `do_sendfile` uses the `splice` infrastructure internally (see below).

### 4.6 Traditional vs sendfile

**Traditional approach (2 context switches + 2 copies):**
```
[Disk] → read() → [User Buffer] → write() → [Socket Buffer] → [Network]
                  (copy 1)                    (copy 2)
```

**sendfile approach (1 context switch + possible 0 copies):**
```
[Disk] → [Page Cache] → [Socket Buffer] → [Network]
         (kernel-internal, no user-space copy)
```

On Linux with `splice` support, `sendfile` can achieve true zero-copy using `struct pipe_buffer` references to page cache pages.

### 4.7 Example

```c
#include <sys/sendfile.h>
#include <fcntl.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <sys/stat.h>
#include <unistd.h>

int serve_file(int client_fd, const char *filename)
{
    int file_fd = open(filename, O_RDONLY);
    if (file_fd < 0) return -1;
    
    struct stat st;
    fstat(file_fd, &st);
    
    // Send HTTP header
    char header[256];
    int hlen = snprintf(header, sizeof(header),
        "HTTP/1.1 200 OK\r\nContent-Length: %ld\r\n\r\n", (long)st.st_size);
    write(client_fd, header, hlen);
    
    // Send file content — zero-copy!
    off_t offset = 0;
    ssize_t sent = 0;
    while (sent < st.st_size) {
        ssize_t n = sendfile(client_fd, file_fd, &offset, st.st_size - sent);
        if (n <= 0) break;
        sent += n;
    }
    
    close(file_fd);
    return sent;
}
```

### 4.8 Limitations

- `in_fd` must support `mmap`-like operations (regular files, not sockets)
- `out_fd` must be a socket (since Linux 2.6.33, some versions allow any writable fd)
- Cannot send from one socket to another (use `splice` for that)

---

## 5. splice

### 5.1 Purpose

`splice` moves data between two file descriptors without copying through user space. Unlike `sendfile`, it can move data between any two descriptors, as long as at least one is a pipe.

### 5.2 Prototype

```c
#include <fcntl.h>
ssize_t splice(int fd_in, off_t *off_in, int fd_out, off_t *off_out,
               size_t len, unsigned int flags);
```

### 5.3 Arguments

- **`fd_in`**: Input file descriptor
- **`off_in`**: Input offset (NULL = use current position)
- **`fd_out`**: Output file descriptor
- **`off_out`**: Output offset (NULL = use current position)
- **`len`**: Number of bytes to move
- **`flags`**: Control flags

| Flag | Description |
|------|-------------|
| `SPLICE_F_MOVE` | Attempt to move pages (hint, not required) |
| `SPLICE_F_NONBLOCK` | Non-blocking operation |
| `SPLICE_F_MORE` | Hint that more data will follow |
| `SPLICE_F_GIFT` | Pages are "gifted" (will not be modified) |

### 5.4 The Pipe Requirement

`splice` uses pipes as an intermediary. At least one of `fd_in` or `fd_out` must be a pipe. The data flows through kernel-internal pipe buffers without entering user space.

### 5.5 Example: File to Socket

```c
// sendfile() is actually implemented using splice() internally
// But here's how to do it manually:

int pipefd[2];
pipe(pipefd);

// splice file → pipe
splice(file_fd, &offset, pipefd[1], NULL, len, SPLICE_F_MOVE);

// splice pipe → socket
splice(pipefd[0], NULL, sock_fd, NULL, len, SPLICE_F_MOVE);
```

### 5.6 Example: Socket to Socket

```c
// Proxy data between two sockets
void proxy(int from_fd, int to_fd)
{
    int pipefd[2];
    pipe(pipefd);
    
    while (1) {
        ssize_t n = splice(from_fd, NULL, pipefd[1], NULL, 65536, SPLICE_F_MORE);
        if (n <= 0) break;
        
        ssize_t sent = 0;
        while (sent < n) {
            ssize_t m = splice(pipefd[0], NULL, to_fd, NULL, n - sent, SPLICE_F_MORE);
            if (m <= 0) break;
            sent += m;
        }
    }
    
    close(pipefd[0]);
    close(pipefd[1]);
}
```

---

## 6. tee

### 6.1 Purpose

`tee` duplicates data from one pipe to another without consuming the data. It's like a "T-splitter" for pipe data. Combined with `splice`, it can duplicate a data stream.

### 6.2 Prototype

```c
#include <fcntl.h>
ssize_t tee(int fd_in, int fd_out, size_t len, unsigned int flags);
```

### 6.3 Arguments

- **`fd_in`**: Input pipe file descriptor
- **`fd_out`**: Output pipe file descriptor
- **`len`**: Number of bytes to duplicate
- **`flags`**: Same as `splice`

### 6.4 Example: Duplicate a Stream

```c
// Copy stdin to two different outputs
int pipe1[2], pipe2[2];
pipe(pipe1);
pipe(pipe2);

// Read from stdin into pipe1
splice(STDIN_FILENO, NULL, pipe1[1], NULL, 4096, 0);

// Duplicate pipe1 data to pipe2
tee(pipe1[0], pipe2[1], 4096, 0);

// Now pipe1[0] and pipe2[0] both have the data
splice(pipe1[0], NULL, output1_fd, NULL, 4096, 0);
splice(pipe2[0], NULL, output2_fd, NULL, 4096, 0);
```

---

## 7. copy_file_range

### 7.1 Purpose

`copy_file_range` (Linux 4.5+) copies data between two file descriptors without transferring data through user space. Unlike `sendfile`, both descriptors can be regular files on the same filesystem, enabling the filesystem to perform server-side copy (e.g., reflink/CoW on btrfs, NFS server-side copy).

### 7.2 Prototype

```c
#include <unistd.h>
ssize_t copy_file_range(int fd_in, off_t *off_in, int fd_out, off_t *off_out,
                        size_t len, unsigned int flags);
```

### 7.3 Arguments

- **`fd_in`**: Source file descriptor
- **`off_in`**: Source offset (NULL = use current position)
- **`fd_out`**: Destination file descriptor
- **`off_out`**: Destination offset (NULL = use current position)
- **`len`**: Number of bytes to copy
- **`flags`**: Currently must be 0

### 7.4 Return Values

- **Success**: Number of bytes copied
- **Failure**: -1 with `errno` set

### 7.5 Kernel Implementation

```c
SYSCALL_DEFINE6(copy_file_range, int, fd_in, loff_t __user *, off_in,
                int, fd_out, loff_t __user *, off_out,
                size_t, len, unsigned int, flags)
{
    // ... validation ...
    
    // Try filesystem-specific copy (server-side copy)
    if (file_in->f_op->copy_file_range) {
        ret = file_in->f_op->copy_file_range(file_in, off_in, file_out,
                                               off_out, len, flags);
    } else {
        // Fallback to generic copy (read + write in kernel space)
        ret = vfs_copy_file_range(file_in, off_in, file_out, off_out, len, flags);
    }
}
```

### 7.6 Filesystem Support

- **btrfs**: Server-side copy with reflink (copy-on-write). Instant for large files.
- **NFS**: Server-side copy (RFC 7862). Data never touches the client.
- **XFS, ext4**: Falls back to generic kernel-space copy.
- **OverlayFS**: Supported for copy-up operations.

### 7.7 Example

```c
#include <fcntl.h>
#include <unistd.h>
#include <stdio.h>
#include <sys/stat.h>

int main(int argc, char *argv[])
{
    if (argc != 3) {
        fprintf(stderr, "Usage: %s <src> <dst>\n", argv[0]);
        return 1;
    }
    
    int src = open(argv[1], O_RDONLY);
    if (src < 0) { perror("open src"); return 1; }
    
    int dst = open(argv[2], O_WRONLY | O_CREAT | O_TRUNC, 0644);
    if (dst < 0) { perror("open dst"); close(src); return 1; }
    
    struct stat st;
    fstat(src, &st);
    
    off_t offset = 0;
    ssize_t total = 0;
    while (total < st.st_size) {
        ssize_t n = copy_file_range(src, &offset, dst, NULL, st.st_size - total, 0);
        if (n <= 0) break;
        total += n;
    }
    
    printf("Copied %zd bytes\n", total);
    close(src);
    close(dst);
    return 0;
}
```

### 7.8 Advantages Over sendfile

- Both fds can be regular files (not just socket output)
- Filesystem can optimize (reflinks, server-side copy)
- Works with any regular file, not just mmap-able files

---

## 8. Detailed Kernel Internals: The splice Infrastructure

### 8.1 How splice Works Internally

`splice` doesn't actually copy data. Instead, it manipulates pipe buffer references:

```
1. splice(file_fd -> pipe_fd):
   - Read file page cache pages
   - Create pipe_buffer entries pointing to those pages
   - No data copy - just pointer/struct manipulation

2. splice(pipe_fd -> socket_fd):
   - Take pipe_buffer entries
   - Pass them to the socket's sendmsg
   - Network stack uses the pages directly for DMA
```

### 8.2 The struct pipe_buffer

```c
struct pipe_buffer {
    struct page *page;      // Physical page
    unsigned int offset;    // Offset within page
    unsigned int len;       // Length of data
    const struct pipe_buf_operations *ops;
};
```

The key insight: `splice` passes page references, not data copies. The page cache pages used by the file are the same pages passed to the network stack for transmission.

### 8.3 The iov_iter Abstraction

The kernel uses `struct iov_iter` to abstract over different buffer types:

```c
struct iov_iter {
    unsigned int type;      // ITER_IOVEC, ITER_KVEC, ITER_PIPE, ITER_BVEC
    size_t count;           // Total bytes
    union {
        const struct iovec *iov;
        const struct kvec *kvec;
        const struct bio_vec *bvec;
        struct pipe_inode_info *pipe;
    };
};
```

This abstraction allows the same code paths to handle user buffers, kernel buffers, pipe buffers, and bio vectors (disk I/O).

### 8.4 sendfile Internal Implementation

Modern `sendfile` is implemented as two `splice` calls internally:

```c
ssize_t do_sendfile(int out_fd, int in_fd, loff_t *ppos, size_t count, ...)
{
    struct fd in = fdget(in_fd);
    struct fd out = fdget(out_fd);
    retval = splice_direct_to_actor(in, &pipe, out, direct_splice_actor);
    return retval;
}
```

The `splice_direct_to_actor` function creates a temporary pipe internally, splices from the input file to the pipe, then calls the actor (which splices from the pipe to the output).

### 8.5 Zero-Copy Networking

For true zero-copy networking with `sendfile`/`splice`, the kernel needs:

1. **Network driver support**: The NIC must support scatter-gather DMA
2. **Page pinning**: Pages must not be reclaimed during transmission
3. **MSG_ZEROCOPY**: For `sendmsg`, the `MSG_ZEROCOPY` flag enables zero-copy

```c
sendmsg(fd, &msg, MSG_ZEROCOPY);
```

### 8.6 Pipe Buffer Limits

Each pipe has a limited number of buffers (default 16) and total capacity (default 64 pages = 256KB). These can be adjusted:

```c
fcntl(pipefd[1], F_SETPIPE_SZ, 1024 * 1024);  // 1MB
int size = fcntl(pipefd[0], F_GETPIPE_SZ);
```

For large `splice` transfers, the kernel handles pipe buffer management automatically - it splices in chunks that fit the pipe capacity.

### 8.7 Direct I/O and splice

`splice` works best with page-cache-backed files. For `O_DIRECT` files, the kernel must perform an extra copy because `O_DIRECT` uses its own buffers (not page cache). This is an important performance consideration.

---

## 9. Performance Comparison

| Method | Context Switches | Memory Copies | Use Case |
|--------|-----------------|---------------|----------|
| `read`+`write` | 2 | 2 (user space) | Simple file copy |
| `sendfile` | 1 | 0-1 (kernel) | File to socket |
| `splice` | 1-2 | 0 (kernel) | Any fd to/from pipe |
| `copy_file_range` | 1 | 0 (server-side) | File to file (same fs) |
| `mmap`+`write` | 1 | 1 (page fault) | Large files |

For large file transfers, `sendfile` and `splice` can be 2-3x faster than `read`+`write` due to eliminated user-space copies.

---

## 10. Security Implications

- **`sendfile`/`splice`**: Data never enters user space, preventing data leakage through memory inspection.
- **`copy_file_range`**: Preserves file attributes. Be careful with ownership/permissions when copying between different contexts.
- **Pipe buffer limits**: `splice` and `tee` use pipe buffers (default 64KB per pipe). Large transfers need multiple iterations.

---

## 11. Common Bugs

```c
// BUG: Not checking sendfile return for partial transfers
sendfile(out_fd, in_fd, &offset, count);  // Might send less than count!

// FIX: Loop until all data sent
ssize_t total = 0;
while (total < count) {
    ssize_t n = sendfile(out_fd, in_fd, &offset, count - total);
    if (n <= 0) break;
    total += n;
}

// BUG: Using splice without a pipe
splice(socket_fd, NULL, file_fd, NULL, 4096, 0);  // EINVAL — need a pipe!

// FIX: One of the fds must be a pipe
int pipefd[2];
pipe(pipefd);
splice(socket_fd, NULL, pipefd[1], NULL, 4096, 0);
splice(pipefd[0], NULL, file_fd, NULL, 4096, 0);
```

---

## 12. Kernel Source References

- **`pread`/`pwrite`**: `fs/read_write.c`
- **`readv`/`writev`**: `fs/read_write.c`, `lib/iov_iter.c`
- **`sendfile`**: `fs/read_write.c`, `net/socket.c`
- **`splice`**: `fs/splice.c`
- **`tee`**: `fs/splice.c`
- **`copy_file_range`**: `fs/read_write.c`
- **Pipe buffer management**: `fs/pipe.c`

---

## 13. Summary

Advanced file I/O syscalls solve real performance problems:
- **`pread`/`pwrite`**: Thread-safe positional I/O
- **`readv`/`writev`**: Scatter/gather I/O reduces syscall overhead
- **`sendfile`**: Zero-copy file-to-socket transfer
- **`splice`**: Zero-copy data movement between any fd and a pipe
- **`tee`**: Pipe duplication
- **`copy_file_range`**: Filesystem-optimized file copying

Choosing the right tool for the job can mean the difference between a fast server and a bottleneck. For high-performance I/O, always prefer zero-copy approaches when available.

### 9.8 Performance Tips for Advanced I/O

1. **Use `writev` instead of multiple `write` calls** — reduces syscall overhead and guarantees atomicity for pipes
2. **Prefer `sendfile`/`splice` for file-to-socket transfers** — eliminates user-space copies
3. **Use `copy_file_range` for file-to-file copies on the same filesystem** — enables reflinks and server-side copy
4. **Use `pread`/`pwrite` for concurrent file access** — avoids lseek race conditions
5. **Tune pipe buffer sizes** for large `splice` transfers — `fcntl(F_SETPIPE_SZ, 1MB)`
6. **Use `O_DIRECT` for large sequential I/O** — bypasses page cache (but requires aligned buffers)
7. **Combine `io_uring` with zero-copy** for maximum throughput
