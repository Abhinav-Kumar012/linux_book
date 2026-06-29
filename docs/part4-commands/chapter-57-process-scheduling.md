# Chapter 57: Process Scheduling — nice, renice, chrt, taskset

## Overview

Process scheduling controls how CPU time is distributed among processes. Linux provides several tools for adjusting process priority, scheduling policy, and CPU affinity. Understanding these tools is essential for optimizing system performance and ensuring critical workloads get adequate resources.

---

## Linux Scheduling Fundamentals

### Scheduling Policies

| Policy | Class | Description |
|--------|-------|-------------|
| `SCHED_OTHER` | CFS (Completely Fair Scheduler) | Default for normal processes |
| `SCHED_BATCH` | CFS | Optimized for batch processing |
| `SCHED_IDLE` | CFS | Very low priority |
| `SCHED_FIFO` | RT (Real-Time) | First-in-first-out, no time slicing |
| `SCHED_RR` | RT | Round-robin with time slicing |
| `SCHED_DEADLINE` | DL | Earliest Deadline First |

### Nice Values

- Range: -20 (highest priority) to 19 (lowest priority)
- Default: 0
- Only root can set negative nice values
- Nice values affect CFS scheduling weight

### Real-Time Priority

- Range: 1 (lowest) to 99 (highest)
- Real-time processes preempt all normal processes
- Dangerous — misconfigured RT processes can hang the system

---

## nice — Run with Modified Priority

### Purpose

`nice` runs a command with an adjusted nice value (priority).

### Syntax

```
nice [OPTION] [COMMAND [ARG]...]
```

### Key Options

| Option | Description |
|--------|-------------|
| `-n N` | Nice value adjustment (-20 to 19) |
| `--adjustment=N` | Same as `-n` |

### Examples

```bash
# Run with lower priority (nice +10)
nice -n 10 ./heavy_task

# Run with higher priority (requires root)
sudo nice -n -10 ./critical_task

# Default nice increment (+10)
nice ./heavy_task

# Run build with low priority
nice -n 19 make -j$(nproc)

# Run backup with low priority
nice -n 10 rsync -av /data/ /backup/

# Run database with high priority
sudo nice -n -20 mysqld
```

### Internals

`nice` calls the `nice()` syscall, which adjusts the process's nice value. The nice value maps to a weight in the CFS scheduler — lower nice values get proportionally more CPU time.

**CFS Weight Mapping**: Each nice value maps to a weight. The ratio of weights determines the proportion of CPU time. A process with nice 0 vs nice 5 gets roughly 1.5x more CPU time.

---

## renice — Change Priority of Running Process

### Purpose

`renice` changes the nice value of one or more running processes.

### Syntax

```
renice [-n] priority [-g|-p|-u] identifier...
```

### Key Options

| Option | Description |
|--------|-------------|
| `-n PRIORITY` | New nice value |
| `-p PID` | Process ID (default) |
| `-g GROUP` | Process group |
| `-u USER` | User's processes |

### Examples

```bash
# Change priority of PID
renice -n 10 -p 1234

# Change priority of multiple PIDs
renice -n 10 -p 1234 5678

# Change priority of user's processes
renice -n 15 -u john

# Change priority of process group
renice -n 5 -g mygroup

# Set high priority (requires root)
sudo renice -n -20 -p 1234

# Set priority to 19 (lowest)
renice -n 19 -p 1234

# Increase priority (requires root)
sudo renice -n -5 -p 1234
```

### Common Mistakes

1. **Forgetting `-n`**: `renice 10 -p 1234` is wrong. Use `renice -n 10 -p 1234`.

2. **Negative values**: Only root can set negative nice values (higher priority).

3. **Effect**: Nice values only affect CFS scheduling. Real-time processes are unaffected.

---

## chrt — Manipulate Real-Time Attributes

### Purpose

`chrt` views or changes the real-time scheduling attributes of a process.

### Syntax

```
chrt [options] priority command [arguments...]
chrt [options] -p [priority] PID
```

### Key Options

| Option | Description |
|--------|-------------|
| `-f` | SCHED_FIFO |
| `-r` | SCHED_RR |
| `-o` | SCHED_OTHER |
| `-b` | SCHED_BATCH |
| `-i` | SCHED_IDLE |
| `-d` | SCHED_DEADLINE |
| `-p PID` | Operate on existing PID |
| `--pid` | Same as `-p` |
| `-m` | Show min/max priorities |
| `-a` | Show all policies |
| `-v` | Verbose |

### Scheduling Policies

| Flag | Policy | Description |
|------|--------|-------------|
| `-f` | FIFO | Real-time, first-in-first-out |
| `-r` | RR | Real-time, round-robin |
| `-o` | OTHER | Normal scheduling |
| `-b` | BATCH | Batch processing |
| `-i` | IDLE | Idle priority |
| `-d` | DEADLINE | Earliest deadline first |

### Examples

```bash
# Run as FIFO with priority 50
chrt -f 50 ./realtime_task

# Run as RR with priority 30
chrt -r 30 ./realtime_task

# Run as normal (OTHER)
chrt -o 0 ./normal_task

# Show min/max priorities
chrt -m

# Change policy of running process
sudo chrt -f -p 50 1234

# Show scheduling info of process
chrt -p 1234

# Show all policies
chrt -a

# Run batch process
chrt -b 0 ./batch_job

# Run idle priority
chrt -i 0 ./background_task

# Verbose output
chrt -v -f 50 ./task
```

### Common Mistakes

1. **RT priority too high**: Setting priority 99 can make the system unresponsive. Use priorities 1-50 for most real-time tasks.

2. **Not using `sudo`**: Only root can set real-time scheduling.

3. **Missing `--pid`**: To change an existing process, use `chrt -f -p PRIORITY PID`.

4. **Starving other processes**: Real-time processes can starve normal processes. Use sparingly.

---

## taskset — Set or Retrieve CPU Affinity

### Purpose

`taskset` sets or retrieves the CPU affinity of a process, controlling which CPU cores a process can use.

### Syntax

```
taskset [options] mask command [arguments...]
taskset [options] -p [mask] pid
```

### Key Options

| Option | Description |
|--------|-------------|
| `-p` | Operate on existing PID |
| `-c` | Use CPU list instead of mask |
| `-a` | Operate on all threads |

### CPU Affinity Mask

The mask is a hexadecimal bitmask where each bit represents a CPU:

| Mask | Binary | CPUs |
|------|--------|------|
| `0x1` | 0001 | CPU 0 |
| `0x2` | 0010 | CPU 1 |
| `0x3` | 0011 | CPU 0, 1 |
| `0x4` | 0100 | CPU 2 |
| `0x5` | 0101 | CPU 0, 2 |
| `0xf` | 1111 | CPU 0, 1, 2, 3 |
| `0xff` | 11111111 | CPU 0-7 |

### Examples

```bash
# Run on CPU 0
taskset 0x1 ./task

# Run on CPU 0 and 1
taskset 0x3 ./task

# Run on CPU 2
taskset -c 2 ./task

# Run on CPU 0, 1, 2
taskset -c 0,1,2 ./task

# Set affinity of running process
taskset -p 0x1 1234

# Set affinity of running process (CPU list)
taskset -pc 0,1 1234

# Show affinity of running process
taskset -p 1234

# Run on specific NUMA node
numactl --cpunodebind=0 ./task

# Combine with nice
taskset -c 0 nice -n -10 ./task

# All threads
taskset -a -p 0x3 1234
```

### Internals

`taskset` calls `sched_setaffinity()` syscall to set the CPU affinity mask. The kernel scheduler will only schedule the process on the specified CPUs.

**Performance Considerations**:
- **Cache locality**: Pinning a process to a CPU improves cache hit rates.
- **NUMA awareness**: Pinning to CPUs on the same NUMA node reduces memory access latency.
- **Isolation**: Pinning critical processes prevents them from competing with other workloads.

---

## Summary

### Quick Reference

```bash
# Priority adjustment
nice -n 10 command              # Lower priority
nice -n -10 command             # Higher priority (root)
renice -n 10 -p 1234            # Change running process

# Real-time scheduling
chrt -f 50 command              # FIFO priority 50
chrt -r 30 command              # RR priority 30
chrt -p 1234                    # Show scheduling info

# CPU affinity
taskset -c 0 command            # Pin to CPU 0
taskset -c 0,1 command          # Pin to CPU 0,1
taskset -pc 2 1234              # Pin running process to CPU 2

# Combine
taskset -c 0 nice -n -10 ./task # Pin to CPU 0, high priority
```
