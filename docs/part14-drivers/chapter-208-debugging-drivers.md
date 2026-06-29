# Chapter 208: Debugging Device Drivers

## 1. Introduction

Debugging device drivers is one of the most challenging tasks in systems programming. Unlike userspace applications, driver bugs can crash the entire system, corrupt memory, hang indefinitely, or cause subtle timing-dependent failures that are difficult to reproduce. The Linux kernel provides a rich set of debugging tools and techniques: from simple printk-based debugging to sophisticated tracing frameworks, dynamic debug, fault injection, and crash dump analysis.

This chapter covers the complete driver debugging toolkit: kernel logging, ftrace, dynamic debug, kprobes, KASAN, UBSAN, lockdep, crash dumps, and practical debugging methodologies for common driver issues.

## 2. Intuition

### 2.1 The Debugging Mindset

Driver debugging requires a different approach than userspace debugging:

- **No debugger by default**: You can't just attach gdb to the kernel (though KGDB exists, it requires setup).
- **System crashes**: A NULL pointer dereference in a driver can panic the entire system.
- **Timing sensitive**: Race conditions and interrupt-related bugs are hard to reproduce.
- **Hardware interaction**: The bug may be in the hardware, the firmware, or the driver.
- **Limited logging**: The kernel log buffer is circular and limited in size.

### 2.2 Categories of Driver Bugs

1. **Crashes**: NULL pointer dereference, use-after-free, stack overflow
2. **Hangs**: Deadlocks, infinite loops, missing wake-ups
3. **Data corruption**: Memory corruption, DMA issues, cache coherency
4. **Performance**: Lock contention, interrupt storms, cache misses
5. **Correctness**: Wrong register values, protocol violations, race conditions

### 2.3 The Debugging Toolkit

| Tool | Purpose | Overhead |
|------|---------|----------|
| `printk`/`pr_*`/`dev_*` | Basic logging | Low |
| `dynamic_debug` | Runtime enable/disable debug messages | None when off |
| `ftrace` | Function tracing, latency analysis | Low-Medium |
| `kprobes` | Dynamic instrumentation | Low-Medium |
| `KASAN` | Memory error detection | High |
| `UBSAN` | Undefined behavior detection | Medium |
| `lockdep` | Lock dependency checking | High |
| `KGDB` | Source-level debugging | High |
| `crash` | Post-mortem dump analysis | N/A |
| `devmem` | Direct memory/register inspection | None |

## 3. Architecture

### 3.1 Kernel Debug Infrastructure

```
┌─────────────────────────────────────────────────┐
│              Debug Output                        │
│  (dmesg, /dev/kmsg, console)                    │
├─────────────────────────────────────────────────┤
│              Logging Framework                   │
│  (printk, pr_*, dev_*, dynamic_debug)           │
├─────────────────────────────────────────────────┤
│              Tracing Framework                   │
│  (ftrace, tracepoints, kprobes, perf)           │
│  ┌──────────────┐  ┌────────────────────────┐  │
│  │ Function     │  │ Event Tracing          │  │
│  │ Tracer       │  │ (tracepoints, events)  │  │
│  └──────────────┘  └────────────────────────┘  │
├─────────────────────────────────────────────────┤
│              Sanitizers                          │
│  (KASAN, UBSAN, KMEMLEAK, KCSAN)               │
├─────────────────────────────────────────────────┤
│              Lock Debugging                      │
│  (lockdep, lock_stat)                           │
├─────────────────────────────────────────────────┤
│              Crash Analysis                      │
│  (kdump, crash, makedumpfile)                   │
├─────────────────────────────────────────────────┤
│              Remote Debugging                    │
│  (KGDB, JTAG, printk over serial)              │
└─────────────────────────────────────────────────┘
```

### 3.2 Debug Workflow

```
Bug detected (crash, hang, wrong behavior)
    │
    ▼
Reproduce the issue
    │
    ├─→ Crash/panic → Enable KASAN, UBSAN, lockdep
    ├─→ Hang → SysRq, ftrace, NMI watchdog
    ├─→ Wrong data → printk, tracepoints
    └─→ Performance → perf, ftrace latency
    │
    ▼
Collect information
    │
    ▼
Analyze (source code, traces, crash dumps)
    │
    ▼
Fix and test
```

## 4. Kernel Implementation

### 4.1 printk and Friends

```c
/* Basic printk (avoid in drivers — use pr_* or dev_* instead) */
printk(KERN_INFO "message\n");

/* Preferred: pr_* macros */
pr_emerg("emergency\n");      /* KERN_EMERG */
pr_alert("alert\n");           /* KERN_ALERT */
pr_crit("critical\n");         /* KERN_CRIT */
pr_err("error\n");             /* KERN_ERR */
pr_warn("warning\n");          /* KERN_WARNING */
pr_notice("notice\n");         /* KERN_NOTICE */
pr_info("info\n");             /* KERN_INFO */
pr_debug("debug\n");           /* KERN_DEBUG — only when DEBUG defined */

/* One-time messages */
pr_info_once("this prints only once\n");
pr_info_ratelimited("this is rate-limited\n");

/* Device-specific messages (preferred) */
dev_emerg(dev, "emergency\n");
dev_err(dev, "error: %d\n", ret);
dev_warn(dev, "warning\n");
dev_info(dev, "info\n");
dev_dbg(dev, "debug\n");      /* Only when DEBUG or dynamic_debug */

/* Hex dump */
print_hex_dump_bytes("data: ", DUMP_PREFIX_OFFSET, buf, len);

/* BUG/WARN macros */
BUG();                         /* Unconditional panic */
BUG_ON(condition);             /* Panic if condition true */
WARN_ON(condition);            /* Warn if condition true (no panic) */
WARN_ON_ONCE(condition);       /* Warn once */
```

### 4.2 Dynamic Debug

```c
/* In driver source: */
#include <linux/dynamic_debug.h>

/* These are enabled at runtime via sysfs or boot param */
dev_dbg(dev, "debug message: val=%d\n", val);
pr_debug("another debug message\n");

/* Runtime control via sysfs: */
/* Enable all dev_dbg in my_driver: */
/* echo "module my_driver +p" > /sys/kernel/debug/dynamic_debug/control */

/* Enable specific file: */
/* echo "file mydriver.c +p" > /sys/kernel/debug/dynamic_debug/control */

/* Enable specific function: */
/* echo "func my_probe +p" > /sys/kernel/debug/dynamic_debug/control */

/* Enable specific line: */
/* echo "file mydriver.c line 42 +p" > /sys/kernel/debug/dynamic_debug/control */

/* Boot parameter: */
/* dyndbg="module my_driver +p" */
/* dyndbg="file mydriver.c +p" */
```

### 4.3 ftrace

```bash
# Function tracing
echo function > /sys/kernel/debug/tracing/current_tracer
echo my_driver_* > /sys/kernel/debug/tracing/set_ftrace_filter
echo 1 > /sys/kernel/debug/tracing/tracing_on
# ... trigger the bug ...
echo 0 > /sys/kernel/debug/tracing/tracing_on
cat /sys/kernel/debug/tracing/trace

# Function graph tracing (shows call/return)
echo function_graph > /sys/kernel/debug/tracing/current_tracer
echo my_driver_probe > /sys/kernel/debug/tracing/set_graph_function
echo 1 > /sys/kernel/debug/tracing/tracing_on

# Trace specific events
echo 1 > /sys/kernel/debug/tracing/events/irq/irq_handler_entry/enable
echo 1 > /sys/kernel/debug/tracing/events/block/block_rq_issue/enable

# Latency tracing
echo preemptirqsoff > /sys/kernel/debug/tracing/current_tracer
echo 1 > /sys/kernel/debug/tracing/tracing_on

# trace-cmd (convenience wrapper)
trace-cmd record -p function_graph -g my_driver_probe
trace-cmd report
```

### 4.4 kprobes

```c
#include <linux/kprobes.h>

/* Static kprobe */
static int handler_pre(struct kprobe *p, struct pt_regs *regs)
{
    pr_info("kprobe: %s called, arg0=%lx\n",
            p->symbol_name, regs->di);  /* x86: first arg in rdi */
    return 0;
}

static struct kprobe kp = {
    .symbol_name = "my_target_function",
    .pre_handler = handler_pre,
};

/* Register in module init */
ret = register_kprobe(&kp);
if (ret < 0) {
    pr_err("register_kprobe failed: %d\n", ret);
    return ret;
}
pr_info("kprobe registered at %p\n", kp.addr);

/* Unregister in module exit */
unregister_kprobe(&kp);

/* kretprobe: probe function return */
static int ret_handler(struct kretprobe_instance *ri,
                       struct pt_regs *regs)
{
    int retval = regs_return_value(regs);
    pr_info("kretprobe: returned %d\n", retval);
    return 0;
}

static struct kretprobe krp = {
    .kp.symbol_name = "my_target_function",
    .handler = ret_handler,
    .maxactive = 20,
};

register_kretprobe(&krp);
```

### 4.5 KASAN (Kernel Address Sanitizer)

```c
/* Enable in kernel config: CONFIG_KASAN=y */

/* KASAN detects:
 * - Use-after-free
 * - Buffer overflow/underflow
 * - Stack buffer overflow
 * - Global buffer overflow
 * - Use-after-scope
 * - Invalid free
 */

/* Example KASAN report: */
/*
 * ==================================================================
 * BUG: KASAN: use-after-free in my_driver_read+0x100/0x200
 * Read of size 8 at addr ffff888012345678 by task cat/1234
 *
 * CPU: 0 PID: 1234 Comm: cat Not tainted 5.15.0 #1
 * Call Trace:
 *  dump_stack+0x8e/0xcd
 *  print_report+0x164/0x4a0
 *  kasan_report+0xad/0x130
 *  my_driver_read+0x100/0x200
 *  ...
 *
 * Allocated by task 1234:
 *  kasan_save_stack+0x1b/0x40
 *  __kasan_kmalloc+0x81/0xa0
 *  kmalloc+0xf3/0x120
 *  my_driver_open+0x50/0x100
 *  ...
 *
 * Freed by task 1234:
 *  kasan_save_stack+0x1b/0x40
 *  kasan_set_track+0x1c/0x30
 *  kasan_set_free_info+0x20/0x30
 *  __kasan_slab_free+0x101/0x150
 *  kfree+0x8a/0x120
 *  my_driver_close+0x30/0x80
 *  ...
 * ==================================================================
 */
```

### 4.6 lockdep (Lock Dependency Validator)

```c
/* Enable in kernel config: CONFIG_LOCKDEP=y */

/* lockdep detects:
 * - Deadlocks (ABBA lock ordering violations)
 * - Lock held while going to sleep
 * - Recursive lock attempts
 * - Missing lock releases
 */

/* Example lockdep report: */
/*
 * ======================================================
 * WARNING: possible circular locking dependency detected
 * 5.15.0 #1 Not tainted
 * ------------------------------------------------------
 * cat/1234 is trying to acquire lock:
 *  ffff888012345678 (&dev->lock){+.+.}-{3:3},
 *  at: my_read+0x50/0x100
 *
 * but task is already holding lock:
 *  ffff88801234abcd (&buf->mutex){+.+.}-{3:3},
 *  at: my_read+0x30/0x100
 *
 * which lock already depends on the new lock.
 *
 * the existing dependency chain (in reverse order) is:
 *
 * -> #1 (&buf->mutex){+.+.}-{3:3}:
 *        mutex_lock+0x40/0x50
 *        my_write+0x40/0x100
 *
 * -> #0 (&dev->lock){+.+.}-{3:3}:
 *        lock_acquire+0x100/0x200
 *        mutex_lock+0x40/0x50
 *        my_read+0x50/0x100
 *
 * DEADLOCK: lock &buf->mutex -> &dev->lock
 *           lock &dev->lock -> &buf->mutex
 * ======================================================
 */
```

### 4.7 Crash Dumps (kdump)

```bash
# Enable kdump (system crash dumps)
# 1. Install kexec-tools
# 2. Configure crashkernel in GRUB:
#    crashkernel=256M
# 3. Load kdump kernel:
#    systemctl enable kdump
#    systemctl start kdump

# After a crash, analyze the dump:
crash /usr/lib/debug/lib/modules/$(uname -r)/vmlinux \
      /var/crash/*/vmcore

# Inside crash:
crash> bt          # Backtrace of crashed task
crash> log         # Kernel log
crash> ps          # Process list
crash> files       # Open files
crash> vm          # Virtual memory info
crash> kmem        # Kernel memory info
crash> mod         # Loaded modules
crash> dis function_name  # Disassemble function
crash> struct my_dev ffff888012345678  # Inspect structure
crash> rd ffff888012345678 16  # Read memory
```

### 4.8 SysRq Keys

```bash
# Enable SysRq: echo 1 > /proc/sys/kernel/sysrq

# Key commands (Alt+SysRq+KEY or echo KEY > /proc/sysrq-trigger):
echo t > /proc/sysrq-trigger  # Show all task states (useful for hangs)
echo w > /proc/sysrq-trigger  # Show blocked tasks
echo l > /proc/sysrq-trigger  # Show all CPU backtraces
echo d > /proc/sysrq-trigger  # Show all locks
echo m > /proc/sysrq-trigger  # Show memory info
echo c > /proc/sysrq-trigger  # Trigger crash (for kdump)
echo b > /proc/sysrq-trigger  # Reboot immediately
echo s > /proc/sysrq-trigger  # Sync all filesystems
echo u > /proc/sysrq-trigger  # Remount all filesystems read-only
```

### 4.9 KGDB (Kernel GDB)

```bash
# Enable in kernel config: CONFIG_KGDB=y, CONFIG_KGDB_SERIAL_CONSOLE=y

# Boot with: kgdboc=ttyS0,115200 kgdbwait

# On host:
gdb vmlinux
(gdb) target remote /dev/ttyS0
(gdb) break my_driver_probe
(gdb) continue
# When breakpoint hits:
(gdb) bt
(gdb) print *dev
(gdb) info registers
(gdb) step
(gdb) next
(gdb) continue
```

## 5. Debugging Techniques

### 5.1 Debugging NULL Pointer Dereferences

```c
/* Symptom: kernel NULL pointer dereference at 0x00000000000000XX */

/* Technique 1: Add NULL checks with meaningful messages */
if (!dev) {
    pr_err("dev is NULL in %s\n", __func__);
    return -ENODEV;
}

/* Technique 2: Use BUG_ON for critical checks */
BUG_ON(!dev);

/* Technique 3: Use KASAN to find use-after-free */

/* Technique 4: Check the offset in the crash message */
/* "unable to handle kernel NULL pointer dereference at 0x0000000000000028"
 * → offset 0x28 in some structure — find which field */
```

### 5.2 Debugging Deadlocks

```c
/* Technique 1: Enable lockdep */

/* Technique 2: Use SysRq to dump blocked tasks */
/* echo w > /proc/sysrq-trigger */

/* Technique 3: Add lockdep annotations */
lock_acquire(&lock->dep_map, 0, 0, 0, 1, NULL, _RET_IP_);
lock_release(&lock->dep_map, _RET_IP_);

/* Technique 4: Check lock ordering */
/* Always acquire locks in the same order: A → B → C */
/* Never: A → B in one path, B → A in another */
```

### 5.3 Debugging Memory Leaks

```c
/* Technique 1: KMEMLEAK */
/* Enable: CONFIG_DEBUG_KMEMLEAK=y */
/* Check: cat /sys/kernel/debug/kmemleak */
/* Scan: echo scan > /sys/kernel/debug/kmemleak */

/* Technique 2: Use devm_* for automatic cleanup */

/* Technique 3: Add allocation/free logging */
pr_debug("alloc %p (%zu bytes)\n", ptr, size);
pr_debug("free %p\n", ptr);
```

### 5.4 Debugging DMA Issues

```c
/* Technique 1: Use DMA debug (CONFIG_DMA_API_DEBUG) */
/* Catches: double unmap, wrong direction, unaligned access */

/* Technique 2: Verify DMA addresses */
if (dma_mapping_error(dev, dma_addr)) {
    dev_err(dev, "DMA mapping failed\n");
    return -EIO;
}

/* Technique 3: Check DMA mask */
if (!dma_set_mask_and_coherent(dev, DMA_BIT_MASK(64)))
    dev_info(dev, "64-bit DMA\n");
else if (!dma_set_mask_and_coherent(dev, DMA_BIT_MASK(32)))
    dev_info(dev, "32-bit DMA\n");
else
    dev_err(dev, "DMA mask error\n");
```

### 5.5 Debugging Interrupt Issues

```c
/* Technique 1: Count interrupts */
static irqreturn_t my_irq(int irq, void *data)
{
    static atomic_t count = ATOMIC_INIT(0);
    int c = atomic_inc_return(&count);
    pr_debug("IRQ %d: count=%d\n", irq, c);
    /* ... */
}

/* Technique 2: Check /proc/interrupts */
/* cat /proc/interrupts */

/* Technique 3: ftrace IRQ events */
/* echo 1 > /sys/kernel/debug/tracing/events/irq/irq_handler_entry/enable */
/* echo 1 > /sys/kernel/debug/tracing/events/irq/irq_handler_exit/enable */

/* Technique 4: Check for interrupt storms */
/* Watch /proc/interrupts — rapidly increasing count = storm */
```

## 6. Common Pitfalls and Solutions

### 6.1 printk Not Appearing

```bash
# Problem: pr_info() output not visible

# Check 1: Is the log level high enough?
# dmesg -n 8  # Show all levels

# Check 2: Is the module loaded?
# lsmod | grep my_module

# Check 3: Use dmesg instead of console
# dmesg | tail

# Check 4: Check kernel config
# CONFIG_PRINTK=y
```

### 6.2 Module Won't Load

```bash
# Check dmesg for error messages
dmesg | tail -20

# Common issues:
# - Version mismatch: modprobe --force (dangerous)
# - Missing symbols: modprobe shows "Unknown symbol"
# - Tainted kernel: check /proc/sys/kernel/tainted
```

### 6.3 System Hangs

```bash
# Enable NMI watchdog
echo 1 > /proc/sys/kernel/nmi_watchdog

# Enable SysRq
echo 1 > /proc/sys/kernel/sysrq

# When hung:
# Alt+SysRq+w → Show blocked tasks
# Alt+SysRq+l → Show all CPU backtraces
# Alt+SysRq+t → Show all task states

# Or via serial console:
echo w > /proc/sysrq-trigger
echo l > /proc/sysrq-trigger
```

## 7. Best Practices

### 7.1 Use dev_dbg for Debug Messages

```c
/* Compile out when not debugging */
dev_dbg(dev, "probe: irq=%d, regs=%p\n", irq, regs);

/* Enable at runtime: */
/* echo "module my_driver +p" > /sys/kernel/debug/dynamic_debug/control */
```

### 7.2 Add Meaningful Error Messages

```c
/* WRONG */
return -EIO;

/* CORRECT */
dev_err(dev, "failed to read register at offset 0x%x: timeout\n", offset);
return -EIO;
```

### 7.3 Use WARN_ON for Sanity Checks

```c
/* Non-fatal sanity check */
if (WARN_ON(!dev))
    return -ENODEV;

/* Fatal sanity check */
BUG_ON(dev->magic != MY_MAGIC);
```

### 7.4 Use pr_fmt for Consistent Prefixes

```c
#define pr_fmt(fmt) KBUILD_MODNAME ": " fmt
#include <linux/module.h>
#include <linux/printk.h>

/* All pr_* messages now prefixed with module name */
pr_info("initialized\n");  /* Outputs: "my_driver: initialized\n" */
```

### 7.5 Use Tracepoints for Production Debugging

```c
/* Define a tracepoint */
TRACE_EVENT(my_driver_event,
    TP_PROTO(struct device *dev, int value),
    TP_ARGS(dev, value),
    TP_STRUCT__entry(
        __string(device, dev_name(dev))
        __field(int, value)
    ),
    TP_fast_assign(
        __assign_str(device, dev_name(dev));
        __entry->value = value;
    ),
    TP_printk("dev=%s value=%d", __get_str(device), __entry->value)
);

/* In driver: */
trace_my_driver_event(dev, 42);
```

## 8. Exercises

### Exercise 1: Debug with printk

Add `pr_debug()` statements to your character driver. Enable them via dynamic debug. Trace the complete lifecycle of a read() call.

### Exercise 2: ftrace Function Graph

Use ftrace function_graph tracer to trace the call graph of your driver's probe function. Identify all kernel functions called during probe.

### Exercise 3: KASAN Bug Hunting

Write a module with intentional memory bugs (use-after-free, buffer overflow). Enable KASAN and verify it catches each bug.

### Exercise 4: lockdep Test

Write a module with an intentional lock ordering violation. Enable lockdep and analyze the deadlock report.

### Exercise 5: Crash Dump Analysis

Set up kdump on a test system. Trigger a kernel panic from a module (`BUG()`). Analyze the crash dump with the `crash` tool.

## 9. References

### Kernel Source
- `kernel/printk/` — printk implementation
- `lib/dynamic_debug.c` — Dynamic debug
- `kernel/trace/` — ftrace framework
- `kernel/kprobes.c` — kprobes
- `mm/kasan/` — KASAN
- `lib/ubsan.c` — UBSAN
- `kernel/locking/lockdep.c` — lockdep
- `Documentation/dev-tools/` — Developer tools documentation
- `Documentation/trace/` — Tracing documentation

### Books
- *Linux Kernel Development, 3rd Edition* — Chapter 18
- *Linux Device Drivers, 3rd Edition* — Chapter 4
- *Professional Linux Kernel Architecture* — Wolfgang Mauerer

### Online
- https://www.kernel.org/doc/html/latest/dev-tools/
- https://www.kernel.org/doc/html/latest/trace/
- https://lwn.net/Articles/537562/ — KASAN
- https://lwn.net/Articles/54204/ — lockdep
- https://github.com/crash-utility/crash — crash tool

## 10. Deep Dive: Debugging Methodologies

### 10.1 The printk Debugging Methodology

Despite the availability of sophisticated tools, printk-based debugging remains the most commonly used technique for driver developers. The key is to use it systematically:

**Strategic Placement**: Place debug messages at key points in the driver lifecycle:
- Entry and exit of probe()/remove()
- Before and after hardware register access
- Entry and exit of interrupt handlers
- Error paths (every error return)
- State transitions (open/close, up/down)

**Conditional Compilation**: Use `#ifdef DEBUG` for verbose messages that shouldn't be in production builds:
```c
#ifdef DEBUG
#define my_dbg(dev, fmt, ...) dev_dbg(dev, fmt, ##__VA_ARGS__)
#else
#define my_dbg(dev, fmt, ...) do {} while (0)
#endif
```

**Rate Limiting**: For messages that might fire rapidly (e.g., in interrupt handlers), use rate limiting:
```c
pr_warn_ratelimited("unexpected interrupt: status=0x%x\n", status);
```

**Hex Dumps**: For debugging data structures or DMA buffers:
```c
print_hex_dump(KERN_DEBUG "my_dev: ", DUMP_PREFIX_OFFSET, 16, 1,
               buf, len, true);
```

### 10.2 Systematic Bug Isolation

When facing a complex bug, use a systematic approach:

1. **Reproduce**: Find a reliable way to trigger the bug. If it's timing-dependent, try adding delays or using stress tests.

2. **Binary Search**: If the bug appeared after changes, use `git bisect` to find the offending commit:
```bash
git bisect start
git bisect bad HEAD
git bisect good v5.10
# Build and test each version
git bisect run ./test_script.sh
```

3. **Narrow Down**: Add printk/breakpoints at key points to determine where execution diverges from expectations.

4. **Isolate**: Create a minimal test case that triggers the bug. Remove unnecessary code until only the essential bug-triggering path remains.

5. **Understand**: Once you can reproduce the bug reliably, understand *why* it happens, not just *where*. The root cause is often different from the symptom.

### 10.3 Hardware Interaction Debugging

Driver bugs often involve incorrect hardware interaction. Debugging these requires understanding both the driver and the hardware:

**Register Dumps**: Add a function that dumps all device registers:
```c
static void my_dump_regs(struct my_dev *dev)
{
    int i;
    for (i = 0; i < REG_SPACE_SIZE; i += 4) {
        dev_dbg(dev, "reg[0x%04x] = 0x%08x\n", i, readl(dev->regs + i));
    }
}
```

**Register Access Tracing**: Log every register read/write:
```c
static u32 my_reg_read(struct my_dev *dev, int offset)
{
    u32 val = readl(dev->regs + offset);
    dev_dbg(dev, "R [0x%04x] = 0x%08x\n", offset, val);
    return val;
}

static void my_reg_write(struct my_dev *dev, int offset, u32 val)
{
    dev_dbg(dev, "W [0x%04x] = 0x%08x\n", offset, val);
    writel(val, dev->regs + offset);
}
```

**Hardware State Machines**: Many devices have internal state machines. When debugging, dump the current state:
```c
u32 state = my_reg_read(dev, STATE_REG);
dev_dbg(dev, "device state: %s\n",
        state == STATE_IDLE ? "IDLE" :
        state == STATE_BUSY ? "BUSY" :
        state == STATE_ERROR ? "ERROR" : "UNKNOWN");
```

**Timing Issues**: Some hardware requires delays between operations. If you suspect timing issues:
```c
my_reg_write(dev, CMD_REG, CMD_START);
udelay(100);  /* Try adding a delay */
my_reg_write(dev, DATA_REG, value);
```

### 10.4 Concurrency Debugging

Race conditions are among the hardest bugs to find. Techniques include:

**Lockdep Annotations**: Use lockdep's annotations to document lock ordering:
```c
static DEFINE_MUTEX(my_mutex);

static void my_func(void)
{
    mutex_lock(&my_mutex);
    /* ... */
    mutex_unlock(&my_mutex);
}
```

**Atomic Operations Verification**: Verify that atomic operations are correctly paired:
```c
static void my_get(struct my_dev *dev)
{
    int count = atomic_inc_return(&dev->refcount);
    dev_dbg(dev, "get: refcount=%d\n", count);
}

static void my_put(struct my_dev *dev)
{
    int count = atomic_dec_return(&dev->refcount);
    dev_dbg(dev, "put: refcount=%d\n", count);
    WARN_ON(count < 0);
}
```

**Lock Ordering Documentation**: Document lock ordering in comments:
```c
/*
 * Lock ordering:
 *   1. my_global_lock
 *   2. dev->lock
 *   3. queue->lock
 */
```

**Race Detection with KCSAN**: Enable CONFIG_KCSAN (Kernel Concurrency Sanitizer) to detect data races at runtime.

### 10.5 Memory Debugging Beyond KASAN

**KMEMLEAK**: Detects kernel memory leaks by scanning for unreachable allocated objects:
```bash
echo scan > /sys/kernel/debug/kmemleak
cat /sys/kernel/debug/kmemleak
```

**Page Owner**: Tracks page allocations to identify who allocated each page:
```bash
# Enable: page_owner=on boot parameter
cat /sys/kernel/debug/page_owner > /tmp/page_owner
sort /tmp/page_owner | uniq -c | sort -rn | head
```

**Slab Debug**: Tracks slab (kmalloc) allocations:
```bash
# Enable: slub_debug=FZP
cat /proc/slabinfo
```

**Debug Page Alloc**: Catches page-level bugs:
```bash
# Enable: debug_pagealloc=on
```

### 10.6 Performance Debugging

**perf**: The standard Linux profiling tool:
```bash
# Profile a specific driver function
perf record -g -a sleep 5
perf report

# Trace specific events
perf trace -e 'irq:*' --filter 'irq==42'

# CPU cycle profiling
perf stat -d ./my_test_program
```

**ftrace Latency Tracers**:
```bash
# Find maximum interrupt-off latency
echo irqsoff > /sys/kernel/debug/tracing/current_tracer
echo 1 > /sys/kernel/debug/tracing/tracing_on
# ... run workload ...
cat /sys/kernel/debug/tracing/trace

# Find maximum preemption-off latency
echo preemptoff > /sys/kernel/debug/tracing/current_tracer
```

**Lock Stat**: Measure lock contention:
```bash
# Enable: CONFIG_LOCK_STAT=y
cat /proc/lock_stat
```

### 10.7 Serial Console Debugging

For systems that crash before the display is initialized, a serial console is essential:

```bash
# In GRUB: add console=ttyS0,115200 to kernel command line
# Or: console=tty0 console=ttyS0,115200 (both screen and serial)

# In kernel config:
CONFIG_SERIAL_8250=y
CONFIG_SERIAL_8250_CONSOLE=y
```

With a serial console, you can:
- See kernel messages even during boot
- Use SysRq keys through the serial connection
- Attach KGDB for source-level debugging
- Capture panic output that would otherwise be lost

### 10.8 QEMU/KVM Debugging

For drivers that can be tested in virtual machines, QEMU provides powerful debugging capabilities:

```bash
# Boot with QEMU and wait for GDB connection
qemu-system-x86_64 -kernel bzImage -append "root=/dev/sda nokaslr" \
    -drive file=rootfs.img -S -s

# In another terminal
gdb vmlinux
(gdb) target remote :1234
(gdb) break my_driver_probe
(gdb) continue

# QEMU monitor commands
# Ctrl+A C to enter QEMU monitor
(qemu) info registers
(qemu) info tlb
(qemu) info pci
```

QEMU also supports:
- `-d int`: Log interrupts
- `-d guest_errors`: Log guest errors
- `-trace enable=...`: Trace specific QEMU events

### 10.9 Documenting Bugs and Fixes

When you find and fix a driver bug, document it:

```c
/*
 * Fix: Handle race between interrupt handler and device removal
 *
 * Previously, the interrupt handler could access device data after
 * the remove() function freed it, causing a use-after-free crash.
 *
 * The fix adds a 'removed' flag and checks it in the IRQ handler
 * after acquiring the lock. The remove() function sets the flag
 * under the lock, then calls synchronize_irq() to ensure the
 * handler has completed.
 *
 * Fixes: abc123 ("Initial driver implementation")
 * Cc: stable@vger.kernel.org
 * Signed-off-by: Your Name <your@email.com>
 */
```
