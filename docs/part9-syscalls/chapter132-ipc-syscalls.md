# Chapter 132: IPC Syscalls

## 1. Introduction

System V IPC (Inter-Process Communication) provides three mechanisms for communication between processes: shared memory, message queues, and semaphores. While POSIX IPC and other mechanisms have largely superseded them, System V IPC remains widely used and is an essential part of the Linux syscall interface.

---

## 2. Shared Memory: shmget / shmat / shmdt / shmctl

### 2.1 Purpose

Shared memory allows multiple processes to access the same physical memory region — the fastest form of IPC.

### 2.2 shmget — Create/Get Shared Memory Segment

```c
#include <sys/ipc.h>
#include <sys/shm.h>
int shmget(key_t key, size_t size, int shmflg);
```

**Arguments:**
- **`key`**: IPC key (or `IPC_PRIVATE` for a new private segment)
- **`size`**: Size in bytes (rounded up to page size)
- **`shmflg`**: Permissions and flags (`IPC_CREAT`, `IPC_EXCL`, `SHM_HUGETLB`)

**Returns:** Shared memory segment ID (positive), or -1 on error.

### 2.3 shmat — Attach Shared Memory

```c
void *shmat(int shmid, const void *shmaddr, int shmflg);
```

**Arguments:**
- **`shmid`**: Segment ID from `shmget`
- **`shmaddr`**: Attach address (NULL = kernel chooses)
- **`shmflg`**: `SHM_RDONLY` (read-only), `SHM_REMAP` (replace existing mapping)

**Returns:** Pointer to shared memory, or `(void *)-1` on error.

### 2.4 shmdt — Detach Shared Memory

```c
int shmdt(const void *shmaddr);
```

Detaches the shared memory segment from the process's address space. The segment persists until explicitly removed with `shmctl(IPC_RMID)`.

### 2.5 shmctl — Control Operations

```c
int shmctl(int shmid, int cmd, struct shmid_ds *buf);
```

**Commands:**
| Command | Description |
|---------|-------------|
| `IPC_STAT` | Get segment info |
| `IPC_SET` | Set segment info (owner, permissions) |
| `IPC_RMID` | Mark segment for deletion |
| `SHM_LOCK` | Lock segment in memory |
| `SHM_UNLOCK` | Unlock segment |
| `SHM_INFO` | Get system-wide shared memory info |
| `SHM_STAT` | Get segment info by index |

### 2.6 Kernel Implementation

```c
SYSCALL_DEFINE3(shmget, key_t, key, size_t, size, int, shmflg)
{
    return ksys_shmget(key, size, shmflg);
}

static long ksys_shmget(key_t key, size_t size, int shmflg)
{
    struct ipc_namespace *ns = current->ipc_ns;
    struct shmid_kernel *shp;
    
    if (key == IPC_PRIVATE) {
        // Create new segment
        shp = newseg(ns, shmflg, size);
    } else {
        // Find existing or create
        shp = shm_find_or_create(ns, key, shmflg, size);
    }
    
    return shp->shm_perm.id;  // Return segment ID
}
```

### 2.7 Example

```c
#include <sys/ipc.h>
#include <sys/shm.h>
#include <stdio.h>
#include <string.h>
#include <sys/wait.h>
#include <unistd.h>

int main(void)
{
    // Create shared memory segment
    int shmid = shmget(IPC_PRIVATE, 4096, IPC_CREAT | 0600);
    if (shmid < 0) { perror("shmget"); return 1; }
    
    if (fork() == 0) {
        // Child: attach and write
        char *shm = shmat(shmid, NULL, 0);
        strcpy(shm, "Hello from child via shared memory!");
        shmdt(shm);
        _exit(0);
    }
    
    // Parent: attach and read
    char *shm = shmat(shmid, NULL, 0);
    wait(NULL);
    printf("Received: %s\n", shm);
    shmdt(shm);
    
    // Remove segment
    shmctl(shmid, IPC_RMID, NULL);
    return 0;
}
```

### 2.8 The `shmid_ds` Structure

```c
struct shmid_ds {
    struct ipc_perm shm_perm;    // Ownership and permissions
    size_t          shm_segsz;   // Size in bytes
    time_t          shm_atime;   // Last attach time
    time_t          shm_dtime;   // Last detach time
    time_t          shm_ctime;   // Last change time
    pid_t           shm_cpid;    // Creator PID
    pid_t           shm_lpid;    // Last shmat/shmdt PID
    shmatt_t        shm_nattch;  // Number of current attaches
};
```

### 2.9 Limits

Configurable via `/proc/sys/kernel/shm*`:
- `shmmax`: Maximum segment size (default 32MB, often increased)
- `shmall`: Total shared memory in pages
- `shmmin`: Minimum segment size
- `shmmni`: Maximum number of segments

---

## 3. Message Queues: msgget / msgsnd / msgrcv / msgctl

### 3.1 Purpose

Message queues allow processes to exchange data in discrete messages with priorities.

### 3.2 msgget — Create/Get Message Queue

```c
#include <sys/ipc.h>
#include <sys/msg.h>
int msgget(key_t key, int msgflg);
```

**Returns:** Message queue ID, or -1 on error.

### 3.3 msgsnd — Send Message

```c
int msgsnd(int msqid, const void *msgp, size_t msgsz, int msgflg);
```

**The message structure:**
```c
struct msgbuf {
    long mtype;       // Message type (must be > 0)
    char mtext[1];    // Message data (flexible size)
};
```

**Flags:** `IPC_NOWAIT` (non-blocking)

### 3.4 msgrcv — Receive Message

```c
ssize_t msgrcv(int msqid, void *msgp, size_t msgsz, long msgtyp, int msgflg);
```

**`msgtyp`**:
| Value | Description |
|-------|-------------|
| `0` | Receive first message |
| `> 0` | Receive first message of type msgtyp |
| `< 0` | Receive first message with type <= abs(msgtyp) |

**Flags:** `IPC_NOWAIT`, `MSG_NOERROR` (truncate long messages), `MSG_EXCEPT` (receive different type)

### 3.5 Example

```c
#include <sys/ipc.h>
#include <sys/msg.h>
#include <stdio.h>
#include <string.h>

struct msgbuf {
    long mtype;
    char mtext[256];
};

int main(void)
{
    int msqid = msgget(IPC_PRIVATE, IPC_CREAT | 0600);
    if (msqid < 0) { perror("msgget"); return 1; }
    
    if (fork() == 0) {
        // Sender
        struct msgbuf msg = { .mtype = 1 };
        strcpy(msg.mtext, "Hello from message queue!");
        msgsnd(msqid, &msg, strlen(msg.mtext) + 1, 0);
        _exit(0);
    }
    
    // Receiver
    struct msgbuf msg;
    msgrcv(msqid, &msg, sizeof(msg.mtext), 0, 0);
    printf("Received (type %ld): %s\n", msg.mtype, msg.mtext);
    
    msgctl(msqid, IPC_RMID, NULL);
    return 0;
}
```

### 3.6 Kernel Implementation

```c
SYSCALL_DEFINE4(msgsnd, int, msqid, struct msgbuf __user *, msgp,
                size_t, msgsz, int, msgflg)
{
    struct msgbuf msg;
    
    // Copy message from user space
    if (copy_from_user(&msg, msgp, sizeof(msg.mtype)))
        return -EFAULT;
    
    // Allocate message and add to queue
    return do_msgsnd(msqid, msg.mtype, msg.mtext, msgsz, msgflg);
}
```

---

## 4. Semaphores: semget / semop / semctl

### 4.1 Purpose

Semaphores provide synchronization between processes — controlling access to shared resources.

### 4.2 semget — Create/Get Semaphore Set

```c
#include <sys/ipc.h>
#include <sys/sem.h>
int semget(key_t key, int nsems, int semflg);
```

**Arguments:**
- **`key`**: IPC key
- **`nsems`**: Number of semaphores in the set
- **`semflg`**: Permissions and flags

### 4.3 semop / semtimedop — Semaphore Operations

```c
int semop(int semid, struct sembuf *sops, size_t nsops);
int semtimedop(int semid, struct sembuf *sops, size_t nsops,
               const struct timespec *timeout);
```

**The `sembuf` structure:**
```c
struct sembuf {
    unsigned short sem_num;  // Semaphore number in set
    short          sem_op;   // Operation
    short          sem_flg;  // Flags
};
```

**`sem_op` values:**
| Value | Description |
|-------|-------------|
| `> 0` | Add to semaphore value (release resource) |
| `0` | Wait for semaphore to become zero |
| `< 0` | Subtract from semaphore value (acquire resource) |

**Flags:** `IPC_NOWAIT`, `SEM_UNDO` (automatically undo on process exit)

### 4.4 semctl — Control Operations

```c
int semctl(int semid, int semnum, int cmd, ...);
```

**Commands:** `GETVAL`, `SETVAL`, `GETPID`, `GETNCNT`, `GETZCNT`, `GETALL`, `SETALL`, `IPC_STAT`, `IPC_SET`, `IPC_RMID`, `IPC_INFO`, `SEM_INFO`.

### 4.5 Example: Producer-Consumer

```c
#include <sys/ipc.h>
#include <sys/sem.h>
#include <sys/shm.h>
#include <stdio.h>
#include <string.h>

union semun {
    int val;
    struct semid_ds *buf;
    unsigned short *array;
};

void sem_op(int semid, int num, int op)
{
    struct sembuf sb = { .sem_num = num, .sem_op = op, .sem_flg = SEM_UNDO };
    semop(semid, &sb, 1);
}

#define SEM_MUTEX 0
#define SEM_EMPTY 1
#define SEM_FULL  2

int main(void)
{
    int semid = semget(IPC_PRIVATE, 3, IPC_CREAT | 0600);
    int shmid = shmget(IPC_PRIVATE, 4096, IPC_CREAT | 0600);
    
    union semun arg;
    arg.val = 1; semctl(semid, SEM_MUTEX, SETVAL, arg);  // mutex
    arg.val = 1; semctl(semid, SEM_EMPTY, SETVAL, arg);  // empty slots
    arg.val = 0; semctl(semid, SEM_FULL, SETVAL, arg);   // full slots
    
    if (fork() == 0) {
        // Producer
        char *shm = shmat(shmid, NULL, 0);
        sem_op(semid, SEM_EMPTY, -1);  // Wait for empty slot
        sem_op(semid, SEM_MUTEX, -1);  // Lock
        strcpy(shm, "Produced data");
        sem_op(semid, SEM_MUTEX, 1);   // Unlock
        sem_op(semid, SEM_FULL, 1);    // Signal full
        shmdt(shm);
        _exit(0);
    }
    
    // Consumer
    char *shm = shmat(shmid, NULL, 0);
    sem_op(semid, SEM_FULL, -1);   // Wait for full slot
    sem_op(semid, SEM_MUTEX, -1);  // Lock
    printf("Consumed: %s\n", shm);
    sem_op(semid, SEM_MUTEX, 1);   // Unlock
    sem_op(semid, SEM_EMPTY, 1);   // Signal empty
    shmdt(shm);
    
    // Cleanup
    semctl(semid, 0, IPC_RMID);
    shmctl(shmid, IPC_RMID, NULL);
    return 0;
}
```

---

## 5. ftok — Generate IPC Keys

```c
#include <sys/ipc.h>
key_t ftok(const char *pathname, int proj_id);
```

Generates a unique key from a filename and project ID. Used to allow unrelated processes to find the same IPC resource.

---

## 6. System V IPC vs POSIX IPC

| Feature | System V | POSIX |
|---------|----------|-------|
| Naming | `ftok()` keys | `/name` strings |
| Shared memory | `shmget`/`shmat` | `shm_open`/`mmap` |
| Message queues | `msgget`/`msgsnd`/`msgrcv` | `mq_open`/`mq_send`/`mq_receive` |
| Semaphores | `semget`/`semop` | `sem_open`/`sem_wait`/`sem_post` |
| Cleanup | Manual (`IPC_RMID`) | `shm_unlink`/`mq_unlink`/`sem_unlink` |
| Persistence | Survives process exit | Reference counted |

---

## 7. Security Implications

- **Permission checks**: Each IPC resource has owner, group, and permission bits (like files).
- **`IPC_PRIVATE`**: Only accessible to the creating process and its children.
- **Resource limits**: `/proc/sys/kernel/shmmax`, `/proc/sys/kernel/msgmnb`, `/proc/sys/kernel/semvmx`.
- **Namespace isolation**: IPC resources are per-namespace (`CLONE_NEWIPC`).
- **`SEM_UNDO`**: Prevents semaphore deadlocks on process crash.

---

## 8. Common Bugs

```c
// BUG: Not removing IPC resources (resource leak)
int shmid = shmget(IPC_PRIVATE, 4096, IPC_CREAT | 0600);
// ... use it ...
// Forgot shmctl(shmid, IPC_RMID, NULL)!

// FIX: Always clean up
shmctl(shmid, IPC_RMID, NULL);

// BUG: Race between semget and semop
int semid = semget(key, 1, IPC_CREAT | 0600);
// Another process might not have initialized the value yet!
// FIX: Use IPC_CREAT | IPC_EXCL and initialize only if creating

// BUG: Not handling EINTR in semop
semop(semid, &sb, 1);  // Might be interrupted!
// FIX: Retry on EINTR
while (semop(semid, &sb, 1) < 0 && errno == EINTR) {}
```

---

## 9. Kernel Source References

- **Shared memory**: `ipc/shm.c`
- **Message queues**: `ipc/msg.c`
- **Semaphores**: `ipc/sem.c`
- **Common IPC code**: `ipc/util.c`
- **SysV IPC namespace**: `include/linux/ipc_namespace.h`

---

## 10. Summary

System V IPC provides three fundamental mechanisms for inter-process communication:
- **Shared memory** (`shmget`/`shmat`): Fastest IPC — direct memory sharing
- **Message queues** (`msgget`/`msgsnd`/`msgrcv`): Structured message passing with priorities
- **Semaphores** (`semget`/`semop`): Synchronization primitives

While POSIX IPC and modern alternatives (like `memfd_create` + Unix sockets) are often preferred for new code, System V IPC remains essential for legacy systems and certain use cases.

---

## 11. Detailed IPC Internals

### 11.1 IPC Namespace Isolation

Each IPC namespace has its own set of IPC identifiers. Resources created in one namespace are invisible to other namespaces:

```c
struct ipc_namespace {
    atomic_t count;
    struct ipc_ids ids[3];  // sem, msg, shm
    int sem_ctls[4];
    int msg_ctlmni;
    int msg_ctlmax;
    int msg_ctlmnb;
    size_t shm_ctlmax;
    size_t shm_ctlall;
    int shm_ctlmni;
    int shm_rmid_forced;
    // ...
};
```

When a process creates `CLONE_NEWIPC`, it gets a fresh IPC namespace with no pre-existing resources.

### 11.2 Shared Memory Page Allocation

When `shmget` creates a segment, the kernel doesn't immediately allocate all pages. Instead, it creates an `shmem_inode_info` structure backed by tmpfs:

```c
struct shmid_kernel {
    struct kern_ipc_perm shm_perm;
    struct file *shm_file;
    unsigned long shm_nattch;    // Number of attaches
    unsigned long shm_segsz;     // Segment size
    time_t shm_atim;             // Last attach time
    time_t shm_dtim;             // Last detach time
    time_t shm_ctim;             // Last change time
    pid_t shm_cprid;             // Creator PID
    pid_t shm_lprid;             // Last operation PID
    struct task_struct *mlock_user;  // User who locked
};
```

Pages are allocated on demand (page faults) and backed by swap when memory is tight.

### 11.3 Huge Page Shared Memory

Shared memory can use huge pages for better TLB efficiency:

```c
int shmid = shmget(key, 2 * 1024 * 1024, IPC_CREAT | SHM_HUGETLB | 0600);
```

The kernel allocates huge pages from the huge page pool (`/proc/sys/vm/nr_hugepages`).

### 11.4 Message Queue Implementation Details

The kernel maintains message queues as linked lists of message segments:

```c
struct msg_queue {
    struct kern_ipc_perm q_perm;
    time_t q_stime;
    time_t q_rtime;
    time_t q_ctime;
    unsigned long q_cbytes;   // Current bytes in queue
    unsigned long q_qnum;     // Number of messages
    unsigned long q_qbytes;   // Maximum bytes
    pid_t q_lspid;            // Last msgsnd PID
    pid_t q_lrpid;            // Last msgrcv PID
    struct list_head q_messages;
    struct list_head q_receivers;
    struct list_head q_senders;
};

struct msg_msg {
    struct list_head m_list;
    long m_type;
    size_t m_ts;              // Message size
    struct msg_msgseg *next;  // Next segment (for large messages)
    void *security;
};
```

Large messages are split across multiple pages using `msg_msgseg` linked list.

### 11.5 Semaphore Undo

The `SEM_UNDO` flag maintains per-semaphore adjustment values that are automatically applied when a process exits:

```c
struct sem_undo {
    struct list_head list_proc;
    struct rcu_head rcu;
    struct sem_undo_list *ulp;
    struct list_head list_id;
    int semid;
    short *semadj;    // Array of adjustments (one per semaphore in set)
};
```

This prevents semaphore deadlocks when processes crash while holding semaphores.

### 11.6 IPC Security and Permission Model

Each IPC resource has a `kern_ipc_perm` structure:

```c
struct kern_ipc_perm {
    spinlock_t lock;
    bool deleted;
    int id;
    key_t key;
    kuid_t uid;       // Creator UID
    kgid_t gid;       // Creator GID
    kuid_t cuid;      // Creator UID (changeable)
    kgid_t cgid;      // Creator GID (changeable)
    umode_t mode;     // Permission bits
    unsigned long seq;
    void *security;   // LSM security context
};
```

Permission checks follow this order:
1. If `uid` matches caller's effective UID → use owner permission bits
2. If `gid` matches caller's effective GID → use group permission bits
3. Otherwise → use other permission bits

### 11.7 IPC Resource Limits

System-wide and per-user limits prevent resource exhaustion:

```bash
# Shared memory
/proc/sys/kernel/shmmax    # Max segment size (bytes)
/proc/sys/kernel/shmall     # Total shared memory (pages)
/proc/sys/kernel/shmmni     # Max number of segments

# Message queues
/proc/sys/kernel/msgmni     # Max number of queues
/proc/sys/kernel/msgmax     # Max message size
/proc/sys/kernel/msgmnb     # Max total bytes per queue

# Semaphores
/proc/sys/kernel/sem         # SEMMSL SEMMNS SEMOPM SEMMNI
```

The `ipcs` command shows current IPC resource usage:
```bash
$ ipcs -a
------ Shared Memory Segments --------
key        shmid    owner    perms    bytes    nattch   status
0x00000000 0        root     644      80       2

------ Semaphore Arrays --------
key        semid    owner    perms    nsems
0x0000a4d2 0        root     600      1

------ Message Queues --------
key        msqid    owner    perms    used-bytes   messages
```

### 11.8 POSIX IPC vs System V IPC: Implementation Differences

POSIX IPC objects are implemented as files in special filesystems:

```bash
# POSIX shared memory
/dev/shm/my_segment  # tmpfs file

# POSIX message queues
/dev/mqueue/my_queue  # mqueue filesystem

# POSIX named semaphores
/dev/shm/sem.my_sem   # tmpfs file
```

This means POSIX IPC objects can be inspected with standard file tools (`ls`, `stat`, `rm`) and are subject to filesystem permissions.

### 11.9 Modern Alternatives

For new code, consider these alternatives to System V IPC:

- **memfd_create + Unix sockets**: Create anonymous memory, pass fd via SCM_RIGHTS
- **eventfd**: Simple counter-based notification
- **io_uring**: High-performance async I/O with shared rings
- **futex**: Fast userspace mutexes (used by pthreads)
- **BPF maps**: Kernel-shared data structures for eBPF programs

These modern interfaces offer better performance, cleaner APIs, and better integration with the rest of the Linux I/O model.

### 11.10 Shared Memory Performance Considerations

Shared memory is the fastest IPC mechanism because it avoids kernel-mediated data copies:

```c
// Performance comparison (approximate):
// - Shared memory: ~50-100 ns per access (direct memory access)
// - Unix socket: ~1-5 μs per message (kernel copy)
// - TCP socket: ~10-50 μs per message (protocol overhead)
// - Message queue: ~1-10 μs per message (kernel copy)
```

**Cache line effects:**
When multiple processes access shared memory, cache line bouncing can degrade performance:

```c
// BAD: False sharing (different variables on same cache line)
struct shared_data {
    int producer_count;  // Modified by producer
    int consumer_count;  // Modified by consumer
    // Both on same 64-byte cache line → cache bouncing!
};

// GOOD: Pad to separate cache lines
struct shared_data {
    int producer_count;
    char padding1[60];   // Fill cache line
    int consumer_count;
    char padding2[60];   // Fill cache line
} __attribute__((aligned(64)));
```

**Memory barriers:**
For lock-free shared memory communication, memory barriers are essential:

```c
// Producer:
data = new_value;
__atomic_store_n(&flag, 1, __ATOMIC_RELEASE);  // Ensure data is visible before flag

// Consumer:
while (__atomic_load_n(&flag, __ATOMIC_ACQUIRE) == 0);  // Wait for flag
use(data);  // Data is guaranteed to be visible
```

### 11.11 Message Queue Priorities

Message queues support priority-based delivery:

```c
// Messages with lower mtype are delivered first
// Within the same mtype, FIFO order is preserved

// Priority message (type 1 = high priority)
struct { long mtype; char mtext[256]; } msg = { .mtype = 1 };
msgsnd(msqid, &msg, len, 0);

// Normal message (type 2 = lower priority)
msg.mtype = 2;
msgsnd(msqid, &msg, len, 0);

// Receive highest priority first
msgrcv(msqid, &buf, sizeof(buf.mtext), 0, 0);  // Gets type 1 first
```

### 11.12 System V IPC vs Modern Alternatives

| Feature | System V shm | memfd_create | mmap(MAP_SHARED) | POSIX shm |
|---------|-------------|--------------|-------------------|-----------|
| Naming | ftok key | None | None | /name string |
| Persistence | Until rmid | Until fd close | Until munmap | Until unlink |
| Filesystem visible | No | No | No | /dev/shm |
| Sealing | No | Yes | No | No |
| Huge pages | SHM_HUGETLB | MFD_HUGETLB | MAP_HUGETLB | No |
| fd passing | No | Yes | No | No |

For new code, `memfd_create` + `mmap` is generally preferred over System V shared memory.

### 11.13 IPC Resource Cleanup Patterns

```c
// Pattern 1: Cleanup on exit
void cleanup_ipc(int shmid, int msqid, int semid) {
    if (shmid >= 0) shmctl(shmid, IPC_RMID, NULL);
    if (msqid >= 0) msgctl(msqid, IPC_RMID, NULL);
    if (semid >= 0) semctl(semid, 0, IPC_RMID);
}

// Pattern 2: Use atexit()
atexit(cleanup_ipc);

// Pattern 3: Signal handler cleanup
void sig_handler(int sig) {
    cleanup_ipc(shmid, msqid, semid);
    _exit(1);
}
signal(SIGINT, sig_handler);
signal(SIGTERM, sig_handler);
```

### 11.14 IPC Namespace Isolation Details

When `CLONE_NEWIPC` is used:

```c
// Each IPC namespace has its own:
// - System V semaphore sets
// - System V message queues
// - System V shared memory segments
// - POSIX message queues (since Linux 3.8)

// IPC resources created in one namespace are invisible to others
// ftok() generates different keys for different namespaces
```

### 11.15 Shared Memory Synchronization

Shared memory doesn't provide synchronization. Use these mechanisms:

```c
// Option 1: POSIX named semaphores
sem_t *sem = sem_open("/mysem", O_CREAT, 0644, 1);
sem_wait(sem);    // Lock
// Access shared memory
sem_post(sem);    // Unlock

// Option 2: Futex-based synchronization
// More complex but doesn't require named semaphores
int *futex_addr = (int *)shared_memory;
*futex_addr = 0;  // Initialize
// Lock:
while (__sync_lock_test_and_set(futex_addr, 1))
    syscall(__NR_futex, futex_addr, FUTEX_WAIT, 1, NULL, NULL, 0);
// Unlock:
*futex_addr = 0;
syscall(__NR_futex, futex_addr, FUTEX_WAKE, 1, NULL, NULL, 0);

// Option 3: pthread mutexes in shared memory
pthread_mutex_t *mutex = (pthread_mutex_t *)shared_memory;
pthread_mutexattr_t attr;
pthread_mutexattr_init(&attr);
pthread_mutexattr_setpshared(&attr, PTHREAD_PROCESS_SHARED);
pthread_mutex_init(mutex, &attr);
```

### 11.16 IPC Monitoring and Debugging

```bash
# List all IPC resources
ipcs -a

# Show shared memory segments
ipcs -m

# Show message queues
ipcs -q

# Show semaphore arrays
ipcs -s

# Remove all IPC resources for a user
ipcrm -a

# Show IPC limits
ipcs -l

# Show IPC creator/owner info
ipcs -p

# Monitor IPC usage in real-time
watch ipcs -a
```

### 11.17 IPC Resource Limits

```bash
# Shared memory limits
/proc/sys/kernel/shmmax    # Max segment size (bytes)
/proc/sys/kernel/shmall     # Total shared memory (pages)
/proc/sys/kernel/shmmni     # Max number of segments

# Message queue limits
/proc/sys/kernel/msgmni     # Max number of queues
/proc/sys/kernel/msgmax     # Max message size (bytes)
/proc/sys/kernel/msgmnb     # Max total bytes per queue

# Semaphore limits
/proc/sys/kernel/sem         # SEMMSL SEMMNS SEMOPM SEMMNI
# Format: SEMMSL (max semaphores per set)
#         SEMMNS (max semaphores system-wide)
#         SEMOPM (max operations per semop call)
#         SEMMNI (max semaphore sets)
```

These limits should be tuned based on application requirements. Database systems often need increased shared memory limits.
