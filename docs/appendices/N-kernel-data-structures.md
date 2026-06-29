# Appendix N: Common Kernel Data Structures

## Overview

The Linux kernel implements several fundamental data structures used extensively throughout the codebase. This appendix documents the most common ones: `list_head`, `rb_root`, `hlist`, `kref`, and `completion`.

---

## 1. list_head — Doubly-Linked List

### Overview

The kernel's doubly-linked list is an intrusive list where the list node is embedded directly in the data structure. This avoids separate allocation for list nodes and improves cache locality.

### Declaration and Initialization

```c
#include <linux/list.h>

struct my_entry {
    int data;
    char name[32];
    struct list_head node;  /* Embedded list node */
};

/* Static initialization */
LIST_HEAD(my_list);

/* Dynamic initialization */
struct list_head my_list;
INIT_LIST_HEAD(&my_list);

/* Initialize entry's list_head */
struct my_entry *entry = kmalloc(sizeof(*entry), GFP_KERNEL);
INIT_LIST_HEAD(&entry->node);
```

### Adding Elements

```c
/* Add after head (stack-like, LIFO) */
list_add(&entry->node, &my_list);

/* Add before head (queue-like, FIFO) */
list_add_tail(&entry->node, &my_list);

/* Add after specific entry */
list_add(&new_entry->node, &existing_entry->node);

/* Add before specific entry */
list_add_tail(&new_entry->node, &existing_entry->node);
```

### Removing Elements

```c
/* Remove from list */
list_del(&entry->node);

/* Remove and reinitialize (safe for reuse) */
list_del_init(&entry->node);

/* Replace entry */
list_replace(&old_entry->node, &new_entry->node);

/* Replace and reinitialize old */
list_replace_init(&old_entry->node, &new_entry->node);
```

### Moving Elements

```c
/* Move to head of another list */
list_move(&entry->node, &other_list);

/* Move to tail of another list */
list_move_tail(&entry->node, &other_list);
```

### Iterating

```c
/* Simple iteration (read-only, no modification) */
struct my_entry *entry;
list_for_each_entry(entry, &my_list, node) {
    pr_info("data: %d, name: %s\n", entry->data, entry->name);
}

/* Safe iteration (allows removal during iteration) */
struct my_entry *entry, *tmp;
list_for_each_entry_safe(entry, tmp, &my_list, node) {
    if (entry->data == 0) {
        list_del(&entry->node);
        kfree(entry);
    }
}

/* Reverse iteration */
list_for_each_entry_reverse(entry, &my_list, node) {
    pr_info("data: %d\n", entry->data);
}

/* From current position */
list_for_each_entry_from(entry, &my_list, node) {
    /* Continue from entry */
}

/* Safe from current position */
list_for_each_entry_safe_from(entry, tmp, &my_list, node) {
    /* Continue from entry, safe for removal */
}
```

### Querying the List

```c
/* Check if list is empty */
if (list_empty(&my_list))
    pr_info("List is empty\n");

/* Check if entry is last */
if (list_is_last(&entry->node, &my_list))
    pr_info("Entry is last\n");

/* Get first entry */
struct my_entry *first = list_first_entry(&my_list, struct my_entry, node);

/* Get last entry */
struct my_entry *last = list_last_entry(&my_list, struct my_entry, node);

/* Get next/prev entry */
struct my_entry *next = list_next_entry(entry, node);
struct my_entry *prev = list_prev_entry(entry, node);

/* Check if list has exactly one entry */
if (!list_empty(&my_list) && list_is_singular(&my_list))
    pr_info("Exactly one entry\n");
```

### List Splicing (Merging)

```c
/* Insert list2 after head of list1 */
list_splice(&list2, &list1);

/* Insert list2 at tail of list1 */
list_splice_tail(&list2, &list1);

/* Insert list2 after head, reinitialize list2 */
list_splice_init(&list2, &list1);

/* Insert list2 at tail, reinitialize list2 */
list_splice_tail_init(&list2, &list1);
```

### Counting and Searching

```c
/* Count entries */
int count = 0;
struct my_entry *entry;
list_for_each_entry(entry, &my_list, node)
    count++;

/* Find entry by condition */
struct my_entry *found = NULL;
list_for_each_entry(entry, &my_list, node) {
    if (entry->data == target) {
        found = entry;
        break;
    }
}
```

### Example: Task List

```c
struct my_task {
    pid_t pid;
    char comm[16];
    struct list_head list;
};

LIST_HEAD(task_list);

void add_task(pid_t pid, const char *comm)
{
    struct my_task *task = kmalloc(sizeof(*task), GFP_KERNEL);
    if (!task)
        return;

    task->pid = pid;
    strscpy(task->comm, comm, sizeof(task->comm));
    list_add_tail(&task->list, &task_list);
}

void remove_task(pid_t pid)
{
    struct my_task *task, *tmp;
    list_for_each_entry_safe(task, tmp, &task_list, list) {
        if (task->pid == pid) {
            list_del(&task->list);
            kfree(task);
            return;
        }
    }
}

void list_tasks(void)
{
    struct my_task *task;
    list_for_each_entry(task, &task_list, list) {
        pr_info("PID: %d, comm: %s\n", task->pid, task->comm);
    }
}

void cleanup_all_tasks(void)
{
    struct my_task *task, *tmp;
    list_for_each_entry_safe(task, tmp, &task_list, list) {
        list_del(&task->list);
        kfree(task);
    }
}
```

---

## 2. hlist — Hash List (Singly-Linked with Tail Pointer)

### Overview

`hlist` is a singly-linked list with a pointer to the last element, making it efficient for hash tables where each bucket needs O(1) insertion at head and O(1) appending.

### Structure

```
hlist_head:  first → [node] → [node] → [node] → NULL
                    ↑                          ↑
              hlist_head                   hlist_node
              (pprev points                 (next points
               to &first or                 to next node
               prev->next)                  or NULL)
```

### Declaration and Initialization

```c
#include <linux/list.h>

struct my_entry {
    int key;
    int value;
    struct hlist_node node;
};

/* Static initialization */
HLIST_HEAD(my_hlist);

/* Dynamic initialization */
struct hlist_head my_hlist;
INIT_HLIST_HEAD(&my_hlist);

/* Initialize node */
struct hlist_node node;
INIT_HLIST_NODE(&node);
```

### Adding Elements

```c
/* Add at head */
hlist_add_head(&entry->node, &my_hlist);

/* Add after existing node */
hlist_add_after(&existing->node, &new_entry->node);

/* Add before existing node */
hlist_add_before(&new_entry->node, &existing->node);
```

### Removing Elements

```c
/* Remove from list */
hlist_del(&entry->node);

/* Remove and reinitialize */
hlist_del_init(&entry->node);
```

### Iterating

```c
/* Simple iteration */
struct my_entry *entry;
hlist_for_each_entry(entry, &my_hlist, node) {
    pr_info("key: %d, value: %d\n", entry->key, entry->value);
}

/* Safe iteration */
struct my_entry *entry, *tmp;
hlist_for_each_entry_safe(entry, tmp, &my_hlist, node) {
    if (entry->key == target) {
        hlist_del(&entry->node);
        kfree(entry);
    }
}

/* Iterate from specific node */
hlist_for_each_entry_from(entry, node) {
    /* Continue from entry */
}
```

### Querying

```c
/* Check if empty */
if (hlist_empty(&my_hlist))
    pr_info("Hash list is empty\n");

/* Check if unhashed */
if (hlist_unhashed(&entry->node))
    pr_info("Entry is not in any list\n");

/* Get first entry */
struct my_entry *first = hlist_entry(my_hlist.first, struct my_entry, node);
```

### Hash Table Example

```c
#include <linux/list.h>
#include <linux/hash.h>

#define HASH_BITS 10
#define HASH_SIZE (1 << HASH_BITS)

struct my_data {
    int key;
    int value;
    struct hlist_node node;
};

HLIST_HEAD(hash_table[HASH_SIZE]);

void hash_insert(int key, int value)
{
    unsigned int hash = hash_32(key, HASH_BITS);
    struct my_data *data = kmalloc(sizeof(*data), GFP_KERNEL);

    data->key = key;
    data->value = value;
    hlist_add_head(&data->node, &hash_table[hash]);
}

struct my_data *hash_lookup(int key)
{
    unsigned int hash = hash_32(key, HASH_BITS);
    struct my_data *entry;

    hlist_for_each_entry(entry, &hash_table[hash], node) {
        if (entry->key == key)
            return entry;
    }
    return NULL;
}

void hash_remove(int key)
{
    unsigned int hash = hash_32(key, HASH_BITS);
    struct my_data *entry, *tmp;

    hlist_for_each_entry_safe(entry, tmp, &hash_table[hash], node) {
        if (entry->key == key) {
            hlist_del(&entry->node);
            kfree(entry);
            return;
        }
    }
}

void hash_cleanup(void)
{
    int i;
    for (i = 0; i < HASH_SIZE; i++) {
        struct my_data *entry, *tmp;
        hlist_for_each_entry_safe(entry, tmp, &hash_table[i], node) {
            hlist_del(&entry->node);
            kfree(entry);
        }
    }
}
```

---

## 3. rb_root — Red-Black Tree

### Overview

Red-black trees are self-balancing binary search trees used throughout the kernel for O(log n) lookups, insertions, and deletions. Used by the scheduler (vruntime), memory management (VMA tree), and more.

### Declaration and Initialization

```c
#include <linux/rbtree.h>

struct my_node {
    int key;
    int value;
    struct rb_node rb;
};

/* Static initialization */
RB_ROOT(my_tree);

/* Dynamic initialization */
struct rb_root my_tree = RB_ROOT;
```

### Insertion

```c
int my_insert(struct rb_root *root, int key, int value)
{
    struct rb_node **new = &root->rb_node;
    struct rb_node *parent = NULL;
    struct my_node *data;

    /* Find insertion point */
    while (*new) {
        struct my_node *entry = rb_entry(*new, struct my_node, rb);
        parent = *new;

        if (key < entry->key)
            new = &(*new)->rb_left;
        else if (key > entry->key)
            new = &(*new)->rb_right;
        else
            return -EEXIST;  /* Duplicate key */
    }

    /* Create and insert new node */
    data = kmalloc(sizeof(*data), GFP_KERNEL);
    if (!data)
        return -ENOMEM;

    data->key = key;
    data->value = value;

    rb_link_node(&data->rb, parent, new);
    rb_insert_color(&data->rb, root);

    return 0;
}
```

### Lookup

```c
struct my_node *my_search(struct rb_root *root, int key)
{
    struct rb_node *node = root->rb_node;

    while (node) {
        struct my_node *entry = rb_entry(node, struct my_node, rb);

        if (key < entry->key)
            node = node->rb_left;
        else if (key > entry->key)
            node = node->rb_right;
        else
            return entry;
    }
    return NULL;
}
```

### Deletion

```c
void my_delete(struct rb_root *root, int key)
{
    struct my_node *entry = my_search(root, key);
    if (entry) {
        rb_erase(&entry->rb, root);
        kfree(entry);
    }
}
```

### Iteration

```c
/* In-order traversal (ascending) */
struct rb_node *node;
for (node = rb_first(&my_tree); node; node = rb_next(node)) {
    struct my_node *entry = rb_entry(node, struct my_node, rb);
    pr_info("key: %d, value: %d\n", entry->key, entry->value);
}

/* Reverse traversal (descending) */
for (node = rb_last(&my_tree); node; node = rb_prev(node)) {
    struct my_node *entry = rb_entry(node, struct my_node, rb);
    pr_info("key: %d, value: %d\n", entry->key, entry->value);
}

/* Safe iteration (allows deletion) */
struct rb_node *node, *next;
for (node = rb_first(&my_tree); node; node = next) {
    struct my_node *entry = rb_entry(node, struct my_node, rb);
    next = rb_next(node);

    if (entry->value == 0) {
        rb_erase(&entry->rb, &my_tree);
        kfree(entry);
    }
}
```

### Replacing a Node

```c
/* Replace old node with new node (preserves position) */
rb_replace_node(&old->rb, &new->rb, &my_tree);
```

### Augmented Red-Black Trees

```c
/* For augmented RB trees (with subtree info) */
#include <linux/rbtree_augmented.h>

struct my_aug_node {
    int key;
    unsigned int subtree_max;
    struct rb_node rb;
};

/* Define augmentation callbacks */
RB_DECLARE_CALLBACKS(static, my_aug_cb, struct my_aug_node, rb,
                     unsigned int, subtree_max, my_aug_compute_max);

static unsigned int my_aug_compute_max(struct my_aug_node *node)
{
    unsigned int max = node->key;

    if (node->rb.rb_left) {
        struct my_aug_node *left = rb_entry(node->rb.rb_left,
                                            struct my_aug_node, rb);
        if (left->subtree_max > max)
            max = left->subtree_max;
    }
    if (node->rb.rb_right) {
        struct my_aug_node *right = rb_entry(node->rb.rb_right,
                                             struct my_aug_node, rb);
        if (right->subtree_max > max)
            max = right->subtree_max;
    }
    return max;
}

/* Insert with augmentation */
void my_aug_insert(struct rb_root *root, struct my_aug_node *data)
{
    /* ... standard insertion ... */
    rb_link_node(&data->rb, parent, new);
    rb_insert_augmented(&data->rb, root, &my_aug_cb);
}
```

---

## 4. kref — Reference Counting

### Overview

`kref` provides a simple reference counting mechanism. When the reference count drops to zero, a release function is called to free the object.

### API

```c
#include <linux/kref.h>

struct my_object {
    struct kref refcount;
    /* ... other fields ... */
};

void my_object_release(struct kref *ref)
{
    struct my_object *obj = container_of(ref, struct my_object, refcount);
    /* Free resources */
    kfree(obj);
}

/* Initialize (count = 1) */
struct my_object *obj = kmalloc(sizeof(*obj), GFP_KERNEL);
kref_init(&obj->refcount);

/* Get reference (increment) */
kref_get(&obj->refcount);

/* Put reference (decrement, release if 0) */
kref_put(&obj->refcount, my_object_release);
```

### Usage Pattern

```c
/* Producer: create and share object */
struct my_object *create_object(void)
{
    struct my_object *obj = kmalloc(sizeof(*obj), GFP_KERNEL);
    if (!obj)
        return NULL;

    kref_init(&obj->refcount);  /* count = 1 */
    return obj;
}

/* Consumer: get reference */
void use_object(struct my_object *obj)
{
    kref_get(&obj->refcount);  /* count++ */
    /* Use object... */
}

/* Consumer: release reference */
void done_with_object(struct my_object *obj)
{
    kref_put(&obj->refcount, my_object_release);  /* count-- */
}
```

### Thread-Safe Reference Counting

```c
#include <linux/kref.h>

/* kref uses atomic operations internally, so it's thread-safe */

struct shared_resource {
    struct kref refcount;
    void *data;
    size_t size;
};

void release_resource(struct kref *ref)
{
    struct shared_resource *res =
        container_of(ref, struct shared_resource, refcount);
    kfree(res->data);
    kfree(res);
}

/* Thread A: create resource */
struct shared_resource *res = kmalloc(sizeof(*res), GFP_KERNEL);
res->data = kmalloc(4096, GFP_KERNEL);
res->size = 4096;
kref_init(&res->refcount);

/* Thread B: get reference */
kref_get(&res->refcount);

/* Thread A: release reference */
kref_put(&res->refcount, release_resource);

/* Thread B: release reference (frees resource) */
kref_put(&res->refcount, release_resource);
```

---

## 5. completion — Synchronization

### Overview

`completion` is a synchronization mechanism that allows one thread to wait for another thread to complete a task. It's lighter weight than using semaphores for this purpose.

### API

```c
#include <linux/completion.h>

/* Static initialization */
DECLARE_COMPLETION(my_completion);

/* Dynamic initialization */
struct completion comp;
init_completion(&comp);

/* Reinitialize (for reuse) */
reinit_completion(&comp);

/* Wait for completion */
wait_for_completion(&my_completion);

/* Wait with timeout (returns 0 on timeout, > 0 on success) */
unsigned long timeout = wait_for_completion_timeout(&my_completion, HZ * 5);

/* Wait, interruptible (returns -ERESTARTSYS if interrupted) */
int ret = wait_for_completion_interruptible(&my_completion);

/* Wait, interruptible with timeout */
long ret = wait_for_completion_interruptible_timeout(&my_completion, HZ * 5);

/* Wait, killable (returns -ERESTARTSYS if killed) */
int ret = wait_for_completion_killable(&my_completion);

/* Signal completion (wake one waiter) */
complete(&my_completion);

/* Signal completion (wake all waiters) */
complete_all(&my_completion);

/* Check if completed (without waiting) */
bool done = try_wait_for_completion(&my_completion);

/* Check if completion is done */
bool done = completion_done(&my_completion);
```

### Example: Producer-Consumer

```c
#include <linux/completion.h>
#include <linux/slab.h>
#include <linux/kthread.h>

DECLARE_COMPLETION(data_ready);
struct my_data *shared_data;

/* Producer thread */
int producer_thread(void *arg)
{
    struct my_data *data = kmalloc(sizeof(*data), GFP_KERNEL);
    data->value = 42;
    shared_data = data;

    /* Signal consumer */
    complete(&data_ready);
    return 0;
}

/* Consumer */
void consumer(void)
{
    /* Wait for producer */
    wait_for_completion(&data_ready);

    /* Use data */
    pr_info("Value: %d\n", shared_data->value);
    kfree(shared_data);
}
```

### Example: Device Initialization

```c
#include <linux/completion.h>

struct my_device {
    struct completion init_done;
    /* ... other fields ... */
};

/* Called from interrupt handler when device is ready */
void my_irq_handler(int irq, void *dev_id)
{
    struct my_device *dev = dev_id;
    complete(&dev->init_done);
}

/* Probe function */
int my_probe(struct platform_device *pdev)
{
    struct my_device *dev;
    int ret;

    dev = devm_kzalloc(&pdev->dev, sizeof(*dev), GFP_KERNEL);
    init_completion(&dev->init_done);

    ret = request_irq(dev->irq, my_irq_handler, 0, "my_dev", dev);
    if (ret)
        return ret;

    /* Start device initialization */
    my_start_init(dev);

    /* Wait for device to be ready (10 second timeout) */
    ret = wait_for_completion_timeout(&dev->init_done, HZ * 10);
    if (ret == 0) {
        pr_err("Device initialization timed out\n");
        free_irq(dev->irq, dev);
        return -ETIMEDOUT;
    }

    pr_info("Device initialized\n");
    return 0;
}
```

---

## 6. Comparison of Data Structures

| Structure | Insert | Delete | Lookup | Traversal | Best For |
|-----------|--------|--------|--------|-----------|----------|
| `list_head` | O(1) | O(1) | O(n) | O(n) | Small lists, ordered traversal |
| `hlist` | O(1) | O(1) | O(1)* | O(n) | Hash table buckets |
| `rb_root` | O(log n) | O(log n) | O(log n) | O(n) | Large sorted collections |
| `kref` | — | — | — | — | Reference counting |
| `completion` | — | — | — | — | Thread synchronization |

*O(1) average case with good hash function

---

*For complete API documentation, see the kernel source headers and `Documentation/` directory.*
