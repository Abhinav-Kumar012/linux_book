# Chapter 139: io_uring

## 1. Introduction

`io_uring` is a high-performance asynchronous I/O interface introduced in Linux 5.1. It solves the fundamental problems of the older AIO interface: it supports all file types (not just O_DIRECT), provides true zero-copy, and uses shared memory rings to minimize syscall overhead. For high-performance I/O, `io_uring` is now the preferred interface.

---

## 2. Architecture Overview

### 2.1 The Ring Buffers

`io_uring` uses two ring buffers shared between user space and kernel:

```
User Space                    Kernel
┌─────────────┐              ┌─────────────┐
│  Submission  │───submit───→│  Submission  │
│    Queue     │              │   Queue     │
│   (SQ ring)  │              │  (SQ ring)  │
└─────────────┘              └──────┬──────┘
                                    │ process
┌─────────────┐              ┌──────┴──────┐
│  Completion  │←──notify────│  Completion  │
│    Queue     │              │   Queue     │
│   (CQ ring)  │              │  (CQ ring)  │
└─────────────┘              └─────────────┘
```

- **Submission Queue (SQ)**: User space writes I/O requests (SQEs), kernel reads them
- **Completion Queue (CQ)**: Kernel writes completions (CQEs), user space reads them

### 2.2 The Flow

1. User space prepares an SQE (submission queue entry) describing the I/O operation
2. User space updates the SQ tail pointer
3. User space calls `io_uring_enter()` to notify the kernel (or uses `IORING_SETUP_SQPOLL` to avoid this)
4. Kernel processes SQEs and writes CQEs to the CQ
5. User space reads CQEs from the CQ head pointer

---

## 3. io_uring_setup

### 3.1 Purpose

`io_uring_setup` creates an io_uring instance and returns a file descriptor.

### 3.2 Prototype

```c
#include <linux/io_uring.h>
int io_uring_setup(unsigned int entries, struct io_uring_params *params);
```

### 3.3 Arguments

- **`entries`**: Number of SQ entries (power of 2, typically 256-4096)
- **`params`**: Configuration parameters (input/output)

### 3.4 The `io_uring_params` Structure

```c
struct io_uring_params {
    __u32 sq_entries;        // SQ ring size (output)
    __u32 cq_entries;        // CQ ring size (output)
    __u32 flags;             // Setup flags
    __u32 sq_thread_cpu;     // SQ polling thread CPU
    __u32 sq_thread_idle;    // SQ polling thread idle timeout (ms)
    __u32 features;          // Supported features (output)
    __u32 wq_fd;             // Workqueue fd (shared rings)
    __u32 resv[3];
    struct io_sqring_offsets sq_off;  // SQ ring offsets (output)
    struct io_cqring_offsets cq_off;  // CQ ring offsets (output)
};
```

### 3.5 Setup Flags

| Flag | Description |
|------|-------------|
| `IORING_SETUP_IOPOLL` | Use busy-polling for I/O completion |
| `IORING_SETUP_SQPOLL` | Kernel thread polls SQ for submissions |
| `IORING_SETUP_SQ_AFF` | Pin SQ polling thread to CPU |
| `IORING_SETUP_CQSIZE` | User specifies CQ size |
| `IORING_SETUP_CLAMP` | Clamp parameters to valid range |
| `IORING_SETUP_R_DISABLED` | Start with ring disabled |
| `IORING_SETUP_SUBMIT_ALL` | Submit all SQEs even if one fails |
| `IORING_SETUP_COOP_TASKRUN` | Cooperative task running (Linux 5.19+) |
| `IORING_SETUP_SINGLE_ISSUER` | Single-threaded submission (Linux 6.0+) |
| `IORING_SETUP_DEFER_TASKRUN` | Deferred task running (Linux 6.1+) |

### 3.6 Example Setup

```c
#include <linux/io_uring.h>
#include <sys/mman.h>
#include <sys/syscall.h>
#include <unistd.h>

struct io_uring ring;

int io_uring_setup_rings(unsigned int entries)
{
    struct io_uring_params params = {0};
    
    int ring_fd = syscall(__NR_io_uring_setup, entries, &params);
    if (ring_fd < 0) return -1;
    
    // Map the SQ ring
    void *sq_ptr = mmap(NULL, params.sq_off.array + params.sq_entries * sizeof(__u32),
                        PROT_READ | PROT_WRITE, MAP_SHARED | MAP_POPULATE,
                        ring_fd, IORING_OFF_SQ_RING);
    
    // Map the CQ ring
    void *cq_ptr = mmap(NULL, params.cq_off.cqes + params.cq_entries * sizeof(struct io_uring_cqe),
                        PROT_READ | PROT_WRITE, MAP_SHARED | MAP_POPULATE,
                        ring_fd, IORING_OFF_CQ_RING);
    
    // Map the SQEs array
    void *sqes = mmap(NULL, params.sq_entries * sizeof(struct io_uring_sqe),
                      PROT_READ | PROT_WRITE, MAP_SHARED | MAP_POPULATE,
                      ring_fd, IORING_OFF_SQES);
    
    // Store pointers for later use
    ring.sq.ring = sq_ptr;
    ring.cq.ring = cq_ptr;
    ring.sq.sqes = sqes;
    ring.fd = ring_fd;
    ring.sq.mask = *(__u32 *)((char *)sq_ptr + params.sq_off.ring_mask);
    ring.cq.mask = *(__u32 *)((char *)cq_ptr + params.cq_off.ring_mask);
    
    return ring_fd;
}
```

---

## 4. io_uring_enter

### 4.1 Purpose

`io_uring_enter` submits SQEs to the kernel and/or waits for completions.

### 4.2 Prototype

```c
int io_uring_enter(int fd, unsigned int to_submit, unsigned int min_complete,
                   unsigned int flags, void *sig);
```

### 4.3 Arguments

- **`fd`**: io_uring file descriptor
- **`to_submit`**: Number of SQEs to submit (0 = just wait)
- **`min_complete`**: Minimum completions to wait for (0 = don't wait)
- **`flags`**: Control flags

| Flag | Description |
|------|-------------|
| `IORING_ENTER_GETEVENTS` | Wait for min_complete events |
| `IORING_ENTER_SQ_WAIT` | Wait for SQ to have space |
| `IORING_ENTER_EXT_ARG` | Use extended arguments |

### 4.4 Kernel Implementation

```c
SYSCALL_DEFINE6(io_uring_enter, unsigned int, fd, u32, to_submit,
                u32, min_complete, u32, flags, void __user *, sig, size_t, sigsz)
{
    struct fd f = fdget(fd);
    struct io_ring_ctx *ctx = f.file->private_data;
    
    if (to_submit)
        ret = io_submit_sqes(ctx, to_submit);
    
    if (flags & IORING_ENTER_GETEVENTS)
        ret = io_cqring_wait(ctx, min_complete, sig, sigsz);
    
    return ret;
}
```

---

## 5. SQE (Submission Queue Entry)

### 5.1 Structure

```c
struct io_uring_sqe {
    __u8  opcode;          // Operation code
    __u8  flags;           // SQE flags
    __u16 ioprio;          // I/O priority
    __s32 fd;              // File descriptor
    union {
        __u64 off;         // File offset
        __u64 addr2;
    };
    union {
        __u64 addr;        // Buffer address
        __u64 splice_off_in;
    };
    __u32 len;             // Buffer length
    union {
        __u32 rw_flags;    // Read/write flags
        __u32 fsync_flags;
        __u32 poll_events;
        __u32 sync_range_flags;
        __u32 msg_flags;
        __u32 timeout_flags;
        __u32 accept_flags;
        __u32 cancel_flags;
        __u32 open_flags;
        __u32 statx_flags;
        __u32 fadvise_advice;
        __u32 splice_flags;
    };
    __u64 user_data;       // User data (returned in CQE)
    union {
        __u16 buf_index;   // Buffer pool index
        __u16 buf_group;
    };
    __u16 personality;     // Credentials to use
    union {
        __s32 splice_fd_in;
        __u32 file_index;
    };
    __u64 __pad2[2];
};
```

### 5.2 Operation Codes

| Opcode | Description |
|--------|-------------|
| `IORING_OP_NOP` | No operation |
| `IORING_OP_READV` | Vectored read |
| `IORING_OP_WRITEV` | Vectored write |
| `IORING_OP_FSYNC` | File sync |
| `IORING_OP_READ_FIXED` | Read with pre-registered buffer |
| `IORING_OP_WRITE_FIXED` | Write with pre-registered buffer |
| `IORING_OP_POLL_ADD` | Add poll |
| `IORING_OP_POLL_REMOVE` | Remove poll |
| `IORING_OP_SYNC_FILE_RANGE` | Sync file range |
| `IORING_OP_SENDMSG` | Send message |
| `IORING_OP_RECVMSG` | Receive message |
| `IORING_OP_TIMEOUT` | Timeout |
| `IORING_OP_TIMEOUT_REMOVE` | Remove timeout |
| `IORING_OP_ACCEPT` | Accept connection |
| `IORING_OP_ASYNC_CANCEL` | Cancel async operation |
| `IORING_OP_LINK_TIMEOUT` | Linked timeout |
| `IORING_OP_CONNECT` | Connect |
| `IORING_OP_OPENAT` | Open file |
| `IORING_OP_CLOSE` | Close file |
| `IORING_OP_READ` | Read (Linux 5.6+) |
| `IORING_OP_WRITE` | Write (Linux 5.6+) |
| `IORING_OP_SPLICE` | Splice |
| `IORING_OP_TEE` | Tee |
| `IORING_OP_SHUTDOWN` | Shutdown socket |
| `IORING_OP_RENAMEAT` | Rename |
| `IORING_OP_UNLINKAT` | Unlink |
| `IORING_OP_MKDIRAT` | Mkdir |
| `IORING_OP_SYMLINKAT` | Symlink |
| `IORING_OP_LINKAT` | Link |
| `IORING_OP_FILES_UPDATE` | Update file table |
| `IORING_OP_PROVIDE_BUFFERS` | Provide buffer ring |
| `IORING_OP_REMOVE_BUFFERS` | Remove buffer ring |
| `IORING_OP_SEND_ZC` | Zero-copy send (Linux 6.0+) |

### 5.3 SQE Flags

| Flag | Description |
|------|-------------|
| `IOSQE_FIXED_FILE` | Use file index (pre-registered) |
| `IOSQE_IO_DRAIN` | Drain previous SQEs first |
| `IOSQE_IO_LINK` | Link with next SQE |
| `IOSQE_IO_HARDLINK` | Hard link (doesn't break on error) |
| `IOSQE_ASYNC` | Force async execution |
| `IOSQE_BUFFER_SELECT` | Select buffer from ring |

---

## 6. CQE (Completion Queue Entry)

### 6.1 Structure

```c
struct io_uring_cqe {
    __u64 user_data;   // User data from SQE
    __s32 res;         // Result (bytes or error code)
    __u32 flags;       // CQE flags
};
```

### 6.2 CQE Flags

| Flag | Description |
|------|-------------|
| `IORING_CQE_F_BUFFER` | Buffer ID in upper 16 bits of flags |
| `IORING_CQE_F_MORE` | More completions to follow |
| `IORING_CQE_F_SOCK_NONEMPTY` | Socket has more data |

---

## 7. Practical Example: File Copy

```c
#include <linux/io_uring.h>
#include <sys/mman.h>
#include <sys/syscall.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>

#define QUEUE_DEPTH 256
#define BLOCK_SIZE  4096

struct io_uring ring;

static int setup_io_uring(void)
{
    struct io_uring_params params = {0};
    ring.fd = syscall(__NR_io_uring_setup, QUEUE_DEPTH, &params);
    if (ring.fd < 0) return -1;
    
    // Map rings and SQEs (simplified — use liburing in production)
    // ...
    return 0;
}

static void submit_read(int fd, void *buf, off_t offset, size_t len)
{
    // Get SQE from ring
    unsigned int tail = *ring.sq.tail;
    unsigned int idx = tail & ring.sq.mask;
    struct io_uring_sqe *sqe = &ring.sq.sqes[idx];
    
    // Fill SQE
    memset(sqe, 0, sizeof(*sqe));
    sqe->opcode = IORING_OP_READ;
    sqe->fd = fd;
    sqe->addr = (unsigned long)buf;
    sqe->len = len;
    sqe->off = offset;
    sqe->user_data = (unsigned long)buf;  // Identify completion
    
    // Update tail
    ring.sq.array[idx] = idx;
    __atomic_store_n(ring.sq.tail, tail + 1, __ATOMIC_RELEASE);
}

static int submit_and_wait(int nr)
{
    return syscall(__NR_io_uring_enter, ring.fd, nr, nr,
                   IORING_ENTER_GETEVENTS, NULL);
}

int main(int argc, char *argv[])
{
    if (argc != 3) return 1;
    
    int src = open(argv[1], O_RDONLY);
    int dst = open(argv[2], O_WRONLY | O_CREAT | O_TRUNC, 0644);
    
    setup_io_uring();
    
    char buf[BLOCK_SIZE];
    off_t offset = 0;
    ssize_t total = 0;
    
    // Submit read
    submit_read(src, buf, offset, BLOCK_SIZE);
    submit_and_wait(1);
    
    // Process completion
    unsigned int head = *ring.cq.head;
    struct io_uring_cqe *cqe = &ring.cq.cqes[head & ring.cq.mask];
    ssize_t bytes = cqe->res;
    __atomic_store_n(ring.cq.head, head + 1, __ATOMIC_RELEASE);
    
    if (bytes > 0) {
        write(dst, buf, bytes);
        total += bytes;
        offset += bytes;
    }
    
    close(src);
    close(dst);
    return 0;
}
```

---

## 8. Advanced Features

### 8.1 SQ Polling (`IORING_SETUP_SQPOLL`)

The kernel creates a thread that continuously polls the SQ for new entries. This eliminates the `io_uring_enter` syscall entirely, achieving near-zero syscall overhead.

```c
struct io_uring_params params = {
    .flags = IORING_SETUP_SQPOLL,
    .sq_thread_idle = 10000,  // 10 seconds idle before sleeping
};
```

### 8.2 Fixed Files

Pre-register file descriptors to avoid fd lookup overhead:

```c
int fds[] = { fd1, fd2, fd3 };
io_uring_register(ring.fd, IORING_REGISTER_FILES, fds, 3);

// In SQE, use file_index instead of fd
sqe->fd = 0;  // Index into registered files
sqe->flags |= IOSQE_FIXED_FILE;
```

### 8.3 Provided Buffers

Register buffer pools for zero-copy receives:

```c
// Register buffer ring
io_uring_register(ring.fd, IORING_REGISTER_BUFFERS, bufs, nr_bufs);

// In SQE, use buffer selection
sqe->flags |= IOSQE_BUFFER_SELECT;
sqe->buf_group = 0;

// CQE contains buffer index in upper 16 bits of flags
int buf_idx = cqe->flags >> IORING_CQE_BUFFER_SHIFT;
```

### 8.4 Linked Operations

Chain SQEs to execute in sequence:

```c
sqe1->flags |= IOSQE_IO_LINK;  // Must complete before sqe2
sqe2->flags |= IOSQE_IO_LINK;  // Must complete before sqe3
// sqe3 executes last
```

### 8.5 Multi-shot Accept

Accept multiple connections with a single SQE (Linux 6.0+):

```c
sqe->opcode = IORING_OP_ACCEPT;
sqe->accept_flags = SOCK_NONBLOCK | SOCK_CLOEXEC;
sqe->ioprio = IORING_ACCEPT_MULTISHOT;
// CQE_F_MORE flag indicates more connections available
```

---

## 9. liburing

The `liburing` library provides a clean wrapper around the raw syscalls:

```c
#include <liburing.h>

struct io_uring ring;
io_uring_queue_init(256, &ring, 0);

// Submit read
struct io_uring_sqe *sqe = io_uring_get_sqe(&ring);
io_uring_prep_read(sqe, fd, buf, len, offset);
io_uring_sqe_set_data(sqe, my_context);
io_uring_submit(&ring);

// Wait for completion
struct io_uring_cqe *cqe;
io_uring_wait_cqe(&ring, &cqe);
ssize_t bytes = cqe->res;
io_uring_cqe_seen(&ring, cqe);

io_uring_queue_exit(&ring);
```

---

## 10. Performance

### 10.1 Benchmarks

| Interface | IOPS (4K random read, NVMe) |
|-----------|----------------------------|
| `pread` (sync) | ~500K |
| `libaio` | ~800K |
| `io_uring` (no polling) | ~1M |
| `io_uring` (SQ polling) | ~1.5M |
| `io_uring` (IOPOLL + SQ polling) | ~2M+ |

### 10.2 Why io_uring is Faster

1. **Shared memory rings**: No syscall needed per I/O (with SQPOLL)
2. **Batch submission**: Multiple SQEs per syscall
3. **Kernel-side polling**: Eliminates interrupt overhead
4. **Fixed files/buffers**: Avoids repeated lookups
5. **Completion batching**: Process multiple CQEs per read

---

## 11. Security Implications

- **`io_uring` and seccomp**: Must be explicitly allowed in seccomp filters
- **Kernel attack surface**: io_uring has had numerous CVEs (it's complex)
- **Container restrictions**: Some container runtimes disable io_uring
- **`IORING_SETUP_SQPOLL`**: Requires `CAP_SYS_ADMIN` or `RLIMIT_NPROC` budget
- **Buffer registration**: Registered buffers are pinned in memory

### 11.1 io_uring CVEs

io_uring has been a significant source of kernel vulnerabilities:
- Use-after-free in various operations
- Race conditions in cancellation
- Buffer overflow in provided buffers
- Privilege escalation via ring operations

This has led to some distributions disabling io_uring for unprivileged users.

---

## 12. Common Bugs

```c
// BUG: Not checking for kernel support
int fd = syscall(__NR_io_uring_setup, entries, &params);
if (fd < 0 && errno == ENOSYS) {
    // io_uring not supported!
}

// BUG: Not reading enough CQEs before submitting more
// The CQ can overflow if completions aren't consumed
// FIX: Check CQ space, consume CQEs regularly

// BUG: Using io_uring_enter with SQPOLL without checking completion
// With SQPOLL, the kernel thread might have already consumed SQEs
// FIX: Check IORING_SQ_NEED_WAKEUP flag
```

---

## 13. Kernel Source References

- **io_uring core**: `io_uring/io_uring.c`
- **SQ polling**: `io_uring/sqpoll.c`
- **io_uring operations**: `io_uring/fs.c`, `io_uring/net.c`
- **io_uring setup**: `io_uring/io_uring.c`
- **liburing**: `src/` in the liburing repository

---

## 14. Summary

`io_uring` is the modern asynchronous I/O interface for Linux:
- **Ring buffers**: Shared memory for zero-overhead submission/completion
- **Batch operations**: Submit multiple I/Os per syscall
- **SQ polling**: Eliminate syscalls entirely
- **All file types**: Works with regular files, sockets, pipes, etc.
- **Rich feature set**: Fixed files, provided buffers, linked operations, multi-shot

For high-performance I/O workloads, `io_uring` is the definitive solution on Linux, offering 2-4x better throughput than traditional interfaces.

---

## 15. Detailed io_uring Internals

### 15.1 The Ring Buffer Memory Layout

The io_uring rings are mapped as shared memory between user space and kernel:

```c
// SQ Ring Layout (offsets from io_sqring_offsets):
// +0: head (u32, kernel writes, user reads)
// +4: tail (u32, user writes, kernel reads)
// +8: ring_mask (u32)
// +12: ring_entries (u32)
// +16: flags (u32)
// +20: dropped (u32)
// +24: array (u32[ring_entries]) - maps SQE indices to SQ entries

// CQ Ring Layout (offsets from io_cqring_offsets):
// +0: head (u32, user writes, kernel reads)
// +4: tail (u32, kernel writes, user reads)
// +8: ring_mask (u32)
// +12: ring_entries (u32)
// +16: overflow (u32)
// +20: cqes (struct io_uring_cqe[ring_entries])
```

### 15.2 Submission Path

```c
// User space:
1. Get SQE from ring: idx = sq_array[tail & sq_mask]
2. Fill SQE with operation details
3. sq_array[tail & sq_mask] = idx
4. tail++ (atomic store)
5. If SQPOLL is not enabled:
   syscall(__NR_io_uring_enter, ring_fd, to_submit, 0, 0, NULL);

// Kernel (io_submit_sqes):
1. Read SQEs from shared memory
2. For each SQE:
   a. Convert to io_kiocb (kernel I/O control block)
   b. Validate opcode and arguments
   c. Queue for async execution
3. Submit to worker threads or execute inline
```

### 15.3 Completion Path

```c
// Kernel:
1. I/O completes (callback from filesystem/network)
2. Fill CQE: user_data, res, flags
3. Advance CQ tail
4. If IOPOLL: set eventfd or wake up waiter
5. If SQPOLL: may need to wake SQ thread

// User space:
1. Check CQ head != CQ tail
2. Read CQE at cqes[head & cq_mask]
3. Process completion
4. head++ (atomic store)
```

### 15.4 SQ Polling Thread

With `IORING_SETUP_SQPOLL`, the kernel creates a kernel thread that continuously polls the SQ:

```c
// The SQ polling thread:
static int io_sq_thread(void *data)
{
    struct io_ring_ctx *ctx = data;
    
    while (!kthread_should_stop()) {
        // Check for new SQEs
        if (io_sqd_events_read(&ctx->sq_data)) {
            // Process SQEs
            io_submit_sqes(ctx, to_submit);
        }
        
        // Sleep if no activity
        if (timeout_expired) {
            // Set IORING_SQ_NEED_WAKEUP flag
            set_bit(IORING_SQ_NEED_WAKEUP, &ctx->sq_data.flags);
            schedule();
        }
    }
}
```

**User-space check:**
```c
if (IO_READ_ONCE(*sq_flags) & IORING_SQ_NEED_WAKEUP) {
    // Kernel thread is sleeping, need to wake it
    io_uring_enter(ring_fd, to_submit, 0, IORING_ENTER_SQ_WAIT, NULL);
} else {
    // Kernel thread is running, just update tail
    // No syscall needed!
}
```

### 15.5 io_uring Worker Threads

io_uring uses worker threads to execute I/O operations:

```c
struct io_wq {
    struct hlist_node node;
    struct io_wq_hash *hash;
    atomic_t worker_refs;
    struct task_struct *parent;
    struct io_wq_work_list work_list;
    // ...
};
```

**Worker thread types:**
- **BOUND workers**: Pinned to a specific CPU
- **UNBOUND workers**: Can run on any CPU

For file I/O, operations are submitted to a workqueue because some filesystem operations can block. For network I/O, operations may complete inline in the submission context.

### 15.6 io_uring and Filesystems

Different file types have different io_uring behaviors:

```c
// Regular files: Uses worker threads (can block on I/O)
// Socket: May complete inline (non-blocking send/recv)
// Pipes: Inline if data available, otherwise async
// Block devices: Worker threads + block layer
```

**io_uring file registration:**
Pre-registering files avoids repeated `fdget()` calls:

```c
int fds[] = { fd1, fd2, fd3 };
io_uring_register(ring_fd, IORING_REGISTER_FILES, fds, 3);

// In SQEs, use IOSQE_FIXED_FILE flag and file index
sqe->fd = 0;  // Index 0 in registered files
sqe->flags |= IOSQE_FIXED_FILE;
```

### 15.7 Buffer Management

io_uring provides two buffer management mechanisms:

**Pre-registered buffers:**
```c
struct iovec iovecs[NUM_BUFFERS];
for (int i = 0; i < NUM_BUFFERS; i++) {
    iovecs[i].iov_base = malloc(BUFFER_SIZE);
    iovecs[i].iov_len = BUFFER_SIZE;
}
io_uring_register(ring_fd, IORING_REGISTER_BUFFERS, iovecs, NUM_BUFFERS);
```

**Provided buffer rings:**
```c
struct io_uring_buf_ring *br;
br = mmap(NULL, size, PROT_READ | PROT_WRITE, MAP_SHARED | MAP_POPULATE,
          ring_fd, IORING_OFF_MMAP_BUFFERS);

// Add buffers to the ring
io_uring_buf_ring_add(br, buf, buf_len, bid, br->mask, 0);
io_uring_buf_ring_advance(br, 1);

// In SQE: select buffer from ring
sqe->flags |= IOSQE_BUFFER_SELECT;
sqe->buf_group = 0;

// In CQE: get buffer index
int bid = cqe->flags >> IORING_CQE_BUFFER_SHIFT;
```

### 15.8 io_uring Restrictions

For security-sensitive applications, io_uring operations can be restricted:

```c
struct io_uring_restriction restrictions[] = {
    { .opcode = IORING_RESTRICTION_SQE_OP, .sqe_op = IORING_OP_READ },
    { .opcode = IORING_RESTRICTION_SQE_OP, .sqe_op = IORING_OP_WRITE },
    { .opcode = IORING_RESTRICTION_SQE_FLAGS_REQUIRED, .sqe_flags = IOSQE_FIXED_FILE },
    { .opcode = IORING_RESTRICTION_SQE_FLAGS_ALLOWED, .sqe_flags = IOSQE_IO_DRAIN },
};

io_uring_register(ring_fd, IORING_REGISTER_RESTRICTIONS, restrictions, 4);
```

### 15.9 io_uring and Memory Ordering

The ring buffers use specific memory ordering guarantees:

```c
// User → Kernel (SQ tail update):
__atomic_store_n(sq_tail, new_tail, __ATOMIC_RELEASE);

// Kernel → User (CQ tail update):
__atomic_store_n(cq_tail, new_tail, __ATOMIC_RELEASE);

// User reads CQ tail:
__atomic_load_n(cq_tail, __ATOMIC_ACQUIRE);

// Kernel reads SQ tail:
__atomic_load_n(sq_tail, __ATOMIC_ACQUIRE);
```

This ensures that SQE/CQE data is visible before the tail pointer is updated.

### 15.10 Future Developments

io_uring continues to evolve rapidly:
- **io_uring_cmd**: Direct device commands (bypassing filesystem)
- **Registered ring**: Share rings between processes
- **Multishot operations**: Single SQE generates multiple CQEs
- **Fixed file tables**: Per-ring file tables for better isolation
- **io_uring + epoll integration**: Use io_uring as the event loop backend

### 15.11 io_uring and Filesystem Types

Different file types have different io_uring behaviors:

```c
// Regular files:
// - Uses worker threads (can block on I/O)
// - Supports readv, writev, read, write, fsync, fallocate
// - O_DIRECT bypasses page cache

// Sockets:
// - Can complete inline (non-blocking send/recv)
// - Supports sendmsg, recvmsg, accept, connect
// - TCP and UDP both supported

// Pipes:
// - Inline if data available
// - Async if pipe is empty/full
// - Supports splice operations

// Block devices:
// - Worker threads + block layer
// - Supports read, write, fallocate
// - O_DIRECT for bypassing page cache

// io_uring doesn't work with:
// - Regular files with epoll (different from epoll)
// - Some character devices
```

### 15.12 io_uring Statistics

The kernel tracks io_uring performance:

```bash
# Per-ring statistics
cat /proc/[pid]/fdinfo/[ring_fd]
# Shows: SQ ring size, CQ ring size, pending operations, etc.

# System-wide io_uring stats
cat /proc/sys/kernel/io_uring_disabled
# 0: Enabled for all
# 1: Enabled for CAP_SYS_ADMIN only
# 2: Disabled completely
```

### 15.13 io_uring Security Hardening

For security-sensitive applications:

```c
// 1. Restrict operations
struct io_uring_restriction restrictions[] = {
    { .opcode = IORING_RESTRICTION_SQE_OP, .sqe_op = IORING_OP_READ },
    { .opcode = IORING_RESTRICTION_SQE_OP, .sqe_op = IORING_OP_WRITE },
    { .opcode = IORING_RESTRICTION_REGISTER_OP, .reg_op = IORING_REGISTER_BUFFERS },
};
io_uring_register(ring_fd, IORING_REGISTER_RESTRICTIONS, restrictions, 3);

// 2. Use seccomp to allow only specific io_uring operations
// 3. Limit ring sizes to prevent resource exhaustion
// 4. Use IORING_SETUP_R_DISABLED and enable later
```

### 15.14 io_uring vs epoll: When to Use Which

| Feature | epoll | io_uring |
|---------|-------|----------|
| File I/O | No (regular files always ready) | Yes |
| Network I/O | Yes | Yes |
| Batching | No (one event per syscall) | Yes (multiple per syscall) |
| Zero-copy | No | Yes (send_zc) |
| Async | No (just notification) | Yes (truly async) |
| Complexity | Low | Medium-High |
| Kernel support | 2.6+ | 5.1+ |

**Use epoll when:**
- Network-only workloads
- Simple event loops
- Need broad kernel compatibility
- Low-complexity requirements

**Use io_uring when:**
- Mixed file + network I/O
- High-throughput requirements
- Need async operations
- Modern kernel available
- Willing to handle complexity

For many applications, a hybrid approach works well: use io_uring for I/O operations and epoll for event notification, or use io_uring's `IORING_OP_POLL` to replace epoll entirely.
