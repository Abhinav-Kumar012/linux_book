# Chapter 58: Tracing and Profiling — strace, ltrace, perf, bpftrace

## Overview

Tracing and profiling tools reveal what programs are doing at the system call, library function, and CPU instruction level. These tools are essential for debugging performance issues, understanding program behavior, and diagnosing system problems.

---

## strace — Trace System Calls

### Purpose

`strace` traces system calls and signals made by a process. It's the primary tool for understanding what a program is doing at the kernel interface level.

### Key Options

| Option | Description |
|--------|-------------|
| `-p PID` | Attach to running process |
| `-e TRACE=set` | Filter system calls |
| `-c` | Summary/statistics mode |
| `-C` | Like `-c` but also produce regular output |
| `-f` | Follow child processes (fork/clone) |
| `-ff` | Write separate trace for each child |
| `-o FILE` | Output to file |
| `-t` | Timestamp (seconds) |
| `-tt` | Timestamp (microseconds) |
| `-ttt` | Timestamp (epoch) |
| `-T` | Time spent in each syscall |
| `-r` | Relative timestamp |
| `-s SIZE` | Max string size (default 32) |
| `-v` | Verbose (don't abbreviate) |
| `-x` | Print in hex |
| `-xx` | Print all strings in hex |
| `-y` | Decode paths (fd to path) |
| `-yy` | Decode sockets (fd to socket info) |
| `-k` | Print stack trace |
| `-n` | Number calls |
| `-a COLUMN` | Align return values |
| `-E VAR=VAL` | Set environment variable |
| `-u USER` | Run as user |
| `-I` | Interruptible only |

### Trace Filters

```bash
# System call classes
strace -e trace=network ./program    # Network calls
strace -e trace=file ./program       # File operations
strace -e trace=process ./program    # Process management
strace -e trace=signal ./program     # Signals
strace -e trace=ipc ./program        # IPC
strace -e trace=memory ./program     # Memory
strace -e trace=desc ./program       # File descriptors
strace -e trace=ipc ./program        # IPC

# Specific syscalls
strace -e trace=open,read,write ./program
strace -e trace=openat,read,write ./program

# Exclude syscalls
strace -e trace=!write ./program
```

### Examples

```bash
# Trace a command
strace ls -la

# Attach to running process
strace -p 1234

# Trace with timestamps
strace -t ls

# Trace with microsecond timestamps
strace -tt ls

# Show time in each syscall
strace -T ls

# Summary statistics
strace -c ls

# Follow child processes
strace -f ./server

# Output to file
strace -o trace.log ls

# Filter network calls
strace -e trace=network curl https://example.com

# Filter file operations
strace -e trace=open,openat,read,write,close ls

# Verbose with large string limit
strace -v -s 1024 ./program

# Show file descriptor paths
strace -y ls

# Show socket info
strace -yy ./server

# Stack traces
strace -k ./program

# Trace multiple PIDs
strace -p 1234 -p 5678

# Summary of child processes
strace -fc ./server

# Trace with environment
strace -E HOME=/tmp ./program

# Number output
strace -n ls

# Trace signals only
strace -e trace=signal ./program

# Attach and detach
strace -p 1234 -e trace=none -e signal=none
# Then Ctrl-C to detach

# Trace clone/fork/vfork
strace -e trace=clone,fork,vfork ./program

# Show relative time
strace -r ls

# All strings in hex
strace -xx ./program
```

### Common System Calls

| Syscall | Description |
|---------|-------------|
| `open/openat` | Open file |
| `read` | Read from file descriptor |
| `write` | Write to file descriptor |
| `close` | Close file descriptor |
| `stat/fstat/lstat` | Get file status |
| `mmap/munmap` | Memory mapping |
| `brk/sbrk` | Heap management |
| `ioctl` | Device control |
| `select/poll/epoll` | I/O multiplexing |
| `socket/connect/bind` | Network |
| `sendto/recvfrom` | Network I/O |
| `fork/clone/vfork` | Process creation |
| `execve` | Execute program |
| `wait4/waitpid` | Wait for child |
| `exit/exit_group` | Process exit |
| `kill/tgkill` | Send signal |
| `fcntl` | File control |
| `dup/dup2` | Duplicate fd |
| `pipe/pipe2` | Create pipe |
| `futex` | Fast userspace mutex |
| `nanosleep` | Sleep |
| `clock_gettime` | Get time |

---

## ltrace — Trace Library Calls

### Purpose

`ltrace` traces dynamic library calls made by a process.

### Key Options

| Option | Description |
|--------|-------------|
| `-p PID` | Attach to process |
| `-e FILTER` | Filter library calls |
| `-l LIBRARY` | Trace specific library |
| `-c` | Summary mode |
| `-f` | Follow child processes |
| `-o FILE` | Output to file |
| `-n N` | Indent nested calls |
| `-S` | Also trace syscalls |
| `-t` | Timestamp |
| `-tt` | Microsecond timestamp |
| `-r` | Relative timestamp |
| `-s SIZE` | Max string size |
| `-a COLUMN` | Align return values |
| `-C` | Demangle C++ names |

### Examples

```bash
# Trace library calls
ltrace ./program

# Trace specific library
ltrace -l libpthread ./program

# Filter calls
ltrace -e malloc,free ./program

# Summary mode
ltrace -c ./program

# Attach to process
ltrace -p 1234

# With syscalls
ltrace -S ./program

# Follow children
ltrace -f ./program

# Output to file
ltrace -o trace.log ./program

# With timestamps
ltrace -tt ./program
```

---

## perf — Performance Analysis Tool

### Purpose

`perf` is the Linux kernel's performance analysis toolkit. It provides CPU profiling, hardware counter monitoring, tracepoint analysis, and more.

### Subcommands

| Subcommand | Description |
|------------|-------------|
| `stat` | Count events |
| `record` | Record profiling data |
| `report` | Analyze recorded data |
| `top` | Real-time profiling |
| `list` | List available events |
| `trace` | Trace events |
| `bench` | Benchmarks |
| `sched` | Scheduler analysis |
| `lock` | Lock analysis |
| `kmem` | Kernel memory analysis |
| `mem` | Memory access analysis |
| `script` | Process trace data |
| `annotate` | Annotate source |
| `archive` | Archive data |
| `buildid-cache` | Build ID cache |
| `buildid-list` | List build IDs |
| `data` | Data file management |
| `evlist` | List events in data |
| `inject` | Filtered stream |
| `kallsyms` | Kernel symbols |
| `probe` | Define new tracepoints |

### perf stat

```bash
# Count events for command
perf stat ls

# Count events for PID
perf stat -p 1234

# Specific events
perf stat -e cache-misses,cache-references,instructions,cycles ./program

# Multiple runs
perf stat -r 5 ./program

# Per-CPU
perf stat -a sleep 5

# Specific CPU
perf stat -C 0 ./program

# Group events
perf stat -e '{instructions,cycles}' ./program

# CSV output
perf stat -x, ./program

# Detailed stats
perf stat -d ./program

# All events
perf stat -a -I 1000  # Every 1000ms
```

### perf record / report

```bash
# Record CPU profile
perf record ./program

# Record with frequency
perf record -F 99 ./program

# Record with call graph
perf record -g ./program

# Record specific event
perf record -e cache-misses ./program

# Record system-wide
perf record -a sleep 10

# Record specific PID
perf record -p 1234 sleep 10

# Record with dwarf call graph
perf record --call-graph dwarf ./program

# Record with stack traces
perf record --call-graph lbr ./program  # Last Branch Record

# Report
perf report

# Report with call graph
perf report --call-graph

# Report specific event
perf report --sort=symbol,dso

# Text report
perf report --stdio

# Annotated source
perf annotate

# Flame graph
perf script | stackcollapse-perf.pl | flamegraph.pl > flamegraph.svg
```

### perf top

```bash
# Real-time system-wide profiling
perf top

# Specific event
perf top -e cache-misses

# Specific CPU
perf top -C 0

# With call graph
perf top -g

# Sort by overhead
perf top -s symbol
```

### perf trace

```bash
# Trace syscalls (like strace)
perf trace ./program

# Trace specific syscalls
perf trace -e open,read,write ./program

# Trace PID
perf trace -p 1234

# Trace with timestamps
perf trace -t ./program

# Summary
perf trace -s ./program
```

### perf list

```bash
# List all events
perf list

# List hardware events
perf list hardware

# List software events
perf list software

# List cache events
perf list cache

# List tracepoints
perf list tracepoint

# List PMU events
perf list pmu
```

### Common Events

| Event | Description |
|-------|-------------|
| `cpu-cycles` | CPU cycles |
| `instructions` | Instructions retired |
| `cache-references` | Cache accesses |
| `cache-misses` | Cache misses |
| `branch-instructions` | Branch instructions |
| `branch-misses` | Branch mispredictions |
| `bus-cycles` | Bus cycles |
| `stalled-cycles-frontend` | Frontend stalls |
| `stalled-cycles-backend` | Backend stalls |
| `context-switches` | Context switches |
| `page-faults` | Page faults |
| `cpu-migrations` | CPU migrations |

---

## bpftrace — High-Level Tracing Language

### Purpose

`bpftrace` is a high-level tracing language for Linux based on eBPF. It provides a powerful, concise way to write tracing programs.

### Syntax

```
bpftrace -e 'program'
bpftrace script.bt
```

### Probe Types

| Probe | Description |
|-------|-------------|
| `tracepoint` | Kernel tracepoints |
| `kprobe` | Kernel function entry |
| `kretprobe` | Kernel function return |
| `uprobe` | Userspace function entry |
| `uretprobe` | Userspace function return |
| `software` | Software events |
| `hardware` | Hardware events |
| `interval` | Timed intervals |
| `profile` | Timed sampling |
| `BEGIN` | Script start |
| `END` | Script end |

### Built-in Variables

| Variable | Description |
|----------|-------------|
| `pid` | Process ID |
| `tid` | Thread ID |
| `uid` | User ID |
| `gid` | Group ID |
| `nsecs` | Nanoseconds |
| `elapsed` | Nanoseconds since start |
| `comm` | Process name |
| `func` | Function name |
| `probe` | Probe name |
| `arg0...argN` | Function arguments |
| `retval` | Return value |
| `ctx` | Context pointer |
| `$1...$N` | Positional parameters |
| `@name` | Map variable |
| `curtask` | Current task struct |
| `cgroup` | Cgroup ID |
| `kstack` | Kernel stack |
| `ustack` | User stack |

### Built-in Functions

| Function | Description |
|----------|-------------|
| `printf()` | Print formatted output |
| `time()` | Print timestamp |
| `str()` | Convert to string |
| `ksym()` | Kernel symbol |
| `usym()` | User symbol |
| `sym()` | Symbol |
| `ntop()` | IP address |
| `pton()` | Parse IP |
| `reg()` | Register value |
| `kaddr()` | Kernel address |
| `uaddr()` | User address |
| `count()` | Count occurrences |
| `sum()` | Sum values |
| `avg()` | Average |
| `min()` | Minimum |
| `max()` | Maximum |
| `hist()` | Histogram |
| `lhist()` | Linear histogram |
| `stats()` | Statistics |
| `delete()` | Delete map entry |
| `clear()` | Clear map |
| `exit()` | Exit script |

### Examples

```bash
# Trace open syscalls
bpftrace -e 'tracepoint:syscalls:sys_enter_openat { printf("%s %s\n", comm, str(args->filename)); }'

# Count syscalls by process
bpftrace -e 'tracepoint:raw_syscalls:sys_enter { @[comm] = count(); }'

# Trace read/write with size
bpftrace -e 'tracepoint:syscalls:sys_exit_read /args->ret > 0/ { @bytes[comm] = sum(args->ret); }'

# Histogram of read sizes
bpftrace -e 'tracepoint:syscalls:sys_exit_read /args->ret > 0/ { @bytes = hist(args->ret); }'

# Trace network connections
bpftrace -e 'kprobe:tcp_connect { printf("%s connected\n", comm); }'

# Count page faults
bpftrace -e 'software:page-faults:1 { @[comm] = count(); }'

# Profile CPU
bpftrace -e 'profile:hz:99 { @[kstack] = count(); }'

# Trace file opens with filename
bpftrace -e 'tracepoint:syscalls:sys_enter_openat { printf("%-16s %-6d %s\n", comm, pid, str(args->filename)); }'

# Count by syscall
bpftrace -e 'tracepoint:raw_syscalls:sys_enter { @[args->id] = count(); }'

# Trace disk I/O
bpftrace -e 'tracepoint:block:block_rq_issue { printf("%-16s %d %s %d\n", comm, pid, args->rwbs, args->bytes); }'

# Interval output
bpftrace -e 'tracepoint:syscalls:sys_enter_openat { @[comm] = count(); } interval:s:5 { print(@); clear(@); }'

# BEGIN/END
bpftrace -e 'BEGIN { printf("Tracing started\n"); } END { printf("Tracing ended\n"); }'

# Arguments
bpftrace -e 'tracepoint:syscalls:sys_enter_openat { printf("%s %s\n", comm, str(args->filename)); }' -- filename

# Trace specific PID
bpftrace -e 'tracepoint:syscalls:sys_enter_openat /pid == 1234/ { printf("%s\n", str(args->filename)); }'

# Kernel stack trace
bpftrace -e 'software:page-faults:1 { @[kstack] = count(); }'

# User stack trace
bpftrace -e 'software:page-faults:1 { @[ustack] = count(); }'

# List tracepoints
bpftrace -l 'tracepoint:syscalls:*'

# List specific tracepoint args
bpftrace -lv 'tracepoint:syscalls:sys_enter_openat'
```

---

## Summary

### Tool Selection Guide

| Task | Tool |
|------|------|
| Trace system calls | `strace` |
| Trace library calls | `ltrace` |
| CPU profiling | `perf record/report` |
| Real-time CPU profiling | `perf top` |
| Count performance events | `perf stat` |
| High-level tracing | `bpftrace` |
| Syscall summary | `strace -c` |
| Network debugging | `strace -e trace=network` |
| File debugging | `strace -e trace=file` |

### Quick Reference

```bash
# strace
strace ./program                    # Full trace
strace -c ./program                 # Summary
strace -e trace=file ./program      # File ops
strace -p 1234                      # Attach

# perf
perf stat ./program                 # Count events
perf record -g ./program            # Record profile
perf report                         # Analyze
perf top                            # Real-time

# bpftrace
bpftrace -e 'tracepoint:syscalls:sys_enter_openat { printf("%s\n", comm); }'
```
