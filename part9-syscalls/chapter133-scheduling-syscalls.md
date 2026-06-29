# Chapter 133: Scheduling Syscalls

## 1. Introduction

Linux provides a set of syscalls that allow processes and threads to influence how the kernel scheduler allocates CPU time. These range from setting the scheduling policy and priority to binding processes to specific CPU cores. Understanding these syscalls is crucial for real-time applications, high-performance computing, and latency-sensitive workloads.

---

## 2. sched_setscheduler / sched_getscheduler

### 2.1 Purpose

`sched_setscheduler` sets the scheduling policy and priority for a process. `sched_getscheduler` retrieves the current policy.

### 2.2 Prototype

```c
#include <sched.h>
int sched_setscheduler(pid_t pid, int policy, const struct sched_param *param);
int sched_getscheduler(pid_t pid);
```

### 2.3 Arguments

- **`pid`**: Process ID (0 = calling process)
- **`policy`**: Scheduling policy

| Policy | Description |
|--------|-------------|
| `SCHED_OTHER` | Normal time-sharing (default) |
| `SCHED_BATCH` | Like OTHER but optimized for batch workloads |
| `SCHED_IDLE` | Very low priority (background tasks) |
| `SCHED_FIFO` | Real-time, first-in-first-out |
| `SCHED_RR` | Real-time, round-robin |
| `SCHED_DEADLINE` | Earliest Deadline First (Linux 3.14+) |

- **`param`**: Scheduling parameters (priority)

```c
struct sched_param {
    int sched_priority;  // Priority (1-99 for SCHED_FIFO/RR)
};
```

### 2.4 Scheduling Policies in Detail

**SCHED_OTHER (Default):**
- Uses the Completely Fair Scheduler (CFS)
- Priority controlled by `nice` value (-20 to 19)
- Time-sharing with dynamic time slices
- Suitable for most applications

**SCHED_FIFO (Real-time):**
- Fixed priority (1-99, higher = more important)
- Runs until voluntarily preempted or blocked
- No time slicing — a SCHED_FIFO task can starve all OTHER tasks
- Requires `CAP_SYS_NICE` or `RLIMIT_RTTIME`

**SCHED_RR (Real-time):**
- Same as FIFO but with time slicing
- Default time quantum: 100ms (`/proc/sys/kernel/sched_rr_timeslice_ms`)
- Round-robin among tasks of equal priority

**SCHED_DEADLINE:**
- Earliest Deadline First (EDF) scheduling
- Three parameters: runtime, deadline, period
- Provides temporal isolation and guaranteed execution

### 2.5 Example

```c
#include <sched.h>
#include <stdio.h>
#include <string.h>

int main(void)
{
    // Set SCHED_FIFO with priority 50
    struct sched_param param = { .sched_priority = 50 };
    
    if (sched_setscheduler(0, SCHED_FIFO, &param) < 0) {
        perror("sched_setscheduler");
        // Probably need: sudo or CAP_SYS_NICE
        return 1;
    }
    
    int policy = sched_getscheduler(0);
    printf("Policy: %s\n",
           policy == SCHED_FIFO ? "FIFO" :
           policy == SCHED_RR ? "RR" :
           policy == SCHED_OTHER ? "OTHER" : "UNKNOWN");
    
    printf("Priority: %d\n", param.sched_priority);
    return 0;
}
```

### 2.6 SCHED_DEADLINE Example

```c
#include <sched.h>
#include <linux/sched/types.h>

struct sched_attr {
    uint32_t size;
    uint32_t sched_policy;
    uint64_t sched_flags;
    int32_t  sched_nice;
    uint32_t sched_priority;
    uint64_t sched_runtime;
    uint64_t sched_deadline;
    uint64_t sched_period;
};

// Use sched_setattr syscall (314 on x86-64)
struct sched_attr attr = {
    .size = sizeof(attr),
    .sched_policy = SCHED_DEADLINE,
    .sched_runtime = 10 * 1000 * 1000,    // 10ms runtime per period
    .sched_deadline = 50 * 1000 * 1000,   // 50ms deadline
    .sched_period = 100 * 1000 * 1000,    // 100ms period
};
syscall(314, 0, &attr, 0);  // sched_setattr
```

### 2.7 Kernel Implementation

```c
SYSCALL_DEFINE3(sched_setscheduler, pid_t, pid, int, policy,
                struct sched_param __user *, param)
{
    struct sched_attr attr = {
        .sched_policy = policy,
        .sched_priority = param->sched_priority,
    };
    return do_sched_setscheduler(pid, policy, &attr);
}
```

---

## 3. sched_setaffinity / sched_getaffinity

### 3.1 Purpose

These syscalls set and retrieve the CPU affinity mask — which CPU cores a process is allowed to run on.

### 3.2 Prototype

```c
#define _GNU_SOURCE
#include <sched.h>
int sched_setaffinity(pid_t pid, size_t cpusetsize, const cpu_set_t *cpuset);
int sched_getaffinity(pid_t pid, size_t cpusetsize, cpu_set_t *cpuset);
```

### 3.3 CPU Set Operations

```c
cpu_set_t mask;
CPU_ZERO(&mask);           // Clear all
CPU_SET(cpu, &mask);       // Add CPU
CPU_CLR(cpu, &mask);       // Remove CPU
CPU_ISSET(cpu, &mask);     // Check CPU
CPU_COUNT(&mask);          // Count CPUs
CPU_AND(&dest, &src1, &src2);  // Bitwise AND
CPU_OR(&dest, &src1, &src2);   // Bitwise OR
```

### 3.4 Example

```c
#define _GNU_SOURCE
#include <sched.h>
#include <stdio.h>

int main(void)
{
    cpu_set_t mask;
    
    // Get current affinity
    sched_getaffinity(0, sizeof(mask), &mask);
    printf("Allowed CPUs: ");
    for (int i = 0; i < CPU_SETSIZE; i++) {
        if (CPU_ISSET(i, &mask))
            printf("%d ", i);
    }
    printf("\n");
    
    // Pin to CPU 0 and 2
    CPU_ZERO(&mask);
    CPU_SET(0, &mask);
    CPU_SET(2, &mask);
    if (sched_setaffinity(0, sizeof(mask), &mask) < 0) {
        perror("sched_setaffinity");
        return 1;
    }
    
    printf("Now pinned to CPUs 0 and 2\n");
    return 0;
}
```

### 3.5 Use Cases

- **Real-time**: Pin real-time threads to dedicated cores
- **NUMA optimization**: Keep threads on the same NUMA node as their memory
- **HPC**: Control process placement for optimal performance
- **Isolation**: Dedicate cores to specific workloads (CPU isolation)

---

## 4. nice / setpriority / getpriority

### 4.1 Purpose

`nice` and `setpriority` adjust the scheduling priority for `SCHED_OTHER` processes. The "nice" value ranges from -20 (highest priority) to 19 (lowest priority).

### 4.2 Prototype

```c
#include <unistd.h>
int nice(int inc);

#include <sys/resource.h>
int setpriority(int which, int who, int prio);
int getpriority(int which, int who);
```

### 4.3 Arguments for setpriority

**`which`**:
| Value | Description |
|-------|-------------|
| `PRIO_PROCESS` | Process (who = PID, 0 = current) |
| `PRIO_PGRP` | Process group (who = PGID, 0 = current) |
| `PRIO_USER` | User (who = UID, 0 = current) |

**`prio`**: Nice value (-20 to 19)

### 4.4 Example

```c
#include <sys/resource.h>
#include <stdio.h>
#include <unistd.h>

int main(void)
{
    // Get current nice value
    int prio = getpriority(PRIO_PROCESS, 0);
    printf("Current nice: %d\n", prio);
    
    // Lower priority (be "nicer")
    setpriority(PRIO_PROCESS, 0, 10);
    printf("New nice: %d\n", getpriority(PRIO_PROCESS, 0));
    
    // Increase priority (requires CAP_SYS_NICE)
    if (setpriority(PRIO_PROCESS, 0, -10) < 0) {
        perror("setpriority (need CAP_SYS_NICE for negative nice)");
    }
    
    // Using nice() — increment by 5
    nice(5);
    printf("After nice(5): %d\n", getpriority(PRIO_PROCESS, 0));
    
    return 0;
}
```

### 4.5 Kernel Implementation

```c
SYSCALL_DEFINE3(setpriority, int, which, int, who, int, niceval)
{
    // Validate nice value
    if (niceval < -20 || niceval > 19)
        return -EINVAL;
    
    // Set nice value for the specified processes
    return set_one_prio(current, which, who, niceval);
}
```

---

## 5. sched_yield

### 5.1 Purpose

`sched_yield` voluntarily relinquishes the CPU, allowing other processes of the same priority to run.

### 5.2 Prototype

```c
#include <sched.h>
int sched_yield(void);
```

### 5.3 Behavior

- For `SCHED_OTHER`: The thread is moved to the end of its priority's run queue
- For `SCHED_FIFO`/`SCHED_RR`: The thread is moved to the end of its priority queue
- If no other thread is ready, the calling thread continues immediately

### 5.4 Example

```c
#include <sched.h>

while (!condition_met) {
    // Do some work
    process_data();
    
    // Give other threads a chance
    sched_yield();
}
```

### 5.5 When to Use

**Good use cases:**
- Spin-wait loops where you want to reduce CPU usage
- Producer-consumer with very short critical sections

**Bad use cases:**
- As a replacement for proper synchronization (use mutexes/condition variables)
- In tight loops (use `futex` or `nanosleep` instead)

---

## 6. sched_setattr / sched_getattr (Linux 3.14+)

### 6.1 Purpose

These are the modern, extensible versions of `sched_setscheduler`/`sched_getscheduler`. They support all scheduling policies including `SCHED_DEADLINE`.

### 6.2 Prototype

```c
#include <linux/sched/types.h>
int sched_setattr(pid_t pid, struct sched_attr *attr, unsigned int flags);
int sched_getattr(pid_t pid, struct sched_attr *attr, unsigned int size, unsigned int flags);
```

### 6.3 The `sched_attr` Structure

```c
struct sched_attr {
    __u32 size;              // Size of this structure
    __u32 sched_policy;      // Scheduling policy
    __u64 sched_flags;       // Flags
    __s32 sched_nice;        // Nice value (for SCHED_OTHER)
    __u32 sched_priority;    // Priority (for FIFO/RR)
    __u64 sched_runtime;     // Runtime (for DEADLINE, nanoseconds)
    __u64 sched_deadline;    // Deadline (for DEADLINE, nanoseconds)
    __u64 sched_period;      // Period (for DEADLINE, nanoseconds)
};
```

---

## 7. sched_get_priority_min / sched_get_priority_max

### 7.1 Purpose

Get the minimum and maximum priority for a scheduling policy.

### 7.2 Prototype

```c
int sched_get_priority_min(int policy);
int sched_get_priority_max(int policy);
```

### 7.3 Values

| Policy | Min | Max |
|--------|-----|-----|
| `SCHED_OTHER` | 0 | 0 |
| `SCHED_FIFO` | 1 | 99 |
| `SCHED_RR` | 1 | 99 |
| `SCHED_DEADLINE` | N/A | N/A |

---

## 8. Security and Privilege Requirements

| Operation | Required Privilege |
|-----------|-------------------|
| Set negative nice value | `CAP_SYS_NICE` |
| Set `SCHED_FIFO`/`SCHED_RR` | `CAP_SYS_NICE` |
| Set `SCHED_DEADLINE` | `CAP_SYS_NICE` |
| Change another user's nice | `CAP_SYS_NICE` |
| Set affinity of another process | `CAP_SYS_NICE` |
| `RLIMIT_RTTIME` | Limits real-time CPU time |

**Security risks:**
- Real-time tasks can starve all other processes (including system services)
- CPU affinity pinning can cause load imbalance
- `SCHED_DEADLINE` misconfiguration can cause missed deadlines

---

## 9. Common Bugs

```c
// BUG: Not checking if SCHED_FIFO requires privileges
sched_setscheduler(0, SCHED_FIFO, &param);  // Fails silently!
// FIX: Check return value and handle EPERM

// BUG: Setting priority outside valid range
param.sched_priority = 100;  // Max is 99!
// FIX: Use sched_get_priority_max()

// BUG: Forgetting that affinity is inherited across fork
sched_setaffinity(0, sizeof(mask), &mask);
fork();
// Child inherits the same affinity!
```

---

## 10. Kernel Source References

- **Scheduler core**: `kernel/sched/core.c`
- **CFS scheduler**: `kernel/sched/fair.c`
- **RT scheduler**: `kernel/sched/rt.c`
- **Deadline scheduler**: `kernel/sched/deadline.c`
- **`sched_setaffinity`**: `kernel/sched/core.c`
- **Nice/priority**: `kernel/sched/core.c`
- **Scheduler configuration**: `/proc/sys/kernel/sched_*`

---

## 11. Summary

Scheduling syscalls control how the kernel allocates CPU time:
- **`sched_setscheduler`**: Set scheduling policy (OTHER, FIFO, RR, DEADLINE)
- **`sched_setaffinity`**: Pin processes to specific CPU cores
- **`setpriority`/`nice`**: Adjust nice value for SCHED_OTHER
- **`sched_yield`**: Voluntarily give up CPU
- **`sched_setattr`**: Modern extensible scheduling interface

Proper use of these syscalls is essential for real-time systems, HPC, and latency-sensitive applications. Misuse can starve other processes or degrade system performance.

---

## 12. Detailed Scheduling Internals

### 12.1 The Completely Fair Scheduler (CFS)

CFS is the default scheduler for `SCHED_OTHER` processes. It uses a red-black tree ordered by `vruntime` (virtual runtime) to ensure fair CPU time distribution.

```c
struct sched_entity {
    struct rb_node run_node;     // Red-black tree node
    u64 vruntime;                // Virtual runtime
    u64 sum_exec_runtime;        // Total execution time
    u64 prev_sum_exec_runtime;   // Previous total
    u64 nr_migrations;           // Number of CPU migrations
    // ...
};
```

**vruntime calculation:**
```
vruntime += delta_exec * NICE_0_WEIGHT / weight_of_process
```

Nice value -20 has weight 88761, nice 0 has weight 1024, nice 19 has weight 15. This means a nice -20 process gets ~87x more CPU time than a nice 19 process.

### 12.2 Scheduling Domains and Load Balancing

The kernel organizes CPUs into scheduling domains based on their topology:

```c
struct sched_domain {
    struct sched_domain *parent;
    struct sched_group *groups;
    unsigned long min_interval;
    unsigned long max_interval;
    unsigned int busy_factor;
    unsigned int imbalance_pct;
    int flags;
    // ...
};
```

**Domain hierarchy on a typical system:**
1. **SMT domain**: Hyperthreaded siblings (share almost everything)
2. **MC domain**: Cores in the same socket (share L3 cache)
3. **DIE domain**: Cores in the same die
4. **NUMA domain**: Nodes connected via interconnect

Load balancing runs periodically to migrate tasks between CPUs within each domain. The balance interval increases at higher levels (less frequent balancing across NUMA nodes).

### 12.3 Real-Time Scheduling Internals

The RT scheduler uses 100 priority levels (0-99). Each priority level has its own queue. The scheduler always picks the highest-priority runnable RT task.

```c
struct rt_prio_array {
    DECLARE_BITMAP(bitmap, MAX_RT_PRIO + 1);
    struct list_head queue[MAX_RT_PRIO];
};
```

**RT throttling** prevents RT tasks from starving the system:
```
/proc/sys/kernel/sched_rt_period_us  (default: 1000000 = 1 second)
/proc/sys/kernel/sched_rt_runtime_us (default: 950000 = 0.95 seconds)
```

By default, RT tasks can use at most 0.95 seconds per 1-second period. This reserves 5% of CPU time for non-RT tasks.

### 12.4 The Deadline Scheduler

`SCHED_DEADLINE` uses Earliest Deadline First (EDF) scheduling with Constant Bandwidth Server (CBS). Each task has three parameters:

- **Runtime**: CPU time needed per period
- **Deadline**: By when the runtime must be completed
- **Period**: Recurrence interval

```c
struct sched_dl_entity {
    struct rb_node rb_node;
    u64 dl_runtime;      // Runtime in nanoseconds
    u64 dl_deadline;     // Relative deadline
    u64 dl_period;       // Period
    u64 dl_bw;           // Bandwidth (runtime / period)
    s64 runtime;         // Remaining runtime
    u64 deadline;        // Absolute deadline
    // ...
};
```

**Admission control:** The kernel ensures that the total bandwidth of all DEADLINE tasks on a CPU doesn't exceed 100%:

```
sum(runtime_i / period_i) <= 1.0 for all DEADLINE tasks on each CPU
```

### 12.5 CPU Frequency Scaling Interaction

The scheduler interacts with CPU frequency governors:

```c
// The scheduler hints at CPU utilization
// The cpufreq governor adjusts frequency accordingly
// P-state selection is driven by schedutil governor
```

The `schedutil` governor uses scheduler utilization data to set CPU frequency, providing better power-performance tradeoffs than the older `ondemand` governor.

### 12.6 NUMA-Aware Scheduling

The scheduler tries to keep tasks on the same NUMA node as their memory:

```c
struct numa_group {
    refcount_t refcount;
    spinlock_t lock;
    int nr_tasks;
    pid_t gid;
    int active_nodes;
    struct rcu_head rcu;
    unsigned long total_faults;
    unsigned long faults[0];
};
```

**AutoNUMA** (Automatic NUMA Balancing) periodically migrates tasks to the NUMA node where their memory is allocated. It uses page fault tracking to determine memory placement.

### 12.7 Cgroup Bandwidth Control

Cgroups v2 provides CPU bandwidth limiting:

```bash
# Limit to 50% of one CPU
echo "50000 100000" > /sys/fs/cgroup/mygroup/cpu.max

# Limit to 2 CPUs worth of time
echo "200000 100000" > /sys/fs/cgroup/mygroup/cpu.max
```

The kernel uses CFS bandwidth throttling to enforce these limits. Tasks in a throttled cgroup are descheduled until the next period.

### 12.8 Processor Affinity and IRQ Balancing

Beyond `sched_setaffinity`, the system's IRQ affinity affects scheduling:

```bash
# Check IRQ affinity
cat /proc/irq/42/smp_affinity

# Set IRQ to CPU 0 and 1
echo 3 > /proc/irq/42/smp_affinity
```

The `irqbalance` daemon automatically distributes IRQs across CPUs for optimal performance.

### 12.9 Scheduling in Containers

In containerized environments, CPU cgroups provide isolation:

```bash
# Kubernetes CPU limits map to cgroup settings
# 2 CPU limit → cpu.max = "200000 100000"
# CPU shares (weight) affect proportional sharing
echo 1024 > /sys/fs/cgroup/container/cpu.weight
```

The CFS scheduler treats each cgroup's tasks as a single scheduling entity, ensuring fair sharing between containers.

### 12.10 Scheduling-Related /proc Files

The kernel exposes scheduling information through /proc:

```bash
# Per-process scheduling info
cat /proc/[pid]/sched       # Detailed scheduler statistics
cat /proc/[pid]/stat        # Process state and scheduling data
cat /proc/[pid]/status      # Human-readable status including nice value

# System-wide scheduler tuning
/proc/sys/kernel/sched_child_runs_first  # Prefer child after fork
/proc/sys/kernel/sched_min_granularity_ns  # Minimum timeslice
/proc/sys/kernel/sched_wakeup_granularity_ns  # Wakeup granularity
/proc/sys/kernel/sched_migration_cost_ns  # Migration cost threshold
/proc/sys/kernel/sched_nr_migrate  # Max tasks to balance at once
/proc/sys/kernel/sched_autogroup_enabled  # Auto-group scheduling
/proc/sys/kernel/sched_rt_period_us  # RT throttling period
/proc/sys/kernel/sched_rt_runtime_us  # RT throttling runtime
/proc/sys/kernel/sched_cfs_bandwidth_slice_us  # CFS bandwidth slice
```

### 12.11 Scheduling Domains and cpuset

The cpuset cgroup controls CPU and memory node placement:

```bash
# Create a cpuset cgroup
mkdir /sys/fs/cgroup/cpuset/mygroup

# Assign CPUs 0-3
echo 0-3 > /sys/fs/cgroup/cpuset/mygroup/cpuset.cpus

# Assign NUMA node 0
echo 0 > /sys/fs/cgroup/cpuset/mygroup/cpuset.mems

# Move a process into the cpuset
echo $PID > /sys/fs/cgroup/cpuset/mygroup/cgroup.procs
```

The scheduler respects cpuset boundaries and only schedules tasks on their assigned CPUs.

### 12.12 Scheduling Fairness Metrics

The kernel tracks several fairness metrics:

- **Fairness index**: Measures how evenly CPU time is distributed
- **Latency**: Time between a task becoming runnable and actually running
- **Throughput**: Total work completed per unit time
- **Fairness vs latency tradeoff**: CFS balances these with configurable parameters

The `schedstat` file provides detailed statistics:
```bash
cat /proc/[pid]/schedstat
# Fields: time_on_cpu time_waiting run_count
```

### 12.13 Preemption in Detail

Linux supports multiple preemption models:

```bash
# Check current preemption model
cat /proc/sys/kernel/preempt
# 0: No forced preemption (server)
# 1: Voluntary kernel preemption (desktop)
# 2: Preemptible kernel (low-latency desktop)
# 3: Preemptible kernel with all debug options (RT)
```

Preemption points in the kernel:
- Return from interrupt
- Return from system call
- `preempt_enable()` calls
- `cond_resched()` calls (voluntary preemption)
- Explicit `schedule()` calls

For real-time applications, the PREEMPT_RT patch provides full kernel preemption, converting spinlocks to rt-mutexes.

### 12.14 The sched_setattr System Call

The modern `sched_setattr` syscall (number 314 on x86-64) provides a unified interface:

```c
#include <linux/sched/types.h>
#include <sys/syscall.h>

int sched_setattr(pid_t pid, struct sched_attr *attr, unsigned int flags)
{
    return syscall(__NR_sched_setattr, pid, attr, flags);
}

int sched_getattr(pid_t pid, struct sched_attr *attr, unsigned int size, unsigned int flags)
{
    return syscall(__NR_sched_getattr, pid, attr, size, flags);
}
```

This syscall supports all scheduling policies including `SCHED_DEADLINE` and provides a future-proof extensible interface.

### 12.15 Scheduling and Power Management

The scheduler interacts with the kernel's power management subsystem:

- **CPU frequency scaling**: The `schedutil` governor uses scheduler utilization data
- **CPU idle states**: The scheduler considers idle state exit latency when placing tasks
- **Energy-aware scheduling (EAS)**: On ARM big.LITTLE systems, the scheduler prefers energy-efficient cores for background tasks

```bash
# Check current governor
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor

# schedutil parameters
cat /sys/devices/system/cpu/cpufreq/policy0/schedutil/rate_limit_us
```

### 12.16 Scheduling Metrics and Monitoring

```bash
# Per-CPU scheduling statistics
cat /proc/schedstat

# Per-process scheduling statistics
cat /proc/[pid]/sched

# Key metrics:
# - se.sum_exec_runtime: Total CPU time consumed
# - se.nr_migrations: Number of CPU migrations
# - se.statistics.wait_max: Maximum wait time
# - se.statistics.wait_sum: Total wait time
# - se.statistics.iowait_sum: Total I/O wait time
```

These metrics are invaluable for diagnosing scheduling-related performance issues.

### 12.17 Scheduling and Real-time Guarantees

For real-time applications, the kernel must provide timing guarantees:

```c
// RT throttling prevents RT tasks from starving the system
// Default: 950ms per 1000ms period
// This means 5% of CPU time is always available for non-RT tasks

// To disable throttling (dangerous!):
echo -1 > /proc/sys/kernel/sched_rt_runtime_us

// Better: Increase the RT budget
echo 990000 > /proc/sys/kernel/sched_rt_runtime_us  # 99% for RT
```

**SCHED_DEADLINE guarantees:**
```c
// The deadline scheduler provides hard temporal isolation
// Each task gets its requested runtime within its deadline
// The admission control ensures feasibility

// Example: Audio processing
// Runtime: 1ms per 10ms period (10% CPU)
// Deadline: 10ms
// The kernel guarantees 1ms of CPU every 10ms
struct sched_attr attr = {
    .sched_policy = SCHED_DEADLINE,
    .sched_runtime = 1000000,     // 1ms
    .sched_deadline = 10000000,   // 10ms
    .sched_period = 10000000,     // 10ms
};
```

### 12.18 Scheduling Monitoring Tools

```bash
# perf sched: Analyze scheduling events
perf sched record -- sleep 10
perf sched latency
perf sched map

# schedstat: Per-CPU scheduling statistics
cat /proc/schedstat

# trace-cmd: Trace scheduling events
trace-cmd record -e sched_switch -e sched_wakeup sleep 5
trace-cmd report

# BPF-based monitoring
# bpftrace -e 'tracepoint:sched:sched_switch { @[comm] = count(); }'
```

These tools are essential for diagnosing scheduling-related performance issues in production systems.

### 12.19 Scheduling Summary Table

| Syscall | Purpose | Privilege Required |
|---------|---------|-------------------|
| `sched_setscheduler` | Set scheduling policy | CAP_SYS_NICE for RT |
| `sched_getscheduler` | Get scheduling policy | None |
| `sched_setparam` | Set RT priority | CAP_SYS_NICE |
| `sched_getparam` | Get RT priority | None |
| `sched_setaffinity` | Set CPU affinity | CAP_SYS_NICE for others |
| `sched_getaffinity` | Get CPU affinity | None |
| `setpriority` | Set nice value | CAP_SYS_NICE for negative |
| `getpriority` | Get nice value | None |
| `nice` | Increment nice value | CAP_SYS_NICE for decrease |
| `sched_yield` | Yield CPU | None |
| `sched_setattr` | Set scheduling attributes | CAP_SYS_NICE for RT |
| `sched_getattr` | Get scheduling attributes | None |
| `sched_get_priority_min` | Get min priority | None |
| `sched_get_priority_max` | Get max priority | None |
| `sched_rr_get_interval` | Get RR time quantum | None |
