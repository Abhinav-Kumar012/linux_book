# Chapter 134: Time Syscalls

## 1. Introduction

Time-related syscalls allow processes to read the system clock, set timers, sleep for precise durations, and receive timer notifications via file descriptors. This chapter covers `gettimeofday`, `clock_gettime`/`clock_settime`, `nanosleep`, `clock_nanosleep`, and `timerfd_create`/`settime`.

---

## 2. gettimeofday

### 2.1 Purpose

`gettimeofday` retrieves the current time with microsecond resolution. Largely superseded by `clock_gettime`.

### 2.2 Prototype

```c
#include <sys/time.h>
int gettimeofday(struct timeval *tv, struct timezone *tz);
```

### 2.3 The `timeval` Structure

```c
struct timeval {
    time_t      tv_sec;     // Seconds since epoch
    suseconds_t tv_usec;    // Microseconds (0-999999)
};
```

### 2.4 Kernel Implementation

On modern systems, `gettimeofday` is implemented via the vDSO — it reads the kernel's time data from a shared memory page without entering the kernel. Typical cost: ~20 nanoseconds.

### 2.5 Limitations

- Microsecond resolution (vs nanosecond for `clock_gettime`)
- Only one clock (`CLOCK_REALTIME` equivalent)
- The `tz` parameter is almost always NULL (timezone is better handled by userspace)

### 2.6 Example

```c
#include <sys/time.h>
#include <stdio.h>

int main(void)
{
    struct timeval tv;
    gettimeofday(&tv, NULL);
    printf("Time: %ld.%06ld\n", (long)tv.tv_sec, (long)tv.tv_usec);
    return 0;
}
```

---

## 3. clock_gettime / clock_settime

### 3.1 Purpose

`clock_gettime` retrieves the time from a specified clock with nanosecond resolution. `clock_settime` sets the time.

### 3.2 Prototype

```c
#include <time.h>
int clock_gettime(clockid_t clkid, struct timespec *tp);
int clock_settime(clockid_t clkid, const struct timespec *tp);
```

### 3.3 Clock Types

| Clock | Description |
|-------|-------------|
| `CLOCK_REALTIME` | System-wide real time (wall clock) |
| `CLOCK_MONOTONIC` | Monotonic time since boot (not affected by NTP) |
| `CLOCK_MONOTONIC_RAW` | Raw monotonic (no NTP adjustments) |
| `CLOCK_MONOTONIC_COARSE` | Fast but coarse monotonic |
| `CLOCK_REALTIME_COARSE` | Fast but coarse realtime |
| `CLOCK_BOOTTIME` | Like MONOTONIC but includes suspend time |
| `CLOCK_TAI` | International Atomic Time |
| `CLOCK_PROCESS_CPUTIME_ID` | Per-process CPU time |
| `CLOCK_THREAD_CPUTIME_ID` | Per-thread CPU time |

### 3.4 The `timespec` Structure

```c
struct timespec {
    time_t tv_sec;    // Seconds
    long   tv_nsec;   // Nanoseconds (0-999999999)
};
```

### 3.5 Kernel Implementation

```c
SYSCALL_DEFINE2(clock_gettime, const clockid_t, which_clock, struct timespec __user *, tp)
{
    struct timespec64 kernel_tp;
    int error = clock_gettime_kernel(which_clock, &kernel_tp);
    if (!error && put_timespec64(&kernel_tp, tp))
        error = -EFAULT;
    return error;
}
```

### 3.6 Performance

| Clock | Mechanism | Typical Cost |
|-------|-----------|-------------|
| `CLOCK_REALTIME` | vDSO | ~20 ns |
| `CLOCK_MONOTONIC` | vDSO | ~20 ns |
| `CLOCK_MONOTONIC_COARSE` | vDSO | ~10 ns |
| `CLOCK_REALTIME_COARSE` | vDSO | ~10 ns |
| `CLOCK_PROCESS_CPUTIME_ID` | Syscall | ~200 ns |
| `CLOCK_THREAD_CPUTIME_ID` | Syscall | ~200 ns |

The coarse clocks have ~1ms resolution (jiffy-based) but are faster.

### 3.7 Example: High-Resolution Timing

```c
#include <time.h>
#include <stdio.h>

static inline double timespec_diff(struct timespec *start, struct timespec *end)
{
    return (end->tv_sec - start->tv_sec) + 
           (end->tv_nsec - start->tv_nsec) / 1e9;
}

int main(void)
{
    struct timespec start, end;
    
    clock_gettime(CLOCK_MONOTONIC, &start);
    
    // Code to measure
    volatile long sum = 0;
    for (long i = 0; i < 100000000; i++)
        sum += i;
    
    clock_gettime(CLOCK_MONOTONIC, &end);
    
    printf("Elapsed: %.9f seconds\n", timespec_diff(&start, &end));
    return 0;
}
```

### 3.8 clock_settime

```c
// Requires CAP_SYS_TIME
struct timespec ts = {
    .tv_sec = 1700000000,  // Unix timestamp
    .tv_nsec = 0,
};
clock_settime(CLOCK_REALTIME, &ts);
```

### 3.9 Security

- `clock_settime` requires `CAP_SYS_TIME`
- `CLOCK_REALTIME` can jump (NTP adjustments) — use `CLOCK_MONOTONIC` for measuring durations
- `CLOCK_BOOTTIME` includes suspend time — useful for accurate uptime tracking

---

## 4. nanosleep / clock_nanosleep

### 4.1 Purpose

`nanosleep` suspends the calling thread for a specified duration. `clock_nanosleep` allows specifying which clock to use and whether the time is absolute or relative.

### 4.2 Prototype

```c
#include <time.h>
int nanosleep(const struct timespec *req, struct timespec *rem);
int clock_nanosleep(clockid_t clockid, int flags, const struct timespec *request, struct timespec *remain);
```

### 4.3 Arguments

**`clock_nanosleep` flags:**
| Flag | Description |
|------|-------------|
| 0 | Relative time (sleep for duration) |
| `TIMER_ABSTIME` | Absolute time (sleep until time) |

### 4.4 Return Values

- **Success**: 0 (full sleep completed)
- **Interrupted**: -1 with `errno = EINTR`, `rem` contains remaining time
- **Error**: -1 with other `errno`

### 4.5 Kernel Implementation

```c
SYSCALL_DEFINE2(nanosleep, struct timespec __user *, rqtp, struct timespec __user *, rmtp)
{
    struct timespec64 tu;
    
    if (get_timespec64(&tu, rqtp))
        return -EFAULT;
    
    if (!timespec64_valid(&tu))
        return -EINVAL;
    
    return hrtimer_nanosleep(&tu, rmtp, HRTIMER_MODE_REL, CLOCK_MONOTONIC);
}
```

The kernel uses high-resolution timers (`hrtimer`) for precise sleep. The thread is removed from the run queue and woken by a timer interrupt.

### 4.6 Example

```c
#include <time.h>
#include <stdio.h>

void precise_sleep(long seconds, long nanoseconds)
{
    struct timespec req = { .tv_sec = seconds, .tv_nsec = nanoseconds };
    struct timespec rem;
    
    while (nanosleep(&req, &rem) < 0) {
        if (errno == EINTR) {
            req = rem;  // Sleep for remaining time
            continue;
        }
        break;
    }
}

int main(void)
{
    struct timespec start, end;
    clock_gettime(CLOCK_MONOTONIC, &start);
    
    precise_sleep(1, 500000000);  // 1.5 seconds
    
    clock_gettime(CLOCK_MONOTONIC, &end);
    printf("Slept for %.9f seconds\n",
           (end.tv_sec - start.tv_sec) + (end.tv_nsec - start.tv_nsec) / 1e9);
    return 0;
}
```

### 4.7 Absolute vs Relative Sleep

```c
// Relative: sleep for 100ms
struct timespec req = { .tv_sec = 0, .tv_nsec = 100000000 };
nanosleep(&req, NULL);

// Absolute: sleep until specific time
struct timespec abs_time = { .tv_sec = 1700000100 };
clock_nanosleep(CLOCK_REALTIME, TIMER_ABSTIME, &abs_time, NULL);
// Advantage: no drift from processing time between calls
```

### 4.8 Sleep Precision

Actual sleep precision depends on:
- Timer resolution (usually 1ns with hrtimers)
- Timer slack (`prctl(PR_SET_TIMERSLACK)`) — default 50μs
- System load and scheduling
- Hardware timer capabilities

Typical accuracy: ±1-10 microseconds for `nanosleep` on a lightly loaded system.

---

## 5. timerfd_create / timerfd_settime / timerfd_gettime

### 5.1 Purpose

`timerfd_create` creates a file descriptor for receiving timer expiration events. Timers can be read from the fd, integrating with `poll`/`epoll` event loops.

### 5.2 Prototype

```c
#include <sys/timerfd.h>
int timerfd_create(int clockid, int flags);
int timerfd_settime(int fd, int flags, const struct itimerspec *new_value,
                    struct itimerspec *old_value);
int timerfd_gettime(int fd, struct itimerspec *curr_value);
```

### 5.3 timerfd_create Arguments

- **`clockid`**: `CLOCK_MONOTONIC`, `CLOCK_REALTIME`, `CLOCK_BOOTTIME`, `CLOCK_REALTIME_ALARM`, `CLOCK_BOOTTIME_ALARM`
- **`flags`**: `TFD_NONBLOCK`, `TFD_CLOEXEC`

### 5.4 The `itimerspec` Structure

```c
struct itimerspec {
    struct timespec it_interval;  // Periodic interval (0 = one-shot)
    struct timespec it_value;     // Initial expiration (0 = disarmed)
};
```

### 5.5 timerfd_settime Flags

| Flag | Description |
|------|-------------|
| 0 | Relative time |
| `TFD_TIMER_ABSTIME` | Absolute time |
| `TFD_TIMER_CANCEL_ON_SET` | Cancel on clock set (Linux 3.17+) |

### 5.6 Reading Timer Events

Each `read` returns a `uint64_t` containing the number of expirations since the last `read`. If the timer expired 5 times before you read, you'll get 5.

### 5.7 Example

```c
#include <sys/timerfd.h>
#include <time.h>
#include <unistd.h>
#include <stdio.h>
#include <stdint.h>
#include <poll.h>

int main(void)
{
    // Create timer fd
    int tfd = timerfd_create(CLOCK_MONOTONIC, TFD_NONBLOCK | TFD_CLOEXEC);
    if (tfd < 0) { perror("timerfd_create"); return 1; }
    
    // Arm timer: first expiration in 1 second, then every 500ms
    struct itimerspec its = {
        .it_interval = { .tv_sec = 0, .tv_nsec = 500000000 },  // 500ms
        .it_value = { .tv_sec = 1, .tv_nsec = 0 },              // 1s initial
    };
    timerfd_settime(tfd, 0, &its, NULL);
    
    // Wait for timer events
    for (int i = 0; i < 10; i++) {
        struct pollfd pfd = { .fd = tfd, .events = POLLIN };
        poll(&pfd, 1, -1);  // Wait for timer
        
        uint64_t expirations;
        read(tfd, &expirations, sizeof(expirations));
        printf("Timer expired %lu times\n", expirations);
    }
    
    close(tfd);
    return 0;
}
```

### 5.8 Disarming a Timer

```c
struct itimerspec zero = { {0, 0}, {0, 0} };
timerfd_settime(tfd, 0, &zero, NULL);  // Disarm
```

---

## 6. alarm / setitimer / getitimer (Legacy)

### 6.1 alarm

```c
unsigned int alarm(unsigned int seconds);
```
Sets a `SIGALRM` delivery after `seconds` seconds. Only one alarm at a time.

### 6.2 setitimer / getitimer

```c
int setitimer(int which, const struct itimerval *new_value, struct itimerval *old_value);
int getitimer(int which, struct itimerval *curr_value);
```

**Timer types:**
| Which | Signal | Description |
|-------|--------|-------------|
| `ITIMER_REAL` | `SIGALRM` | Real time |
| `ITIMER_VIRTUAL` | `SIGVTALRM` | Process virtual time |
| `ITIMER_PROF` | `SIGPROF` | Process + system time |

These are largely superseded by `timerfd` and POSIX timers (`timer_create`).

---

## 7. POSIX Timers: timer_create / timer_settime / timer_gettime

### 7.1 Purpose

POSIX timers provide per-process timers with signal notification.

### 7.2 Prototype

```c
#include <signal.h>
#include <time.h>
int timer_create(clockid_t clockid, struct sigevent *sevp, timer_t *timerid);
int timer_settime(timer_t timerid, int flags, const struct itimerspec *new_value,
                  struct itimerspec *old_value);
int timer_gettime(timer_t timerid, struct itimerspec *curr_value);
int timer_delete(timer_t timerid);
```

### 7.3 Signal Notification

```c
struct sigevent sev = {
    .sigev_notify = SIGEV_SIGNAL,
    .sigev_signo = SIGRTMIN,
    .sigev_value.sival_ptr = &timerid,
};
timer_create(CLOCK_MONOTONIC, &sev, &timerid);
```

Or with thread notification:
```c
sev.sigev_notify = SIGEV_THREAD;
sev.sigev_notify_function = timer_callback;
```

---

## 8. Security Implications

- **`clock_settime`**: Requires `CAP_SYS_TIME`. NTP daemon typically has this.
- **Timer bombs**: Creating many timers can exhaust kernel resources. Use `RLIMIT_SIGPENDING`.
- **`CLOCK_REALTIME` jumps**: NTP can cause sudden time jumps. Use `CLOCK_MONOTONIC` for intervals.
- **Timer slack**: `prctl(PR_SET_TIMERSLACK)` can delay timer delivery. Malicious processes can set large slack to delay signals.

---

## 9. Common Bugs

```c
// BUG: Using CLOCK_REALTIME for measuring durations
clock_gettime(CLOCK_REALTIME, &start);
do_work();
clock_gettime(CLOCK_REALTIME, &end);
// NTP might have adjusted the clock between measurements!

// FIX: Use CLOCK_MONOTONIC
clock_gettime(CLOCK_MONOTONIC, &start);
do_work();
clock_gettime(CLOCK_MONOTONIC, &end);

// BUG: Not handling EINTR in nanosleep
nanosleep(&req, NULL);  // Might be interrupted!
// FIX: Loop and use remaining time
while (nanosleep(&req, &rem) < 0 && errno == EINTR) req = rem;

// BUG: Not reading timerfd before it overflows
// If you don't read the timerfd, expirations accumulate
// Read returns the count — handle multiple expirations
```

---

## 10. Kernel Source References

- **`gettimeofday`/`clock_gettime`**: `kernel/time/timekeeping.c`
- **`nanosleep`/`clock_nanosleep`**: `kernel/time/hrtimer.c`, `kernel/time/nanosleep.c`
- **`timerfd`**: `fs/timerfd.c`
- **POSIX timers**: `kernel/time/posix-timers.c`
- **vDSO time**: `arch/x86/entry/vdso/vclock_gettime.c`
- **High-resolution timers**: `kernel/time/hrtimer.c`

---

## 11. Summary

Time syscalls provide the foundation for timing, scheduling, and synchronization:
- **`clock_gettime`**: Read clocks with nanosecond precision (prefer over `gettimeofday`)
- **`nanosleep`/`clock_nanosleep`**: Precise thread sleeping
- **`timerfd_create`/`settime`**: File-descriptor-based timer notification (best for event loops)
- **`timer_create`/`settime`**: POSIX timer with signal notification
- **`alarm`/`setitimer`**: Legacy timer mechanisms

For modern applications, use `clock_gettime(CLOCK_MONOTONIC)` for measuring durations and `timerfd` for timer events integrated with `epoll`.

---

## 12. Detailed Time Internals

### 12.1 The Kernel Time Subsystem

The Linux kernel maintains multiple clocks, each backed by a clocksource:

```c
struct clocksource {
    const char *name;
    struct list_head list;
    int rating;                // Quality rating (higher = better)
    cycle_t (*read)(struct clocksource *cs);
    cycle_t mask;
    u32 mult;                  // Conversion multiplier
    u32 shift;                 // Conversion shift
    u64 max_idle_ns;
    u32 maxadj;
    // ...
};
```

**Typical clocksources:**
- `tsc` (Time Stamp Counter): ~24 cycles per read, rating 300
- `hpet` (High Precision Event Timer): ~200 cycles, rating 250
- `acpi_pm` (ACPI Power Management): ~500 cycles, rating 200
- `kvm-clock`: Paravirtualized clock for VMs, rating 400

### 12.2 Timekeeping Architecture

The kernel's timekeeper maintains the current time:

```c
struct timekeeper {
    struct clocksource *clock;
    cycle_t cycle_last;
    u64 xtime_sec;              // Seconds since epoch
    unsigned long xtime_nsec;   // Nanoseconds
    u64 raw_sec;                // Raw monotonic seconds
    unsigned long raw_nsec;     // Raw monotonic nanoseconds
    s64 monotonic_to_boot;      // Offset to boottime
    // ...
};
```

**Update path:**
```
Timer interrupt (tick) or hrtimer
  → update_wall_time()
    → clocksource_read()
    → timekeeping_update()
      → update_fast_timekeeper() (for vDSO)
```

### 12.3 vDSO Time Implementation

The vDSO provides fast time reads without syscall overhead:

```c
// In the vDSO shared page (read-only mapping from kernel)
struct vdso_data {
    u32 seq;                    // Sequence counter (for lockless reads)
    s32 clock_mode;             // Clock mode
    u64 cycle_last;             // Last cycle count
    u64 mask;                   // Cycle mask
    u64 mult;                   // Cycle to nanosecond multiplier
    u32 shift;                  // Cycle to nanosecond shift
    struct timespec basetime[CS_BASES]; // Base times for each clock
    // ...
};
```

**vDSO read algorithm (lockless):**
```c
do {
    seq = vdso->seq;  // Read sequence number
    // rmb() barrier
    // Read time data
    // rmb() barrier
} while (seq != vdso->seq || (seq & 1));  // Retry if writer was active
```

### 12.4 NTP Integration

The kernel implements a hybrid PLL/FLL (Phase-Locked Loop / Frequency-Locked Loop) for clock synchronization:

```c
// NTP adjustment fields in timekeeper
s64 ntp_tick_adj;          // Tick adjustment (nanoseconds)
s64 ntp_error;             // Current error
s32 ntp_error_shift;       // Error filter shift
long time_freq;            // Frequency offset
long time_adjust;          // Step adjustment
long time_offset;          // Current offset
```

NTP adjustments are applied gradually to avoid time jumps:
- **Slew mode**: Gradual frequency adjustment (up to ±500 ppm)
- **Step mode**: Sudden time jump (for large offsets > 0.5 seconds)

### 12.5 Leap Second Handling

Leap seconds are handled specially:

```c
// When a leap second is inserted:
// 1. Kernel receives notification via adjtimex()
// 2. The leap second is applied at midnight UTC
// 3. timekeeper.leapsec is set
// 4. The second :60 is inserted (or :59 is skipped for negative leap)
```

**Leap second smearing:** Some NTP servers "smear" the leap second over 24 hours, gradually adjusting the clock rate. This avoids the discontinuity.

### 12.6 High-Resolution Timers (hrtimers)

The kernel uses hrtimers for precise timing:

```c
struct hrtimer {
    struct timerqueue_node node;
    ktime_t _softexpires;
    enum hrtimer_restart (*function)(struct hrtimer *);
    struct hrtimer_clock_base *base;
    u8 state;
    u8 is_rel;
    // ...
};
```

hrtimers are organized in clock bases:
- `HRTIMER_BASE_MONOTONIC`: CLOCK_MONOTONIC
- `HRTIMER_BASE_REALTIME`: CLOCK_REALTIME
- `HRTIMER_BASE_BOOTTIME`: CLOCK_BOOTTIME
- `HRTIMER_BASE_TAI`: CLOCK_TAI

The hrtimer interrupt programs the hardware timer for the next expiration. This allows sub-jiffy precision.

### 12.7 Timer Wheel vs hrtimers

The kernel has two timer mechanisms:

**Timer wheel** (`timer_list`): For large timeouts (milliseconds to hours). Uses a hierarchical wheel structure. Resolution is one jiffy (typically 1-10ms).

**hrtimers**: For precise timeouts (nanoseconds to seconds). Uses red-black trees. Resolution is hardware-limited (nanoseconds with modern hardware).

### 12.8 Clock Events and Tick Broadcast

On systems with CPU idle states that stop the local APIC timer:

```c
// Tick broadcast is used when the local timer stops during idle
// A global broadcast device (HPET, etc.) wakes CPUs for timer events
struct tick_device {
    struct clock_event_device *evtdev;
    enum tick_device_mode mode;
};
```

This is why `CLOCK_MONOTONIC` can have slightly lower precision on idle CPUs.

### 12.9 Time Namespaces (Linux 5.6+)

Time namespaces allow offsetting `CLOCK_MONOTONIC` and `CLOCK_BOOTTIME`:

```c
// Create time namespace
unshare(CLONE_NEWTIME);

// Set offsets
// Write to /proc/self/timens_offsets:
// "monotonic <offset_sec> <offset_nsec>"
// "boottime <offset_sec> <offset_nsec>"
```

This is useful for containers that need consistent timestamps after checkpoint/restore (CRIU).

### 12.10 Performance Measurement Best Practices

```c
// For measuring code sections:
struct timespec start, end;
clock_gettime(CLOCK_MONOTONIC, &start);

// ... code to measure ...

clock_gettime(CLOCK_MONOTONIC, &end);
double elapsed = (end.tv_sec - start.tv_sec) + 
                 (end.tv_nsec - start.tv_nsec) / 1e9;

// For measuring with maximum precision:
// Use rdtsc on x86 (CPU cycle counter)
// Available via __rdtsc() intrinsic
unsigned long long tsc = __rdtsc();
```

**Tips:**
- Use `CLOCK_MONOTONIC` for intervals, never `CLOCK_REALTIME`
- For very short intervals, consider `rdtsc` (but handle CPU frequency changes)
- Pin to a single CPU with `sched_setaffinity` for consistent measurements
- Warm up the CPU before measurements (frequency scaling)
- Use `perf stat` for cycle-accurate measurements when available

### 12.11 POSIX Timers in Detail

POSIX timers provide per-process timer objects:

```c
#include <signal.h>
#include <time.h>

timer_t timerid;
struct sigevent sev = {
    .sigev_notify = SIGEV_THREAD,      // Notify via thread
    .sigev_notify_function = timer_callback,
    .sigev_value.sival_ptr = &timerid,
};

// Create timer
timer_create(CLOCK_MONOTONIC, &sev, &timerid);

// Arm timer
struct itimerspec its = {
    .it_interval = { 0, 500000000 },  // 500ms interval
    .it_value = { 1, 0 },              // 1s initial
};
timer_settime(timerid, 0, &its, NULL);

// Later: disarm
its.it_value = (struct timespec){ 0, 0 };
timer_settime(timerid, 0, &its, NULL);

// Delete timer
timer_delete(timerid);
```

### 12.12 The adjtimex System Call

`adjtimex` provides fine-grained clock adjustment:

```c
#include <sys/timex.h>

struct timex tx = {
    .modes = ADJ_FREQUENCY,  // Adjust frequency
    .frequency = 1000,       // +1000 ppm
};
adjtimex(&tx);

// Modes:
// ADJ_OFFSET: Adjust time offset
// ADJ_FREQUENCY: Adjust clock frequency
// ADJ_MAXERROR: Set maximum error
// ADJ_ESTERROR: Set estimated error
// ADJ_STATUS: Set clock status
// ADJ_SETOFFSET: Set absolute offset
```

### 12.13 The clock_adjtime System Call

Like `adjtimex` but for specific clocks:

```c
int clock_adjtime(clockid_t clkid, struct timex *tx);
```

This allows adjusting `CLOCK_TAI` independently from `CLOCK_REALTIME`.

### 12.14 Timer Slack

Timer slack allows the kernel to coalesce timer expirations for power efficiency:

```c
// Set timer slack (in nanoseconds)
prctl(PR_SET_TIMERSLACK, 1000000);  // 1ms slack

// Default slack: 50 microseconds
// Larger slack = better power efficiency
// Smaller slack = more precise timing
```

The kernel uses timer slack to batch timer expirations, reducing wake-ups and saving power on battery-powered devices.

### 12.15 Time-related Resource Limits

```c
// RLIMIT_CPU: Maximum CPU seconds per process
// SIGXCPU sent when soft limit reached
// Process killed when hard limit reached

struct rlimit rl;
getrlimit(RLIMIT_CPU, &rl);
rl.rlim_cur = 60;    // 60 seconds soft limit
rl.rlim_max = 120;   // 120 seconds hard limit
setrlimit(RLIMIT_CPU, &rl);
```

### 12.16 The sched_yield and Timing Interaction

`sched_yield` can interact with timers in unexpected ways:

```c
// BUG: Using sched_yield for timing
while (1) {
    sched_yield();      // Might return immediately if no other tasks
    do_periodic_work(); // Timing is unreliable
}

// FIX: Use nanosleep or timerfd for precise timing
while (1) {
    nanosleep(&interval, NULL);
    do_periodic_work();
}
```

### 12.17 Clock Sources and Hardware Timers

The kernel selects the best available clocksource:

```bash
# List available clock sources
cat /sys/devices/system/clocksource/clocksource0/available_clocksource

# Current clock source
cat /sys/devices/system/clocksource/clocksource0/current_clocksource

# Switch clock source
echo tsc > /sys/devices/system/clocksource/clocksource0/current_clocksource
```

**Hardware timer types:**
- **TSC (Time Stamp Counter)**: CPU register, ~1ns resolution
- **HPET (High Precision Event Timer)**: Hardware timer, ~100ns resolution
- **ACPI PM Timer**: Power management timer, ~300ns resolution
- **PIT (Programmable Interval Timer)**: Legacy, ~1μs resolution
- **Local APIC Timer**: Per-CPU timer for scheduling

### 12.18 Timer Accuracy Considerations

Several factors affect timer accuracy:

- **NTP adjustments**: Can cause time jumps or gradual adjustments
- **CPU frequency scaling**: TSC may not be invariant
- **Suspend/resume**: `CLOCK_MONOTONIC` stops during suspend
- **Virtualization**: Guest clocks may drift from host
- **Timer coalescing**: Kernel may batch timer expirations for power efficiency

For maximum accuracy:
- Use `CLOCK_MONOTONIC_RAW` (no NTP adjustments)
- Pin to a single CPU
- Use `prctl(PR_SET_TIMERSLACK, 1)` to minimize coalescing
- Consider `CLOCK_BOOTTIME` for measuring wall-clock intervals including suspend
