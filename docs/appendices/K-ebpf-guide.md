# Appendix K: eBPF Quick Guide

## Overview

eBPF (extended Berkeley Packet Filter) is a revolutionary technology that allows running sandboxed programs inside the Linux kernel without modifying the kernel source or loading kernel modules. This guide covers program types, map types, helper functions, and practical one-liners.

---

## 1. eBPF Program Types

### Tracing Programs

| Type | Attachment Point | Description |
|------|-----------------|-------------|
| `BPF_PROG_TYPE_KPROBE` | Kernel functions | Attach to kernel function entry/exit |
| `BPF_PROG_TYPE_TRACEPOINT` | Tracepoints | Attach to kernel static tracepoints |
| `BPF_PROG_TYPE_PERF_EVENT` | Perf events | Attach to perf events (HW/SW) |
| `BPF_PROG_TYPE_RAW_TRACEPOINT` | Raw tracepoints | Access raw tracepoint arguments |
| `BPF_PROG_TYPE_TRACING` | fentry/fexit | Modern function entry/exit tracing |

### Network Programs

| Type | Attachment Point | Description |
|------|-----------------|-------------|
| `BPF_PROG_TYPE_SOCKET_FILTER` | Socket | Filter packets on sockets |
| `BPF_PROG_TYPE_XDP` | Network driver | eXpress Data Path (fastest) |
| `BPF_PROG_TYPE_SCHED_CLS` | TC ingress | Traffic control classifier |
| `BPF_PROG_TYPE_SCHED_ACT` | TC action | Traffic control action |
| `BPF_PROG_TYPE_CGROUP_SKB` | Cgroup | Filter packets by cgroup |
| `BPF_PROG_TYPE_SK_SKB` | Socket | Socket-to-socket redirection |
| `BPF_PROG_TYPE_SK_MSG` | Socket | Message-level socket redirect |
| `BPF_PROG_TYPE_LWT_IN` | LWT | Lightweight tunnel ingress |
| `BPF_PROG_TYPE_LWT_OUT` | LWT | Lightweight tunnel egress |
| `BPF_PROG_TYPE_FLOW_DISSECTOR` | Flow dissector | Protocol parsing |

### Other Programs

| Type | Attachment Point | Description |
|------|-----------------|-------------|
| `BPF_PROG_TYPE_CGROUP_DEVICE` | Cgroup | Device access control |
| `BPF_PROG_TYPE_CGROUP_SOCK` | Cgroup | Socket operations |
| `BPF_PROG_TYPE_CGROUP_SOCKOPT` | Cgroup | Socket option control |
| `BPF_PROG_TYPE_LSM` | LSM hooks | Linux Security Module hooks |
| `BPF_PROG_TYPE_STRUCT_OPS` | Struct ops | Replace kernel struct operations |

---

## 2. eBPF Map Types

### Basic Maps

| Type | Description | Key | Value |
|------|-------------|-----|-------|
| `BPF_MAP_TYPE_HASH` | Hash table | Any | Any |
| `BPF_MAP_TYPE_ARRAY` | Fixed-size array | u32 | Any |
| `BPF_MAP_TYPE_PERCPU_HASH` | Per-CPU hash table | Any | Any |
| `BPF_MAP_TYPE_PERCPU_ARRAY` | Per-CPU array | u32 | Any |
| `BPF_MAP_TYPE_LRU_HASH` | LRU hash table | Any | Any |
| `BPF_MAP_TYPE_LRU_PERCPU_HASH` | Per-CPU LRU hash | Any | Any |

### Special Maps

| Type | Description |
|------|-------------|
| `BPF_MAP_TYPE_RINGBUF` | Ring buffer (efficient output) |
| `BPF_MAP_TYPE_STACK_TRACE` | Stack traces |
| `BPF_MAP_TYPE_STACK` | Stack (LIFO) |
| `BPF_MAP_TYPE_QUEUE` | Queue (FIFO) |
| `BPF_MAP_TYPE_PROG_ARRAY` | Program array (tail calls) |
| `BPF_MAP_TYPE_PERF_EVENT_ARRAY` | Perf event output |
| `BPF_MAP_TYPE_CGROUP_ARRAY` | Cgroup references |
| `BPF_MAP_TYPE_DEVMAP` | Network device map |
| `BPF_MAP_TYPE_SOCKMAP` | Socket map |
| `BPF_MAP_TYPE_SOCKHASH` | Socket hash map |
| `BPF_MAP_TYPE_REUSEPORT_SOCKARRAY` | Reuseport sockets |
| `BPF_MAP_TYPE_HASH_OF_MAPS` | Map-in-map (hash) |
| `BPF_MAP_TYPE_ARRAY_OF_MAPS` | Map-in-map (array) |

---

## 3. eBPF Helper Functions

### Map Operations

| Helper | Signature | Description |
|--------|-----------|-------------|
| `bpf_map_lookup_elem` | `void*(map, key)` | Lookup element in map |
| `bpf_map_update_elem` | `int(map, key, value, flags)` | Update element |
| `bpf_map_delete_elem` | `int(map, key)` | Delete element |
| `bpf_map_push_elem` | `int(map, value, flags)` | Push to stack/queue |
| `bpf_map_pop_elem` | `int(map, value)` | Pop from stack/queue |
| `bpf_map_peek_elem` | `int(map, value)` | Peek at stack/queue |

### Ring Buffer

| Helper | Signature | Description |
|--------|-----------|-------------|
| `bpf_ringbuf_reserve` | `void*(map, size, flags)` | Reserve space in ringbuf |
| `bpf_ringbuf_submit` | `void*(data, flags)` | Submit reserved space |
| `bpf_ringbuf_discard` | `void*(data, flags)` | Discard reserved space |
| `bpf_ringbuf_output` | `int(map, data, size, flags)` | Write to ringbuf |
| `bpf_ringbuf_query` | `u64(map, flags)` | Query ringbuf state |

### Network Helpers

| Helper | Signature | Description |
|--------|-----------|-------------|
| `bpf_skb_load_bytes` | `int(skb, offset, to, len)` | Load bytes from packet |
| `bpf_skb_store_bytes` | `int(skb, offset, from, len, flags)` | Store bytes to packet |
| `bpf_skb_adjust_room` | `int(skb, len_diff, mode, flags)` | Adjust packet size |
| `bpf_skb_csum_diff` | `int(from, from_size, to, to_size, seed)` | Compute checksum diff |
| `bpf_skb_set_tunnel_key` | `int(skb, key, size, flags)` | Set tunnel metadata |
| `bpf_redirect` | `int(ifindex, flags)` | Redirect packet |
| `bpf_redirect_map` | `int(map, key, flags)` | Redirect via map |
| `bpf_clone_redirect` | `int(skb, ifindex, flags)` | Clone and redirect |
| `bpf_l3_csum_replace` | `int(skb, offset, from, to, flags)` | Replace L3 checksum |
| `bpf_l4_csum_replace` | `int(skb, offset, from, to, flags)` | Replace L4 checksum |

### Tracing Helpers

| Helper | Signature | Description |
|--------|-----------|-------------|
| `bpf_get_current_pid_tgid` | `u64()` | Get current PID/TGID |
| `bpf_get_current_uid_gid` | `u64()` | Get current UID/GID |
| `bpf_get_current_comm` | `int(buf, size)` | Get current command name |
| `bpf_ktime_get_ns` | `u64()` | Get kernel time (nanoseconds) |
| `bpf_ktime_get_boot_ns` | `u64()` | Get boot time (nanoseconds) |
| `bpf_get_current_task` | `u64()` | Get current task_struct pointer |
| `bpf_probe_read` | `int(dst, size, unsafe_ptr)` | Safely read kernel memory |
| `bpf_probe_read_user` | `int(dst, size, unsafe_ptr)` | Read user memory |
| `bpf_probe_read_kernel` | `int(dst, size, unsafe_ptr)` | Read kernel memory |
| `bpf_probe_read_str` | `int(dst, size, unsafe_ptr)` | Read string |
| `bpf_get_stackid` | `int(ctx, map, flags)` | Get stack trace ID |
| `bpf_get_stack` | `int(ctx, buf, size, flags)` | Get stack trace |

### Tail Calls

| Helper | Signature | Description |
|--------|-----------|-------------|
| `bpf_tail_call` | `int(ctx, prog_array_map, index)` | Call another BPF program |

### Other Helpers

| Helper | Signature | Description |
|--------|-----------|-------------|
| `bpf_get_prandom_u32` | `u32()` | Random number |
| `bpf_get_smp_processor_id` | `u32()` | Current CPU ID |
| `bpf_get_numa_node_id` | `long()` | Current NUMA node |
| `bpf_spin_lock` | `int(lock)` | Acquire spin lock |
| `bpf_spin_unlock` | `int(lock)` | Release spin lock |
| `bpf_get_cgroup_classid` | `u32()` | Get cgroup classid |

---

## 4. BPF Flags

### Map Update Flags

| Flag | Value | Description |
|------|-------|-------------|
| `BPF_ANY` | 0 | Create or update element |
| `BPF_NOEXIST` | 1 | Create only if doesn't exist |
| `BPF_EXIST` | 2 | Update only if exists |
| `BPF_F_LOCK` | 4 | Lock spin_lock field |

### XDP Flags

| Flag | Value | Description |
|------|-------|-------------|
| `XDP_ABORTED` | 0 | Error (drop + trace) |
| `XDP_DROP` | 1 | Drop packet |
| `XDP_PASS` | 2 | Pass to network stack |
| `XDP_TX` | 3 | Transmit on same interface |
| `XDP_REDIRECT` | 4 | Redirect to another interface |

---

## 5. bpftrace One-Liners

### System Calls

```bash
# Trace all syscalls
bpftrace -e 'tracepoint:syscalls:sys_enter_* { @[probe] = count(); }'

# Count syscalls by process
bpftrace -e 'tracepoint:raw_syscalls:sys_enter { @[comm] = count(); }'

# Trace open syscalls
bpftrace -e 'tracepoint:syscalls:sys_enter_openat { printf("%s %s\n", comm, str(args->filename)); }'

# Trace open with latency
bpftrace -e '
tracepoint:syscalls:sys_enter_openat { @start[tid] = nsecs; }
tracepoint:syscalls:sys_exit_openat /@start[tid]/ {
    printf("%s %s %d us\n", comm, str(@start[tid]), (nsecs - @start[tid]) / 1000);
    delete(@start[tid]);
}'

# Count open errors
bpftrace -e 'tracepoint:syscalls:sys_exit_openat /args->ret < 0/ { @[comm, args->ret] = count(); }'

# Trace connect syscalls
bpftrace -e 'kprobe:sys_connect { printf("%s connecting\n", comm); }'

# Trace read/write bytes by process
bpftrace -e '
tracepoint:syscalls:sys_exit_read /args->ret > 0/ { @bytes[comm] = sum(args->ret); }
tracepoint:syscalls:sys_exit_write /args->ret > 0/ { @bytes[comm] = sum(args->ret); }'
```

### Process Tracing

```bash
# Trace new processes
bpftrace -e 'tracepoint:sched:sched_process_exec { printf("new: %s (pid=%d)\n", comm, pid); }'

# Trace process exits
bpftrace -e 'tracepoint:sched:sched_process_exit { printf("exit: %s (pid=%d)\n", comm, pid); }'

# Count fork by process
bpftrace -e 'tracepoint:sched:sched_process_fork { @[comm] = count(); }'

# Trace signals
bpftrace -e 'tracepoint:signal:signal_generate { printf("%s -> pid %d: sig %d\n", comm, args->pid, args->sig); }'
```

### Disk I/O

```bash
# Trace block I/O
bpftrace -e 'tracepoint:block:block_rq_issue { printf("%s %d %s %d\n", comm, pid, args->rwbs, args->bytes); }'

# I/O latency histogram
bpftrace -e '
kprobe:blk_account_io_start { @start[tid] = nsecs; }
kprobe:blk_account_io_done /@start[tid]/ {
    @usecs = hist((nsecs - @start[tid]) / 1000);
    delete(@start[tid]);
}'

# I/O size by process
bpftrace -e 'tracepoint:block:block_rq_issue { @[comm] = sum(args->bytes); }'
```

### Network

```bash
# Trace TCP connections
bpftrace -e 'kprobe:tcp_connect { printf("%s connecting\n", comm); }'

# Trace TCP accept
bpftrace -e 'kprobe:inet_csk_accept { printf("%s accepted connection\n", comm); }'

# Count TCP retransmits
bpftrace -e 'kprobe:tcp_retransmit_skb { @[comm, kstack(5)] = count(); }'

# Trace DNS queries (UDP port 53)
bpftrace -e '
kprobe:udp_sendmsg {
    $sk = (struct sock *)arg0;
    $dport = $sk->__sk_common.skc_dport;
    if ($dport == 0x3500) { printf("%s DNS query\n", comm); }
}'
```

### Memory

```bash
# Page faults by process
bpftrace -e 'software:page-fault:1 { @[comm, kstack(5)] = count(); }'

# Count page allocations
bpftrace -e 'kprobe:__alloc_pages { @[comm] = count(); }'

# Track kmalloc
bpftrace -e 'kprobe:kmalloc { @bytes[comm] = sum(arg1); }'
```

### Scheduler

```bash
# CPU time by process
bpftrace -e '
tracepoint:sched:sched_switch { @[args->prev_comm] = sum(args->prev_state == 0 ? nsecs : 0); }'

# Context switch count
bpftrace -e 'tracepoint:sched:sched_switch { @[comm] = count(); }'

# Run queue latency
bpftrace -e '
tracepoint:sched:sched_wakeup { @qstart[args->pid] = nsecs; }
tracepoint:sched:sched_switch /@qstart[args->next_pid]/ {
    @us = hist((nsecs - @qstart[args->next_pid]) / 1000);
    delete(@qstart[args->next_pid]);
}'
```

---

## 6. BCC (BPF Compiler Collection) Tools

### Available Tools

| Tool | Description |
|------|-------------|
| `execsnoop` | Trace new process execution |
| `opensnoop` | Trace file opens |
| `biolatency` | Block I/O latency histogram |
| `biosnoop` | Block I/O tracing |
| `biotop` | Block I/O top |
| `cachestat` | Page cache hit/miss stats |
| `tcpconnect` | Trace TCP connections |
| `tcpaccept` | Trace TCP accepts |
| `tcpretrans` | TCP retransmissions |
| `tcplife` | TCP session lifespan |
| `tcptop` | TCP throughput top |
| `profile` | CPU profiling (flame graphs) |
| `funccount` | Count kernel function calls |
| `funclatency` | Function latency histogram |
| `trace` | Trace kernel functions |
| `argdist` | Argument distribution |
| `hardirqs` | Hardware interrupt time |
| `softirqs` | Software interrupt time |
| `runqlat` | Run queue latency |
| `runqlen` | Run queue length |
| `cpudist` | CPU scheduling latency |
| `memleak` | Memory leak detection |
| `oomkill` | Trace OOM kills |
| `filetop` | File I/O top |
| `ext4slower` | Slow ext4 operations |
| `xfsslower` | Slow XFS operations |
| `btrfsdist` | Btrfs latency distribution |
| `btrfsslower` | Slow Btrfs operations |
| `pidstat` | Per-PID statistics |
| `dcstat` | Directory cache stats |
| `vfsstat` | VFS operation stats |

### Common Usage

```bash
# Trace all execs
execsnoop

# Trace file opens with latency
opensnoop -T  # Include timestamps

# Block I/O latency
biolatency -D  # Per-disk

# TCP connections
tcpconnect -d  # Include DNS

# CPU profiling (60 seconds)
profile -F 99 -f 60 > out.stacks
# Generate flame graph
FlameGraph/flamegraph.pl out.stacks > profile.svg

# Trace specific function
trace 'do_sys_open "%s", arg2'

# Memory leak detection
memleak -p $(pidof myapp) 60

# Run queue latency
runqlat 10 1
```

---

## 7. libbpf and BPF CO-RE

### BPF CO-RE (Compile Once - Run Everywhere)

```c
// my_bpf.c
#include <vmlinux.h>
#include <bpf/bpf_helpers.h>
#include <bpf/bpf_tracing.h>
#include <bpf/bpf_core_read.h>

// Map definition
struct {
    __uint(type, BPF_MAP_TYPE_RINGBUF);
    __uint(max_entries, 256 * 1024);
} events SEC(".maps");

// BPF program
SEC("tracepoint/syscalls/sys_enter_openat")
int handle_open(struct trace_event_raw_sys_enter *ctx) {
    struct event *e;
    const char *filename;

    e = bpf_ringbuf_reserve(&events, sizeof(*e), 0);
    if (!e)
        return 0;

    e->pid = bpf_get_current_pid_tgid() >> 32;
    bpf_get_current_comm(&e->comm, sizeof(e->comm));

    // CO-RE: portable read from kernel struct
    filename = (const char *)ctx->args[1];
    bpf_probe_read_user_str(&e->filename, sizeof(e->filename), filename);

    bpf_ringbuf_submit(e, 0);
    return 0;
}

char LICENSE[] SEC("license") = "GPL";
```

### Build with libbpf

```bash
# Generate vmlinux.h
bpftool btf dump file /sys/kernel/btf/vmlinux format c > vmlinux.h

# Compile BPF program
clang -O2 -g -target bpf -c my_bpf.c -o my_bpf.o

# Generate skeleton
bpftool gen skeleton my_bpf.o > my_bpf.skel.h
```

---

## 8. bpftool Commands

```bash
# List all loaded BPF programs
bpftool prog list

# Show program details
bpftool prog show id 42

# Dump program instructions
bpftool prog dump xlated id 42
bpftool prog dump jited id 42

# List all maps
bpftool map list

# Dump map contents
bpftool map dump id 42

# Update map entry
bpftool map update id 42 key 0 0 0 0 value 1 0 0 0

# List BTF
bpftool btf list

# Dump BTF
bpftool btf dump id 42

# List links
bpftool link list

# List features
bpftool feature probe

# Pin program
bpftool prog pin id 42 /sys/fs/bpf/myprog

# Load and attach program
bpftool prog load my_bpf.o /sys/fs/bpf/myprog type tracepoint
```

---

## 9. BPF Type Format (BTF)

```bash
# Check if BTF is available
ls -la /sys/kernel/btf/vmlinux

# Dump BTF as C headers
bpftool btf dump file /sys/kernel/btf/vmlinux format c > vmlinux.h

# Show specific type
bpftool btf dump file /sys/kernel/btf/vmlinux format c | grep "struct task_struct"

# List all types
bpftool btf dump file /sys/kernel/btf/vmlinux | head -50
```

---

## 10. Practical Recipes

### File Access Auditing

```bash
# bpftrace: trace all file opens with full path
bpftrace -e '
tracepoint:syscalls:sys_enter_openat {
    printf("%-16s %-6d %s\n", comm, pid, str(args->filename));
}'
```

### Network Connection Monitoring

```bash
# BCC tcpconnect: trace outbound TCP connections
tcpconnect -d

# bpftrace: trace connect with IP/port
bpftrace -e '
kprobe:tcp_connect {
    $sk = (struct sock *)arg0;
    $daddr = $sk->__sk_common.skc_daddr;
    $dport = $sk->__sk_common.skc_dport;
    printf("%-16s %d.%d.%d.%d:%d\n", comm,
        ($daddr & 0xff), ($daddr >> 8) & 0xff,
        ($daddr >> 16) & 0xff, ($daddr >> 24) & 0xff,
        $dport >> 8 | (($dport & 0xff) << 8));
}'
```

### System Call Latency

```bash
# bpftrace: syscall latency histogram
bpftrace -e '
tracepoint:raw_syscalls:sys_enter { @start[tid] = nsecs; }
tracepoint:raw_syscalls:sys_exit /@start[tid]/ {
    @usecs = hist((nsecs - @start[tid]) / 1000);
    delete(@start[tid]);
}'
```

---

*eBPF documentation: https://ebpf.io/ and https://www.kernel.org/doc/html/latest/bpf/. BCC tools: https://github.com/iovisor/bcc.*
