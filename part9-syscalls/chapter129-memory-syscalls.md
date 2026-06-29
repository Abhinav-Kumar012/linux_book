# Chapter 129: Memory Syscalls

## 1. Introduction

Memory management syscalls control how processes allocate, protect, and manage their virtual address space. From the fundamental `brk`/`sbrk` to the versatile `mmap`, these syscalls are the foundation of every memory allocation in a Linux process. This chapter covers `mmap`, `munmap`, `brk`, `mprotect`, `mlock`/`mlockall`, `madvise`, and `mremap`.

---

## 2. mmap

### 2.1 Purpose

`mmap` maps files or devices into memory, or allocates anonymous memory. It's the most versatile memory syscall — used for file I/O, shared memory, memory allocation, and more.

### 2.2 Prototype

```c
#include <sys/mman.h>
void *mmap(void *addr, size_t length, int prot, int flags, int fd, off_t offset);
```

### 2.3 Arguments

- **`addr`**: Hint address (kernel may ignore). NULL lets the kernel choose.
- **`length`**: Length of mapping (rounded up to page size)
- **`prot`**: Memory protection flags

| Prot | Description |
|------|-------------|
| `PROT_NONE` | No access |
| `PROT_READ` | Read access |
| `PROT_WRITE` | Write access |
| `PROT_EXEC` | Execute access |

- **`flags`**: Mapping flags

| Flag | Description |
|------|-------------|
| `MAP_SHARED` | Share mapping (changes visible to other processes) |
| `MAP_PRIVATE` | Private mapping (COW on write) |
| `MAP_ANONYMOUS` | Anonymous memory (no file, fd ignored) |
| `MAP_FIXED` | Place at exact address (dangerous) |
| `MAP_FIXED_NOREPLACE` | Like FIXED but fails if address in use (Linux 4.17+) |
| `MAP_NORESERVE` | Don't reserve swap space |
| `MAP_POPULATE` | Prefault all pages |
| `MAP_LOCKED` | Lock pages in memory |
| `MAP_HUGETLB` | Use huge pages |
| `MAP_GROWSDOWN` | Stack-like growth |
| `MAP_SYNC` | DAX-aware persistent memory |

- **`fd`**: File descriptor (ignored for `MAP_ANONYMOUS`)
- **`offset`**: Offset into file (must be page-aligned)

### 2.4 Return Values

- **Success**: Pointer to mapped region
- **Failure**: `MAP_FAILED` ((void *)-1) with `errno` set

### 2.5 Error Codes

| Error | Description |
|-------|-------------|
| `EACCES` | File not opened with correct mode |
| `EAGAIN` | File locked or `MAP_NORESERVE` insufficient swap |
| `EBADF` | Bad file descriptor |
| `EINVAL` | Invalid arguments |
| `ENFILE` | System-wide file limit reached |
| `ENOMEM` | No memory available |
| `EOVERFLOW` | Offset + length exceeds file size (32-bit) |

### 2.6 Kernel Implementation

```c
SYSCALL_DEFINE6(mmap, unsigned long, addr, unsigned long, len,
                unsigned long, prot, unsigned long, flags,
                unsigned long, fd, unsigned long, off)
{
    struct file *file = NULL;
    
    if (!(flags & MAP_ANONYMOUS)) {
        file = fget(fd);
        if (!file) return -EBADF;
    }
    
    return ksys_mmap_pgoff(addr, len, prot, flags, file, off >> PAGE_SHIFT);
}
```

The kernel creates a `vm_area_struct` (VMA) representing the mapping, but doesn't immediately allocate physical pages. Pages are allocated on demand via page faults.

### 2.7 Anonymous Memory

```c
void *p = mmap(NULL, 4096, PROT_READ | PROT_WRITE,
               MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
if (p == MAP_FAILED) { perror("mmap"); return; }
// Use p[0] through p[4095]
munmap(p, 4096);
```

### 2.8 File Mapping

```c
int fd = open("data.bin", O_RDONLY);
void *p = mmap(NULL, file_size, PROT_READ, MAP_PRIVATE, fd, 0);
// Read data directly: p[0], p[1], ...
// Data is loaded on demand (page faults)
munmap(p, file_size);
close(fd);
```

### 2.9 Shared Memory Between Processes

```c
// Process A
void *shared = mmap(NULL, 4096, PROT_READ | PROT_WRITE,
                     MAP_SHARED | MAP_ANONYMOUS, -1, 0);
// After fork(), child shares this mapping
pid_t pid = fork();
if (pid == 0) {
    strcpy(shared, "Hello from child");
    _exit(0);
}
wait(NULL);
printf("Child wrote: %s\n", (char *)shared);
```

### 2.10 Performance

- **Anonymous mmap**: ~200-500 nanoseconds (just creates VMA)
- **File-backed mmap**: Creates VMA + maps page table entries. Actual I/O happens on page fault.
- **Page fault (major)**: 1-10 ms (disk I/O)
- **Page fault (minor)**: 1-10 μs (page cache hit)

---

## 3. munmap

### 3.1 Purpose

`munmap` removes a memory mapping.

### 3.2 Prototype

```c
int munmap(void *addr, size_t length);
```

### 3.3 Kernel Implementation

```c
SYSCALL_DEFINE2(munmap, unsigned long, addr, size_t, len)
{
    addr = untagged_addr(addr);
    profile_munmap(addr);
    return __vm_munmap(addr, len, true);
}
```

`munmap` removes VMAs, flushes TLB entries, and frees physical pages (for anonymous mappings). For file-backed mappings, dirty pages may be written back to disk.

### 3.4 Partial Unmap

`munmap` can partially unmap a region. The kernel splits VMAs as needed:

```c
// Before: [0x1000 - 0x5000] (4 pages)
munmap((void*)0x2000, 0x2000);  // Unmap middle 2 pages
// After: [0x1000 - 0x2000] [0x4000 - 0x5000]
```

---

## 4. brk / sbrk

### 4.1 Purpose

`brk` sets the program break (end of the data segment). `sbrk` increments it. These are the traditional Unix memory allocation mechanisms, but `mmap` is preferred for modern programs.

### 4.2 Prototype

```c
#include <unistd.h>
int brk(void *addr);
void *sbrk(intptr_t increment);
```

### 4.3 Kernel Implementation

```c
SYSCALL_DEFINE1(brk, unsigned long, brk)
{
    unsigned long retval;
    unsigned long newbrk, oldbrk;
    struct mm_struct *mm = current->mm;
    
    // Round up to page boundary
    newbrk = PAGE_ALIGN(brk);
    oldbrk = PAGE_ALIGN(mm->brk);
    
    if (newbrk == oldbrk) {
        mm->brk = brk;
        return brk;
    }
    
    if (newbrk > oldbrk) {
        // Expand: map new pages
        if (do_brk_flags(oldbrk, newbrk - oldbrk, 0) < 0)
            return mm->brk;
    } else {
        // Shrink: unmap pages
        munmap(newbrk, oldbrk - newbrk);
    }
    
    mm->brk = brk;
    return brk;
}
```

### 4.4 Modern Usage

glibc's `malloc` uses `mmap` for large allocations and `brk` for the initial small allocations. Direct use of `brk`/`sbrk` is discouraged.

---

## 5. mprotect

### 5.1 Purpose

`mprotect` changes the access protections on a memory region.

### 5.2 Prototype

```c
#include <sys/mman.h>
int mprotect(void *addr, size_t len, int prot);
```

### 5.3 Arguments

Same `prot` flags as `mmap`: `PROT_NONE`, `PROT_READ`, `PROT_WRITE`, `PROT_EXEC`.

### 5.4 Kernel Implementation

```c
SYSCALL_DEFINE3(mprotect, unsigned long, start, size_t, len, unsigned long, prot)
{
    return do_mprotect_pkey(start, len, prot, -1);
}
```

The kernel iterates through VMAs, updating page table permissions and flushing TLB entries.

### 5.5 Security Applications

```c
// Make code read-only after loading
mprotect(text_page, text_size, PROT_READ | PROT_EXEC);

// Make data non-executable (W^X)
mprotect(data_page, data_size, PROT_READ | PROT_WRITE);

// Guard page (detect stack overflow)
mprotect(guard_page, PAGE_SIZE, PROT_NONE);
```

### 5.6 Example: JIT Compilation

```c
void *code = mmap(NULL, PAGE_SIZE, PROT_READ | PROT_WRITE,
                  MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);

// Write machine code
memcpy(code, jit_code, jit_code_len);

// Make executable (but not writable — W^X)
mprotect(code, PAGE_SIZE, PROT_READ | PROT_EXEC);

// Execute
((void (*)(void))code)();
```

---

## 6. mlock / mlockall

### 6.1 Purpose

`mlock` locks specific pages in physical memory, preventing them from being swapped out. `mlockall` locks all pages of the process.

### 6.2 Prototype

```c
#include <sys/mman.h>
int mlock(const void *addr, size_t len);
int munlock(const void *addr, size_t len);
int mlockall(int flags);
int munlockall(void);
```

### 6.3 Flags (mlockall)

| Flag | Description |
|------|-------------|
| `MCL_CURRENT` | Lock all current mappings |
| `MCL_FUTURE` | Lock all future mappings |
| `MCL_ONFAULT` | Lock pages on page fault (Linux 4.4+) |

### 6.4 Use Cases

- **Real-time applications**: Prevent page faults during critical sections
- **Security**: Prevent sensitive data (passwords, keys) from being swapped to disk
- **High-frequency trading**: Eliminate swap-related latency spikes

### 6.5 Kernel Implementation

```c
SYSCALL_DEFINE2(mlock, unsigned long, start, size_t, len)
{
    return do_mlock(start, len, VM_LOCKED);
}
```

### 6.6 Privilege Requirements

- `mlock` requires `CAP_IPC_LOCK` or the `RLIMIT_MEMLOCK` resource limit to be sufficient
- Unprivileged users can lock up to `RLIMIT_MEMLOCK` bytes (default 64KB on most systems)

---

## 7. madvise

### 7.1 Purpose

`madvise` gives the kernel hints about how memory will be used, allowing optimizations.

### 7.2 Prototype

```c
#include <sys/mman.h>
int madvise(void *addr, size_t length, int advice);
```

### 7.3 Advice Values

| Advice | Description |
|--------|-------------|
| `MADV_NORMAL` | Default behavior |
| `MADV_RANDOM` | Random access pattern (disable readahead) |
| `MADV_SEQUENTIAL` | Sequential access (aggressive readahead) |
| `MADV_WILLNEED` | Pages will be needed soon (prefault) |
| `MADV_DONTNEED` | Pages won't be needed (free them) |
| `MADV_FREE` | Mark pages as lazy free (Linux 4.5+) |
| `MADV_HUGEPAGE` | Enable transparent huge pages |
| `MADV_NOHUGEPAGE` | Disable transparent huge pages |
| `MADV_DONTDUMP` | Exclude from core dump |
| `MADV_DODUMP` | Include in core dump |
| `MADV_MERGEABLE` | Enable KSM (Kernel Same-page Merging) |
| `MADV_UNMERGEABLE` | Disable KSM |
| `MADV_HWPOISON` | Poison a page (testing) |
| `MADV_COLD` | Mark pages as cold (Linux 5.4+) |
| `MADV_PAGEOUT` | Swap out pages (Linux 5.4+) |

### 7.4 Key Operations

**Prefaulting:**
```c
madvise(addr, len, MADV_WILLNEED);
// Kernel starts reading pages into memory
// Next access will be a minor fault (fast)
```

**Releasing memory:**
```c
madvise(addr, len, MADV_DONTNEED);
// Pages are freed. Next access will zero-fill.
// For anonymous mappings, data is lost!
```

**`MADV_FREE` vs `MADV_DONTNEED`:**
- `MADV_FREE`: Marks pages as "lazy free" — they're retained until memory pressure, then freed. Data is preserved if no memory pressure.
- `MADV_DONTNEED`: Immediately frees pages. Data is lost.

### 7.5 Kernel Implementation

```c
SYSCALL_DEFINE3(madvise, unsigned long, start, size_t, len_in, int, behavior)
{
    return do_madvise(current->mm, start, len_in, behavior);
}
```

---

## 8. mremap

### 8.1 Purpose

`mremap` resizes or moves an existing mapping.

### 8.2 Prototype

```c
#include <sys/mman.h>
void *mremap(void *old_address, size_t old_size, size_t new_size,
             int flags, ... /* void *new_address */);
```

### 8.3 Flags

| Flag | Description |
|------|-------------|
| `MREMAP_MAYMOVE` | Allow kernel to move the mapping |
| `MREMAP_FIXED` | Move to specific address (Linux 5.7+) |
| `MREMAP_DONTUNMAP` | Don't unmap old mapping (Linux 5.7+) |

### 8.4 Example

```c
void *p = mmap(NULL, 4096, PROT_READ | PROT_WRITE,
               MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);

// Grow to 8192 bytes
p = mremap(p, 4096, 8192, MREMAP_MAYMOVE);
if (p == MAP_FAILED) { perror("mremap"); }
```

### 8.5 Kernel Implementation

```c
SYSCALL_DEFINE5(mremap, unsigned long, addr, unsigned long, old_len,
                unsigned long, new_len, unsigned long, flags,
                unsigned long, new_addr)
{
    // If new_len > old_len and MREMAP_MAYMOVE:
    //   Try to extend in place
    //   If not possible, allocate new region, copy, unmap old
    // If shrinking:
    //   Unmap the excess pages
}
```

---

## 9. Performance Considerations

| Operation | Typical Cost |
|-----------|-------------|
| `mmap` (anonymous) | ~200-500 ns |
| `mmap` (file-backed) | ~500 ns - 2 μs |
| `munmap` (1 page) | ~200-500 ns |
| `mprotect` | ~200-500 ns per page |
| `madvise(MADV_DONTNEED)` | ~100-300 ns per page |
| Minor page fault | ~1-10 μs |
| Major page fault | ~1-10 ms |

---

## 10. Security Implications

- **`mmap` with `PROT_EXEC`**: Executable memory is dangerous. Use `PROT_READ | PROT_WRITE` for data, `PROT_READ | PROT_EXEC` for code.
- **W^X policy**: Never have memory both writable and executable simultaneously (prevents code injection).
- **`madvise(MADV_DONTNEED)` on shared mappings**: Can cause data loss. Always verify mapping is private.
- **`mlock` and resource limits**: Prevents memory exhaustion attacks but can be used for DoS.
- **`MAP_FIXED` overwriting**: Can corrupt existing mappings. Use `MAP_FIXED_NOREPLACE` instead.

---

## 11. Common Bugs

```c
// BUG: Not checking mmap return value
void *p = mmap(NULL, len, PROT_READ, MAP_PRIVATE, fd, 0);
p[0] = 'x';  // SIGSEGV if mmap failed!

// FIX: Check for MAP_FAILED
if (p == MAP_FAILED) { perror("mmap"); return; }

// BUG: Forgetting page alignment for mprotect
mprotect((void*)0x12345, 4096, PROT_READ);  // EINVAL — not page-aligned!
// FIX: Use page-aligned addresses
mprotect((void*)(addr & ~(PAGE_SIZE-1)), 4096, PROT_READ);

// BUG: Using MADV_DONTNEED on MAP_SHARED file mapping
madvise(shared_mapping, len, MADV_DONTNEED);  // Writes dirty pages to disk, frees them
// Might not be what you intended!
```

---

## 12. Kernel Source References

- **`mmap`/`munmap`**: `mm/mmap.c`
- **`brk`**: `mm/mmap.c`
- **`mprotect`**: `mm/mprotect.c`
- **`mlock`/`mlockall`**: `mm/mlock.c`
- **`madvise`**: `mm/madvise.c`
- **`mremap`**: `mm/mremap.c`
- **Page fault handler**: `mm/memory.c`
- **VMA management**: `include/linux/mm_types.h`

---

## 13. Summary

Memory syscalls control the fundamental resource of virtual memory:
- **`mmap`**: Map files or allocate anonymous memory (the Swiss army knife)
- **`munmap`**: Remove mappings
- **`brk`**: Legacy heap management (prefer `mmap`)
- **`mprotect`**: Change page permissions
- **`mlock`/`mlockall`**: Lock pages in physical memory
- **`madvise`**: Give the kernel hints about memory usage
- **`mremap`**: Resize or move mappings

---

## 14. Detailed Memory Management Internals

### 14.1 Virtual Memory Areas (VMAs)

Each memory mapping is represented by a VMA:

```c
struct vm_area_struct {
    unsigned long vm_start;     // Start address
    unsigned long vm_end;       // End address
    struct mm_struct *vm_mm;    // Address space
    pgprot_t vm_page_prot;      // Page protections
    unsigned long vm_flags;     // VM_READ, VM_WRITE, VM_EXEC, etc.
    
    struct rb_node vm_rb;       // Red-black tree node
    union {
        struct { struct vm_area_struct *next, *prev; } linked_list;
        struct rb_node rb;
    } shared;
    
    struct list_head anon_vma_chain;
    struct anon_vma *anon_vma;
    
    const struct vm_operations_struct *vm_ops;  // Operations
    unsigned long vm_pgoff;     // File offset (in pages)
    struct file *vm_file;       // File mapping (NULL for anonymous)
    void *vm_private_data;
    // ...
};
```

VMAs are stored in a red-black tree for O(log n) lookup by address. The kernel also maintains a linked list for iterating all VMAs.

### 14.2 Page Table Structure (x86-64)

x86-64 uses 4-level page tables (or 5-level with LA57):

```c
// 4-level page table hierarchy:
// PGD (Page Global Directory) → PUD → PMD → PTE → Page
//
// Each level has 512 entries (9 bits each)
// 48-bit virtual address space:
//   Bits 47-39: PGD index (9 bits)
//   Bits 38-30: PUD index (9 bits)
//   Bits 29-21: PMD index (9 bits)
//   Bits 20-12: PTE index (9 bits)
//   Bits 11-0:  Page offset (12 bits)

typedef struct { unsigned long pgd; } pgd_t;
typedef struct { unsigned long p4d; } p4d_t;
typedef struct { unsigned long pud; } pud_t;
typedef struct { unsigned long pmd; } pmd_t;
typedef struct { unsigned long pte; } pte_t;
```

### 14.3 Page Fault Handler

When a page fault occurs, the kernel's page fault handler is invoked:

```c
// arch/x86/mm/fault.c
void do_user_addr_fault(struct pt_regs *regs, unsigned long error_code, unsigned long address)
{
    struct mm_struct *mm;
    struct vm_area_struct *vma;
    
    mm = current->mm;
    
    // Find the VMA containing the faulting address
    vma = find_vma(mm, address);
    
    if (!vma || address < vma->vm_start) {
        // No VMA → SIGSEGV
        __bad_area_nosemaphore(regs, error_code, address);
        return;
    }
    
    // Check permissions
    if (error_code & X86_PF_WRITE) {
        if (!(vma->vm_flags & VM_WRITE)) {
            __bad_area_nosemaphore(regs, error_code, address);
            return;
        }
    }
    
    // Handle the fault
    handle_mm_fault(vma, address, flags, regs);
}
```

### 14.4 Types of Page Faults

| Type | Cause | Handler | Cost |
|------|-------|---------|------|
| Minor (anonymous) | First access to anonymous page | `do_anonymous_page()` | ~1-5 μs |
| Minor (file, cached) | First access to file page in page cache | `do_read_fault()` | ~1-10 μs |
| Major (file, not cached) | First access to file page not in cache | `do_read_fault()` + disk I/O | ~1-10 ms |
| Minor (COW) | Write to shared page | `do_wp_page()` | ~1-5 μs |
| Minor (swap) | Access to swapped-out page in swap cache | `do_swap_page()` | ~1-10 μs |
| Major (swap) | Access to swapped-out page not in cache | `do_swap_page()` + disk I/O | ~1-10 ms |

### 14.5 Copy-on-Write (COW) in Detail

When `fork()` creates a child, the kernel marks all writable pages as read-only in both parent and child:

```c
static vm_fault_t do_wp_page(struct vm_fault *vmf)
{
    struct page *old_page = vmf->page;
    
    // If the page is shared (multiple references), copy it
    if (page_count(old_page) > 1) {
        // Allocate a new page
        struct page *new_page = alloc_page_vma(GFP_HIGHUSER_MOVABLE, vma, address);
        
        // Copy data
        copy_user_highpage(new_page, old_page, address, vma);
        
        // Update page table to point to new page
        wp_page_reuse(vmf, new_page, old_page);
    } else {
        // Page has only one reference — reuse it (just change permissions)
        wp_page_reuse(vmf, old_page, NULL);
    }
}
```

### 14.6 Page Cache

The page cache stores file data in memory:

```c
struct address_space {
    struct inode *host;              // Owning inode
    struct radix_tree_root i_pages;  // Page tree (by file offset)
    gfp_t gfp_mask;
    atomic_t i_mmap_writable;
    struct rb_root i_mmap;           // mmap'd pages
    unsigned long nrpages;           // Total pages
    unsigned long nrexceptional;     // Non-present entries (DAX, etc.)
    // ...
};
```

**Page cache operations:**
- **Read**: Check page cache first. If miss, read from disk and cache.
- **Write**: Write to page cache, mark page dirty. Writeback flushes to disk.
- **Reclaim**: Under memory pressure, clean pages are freed. Dirty pages are written back first.

### 14.7 Memory Reclaim

The kernel's memory reclaim system frees pages when memory is low:

```c
// kswapd: Background reclaim daemon
// Runs when free memory falls below watermark_low
// Frees pages until free memory reaches watermark_high

// Direct reclaim: Called synchronously when allocation fails
// More expensive — blocks the allocating process
```

**Reclaim priority:**
1. Free slab cache (dentry, inode caches)
2. Clean page cache pages
3. Dirty page cache pages (write back first)
4. Anonymous pages (swap out)

### 14.8 Transparent Huge Pages (THP)

THP automatically uses 2MB pages when possible:

```c
// Kernel automatically promotes contiguous small pages to huge pages
// and splits huge pages when needed

// madvise hints for THP:
madvise(addr, len, MADV_HUGEPAGE);    // Enable THP for region
madvise(addr, len, MADV_NOHUGEPAGE);  // Disable THP for region

// System-wide control:
// /sys/kernel/mm/transparent_hugepage/enabled
// Values: always, madvise, never
```

### 14.9 Memory Compaction

When memory is fragmented, the kernel compacts it to create contiguous free regions:

```c
// Compaction moves movable pages to create contiguous free blocks
// Used for THP allocation and huge page allocation
// Can be triggered manually:
// echo 1 > /proc/sys/vm/compact_memory
```

### 14.10 OOM Killer

When the system is completely out of memory, the OOM killer selects and kills a process:

```c
// OOM score calculation:
// score = process RSS + swap usage
// Adjusted by /proc/[pid]/oom_score_adj (-1000 to 1000)

// OOM score:
cat /proc/[pid]/oom_score

// Adjust OOM priority:
echo -500 > /proc/[pid]/oom_score_adj  // Less likely to be killed
echo 1000 > /proc/[pid]/oom_score_adj  // More likely to be killed
echo -1000 > /proc/[pid]/oom_score_adj // Never kill (disable OOM for this process)
```

### 14.11 Memory Cgroups

Cgroups v2 provide memory accounting and limits:

```bash
# Set memory limit
echo 1G > /sys/fs/cgroup/mygroup/memory.max

# Set memory soft limit
echo 768M > /sys/fs/cgroup/mygroup/memory.high

# Current usage
cat /sys/fs/cgroup/mygroup/memory.current

# OOM events
cat /sys/fs/cgroup/mygroup/memory.events
```

When a cgroup exceeds its limit, the kernel invokes the cgroup OOM killer (or throttles at the soft limit).
