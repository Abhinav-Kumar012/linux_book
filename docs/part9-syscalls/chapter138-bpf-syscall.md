# Chapter 138: BPF Syscall

## 1. Introduction

The `bpf()` syscall is the interface to the Berkeley Packet Filter (BPF) virtual machine in the Linux kernel. Originally designed for packet filtering, modern eBPF (extended BPF) is a general-purpose in-kernel virtual machine used for networking, tracing, security, and more. The `bpf()` syscall loads programs, manages maps, and controls BPF objects.

---

## 2. bpf() Syscall

### 2.1 Prototype

```c
#include <linux/bpf.h>
int bpf(int cmd, union bpf_attr *attr, unsigned int size);
```

### 2.2 Arguments

- **`cmd`**: BPF command
- **`attr`**: Command-specific attributes (union)
- **`size`**: Size of the attr structure

### 2.3 Commands

| Command | Description |
|---------|-------------|
| `BPF_MAP_CREATE` | Create a BPF map |
| `BPF_MAP_LOOKUP_ELEM` | Look up element in map |
| `BPF_MAP_UPDATE_ELEM` | Update element in map |
| `BPF_MAP_DELETE_ELEM` | Delete element from map |
| `BPF_MAP_GET_NEXT_KEY` | Iterate map keys |
| `BPF_PROG_LOAD` | Load a BPF program |
| `BPF_OBJ_PIN` | Pin object to BPF filesystem |
| `BPF_OBJ_GET` | Get pinned object |
| `BPF_PROG_ATTACH` | Attach program to hook |
| `BPF_PROG_DETACH` | Detach program from hook |
| `BPF_PROG_TEST_RUN` | Test run a program |
| `BPF_PROG_GET_NEXT_ID` | Iterate loaded programs |
| `BPF_MAP_GET_NEXT_ID` | Iterate loaded maps |
| `BPF_BTF_LOAD` | Load BTF (BPF Type Format) data |
| `BPF_LINK_CREATE` | Create a BPF link |
| `BPF_LINK_UPDATE` | Update a BPF link |
| `BPF_ENABLE_STATS` | Enable BPF statistics |

---

## 3. BPF Maps

### 3.1 Purpose

BPF maps are generic key-value data structures shared between BPF programs and user space.

### 3.2 Map Types

| Type | Description |
|------|-------------|
| `BPF_MAP_TYPE_HASH` | Hash table |
| `BPF_MAP_TYPE_ARRAY` | Fixed-size array |
| `BPF_MAP_TYPE_PERCPU_HASH` | Per-CPU hash table |
| `BPF_MAP_TYPE_PERCPU_ARRAY` | Per-CPU array |
| `BPF_MAP_TYPE_LRU_HASH` | LRU hash table |
| `BPF_MAP_TYPE_RINGBUF` | Ring buffer (Linux 5.8+) |
| `BPF_MAP_TYPE_QUEUE` | FIFO queue (Linux 4.20+) |
| `BPF_MAP_TYPE_STACK` | LIFO stack (Linux 4.20+) |
| `BPF_MAP_TYPE_LPM_TRIE` | Longest prefix match trie |
| `BPF_MAP_TYPE_DEVMAP` | Device map (XDP) |
| `BPF_MAP_TYPE_CPUMAP` | CPU map (XDP) |
| `BPF_MAP_TYPE_PROG_ARRAY` | Program array (tail calls) |
| `BPF_MAP_TYPE_STACK_TRACE` | Stack trace map |

### 3.3 Creating a Map

```c
#include <linux/bpf.h>
#include <sys/syscall.h>
#include <unistd.h>

int bpf_create_map(enum bpf_map_type map_type, int key_size,
                   int value_size, int max_entries)
{
    union bpf_attr attr = {
        .map_type = map_type,
        .key_size = key_size,
        .value_size = value_size,
        .max_entries = max_entries,
    };
    return syscall(__NR_bpf, BPF_MAP_CREATE, &attr, sizeof(attr));
}

// Example
int map_fd = bpf_create_map(BPF_MAP_TYPE_HASH, sizeof(int), sizeof(long), 1024);
```

### 3.4 Map Operations

```c
// Lookup
int bpf_map_lookup_elem(int fd, const void *key, void *value)
{
    union bpf_attr attr = {
        .map_fd = fd,
        .key = (unsigned long)key,
        .value = (unsigned long)value,
    };
    return syscall(__NR_bpf, BPF_MAP_LOOKUP_ELEM, &attr, sizeof(attr));
}

// Update
int bpf_map_update_elem(int fd, const void *key, const void *value, __u64 flags)
{
    union bpf_attr attr = {
        .map_fd = fd,
        .key = (unsigned long)key,
        .value = (unsigned long)value,
        .flags = flags,
    };
    return syscall(__NR_bpf, BPF_MAP_UPDATE_ELEM, &attr, sizeof(attr));
}

// Delete
int bpf_map_delete_elem(int fd, const void *key)
{
    union bpf_attr attr = {
        .map_fd = fd,
        .key = (unsigned long)key,
    };
    return syscall(__NR_bpf, BPF_MAP_DELETE_ELEM, &attr, sizeof(attr));
}

// Get next key (for iteration)
int bpf_map_get_next_key(int fd, const void *key, void *next_key)
{
    union bpf_attr attr = {
        .map_fd = fd,
        .key = (unsigned long)key,
        .next_key = (unsigned long)next_key,
    };
    return syscall(__NR_bpf, BPF_MAP_GET_NEXT_KEY, &attr, sizeof(attr));
}
```

### 3.5 Map Flags

| Flag | Description |
|------|-------------|
| `BPF_ANY` | Create or update |
| `BPF_NOEXIST` | Create only (fail if exists) |
| `BPF_EXIST` | Update only (fail if doesn't exist) |
| `BPF_F_LOCK` | Use spin_lock in value |

---

## 4. BPF Program Loading

### 4.1 Purpose

`BPF_PROG_LOAD` compiles and loads a BPF program into the kernel.

### 4.2 Program Types

| Type | Description |
|------|-------------|
| `BPF_PROG_TYPE_SOCKET_FILTER` | Socket packet filter |
| `BPF_PROG_TYPE_KPROBE` | Kernel probe |
| `BPF_PROG_TYPE_TRACEPOINT` | Tracepoint |
| `BPF_PROG_TYPE_XDP` | Express Data Path |
| `BPF_PROG_TYPE_SCHED_CLS` | Traffic control classifier |
| `BPF_PROG_TYPE_SCHED_ACT` | Traffic control action |
| `BPF_PROG_TYPE_CGROUP_SKB` | Cgroup socket buffer |
| `BPF_PROG_TYPE_LWT_IN` | Lightweight tunnel ingress |
| `BPF_PROG_TYPE_LWT_OUT` | Lightweight tunnel egress |
| `BPF_PROG_TYPE_SOCK_OPS` | Socket operations |
| `BPF_PROG_TYPE_SK_SKB` | Socket skb |
| `BPF_PROG_TYPE_CGROUP_DEVICE` | Device cgroup |
| `BPF_PROG_TYPE_LSM` | Linux Security Module |
| `BPF_PROG_TYPE_STRUCT_OPS` | Struct ops |

### 4.3 Loading a Program

```c
int bpf_prog_load(enum bpf_prog_type type, const struct bpf_insn *insns,
                  int insn_cnt, const char *license)
{
    union bpf_attr attr = {
        .prog_type = type,
        .insns = (unsigned long)insns,
        .insn_cnt = insn_cnt,
        .license = (unsigned long)license,
        .log_buf = (unsigned long)log_buf,
        .log_size = LOG_BUF_SIZE,
        .log_level = 1,
    };
    return syscall(__NR_bpf, BPF_PROG_LOAD, &attr, sizeof(attr));
}
```

### 4.4 BPF Instruction Set

BPF programs are arrays of 64-bit instructions:

```c
struct bpf_insn {
    __u8 code;      // Opcode
    __u8 dst_reg:4; // Destination register
    __u8 src_reg:4; // Source register
    __s16 off;      // Signed offset
    __s32 imm;      // Signed immediate
};
```

### 4.5 Example: Simple Counter Program

```c
#include <linux/bpf.h>
#include <bpf/bpf_helpers.h>

// BPF map
struct {
    __uint(type, BPF_MAP_TYPE_ARRAY);
    __uint(max_entries, 1);
    __type(key, __u32);
    __type(value, __u64);
} counter_map SEC(".maps");

SEC("tracepoint/syscalls/sys_enter_read")
int count_reads(struct trace_event_raw_sys_enter *ctx)
{
    __u32 key = 0;
    __u64 *val = bpf_map_lookup_elem(&counter_map, &key);
    if (val)
        __sync_fetch_and_add(val, 1);
    return 0;
}

char LICENSE[] SEC("license") = "GPL";
```

---

## 5. BTF (BPF Type Format)

### 5.1 Purpose

BTF is a metadata format that describes C types, enabling the kernel to understand BPF program data structures for better error messages, map pretty-printing, and CO-RE (Compile Once, Run Everywhere).

### 5.2 Loading BTF

```c
int btf_fd = syscall(__NR_bpf, BPF_BTF_LOAD, &attr, sizeof(attr));
```

### 5.3 BTF Features

- **Better error messages**: The verifier can show field names and types
- **Map pretty-printing**: `bpftool map dump` shows structured data
- **CO-RE**: BPF programs compiled on one kernel version run on others
- **Module BTF**: Separate BTF for kernel modules

---

## 6. BPF Links

### 6.1 Purpose

BPF links (Linux 5.8+) are persistent attachments between BPF programs and hooks. Unlike `BPF_PROG_ATTACH`, links have file descriptors and are automatically cleaned up.

### 6.2 Creating Links

```c
int link_fd = syscall(__NR_bpf, BPF_LINK_CREATE, &attr, sizeof(attr));
```

### 6.3 Link Types

- **Tracing**: Attach to kprobes, tracepoints, perf events
- **Netns**: Attach to network namespace hooks
- **XDP**: Attach to network interfaces
- **Cgroup**: Attach to cgroup hooks
- **Iter**: Attach to BPF iterators

---

## 7. Using libbpf (Recommended)

Raw `bpf()` syscall usage is rare. Most users use `libbpf` or `bpftool`:

```c
#include <bpf/libbpf.h>
#include <bpf/bpf.h>

int main(void)
{
    // Open and load BPF object
    struct bpf_object *obj = bpf_object__open_file("program.bpf.o", NULL);
    bpf_object__load(obj);
    
    // Get program
    struct bpf_program *prog = bpf_object__find_program_by_name(obj, "count_reads");
    
    // Attach to tracepoint
    struct bpf_link *link = bpf_program__attach(prog);
    
    // Access map
    struct bpf_map *map = bpf_object__find_map_by_name(obj, "counter_map");
    int map_fd = bpf_map__fd(map);
    
    // Read from map
    __u32 key = 0;
    __u64 value;
    bpf_map_lookup_elem(map_fd, &key, &value);
    printf("Read count: %lu\n", value);
    
    bpf_link__destroy(link);
    bpf_object__close(obj);
    return 0;
}
```

---

## 8. BPF Verifier

### 8.1 Purpose

The BPF verifier is a static analysis tool that ensures BPF programs are safe before loading. It checks:

- No infinite loops (must be bounded)
- No out-of-bounds memory access
- No null pointer dereferences
- All code paths are reachable
- Program terminates
- Correct use of helper functions
- Map access is valid

### 8.2 Verification Process

```c
// The verifier runs automatically during BPF_PROG_LOAD
// If verification fails, the syscall returns -1 with details in log_buf

char log_buf[65536];
union bpf_attr attr = {
    // ...
    .log_buf = (unsigned long)log_buf,
    .log_size = sizeof(log_buf),
    .log_level = 1,
};
int fd = syscall(__NR_bpf, BPF_PROG_LOAD, &attr, sizeof(attr));
if (fd < 0) {
    printf("Verifier error:\n%s\n", log_buf);
}
```

### 8.3 Verifier Complexity Limits

- Maximum 1 million instructions (since Linux 5.2)
- Maximum 4096 stack bytes
- Maximum 512 map references per program

---

## 9. Use Cases

### 9.1 Network Packet Filtering (XDP)

```c
SEC("xdp")
int xdp_drop(struct xdp_md *ctx)
{
    void *data = (void *)(long)ctx->data;
    void *data_end = (void *)(long)ctx->data_end;
    
    struct ethhdr *eth = data;
    if ((void *)(eth + 1) > data_end)
        return XDP_PASS;
    
    // Drop IPv6 packets
    if (eth->h_proto == htons(ETH_P_IPV6))
        return XDP_DROP;
    
    return XDP_PASS;
}
```

### 9.2 Tracing and Profiling

```c
SEC("kprobe/do_sys_openat2")
int trace_open(struct pt_regs *ctx)
{
    __u64 pid = bpf_get_current_pid_tgid();
    bpf_printk("open called by PID %d\n", pid);
    return 0;
}
```

### 9.3 Security (LSM BPF)

```c
SEC("lsm/file_open")
int BPF_PROG(restrict_open, struct file *file, int ret)
{
    // Block access to specific files
    // ...
    return 0;  // Allow
}
```

---

## 10. Security Implications

- **BPF capabilities**: Loading BPF programs requires `CAP_BPF` (Linux 5.8+) or `CAP_SYS_ADMIN`
- **Verifier bypasses**: Historically, verifier bugs have allowed arbitrary kernel read/write
- **BPF and containers**: Containers typically can't load BPF programs
- **Spectre mitigations**: BPF programs run in a sandboxed environment with Spectre protections
- **Unprivileged BPF**: Some program types (socket filters) can be loaded without capabilities, but with restrictions

---

## 11. Common Bugs

```c
// BUG: Not checking verifier log
int fd = syscall(__NR_bpf, BPF_PROG_LOAD, &attr, sizeof(attr));
if (fd < 0) {
    // attr.log_buf contains detailed error — read it!
}

// BUG: Using wrong key/value sizes
bpf_create_map(BPF_MAP_TYPE_HASH, sizeof(int), sizeof(long), 1024);
// Later, user space uses wrong sizes when accessing the map

// BUG: Not handling BPF_MAP_UPDATE_ELEM flags
bpf_map_update_elem(fd, &key, &value, BPF_ANY);
// Might overwrite existing entry when you wanted BPF_NOEXIST
```

---

## 12. Kernel Source References

- **BPF syscall**: `kernel/bpf/syscall.c`
- **BPF verifier**: `kernel/bpf/verifier.c`
- **BPF maps**: `kernel/bpf/map*.c`
- **BPF helpers**: `kernel/bpf/helpers.c`
- **BTF**: `kernel/bpf/btf.c`
- **BPF JIT**: `arch/x86/net/bpf_jit_comp.c`
- **libbpf**: `tools/lib/bpf/`

---

## 13. Summary

The `bpf()` syscall is the gateway to the Linux kernel's eBPF virtual machine:
- **Maps**: Generic key-value data structures shared between kernel and user space
- **Programs**: Verified bytecode that runs in the kernel
- **BTF**: Type metadata for better debugging and portability
- **Links**: Persistent program attachments

eBPF is one of the most transformative Linux technologies, enabling programmable networking, tracing, security, and more — all verified safe before execution.

---

## 14. Detailed BPF Internals

### 14.1 BPF Instruction Set Architecture

The eBPF ISA defines 64-bit instructions with 11 registers (R0-R10):

```c
// Register conventions:
// R0: Return value from BPF helper functions
// R1-R5: Arguments to BPF helper functions
// R6-R9: Callee-saved registers
// R10: Frame pointer (read-only, points to stack)
//
// All registers are 64-bit
// Lower 32-bit sub-register access is available (w0-w9)
```

**Instruction encoding:**
```
| 8-bit opcode | 4-bit dst_reg | 4-bit src_reg | 16-bit offset | 32-bit immediate |
```

**Instruction classes:**
- `BPF_LD`: Load (special, 16-byte instructions for map access)
- `BPF_LDX`: Load from memory
- `BPF_ST`: Store immediate
- `BPF_STX`: Store register
- `BPF_ALU`: 32-bit arithmetic
- `BPF_ALU64`: 64-bit arithmetic
- `BPF_JMP`: Unconditional jump
- `BPF_JMP32`: 32-bit conditional jump

### 14.2 BPF Helper Functions

BPF programs can call a rich set of helper functions:

```c
// Map operations
void *bpf_map_lookup_elem(struct bpf_map *map, const void *key);
long bpf_map_update_elem(struct bpf_map *map, const void *key, const void *value, u64 flags);
long bpf_map_delete_elem(struct bpf_map *map, const void *key);

// Current task info
u64 bpf_get_current_pid_tgid(void);
u64 bpf_get_current_uid_gid(void);
long bpf_get_current_comm(void *buf, u32 size_buf);

// Time
u64 bpf_ktime_get_ns(void);
u64 bpf_ktime_get_boot_ns(void);

// Network helpers
long bpf_skb_load_bytes(const struct sk_buff *skb, u32 offset, void *to, u32 len);
long bpf_redirect(u32 ifindex, u64 flags);

// Tracing
long bpf_trace_printk(const char *fmt, u32 fmt_size, ...);

// Task info
long bpf_get_task_stack(struct task_struct *task, void *buf, u32 size, u64 flags);
```

Each helper has a specific set of allowed program types. The verifier checks that helpers are only called from compatible programs.

### 14.3 BPF Map Internals

Maps are implemented as kernel data structures with a standard interface:

```c
struct bpf_map_ops {
    int (*map_alloc_check)(union bpf_attr *attr);
    struct bpf_map *(*map_alloc)(union bpf_attr *attr);
    void (*map_free)(struct bpf_map *map);
    int (*map_get_next_key)(struct bpf_map *map, const void *key, void *next_key);
    void *(*map_lookup_elem)(struct bpf_map *map, const void *key);
    int (*map_update_elem)(struct bpf_map *map, const void *key, const void *value, u64 flags);
    int (*map_delete_elem)(struct bpf_map *map, const void *key);
    // ...
};
```

**Ring buffer implementation:**
The `BPF_MAP_TYPE_RINGBUF` uses a shared ring buffer with lock-free single-producer/single-consumer semantics:

```c
struct bpf_ringbuf {
    spinlock_t producer_lock;
    spinlock_t consumer_lock;
    u32 prod_pos;     // Producer position
    u32 cons_pos;     // Consumer position
    u32 mask;         // Size - 1 (for fast modulo)
    // ... data follows
};
```

### 14.4 BPF JIT Compilation

BPF programs are JIT-compiled to native machine code for performance:

```c
// arch/x86/net/bpf_jit_comp.c
// Each BPF instruction is translated to x86-64 machine code
// The JIT compiler performs optimizations:
// - Dead code elimination
// - Constant folding
// - Branch optimization
// - Tail call optimization
```

JIT compilation happens at program load time. The compiled code is stored in executable kernel memory.

### 14.5 BPF Program Attach Points

Programs are attached to various kernel hooks:

```c
struct bpf_link_ops {
    void (*release)(struct bpf_link *link);
    void (*dealloc)(struct bpf_link *link);
    int (*detach)(struct bpf_link *link);
    int (*update_prog)(struct bpf_link *link, struct bpf_prog *new_prog, struct bpf_prog *old_prog);
    // ...
};
```

**Attach mechanisms:**
- **Kprobes**: Dynamically instrument kernel functions
- **Tracepoints**: Static instrumentation points
- **XDP**: Network packet processing at driver level
- **TC**: Traffic control hooks
- **Cgroup**: Process group hooks
- **LSM**: Security hooks
- **Struct_ops**: Replace kernel struct function pointers

### 14.6 BPF CO-RE (Compile Once, Run Everywhere)

CO-RE allows BPF programs compiled on one kernel to run on different kernel versions:

```c
// BTF provides type information
// The loader relocates field offsets at load time
// libbpf handles the relocation automatically

struct task_struct *task = (void *)bpf_get_current_task();
// libbpf relocates the offset of task->pid at load time
int pid = BPF_CORE_READ(task, pid);
```

### 14.7 BPF and Security

**Capabilities required:**
- `CAP_BPF`: Load most BPF program types (Linux 5.8+)
- `CAP_NET_ADMIN`: Network-related BPF programs
- `CAP_PERFMON`: Perf-related BPF programs (kprobes, tracepoints)
- `CAP_SYS_ADMIN`: Legacy (before Linux 5.8)

**BPF and unprivileged users:**
Most BPF operations require capabilities. Socket filters are the exception — unprivileged users can load simple socket filters, but they are heavily restricted by the verifier.

**BPF hardening:**
- BPF programs run in a sandboxed environment
- The verifier prevents all unsafe operations
- JIT spraying mitigations (constant blinding)
- Spectre mitigations (retpolines in JIT code)

### 14.8 BPF Iterator Programs

BPF iterators (Linux 5.8+) allow BPF programs to iterate over kernel data structures:

```c
SEC("iter/task")
int dump_tasks(struct bpf_iter__task *ctx)
{
    struct task_struct *task = ctx->task;
    if (!task)
        return 0;
    
    BPF_SEQ_PRINTF(seq, "PID: %d, comm: %s\n", task->pid, task->comm);
    return 0;
}
```

Iterators can be read from user space via a special file descriptor, providing structured kernel data without parsing /proc.

### 14.9 BPF and Network Namespace

BPF programs can be attached to network namespaces for traffic monitoring and filtering:

```c
// Attach to a network namespace
int netns_fd = open("/proc/self/ns/net", O_RDONLY);
union bpf_attr attr = {
    .link_create.attach_type = BPF_NETNS_INET_SOCK_CONNECT,
    .link_create.target_fd = netns_fd,
    .link_create.prog_fd = prog_fd,
};
int link_fd = syscall(__NR_bpf, BPF_LINK_CREATE, &attr, sizeof(attr));
```

### 14.10 Common BPF Patterns

**Pattern 1: Map-in-map (map of maps)**
```c
// Outer map: hash of map fd
// Inner map: per-connection state
struct {
    __uint(type, BPF_MAP_TYPE_HASH_OF_MAPS);
    __uint(max_entries, 1024);
    __type(key, __u32);
    __array(values, struct bpf_map);
} outer SEC(".maps");
```

**Pattern 2: Tail calls (program chaining)**
```c
bpf_tail_call(ctx, &prog_array, index);
// Transfers control to another BPF program (never returns)
```

**Pattern 3: BPF ringbuf for efficient event reporting**
```c
struct event *e = bpf_ringbuf_reserve(&rb, sizeof(*e), 0);
if (e) {
    e->pid = bpf_get_current_pid_tgid();
    bpf_ringbuf_submit(e, 0);
}
```

### 14.11 BPF and Performance Monitoring

BPF programs can attach to performance events:

```c
// Attach to hardware performance counters
struct perf_event_attr attr = {
    .type = PERF_TYPE_HARDWARE,
    .config = PERF_COUNT_HW_CPU_CYCLES,
    .sample_period = 1000000,
    .freq = 0,
};

int perf_fd = perf_event_open(&attr, 0, -1, -1, 0);
bpf_prog_attach(prog_fd, perf_fd, BPF_PERF_EVENT, 0);
```

### 14.12 BPF and cgroups

BPF programs can be attached to cgroups for network and device control:

```c
// Attach to cgroup for network policy
int cgrp_fd = open("/sys/fs/cgroup/mygroup", O_RDONLY);
bpf_prog_attach(prog_fd, cgrp_fd, BPF_CGROUP_INET4_CONNECT, 0);

// Attach to cgroup for device access control
bpf_prog_attach(dev_prog_fd, cgrp_fd, BPF_CGROUP_DEVICE, 0);
```

### 14.13 BPF Map Types in Detail

**Hash maps:**
```c
// Good for: Dynamic key-value storage
// Lookup: O(1) average, O(n) worst case
// Use cases: Connection tracking, flow state

struct {
    __uint(type, BPF_MAP_TYPE_HASH);
    __uint(max_entries, 10000);
    __type(key, struct flow_key);
    __type(value, struct flow_stats);
} flow_table SEC(".maps");
```

**LRU hash maps:**
```c
// Good for: Bounded-size caches
// Automatically evicts least recently used entries
// Use cases: Packet sampling, connection caching

struct {
    __uint(type, BPF_MAP_TYPE_LRU_HASH);
    __uint(max_entries, 1000);
    __type(key, __u32);    // IP address
    __type(value, __u64);  // Timestamp
} recent_ips SEC(".maps");
```

**Per-CPU arrays:**
```c
// Good for: Per-CPU counters
// No locking needed (each CPU has its own copy)
// Use cases: Statistics, counters

struct {
    __uint(type, BPF_MAP_TYPE_PERCPU_ARRAY);
    __uint(max_entries, 256);
    __type(key, __u32);
    __type(value, struct percpu_stats);
} stats SEC(".maps");
```

### 14.14 BPF Program Types: Network

**XDP (eXpress Data Path):**
```c
// Runs at the NIC driver level, before the network stack
// Can drop/modify/redirect packets at line rate

SEC("xdp")
int xdp_firewall(struct xdp_md *ctx) {
    void *data = (void *)(long)ctx->data;
    void *data_end = (void *)(long)ctx->data_end;
    
    struct ethhdr *eth = data;
    if ((void *)(eth + 1) > data_end)
        return XDP_PASS;
    
    // Drop specific MAC addresses
    if (eth->h_source[0] == 0x00 && eth->h_source[1] == 0x11)
        return XDP_DROP;
    
    return XDP_PASS;
}
```

**TC (Traffic Control):**
```c
// Runs in the network stack's traffic control layer
// Can modify, redirect, or classify packets

SEC("tc")
int tc_classifier(struct __sk_buff *skb) {
    // Classify based on protocol
    return TC_ACT_OK;
}
```

**Socket filters:**
```c
// Attach to sockets to filter incoming packets
// Used by tcpdump and similar tools

SEC("socket")
int socket_filter(struct __sk_buff *skb) {
    // Filter TCP SYN packets
    return 1;  // Accept
}
```

### 14.15 BPF and Security Policy Enforcement

BPF can enforce security policies at various levels:

```c
// cgroup device controller
SEC("cgroup/dev")
int bpf_cgroup_dev(struct bpf_cgroup_dev_ctx *ctx) {
    // Allow only /dev/null and /dev/zero
    __u32 major = ctx->access_type & 0xFFFFF;
    __u32 minor = (ctx->access_type >> 20) & 0xFFF;
    
    if (major == 1 && (minor == 3 || minor == 5))
        return 1;  // Allow
    return 0;  // Deny
}
```

### 14.16 BPF and Container Security

BPF is increasingly used for container security:

```c
// Container network policy with BPF
// Attach to cgroup to control network access
SEC("cgroup/sock_create")
int container_net_policy(struct bpf_sock *sk) {
    // Only allow TCP and UDP
    if (sk->type != SOCK_STREAM && sk->type != SOCK_DGRAM)
        return 0;  // Deny
    
    // Block connections to port 22 (SSH)
    if (sk->type == SOCK_STREAM && sk->dst_port == htons(22))
        return 0;  // Deny
    
    return 1;  // Allow
}
```

### 14.17 BPF Performance Considerations

- **JIT compilation**: BPF programs are compiled to native code for performance
- **Per-CPU maps**: Avoid lock contention with per-CPU data structures
- **Ring buffers**: More efficient than perf event buffers for high-frequency events
- **Tail calls**: Can be used to split complex programs and reduce verification time
- **BPF program complexity**: The verifier limits instruction count (1M) — complex programs may need to be split

### 14.18 BPF and Observability

BPF is the foundation of modern Linux observability tools:

```bash
# bpftrace: High-level tracing language
bpftrace -e 'tracepoint:syscalls:sys_enter_open { printf("%s %s\n", comm, str(args->filename)); }'

# BCC: Python/C framework for BPF tools
/usr/share/bcc/tools/execsnoop    # Trace new processes
/usr/share/bcc/tools/tcpconnect   # Trace TCP connections
/usr/share/bcc/tools/biolatency   # Trace block I/O latency

# bpftool: Inspect BPF programs and maps
bpftool prog list
bpftool map dump id 123
bpftool prog show id 456
```

These tools provide deep kernel observability with minimal overhead, enabling performance analysis and security monitoring in production systems.
