# Appendix L: Kernel APIs Reference

## Overview

This appendix documents essential Linux kernel APIs for module and driver developers: memory allocation, locking mechanisms, kernel lists, workqueues, timers, and kobject/kref interfaces.

---

## 1. Memory Allocation

### Page-Level Allocation

| Function | Header | Description |
|----------|--------|-------------|
| `__get_free_page(gfp_mask)` | `<linux/gfp.h>` | Allocate one page (4KB) |
| `__get_free_pages(gfp_mask, order)` | `<linux/gfp.h>` | Allocate 2^order pages |
| `get_zeroed_page(gfp_mask)` | `<linux/gfp.h>` | Allocate zeroed page |
| `free_page(addr)` | `<linux/gfp.h>` | Free one page |
| `free_pages(addr, order)` | `<linux/gfp.h>` | Free 2^order pages |
| `alloc_pages(gfp_mask, order)` | `<linux/gfp.h>` | Allocate pages, returns `struct page *` |
| `__free_pages(page, order)` | `<linux/gfp.h>` | Free pages by `struct page *` |

### Slab Allocation (kmalloc family)

| Function | Header | Description |
|----------|--------|-------------|
| `kmalloc(size, gfp_mask)` | `<linux/slab.h>` | Allocate contiguous, physically contiguous memory |
| `kzalloc(size, gfp_mask)` | `<linux/slab.h>` | Allocate zeroed memory |
| `kcalloc(n, size, gfp_mask)` | `<linux/slab.h>` | Allocate array (zeroed) |
| `krealloc(ptr, size, gfp_mask)` | `<linux/slab.h>` | Reallocate |
| `kfree(ptr)` | `<linux/slab.h>` | Free kmalloc'd memory |
| `kvmalloc(size, gfp_mask)` | `<linux/slab.h>` | Allocate (tries kmalloc, falls back to vmalloc) |
| `kvzalloc(size, gfp_mask)` | `<linux/slab.h>` | Allocate zeroed (kmalloc or vmalloc) |
| `kvfree(ptr)` | `<linux/slab.h>` | Free kvmalloc'd memory |

### vmalloc (Virtual Contiguous)

| Function | Header | Description |
|----------|--------|-------------|
| `vmalloc(size)` | `<linux/vmalloc.h>` | Allocate virtually contiguous memory |
| `vzalloc(size)` | `<linux/vmalloc.h>` | Allocate zeroed virtually contiguous memory |
| `vfree(ptr)` | `<linux/vmalloc.h>` | Free vmalloc'd memory |

### GFP Flags

| Flag | Description |
|------|-------------|
| `GFP_KERNEL` | Normal kernel allocation (may sleep) |
| `GFP_ATOMIC` | Atomic allocation (never sleep, use in interrupt context) |
| `GFP_NOWAIT` | Don't wait for memory |
| `GFP_NOIO` | No I/O operations |
| `GFP_NOFS` | No filesystem operations |
| `GFP_USER` | Allocate for user space |
| `GFP_DMA` | Allocate in DMA zone |
| `GFP_DMA32` | Allocate in DMA32 zone |
| `__GFP_ZERO` | Zero the allocated memory |
| `__GFP_NOFAIL` | Never fail (retry forever) |
| `__GFP_NORETRY` | Don't retry on failure |
| `__GFP_NOWARN` | Suppress allocation failure warnings |

### Allocation Size Guidelines

| Size | Recommended Function |
|------|---------------------|
| < 4KB | `kmalloc()` / `kzalloc()` |
| 4KB - 128KB | `kmalloc()` (if physically contiguous needed) |
| > 128KB | `vmalloc()` / `kvmalloc()` |
| Page-aligned | `__get_free_pages()` |
| DMA buffers | `dma_alloc_coherent()` |

---

## 2. Locking Mechanisms

### Spinlock

```c
#include <linux/spinlock.h>

DEFINE_SPINLOCK(my_lock);       // Static initialization
spinlock_t lock;
spin_lock_init(&lock);          // Dynamic initialization

spin_lock(&my_lock);            // Acquire (disable preemption)
// Critical section
spin_unlock(&my_lock);          // Release

spin_lock_irq(&my_lock);        // Acquire, disable interrupts
spin_unlock_irq(&my_lock);      // Release, enable interrupts

spin_lock_irqsave(&my_lock, flags);  // Acquire, save and disable IRQs
spin_unlock_irqrestore(&my_lock, flags); // Release, restore IRQs

spin_lock_bh(&my_lock);        // Acquire, disable bottom halves
spin_unlock_bh(&my_lock);      // Release, enable bottom halves

spin_trylock(&my_lock);         // Try to acquire (returns 0 on failure)
```

**Usage**: Short critical sections, cannot sleep while holding.

### Mutex

```c
#include <linux/mutex.h>

DEFINE_MUTEX(my_mutex);         // Static initialization
struct mutex mutex;
mutex_init(&mutex);             // Dynamic initialization

mutex_lock(&my_mutex);          // Acquire (may sleep)
// Critical section (can sleep)
mutex_unlock(&my_mutex);        // Release

mutex_trylock(&my_mutex);       // Try to acquire
mutex_lock_interruptible(&my_mutex); // Acquire, interruptible
mutex_is_locked(&my_mutex);     // Check if locked
```

**Usage**: Longer critical sections, can sleep while holding.

### Read-Write Lock (rwlock)

```c
#include <linux/rwlock.h>

DEFINE_RWLOCK(my_rwlock);

read_lock(&my_rwlock);          // Acquire for reading
// Multiple readers allowed
read_unlock(&my_rwlock);

write_lock(&my_rwlock);         // Acquire for writing (exclusive)
// Exclusive access
write_unlock(&my_rwlock);
```

### Read-Copy-Update (RCU)

```c
#include <linux/rcupdate.h>

// Reader
rcu_read_lock();
p = rcu_dereference(ptr);
// Use p (no blocking/sleeping)
rcu_read_unlock();

// Writer
rcu_assign_pointer(ptr, new_p);
synchronize_rcu();  // Wait for all readers to finish
kfree(old_p);

// Or use call_rcu() for asynchronous cleanup
call_rcu(&old_p->rcu, my_callback);
```

### Semaphore

```c
#include <linux/semaphore.h>

DEFINE_SEM(my_sem, 1);          // Binary semaphore
struct semaphore sem;
sema_init(&sem, 1);             // Counting semaphore

down(&my_sem);                  // Acquire (may sleep)
up(&my_sem);                    // Release

down_trylock(&my_sem);         // Try to acquire
down_interruptible(&my_sem);   // Acquire, interruptible
```

### Atomic Operations

```c
#include <linux/atomic.h>

atomic_t counter = ATOMIC_INIT(0);

atomic_set(&counter, 42);       // Set value
atomic_read(&counter);          // Read value
atomic_inc(&counter);           // Increment
atomic_dec(&counter);           // Decrement
atomic_add(5, &counter);       // Add
atomic_sub(3, &counter);       // Subtract
atomic_inc_and_test(&counter); // Increment, test if zero
atomic_dec_and_test(&counter); // Decrement, test if zero
atomic_cmpxchg(&counter, old, new); // Compare and exchange
atomic_xchg(&counter, new);    // Exchange

// 64-bit atomic
atomic64_t val = ATOMIC64_INIT(0);
atomic64_inc(&val);
atomic64_read(&val);

// Bit operations
set_bit(nr, &flags);
clear_bit(nr, &flags);
change_bit(nr, &flags);
test_bit(nr, &flags);
test_and_set_bit(nr, &flags);
test_and_clear_bit(nr, &flags);
```

---

## 3. Kernel Linked Lists

### Doubly-Linked List (list_head)

```c
#include <linux/list.h>

// Define and initialize
struct my_struct {
    int data;
    struct list_head list;
};

LIST_HEAD(my_list);  // Static initialization
// Or:
INIT_LIST_HEAD(&my_list);  // Dynamic initialization

// Adding
list_add(&new->list, &my_list);         // Add after head
list_add_tail(&new->list, &my_list);    // Add before head (at tail)

// Deleting
list_del(&entry->list);                 // Remove from list
list_del_init(&entry->list);            // Remove and reinitialize

// Moving
list_move(&entry->list, &my_list);      // Move to head
list_move_tail(&entry->list, &my_list); // Move to tail

// Iteration
struct my_struct *entry;
list_for_each_entry(entry, &my_list, list) {
    printk(KERN_INFO "data: %d\n", entry->data);
}

// Safe iteration (allows removal)
struct my_struct *tmp;
list_for_each_entry_safe(entry, tmp, &my_list, list) {
    if (entry->data == 42) {
        list_del(&entry->list);
        kfree(entry);
    }
}

// Reverse iteration
list_for_each_entry_reverse(entry, &my_list, list) { ... }

// Check if empty
list_empty(&my_list)

// Splice (merge lists)
list_splice(&other_list, &my_list);
list_splice_tail(&other_list, &my_list);
```

### Hash List (hlist)

```c
#include <linux/list.h>

struct my_entry {
    int key;
    int value;
    struct hlist_node node;
};

#define HASH_SIZE 16
HLIST_HEAD(hash_table[HASH_SIZE]);

// Add to hash list
hlist_add_head(&entry->node, &hash_table[hash]);

// Delete
hlist_del(&entry->node);
hlist_del_init(&entry->node);

// Iteration
struct my_entry *entry;
hlist_for_each_entry(entry, &hash_table[i], node) {
    // Process entry
}

// Safe iteration
struct my_entry *tmp;
hlist_for_each_entry_safe(entry, tmp, &hash_table[i], node) {
    if (condition) {
        hlist_del(&entry->node);
        kfree(entry);
    }
}
```

---

## 4. Workqueues

### Using Workqueues

```c
#include <linux/workqueue.h>

// Define work
struct work_struct my_work;
struct delayed_work my_delayed_work;

// Work function
void my_work_func(struct work_struct *work) {
    // Do work (can sleep)
}

// Initialize
INIT_WORK(&my_work, my_work_func);
INIT_DELAYED_WORK(&my_delayed_work, my_work_func);

// Queue work
schedule_work(&my_work);                    // On system_wq
queue_work(my_wq, &my_work);               // On custom workqueue

// Queue delayed work
schedule_delayed_work(&my_delayed_work, HZ); // 1 second delay
queue_delayed_work(my_wq, &my_delayed_work, HZ);

// Cancel
cancel_work_sync(&my_work);
cancel_delayed_work_sync(&my_delayed_work);

// Flush
flush_work(&my_work);
flush_scheduled_work();
```

### Creating Custom Workqueues

```c
// Create single-threaded workqueue
struct workqueue_struct *my_wq;
my_wq = create_singlethread_workqueue("my_wq");
// Or (new API):
my_wq = alloc_workqueue("my_wq", WQ_UNBOUND, 0);

// Create multi-threaded workqueue
my_wq = alloc_workqueue("my_wq", WQ_UNBOUND | WQ_HIGHPRI, 0);

// Destroy
destroy_workqueue(my_wq);
```

### Workqueue Flags

| Flag | Description |
|------|-------------|
| `WQ_UNBOUND` | Not bound to any CPU |
| `WQ_FREEZABLE` | Freezable during suspend |
| `WQ_MEM_RECLAIM` | Guaranteed to make forward progress |
| `WQ_HIGHPRI` | High priority |
| `WQ_CPU_INTENSIVE` | CPU-intensive work |
| `WQ_SYSFS` | Visible in sysfs |

---

## 5. Timers

### Kernel Timers (Low Resolution)

```c
#include <linux/timer.h>

struct timer_list my_timer;

// Timer callback
void my_timer_func(struct timer_list *t) {
    // Timer expired
    // Re-arm if needed:
    mod_timer(&my_timer, jiffies + HZ);
}

// Initialize
timer_setup(&my_timer, my_timer_func, 0);

// Start timer
mod_timer(&my_timer, jiffies + HZ);  // 1 second

// Delete timer
del_timer(&my_timer);
del_timer_sync(&my_timer);  // Wait for callback to finish

// Check if pending
timer_pending(&my_timer);

// Modify timeout
mod_timer(&my_timer, jiffies + 2 * HZ);
```

### High-Resolution Timers (hrtimer)

```c
#include <linux/hrtimer.h>

struct hrtimer my_hrtimer;

// Callback
enum hrtimer_restart my_hrtimer_func(struct hrtimer *timer) {
    // Timer expired
    // Return HRTIMER_RESTART to re-arm, HRTIMER_NORESTART to stop
    return HRTIMER_NORESTART;
}

// Initialize
hrtimer_init(&my_hrtimer, CLOCK_MONOTONIC, HRTIMER_MODE_REL);
my_hrtimer.function = my_hrtimer_func;

// Start (relative, 100ms)
ktime_t ktime = ktime_set(0, 100000000);  // 0 sec, 100 ms
hrtimer_start(&my_hrtimer, ktime, HRTIMER_MODE_REL);

// Cancel
hrtimer_cancel(&my_hrtimer);

// Forward
hrtimer_forward(&my_hrtimer, now, interval);
```

### Kernel Time Functions

| Function | Description |
|----------|-------------|
| `jiffies` | Current tick count |
| `msecs_to_jiffies(ms)` | Convert milliseconds to jiffies |
| `jiffies_to_msecs(j)` | Convert jiffies to milliseconds |
| `usecs_to_jiffies(us)` | Convert microseconds to jiffies |
| `ktime_get()` | Get monotonic time (ktime_t) |
| `ktime_get_ns()` | Get monotonic time in nanoseconds |
| `ktime_get_real()` | Get real (wall clock) time |
| `ktime_get_boottime()` | Get boot time |
| `time_after(a, b)` | Is a after b? (jiffies comparison) |
| `time_before(a, b)` | Is a before b? |

---

## 6. kobject and kref

### kobject

```c
#include <linux/kobject.h>

struct my_device {
    struct kobject kobj;
    int value;
};

// Release function
void my_release(struct kobject *kobj) {
    struct my_device *dev = container_of(kobj, struct my_device, kobj);
    kfree(dev);
}

// Show/store for sysfs attributes
ssize_t value_show(struct kobject *kobj, struct kobj_attribute *attr, char *buf) {
    struct my_device *dev = container_of(kobj, struct my_device, kobj);
    return sprintf(buf, "%d\n", dev->value);
}

ssize_t value_store(struct kobject *kobj, struct kobj_attribute *attr,
                    const char *buf, size_t count) {
    struct my_device *dev = container_of(kobj, struct my_device, kobj);
    sscanf(buf, "%d", &dev->value);
    return count;
}

// Define attribute
struct kobj_attribute value_attr = __ATTR(value, 0644, value_show, value_store);

// Create kobject
struct my_device *dev = kzalloc(sizeof(*dev), GFP_KERNEL);
kobject_init_and_add(&dev->kobj, &my_ktype, NULL, "my_device");

// Create sysfs file
sysfs_create_file(&dev->kobj, &value_attr.attr);

// Remove
kobject_put(&dev->kobj);
```

### kref (Reference Counting)

```c
#include <linux/kref.h>

struct my_object {
    struct kref refcount;
    // ... other fields
};

void my_object_release(struct kref *ref) {
    struct my_object *obj = container_of(ref, struct my_object, refcount);
    kfree(obj);
}

// Initialize
struct my_object *obj = kmalloc(sizeof(*obj), GFP_KERNEL);
kref_init(&obj->refcount);  // Sets count to 1

// Get reference
kref_get(&obj->refcount);  // Increment count

// Put reference (release when count reaches 0)
kref_put(&obj->refcount, my_object_release);
```

---

## 7. Completion

```c
#include <linux/completion.h>

DECLARE_COMPLETION(my_completion);
// Or:
struct completion comp;
init_completion(&comp);

// Wait for completion
wait_for_completion(&my_completion);

// Wait with timeout
wait_for_completion_timeout(&my_completion, HZ * 5);  // 5 seconds

// Wait, interruptible
wait_for_completion_interruptible(&my_completion);

// Signal completion
complete(&my_completion);           // Wake one waiter
complete_all(&my_completion);       // Wake all waiters

// Reinitialize
reinit_completion(&my_completion);

// Check if completed
bool done = try_wait_for_completion(&my_completion);
```

---

## 8. Kernel Logging

```c
#include <linux/kernel.h>
#include <linux/printk.h>

// Log levels
printk(KERN_EMERG   "emergency\n");   // 0
printk(KERN_ALERT   "alert\n");       // 1
printk(KERN_CRIT    "critical\n");    // 2
printk(KERN_ERR     "error\n");       // 3
printk(KERN_WARNING "warning\n");     // 4
printk(KERN_NOTICE  "notice\n");      // 5
printk(KERN_INFO    "info\n");        // 6
printk(KERN_DEBUG   "debug\n");       // 7

// Dynamic debug
pr_debug("debug message\n");
dev_dbg(dev, "device debug: %d\n", value);

// Rate-limited
printk_ratelimited(KERN_WARNING "frequent warning\n");
pr_warn_ratelimited("rate-limited warning\n");

// Once
pr_warn_once("warning shown only once\n");

// Hex dump
print_hex_dump(KERN_DEBUG, "data: ", DUMP_PREFIX_OFFSET,
               16, 1, buf, len, true);
```

---

## 9. Error Handling Patterns

```c
#include <linux/err.h>

// Return error as pointer
struct device *my_create(void) {
    if (error)
        return ERR_PTR(-ENOMEM);
    return dev;
}

// Check for error
struct device *dev = my_create();
if (IS_ERR(dev)) {
    int err = PTR_ERR(dev);
    pr_err("Failed: %d\n", err);
    return err;
}

// Return negative errno
static int my_func(void) {
    if (!resource)
        return -ENOMEM;
    if (!permission)
        return -EACCES;
    return 0;
}

// Common error handling pattern
static int my_init(void) {
    int ret;

    ret = allocate_resource1();
    if (ret)
        goto err1;

    ret = allocate_resource2();
    if (ret)
        goto err2;

    ret = allocate_resource3();
    if (ret)
        goto err3;

    return 0;

err3:
    free_resource2();
err2:
    free_resource1();
err1:
    return ret;
}
```

---

## 10. Module Basics

```c
#include <linux/module.h>
#include <linux/init.h>

static int __init my_init(void) {
    pr_info("Module loaded\n");
    return 0;
}

static void __exit my_exit(void) {
    pr_info("Module unloaded\n");
}

module_init(my_init);
module_exit(my_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Author Name");
MODULE_DESCRIPTION("Module description");
MODULE_VERSION("1.0");
MODULE_ALIAS("custom:my-module");
```

### Module Parameters

```c
#include <moduleparam.h>

static int count = 1;
module_param(count, int, 0644);
MODULE_PARM_DESC(count, "Number of devices");

static char *name = "default";
module_param(name, charp, 0644);
MODULE_PARM_DESC(name, "Device name");

static int debug;
module_param(debug, bool, 0644);
MODULE_PARM_DESC(debug, "Enable debug output");
```

```bash
# Load with parameters
modprobe my_module count=4 name="test" debug=1

# View/change at runtime
cat /sys/module/my_module/parameters/count
echo 8 > /sys/module/my_module/parameters/count
```

---

*For kernel API documentation, see https://www.kernel.org/doc/html/latest/ and the kernel source at https://github.com/torvalds/linux.*
