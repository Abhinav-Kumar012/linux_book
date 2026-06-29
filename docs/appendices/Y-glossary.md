# Appendix Y: Glossary

## Overview

This glossary defines over 500 terms used throughout the Linux ecosystem. Terms are listed alphabetically.

---

## A

**ABI (Application Binary Interface)** — The interface between an application and the operating system or between application components at the binary level. Defines calling conventions, data sizes, and binary format.

**ACL (Access Control List)** — A list of permissions attached to an object that specifies which users or system processes are granted access and what operations are allowed.

**Address Space** — The range of memory addresses available to a process. Each process has its own virtual address space.

**AF_UNIX** — Address family for UNIX domain sockets, used for inter-process communication on the same machine.

**AG (Allocation Group)** — In XFS, a subdivision of the filesystem that allows parallel allocation and I/O operations.

**Aggregate** — In ZFS, a collection of virtual devices (vdevs) that form a storage pool.

**AHCI (Advanced Host Controller Interface)** — A hardware mechanism that allows software to communicate with SATA devices.

**AIO (Asynchronous I/O)** — I/O operations that do not block the calling thread, allowing other work to proceed while I/O is in progress.

**Anon VMA (Anonymous Virtual Memory Area)** — A memory region that is not backed by a file, such as heap or stack memory.

**API (Application Programming Interface)** — A set of functions, protocols, and tools for building software applications.

**AppArmor** — A Linux security module that restricts program capabilities using per-program profiles.

**ARP (Address Resolution Protocol)** — A protocol for mapping IP addresses to MAC addresses on a local network.

**ASLR (Address Space Layout Randomization)** — A security technique that randomizes the memory addresses used by system and application code.

**Assembly** — A low-level programming language that corresponds closely to machine code instructions.

**ATA (Advanced Technology Attachment)** — A standard interface for connecting storage devices.

**Atomic Operation** — An operation that completes entirely or not at all, without intermediate states visible to other threads.

**Audit** — The systematic examination of system events and security-relevant activities.

**Autofs** — A program that automatically mounts filesystems on demand.

**AVX (Advanced Vector Extensions)** — SIMD extensions to the x86 instruction set for parallel data processing.

---

## B

**Backtrace** — A trace of the function calls that led to a particular point in a program's execution.

**BBR (Bottleneck Bandwidth and Round-trip propagation time)** — A TCP congestion control algorithm that models the network path.

**Bcache** — A Linux kernel block layer cache that allows SSDs to act as caching devices for HDDs.

**BCC (BPF Compiler Collection)** — A toolkit for creating efficient kernel tracing and manipulation programs using eBPF.

**BDFL (Benevolent Dictator For Life)** — A title given to a small number of open-source project leaders who have the final say in disputes.

**BER (Basic Encoding Rules)** — A format for encoding ASN.1 data structures.

**BFS (Breadth-First Search)** — A graph traversal algorithm that explores all neighbors at the current depth before moving to the next level.

**Big O Notation** — A mathematical notation describing the upper bound of an algorithm's time or space complexity.

**BIOS (Basic Input/Output System)** — Firmware used to perform hardware initialization during the booting process.

**Bitfield** — A data structure that allows individual bits to be addressed and manipulated.

**Block Device** — A device that transfers data in fixed-size blocks, such as hard drives and SSDs.

**Block Layer** — The kernel subsystem that handles block device I/O requests.

**Boot Loader** — Software that loads the operating system kernel into memory during boot.

**BPF (Berkeley Packet Filter)** — A technology for running sandboxed programs in the Linux kernel, originally for packet filtering.

**BRE (Basic Regular Expressions)** — A regular expression syntax defined by POSIX, using `\` for special characters.

**BSS (Block Started by Symbol)** — A section of an executable that contains uninitialized static variables.

**Buffer** — A region of memory used to temporarily hold data during transfer.

**Buffer Overflow** — A condition where a program writes data beyond the boundaries of allocated memory.

**Btrfs (B-tree Filesystem)** — A copy-on-write filesystem for Linux with snapshots, RAID, and checksumming.

**B-tree** — A self-balancing tree data structure that maintains sorted data and allows searches, insertions, and deletions in logarithmic time.

---

## C

**Cache** — A smaller, faster memory that stores copies of data from frequently used main memory locations.

**Cache Coherency** — The consistency of data stored in local caches of a shared resource.

**Call Stack** — A stack data structure that stores information about active subroutines of a program.

**Capability** — In Linux, a set of privileges that can be independently granted to processes.

**CFS (Completely Fair Scheduler)** — The default Linux process scheduler, designed to provide fair CPU time to all processes.

**CGI (Common Gateway Interface)** — A standard for web servers to execute external programs to generate web pages.

**cgroup (Control Group)** — A Linux kernel feature that limits, accounts for, and isolates resource usage of processes.

**Character Device** — A device that transfers data character by character, such as terminals and serial ports.

**CIDR (Classless Inter-Domain Routing)** — A method for allocating IP addresses and routing that replaces classful addressing.

**CISC (Complex Instruction Set Computing)** — A CPU design philosophy with many specialized instructions.

**Clone** — A system call that creates a new process with fine-grained control over what is shared with the parent.

**CNAME (Canonical Name)** — A DNS record that aliases one domain name to another.

**CO-RE (Compile Once - Run Everywhere)** — An eBPF feature that allows BPF programs compiled once to run on different kernel versions.

**Completion** — A kernel synchronization primitive that allows one thread to signal another that work is complete.

**Condition Variable** — A synchronization primitive that allows threads to wait until a particular condition is true.

**Container** — An isolated instance of a process or group of processes with its own view of system resources.

**Context Switch** — The process of saving and restoring the state of a CPU so that multiple processes can share a single CPU.

**COW (Copy-on-Write)** — A technique where data is shared until it is modified, at which point a private copy is made.

**CPAN (Comprehensive Perl Archive Network)** — A repository of Perl modules and scripts.

**CPU (Central Processing Unit)** — The primary component of a computer that performs most of the processing.

**CPU Affinity** — The binding of a process to a specific CPU or set of CPUs.

**crash** — A kernel crash dump analysis utility.

**Cron** — A time-based job scheduler in Unix-like operating systems.

**CSMA/CD (Carrier Sense Multiple Access with Collision Detection)** — A media access control method used in Ethernet.

**CWE (Common Weakness Enumeration)** — A list of software and hardware weakness types.

**Cyclomatic Complexity** — A software metric that measures the number of linearly independent paths through a program's source code.

---

## D

**Daemon** — A background process that runs without user interaction.

**DAX (Direct Access)** — A method for accessing files on persistent memory directly, bypassing the page cache.

**DDoS (Distributed Denial of Service)** — An attack that attempts to make a service unavailable by overwhelming it with traffic from multiple sources.

**Deadlock** — A situation where two or more processes are unable to proceed because each is waiting for the other to release a resource.

**Debug Symbol** — Information in a binary that maps machine code to source code lines and variable names.

**Device File** — A file in `/dev` that represents a hardware device or virtual device.

**Device Mapper** — A kernel framework for mapping block devices onto other block devices.

**DHCP (Dynamic Host Configuration Protocol)** — A protocol for automatically assigning IP addresses to devices on a network.

**DIME (Distributed Invocation Message Encoding)** — A protocol for web services.

**DMA (Direct Memory Access)** — A feature that allows hardware devices to access system memory directly, without CPU involvement.

**DMI (Desktop Management Interface)** — A standard for managing and tracking hardware components in a system.

**DNS (Domain Name System)** — A hierarchical naming system that translates domain names to IP addresses.

**Docker** — A platform for developing, shipping, and running applications in containers.

**DPC (Deferred Procedure Call)** — A Windows mechanism for deferring work from interrupt context. Linux equivalent: softirq/tasklet.

**DPDK (Data Plane Development Kit)** — A set of libraries and drivers for fast packet processing.

**DRAM (Dynamic Random-Access Memory)** — A type of volatile memory that stores each bit of data in a separate capacitor.

**DWARF** — A debugging file format used by most compilers and debuggers.

**Dynamic Linking** — Linking libraries at runtime rather than compile time, allowing shared code.

**Dynamic Loader** — The program that loads shared libraries into a process's address space at runtime.

---

## E

**EAGAIN** — An errno indicating a non-blocking operation would block; try again later.

**EBPF (Extended BPF)** — See eBPF.

**eBPF (extended Berkeley Packet Filter)** — A technology that allows running sandboxed programs in the Linux kernel without modifying kernel source.

**ECC (Error-Correcting Code)** — Memory that can detect and correct data corruption.

**EDAC (Error Detection And Correction)** — A Linux subsystem for detecting and reporting hardware memory errors.

**Edge Triggered** — In epoll, an event is reported only when the state changes, not when the state persists.

**EEPROM (Electrically Erasable Programmable Read-Only Memory)** — Non-volatile memory that can be erased and reprogrammed electrically.

**EEXIST** — An errno indicating a file already exists when exclusive creation was requested.

**EFI (Extensible Firmware Interface)** — See UEFI.

**EIP (Extended Instruction Pointer)** — The 32-bit instruction pointer register in x86 architecture.

**ELF (Executable and Linkable Format)** — The standard binary format for executables, object files, shared libraries, and core dumps on Linux.

**Embedded System** — A computer system with a dedicated function within a larger system.

**Ephemeral Port** — A temporary port number assigned by the OS for the client side of a network connection.

**Epoll** — A Linux API for scalable I/O event notification.

**ERRNO** — A global variable (or thread-local) that indicates the error code of the last failed system call.

**Error Injection** — A testing technique where errors are deliberately introduced to test error handling.

**ESRCH** — An errno indicating no such process was found.

**Ethernet** — A family of networking technologies for local area networks (LANs).

**Event Loop** — A programming construct that waits for and dispatches events or messages in a program.

**Executable** — A file that contains a program in a format the operating system can load and run.

**Exit Code** — A numeric value returned by a process to its parent upon termination.

**Ext4 (Fourth Extended Filesystem)** — The default filesystem for many Linux distributions.

---

## F

**FAQ (Frequently Asked Questions)** — A document listing common questions and answers.

**Fast Kernel Headers** — A project to speed up Linux kernel compilation by optimizing header file dependencies.

**FD (File Descriptor)** — An integer that uniquely identifies an open file or I/O resource in a process.

**FHS (Filesystem Hierarchy Standard)** — A standard defining the directory structure and directory contents in Linux systems.

**Fiber** — A lightweight thread managed by a user-space scheduler.

**FIFO (First In, First Out)** — A data structure where the first element added is the first to be removed. Also, a named pipe.

**Filesystem** — A method of organizing and storing data on a storage device.

**Firewall** — A network security system that monitors and controls incoming and outgoing network traffic.

**Firmware** — Software permanently programmed into a hardware device.

**Fork** — A system call that creates a new process by duplicating the calling process.

**FPU (Floating-Point Unit)** — A part of a CPU designed for operations on floating-point numbers.

**Framebuffer** — A portion of memory that holds a complete frame of data for display.

**Free Software** — Software that can be freely used, modified, and distributed.

**fsck (Filesystem Check)** — A utility for checking and repairing filesystem inconsistencies.

**ftrace** — A Linux kernel tracing framework for tracing kernel functions.

**FUSE (Filesystem in Userspace)** — A framework that allows implementing filesystems in user space.

**Futex (Fast Userspace Mutex)** — A kernel mechanism for implementing efficient synchronization primitives.

---

## G

**GCC (GNU Compiler Collection)** — A compiler system supporting various programming languages.

**GDB (GNU Debugger)** — The standard debugger for Linux.

**GDT (Global Descriptor Table)** — A data structure used by x86 processors to define memory segments.

**GFP (Get Free Pages)** — Flags used in kernel memory allocation to specify the type of memory requested.

**GID (Group Identifier)** — A numeric identifier for a group of users.

**Git** — A distributed version control system.

**GLIBC (GNU C Library)** — The C library used by most Linux systems.

**GNU (GNU's Not Unix)** — A free software project that provides many tools used in Linux.

**GOT (Global Offset Table)** — A table used in ELF files for position-independent access to global variables and functions.

**Governor** — In CPU frequency scaling, a policy that determines how the CPU frequency is adjusted.

**GPL (GNU General Public License)** — A free software license that guarantees end users the freedom to run, study, share, and modify the software.

**GRUB (GRand Unified Bootloader)** — A common boot loader for Linux systems.

**GSM (Global System for Mobile Communications)** — A standard for mobile communications.

**Guest OS** — An operating system running inside a virtual machine.

---

## H

**Handle** — An abstract reference to a resource, such as a file or network connection.

**Hard Link** — A directory entry that associates a name with an existing file on the same filesystem.

**Hardware Watchpoint** — A watchpoint implemented using CPU debug registers, faster than software watchpoints.

**Hash** — A fixed-size value computed from variable-size data, used for integrity checking and indexing.

**HBA (Host Bus Adapter)** — A hardware interface for connecting a host computer to storage devices.

**Header File** — A file containing declarations of functions, variables, and types, used in C/C++ compilation.

**Heap** — A region of memory used for dynamic allocation during program execution.

**Hertz (Hz)** — A unit of frequency, equal to one cycle per second.

**Huge Pages** — Large memory pages (typically 2MB or 1GB) that reduce TLB misses.

**Hypervisor** — Software that creates and runs virtual machines.

**Hyperthreading** — Intel's simultaneous multithreading (SMT) technology that allows multiple threads to run on each CPU core.

---

## I

**I/O (Input/Output)** — Communication between a computer and external devices or between components.

**I/O Scheduler** — A kernel component that determines the order of block device I/O operations.

**ICMP (Internet Control Message Protocol)** — A protocol used for diagnostic and error reporting in IP networks.

**IDT (Interrupt Descriptor Table)** — A data structure used by x86 processors to handle interrupts.

**IEEE (Institute of Electrical and Electronics Engineers)** — A professional association for electronic engineering and electrical engineering.

**InfiniBand** — A high-speed networking technology used in high-performance computing.

**init** — The first process started by the kernel during boot, the ancestor of all processes.

**Inode** — A data structure on a filesystem that stores metadata about a file or directory.

**Interrupt** — A signal to the processor indicating an event that needs immediate attention.

**Interrupt Handler** — A function that executes in response to an interrupt.

**ioctl (I/O Control)** — A system call for device-specific operations.

**IOMMU (I/O Memory Management Unit)** — Hardware that maps device-visible virtual addresses to physical addresses.

**io_uring** — A Linux interface for asynchronous I/O operations.

**IP (Internet Protocol)** — The principal protocol for relaying datagrams across network boundaries.

**IPC (Inter-Process Communication)** — Mechanisms for processes to communicate with each other.

**IRQ (Interrupt Request)** — A hardware signal that requests the processor's attention.

**ISA (Instruction Set Architecture)** — The abstract model of a computer that defines the set of instructions the CPU can execute.

**ISDN (Integrated Services Digital Network)** — A set of standards for digital transmission of voice and data.

---

## J

**Journal** — A log of filesystem changes used for crash recovery.

**Jiffies** — The smallest unit of time measurement in the Linux kernel, typically 1ms to 10ms.

**JIT (Just-In-Time Compilation)** — A compilation technique where code is compiled during execution rather than before.

**Jumbo Frame** — An Ethernet frame with more than 1500 bytes of payload.

---

## K

**KASAN (Kernel Address Sanitizer)** — A dynamic memory error detector for the Linux kernel.

**Kconfig** — The Linux kernel configuration system.

**Kdump** — A mechanism for capturing kernel crash dumps.

**Kernel** — The core component of an operating system that manages hardware and provides services to applications.

**Kernel Module** — A piece of code that can be loaded into the kernel at runtime.

**Kernel Space** — The memory region where the kernel executes, with full access to hardware.

**Kernel Thread** — A thread that runs in kernel space, used for background tasks.

**Kexec** — A mechanism for loading a new kernel from a running kernel without going through the BIOS.

**klist** — A kernel linked list implementation for hash table buckets.

**kobject** — The fundamental building block of the Linux device model.

**kprobe** — A kernel debugging mechanism for dynamically tracing kernel functions.

**kref** — A kernel reference counting mechanism.

**KSPP (Kernel Self-Protection Project)** — A project to harden the Linux kernel against security vulnerabilities.

**KVM (Kernel-based Virtual Machine)** — A Linux kernel module that provides hardware virtualization.

---

## L

**L1 Cache** — The first level of CPU cache, fastest and smallest.

**L2 Cache** — The second level of CPU cache, larger but slower than L1.

**L3 Cache** — The third level of CPU cache, shared among CPU cores.

**LACP (Link Aggregation Control Protocol)** — A protocol for bundling multiple network connections in parallel.

**Latency** — The time delay between a cause and its effect in a system.

**LBA (Logical Block Addressing)** — A method of addressing data on storage devices by linear block numbers.

**LCM (Last-Level Cache)** — The largest and slowest cache level before main memory.

**LDAP (Lightweight Directory Access Protocol)** — A protocol for accessing and maintaining distributed directory information services.

**Leak** — A resource that is allocated but never freed.

**Library** — A collection of pre-compiled code that can be reused by programs.

**Linker** — A program that combines object files into an executable or library.

**list_head** — The Linux kernel's intrusive doubly-linked list implementation.

**Livepatch** — A mechanism for applying kernel patches without rebooting.

**LLD** — The LLVM linker, a high-performance linker.

**Load Average** — A measure of the amount of computational work a system is performing.

**Load Balancing** — Distributing work across multiple computing resources.

**Lock** — A synchronization mechanism that prevents concurrent access to shared resources.

**Lockdep** — A kernel lock dependency validator.

**Log-Structured Filesystem** — A filesystem that writes data in a sequential log-like structure.

**Loopback** — A virtual network interface for local communication.

**LRU (Least Recently Used)** — A cache eviction policy that discards the least recently used items first.

**LSB (Linux Standard Base)** — A standard that increases compatibility among Linux distributions.

**LTO (Link-Time Optimization)** — Optimization performed during linking, allowing cross-module optimization.

**LUKS (Linux Unified Key Setup)** — A disk encryption specification for Linux.

**LVM (Logical Volume Manager)** — A device mapper framework for flexible disk management.

---

## M

**Machine Code** — The lowest-level representation of a program, directly executable by the CPU.

**Macro** — A rule that specifies how input is mapped to output during preprocessing.

**Makefile** — A file containing instructions for the `make` build tool.

**Malloc** — A C library function for dynamic memory allocation.

**Man Page** — A form of software documentation found on Unix-like systems.

**Map** — In eBPF, a data structure used for communication between BPF programs and user space.

**Mask** — A bit pattern used to select specific bits from a value.

**MAU (Medium Attachment Unit)** — A transceiver used in Ethernet networks.

**MD5** — A cryptographic hash function producing a 128-bit hash value.

**Memory Barrier** — A CPU instruction that enforces ordering of memory operations.

**Memory-Mapped I/O** — A method of performing I/O by mapping device registers into the address space.

**Memory-Mapped File** — A file mapped into virtual memory, allowing file I/O via memory access.

**MESI Protocol** — A cache coherency protocol with four states: Modified, Exclusive, Shared, Invalid.

**Metadata** — Data about data, such as file permissions, ownership, and timestamps.

**Microarchitecture** — The internal design of a CPU, implementing a particular ISA.

**Microkernel** — A kernel design where only essential services run in kernel space.

**MIME (Multipurpose Internet Mail Extensions)** — A standard for formatting non-ASCII messages.

**MIPS (Million Instructions Per Second)** — A measure of a computer's processing speed.

**mmap** — A system call that maps files or devices into memory.

**Module** — A piece of code that can be loaded into the kernel at runtime.

**Monolithic Kernel** — A kernel design where all OS services run in kernel space.

**Mount** — Making a filesystem accessible at a point in the directory tree.

**Mutex** — A synchronization primitive that provides mutual exclusion.

**MX Record** — A DNS record that specifies a mail server for a domain.

---

## N

**Name Space** — A kernel feature that partitions system resources so that one set of processes sees one set of resources while another set sees a different set.

**NAT (Network Address Translation)** — A method of remapping IP addresses by modifying packet headers.

**Netfilter** — A Linux kernel framework for packet filtering and network address translation.

**Network Namespace** — A namespace that provides isolated network stacks.

**NFS (Network File System)** — A protocol for accessing files over a network.

**Nice Value** — A value (-20 to 19) that affects process scheduling priority.

**NMI (Non-Maskable Interrupt)** — An interrupt that cannot be ignored by the CPU.

**Node** — In NUMA, a CPU and its directly attached memory.

**Non-Uniform Memory Access (NUMA)** — A memory design where memory access time depends on the memory location relative to the processor.

**No-op Scheduler** — The simplest I/O scheduler, performing no reordering.

**NPTL (Native POSIX Threads Library)** — The Linux implementation of POSIX threads.

**NSCD (Name Service Cache Daemon)** — A daemon that caches name service lookups.

**ntpd** — The Network Time Protocol daemon for synchronizing system clocks.

**NUMA Node** — A group of CPUs and their directly attached memory in a NUMA system.

---

## O

**Object File** — A file containing machine code and data, not yet linked into an executable.

**OOM (Out of Memory)** — A condition where the system runs out of available memory.

**OOM Killer** — A kernel mechanism that terminates processes when the system is critically low on memory.

**Open Source** — Software whose source code is freely available for modification and distribution.

**Operating System** — Software that manages computer hardware and provides services for application software.

**OverlayFS** — A union filesystem that combines multiple directories into a single view.

---

## P

**Page** — The smallest unit of memory management, typically 4KB.

**Page Cache** — A kernel cache of file data in memory.

**Page Fault** — An exception that occurs when a process accesses a virtual memory page not currently in physical memory.

**Page Table** — A data structure used by the virtual memory system to map virtual addresses to physical addresses.

**PAM (Pluggable Authentication Modules)** — A framework for system authentication.

**Panic** — A kernel condition where the system cannot continue safely.

**Partition** — A logical division of a storage device.

**PCI (Peripheral Component Interconnect)** — A standard for connecting peripheral devices to a computer.

**PCRE (Perl-Compatible Regular Expressions)** — A regex library offering features beyond POSIX regex.

**Performance Counter** — Hardware registers that count events like cache misses and branch mispredictions.

**Permalink** — A permanent URL to a specific piece of web content.

**PID (Process Identifier)** — A unique number assigned to each running process.

**PID Namespace** — A namespace that provides isolated process ID spaces.

**Pipe** — A mechanism for inter-process communication where the output of one process is the input of another.

**POSIX (Portable Operating System Interface)** — A family of standards for maintaining compatibility between operating systems.

**Preemption** — The act of temporarily interrupting a task to resume it later.

**Privilege Escalation** — Gaining higher privileges than originally granted.

**Process** — An instance of a program in execution.

**Process Group** — A collection of related processes.

**Protocol** — A set of rules governing data communication.

**PSW (Program Status Word)** — A register that contains the current state of the processor.

**PTE (Page Table Entry)** — An entry in a page table mapping a virtual page to a physical page.

**ptrace** — A system call for process tracing and debugging.

**Ptrace Scope** — A security setting controlling who can trace processes.

**PTS (Pseudo-Terminal Slave)** — The slave end of a pseudo-terminal pair.

**PTY (Pseudo-Terminal)** — A virtual terminal device used for terminal emulation.

---

## Q

**Quantum** — The time slice allocated to a process by the scheduler.

**Queue** — A data structure that follows the First In, First Out (FIFO) principle.

**QoS (Quality of Service)** — Mechanisms for controlling network traffic priority and bandwidth.

**Quota** — A limit on the amount of disk space or number of files a user or group can use.

---

## R

**RAID (Redundant Array of Independent Disks)** — A data storage virtualization technology that combines multiple physical disk drives.

**RARP (Reverse ARP)** — A protocol for obtaining an IP address from a MAC address.

**RB-Tree (Red-Black Tree)** — A self-balancing binary search tree used in the kernel for efficient lookups.

**RCU (Read-Copy-Update)** — A synchronization mechanism optimized for read-heavy workloads.

**Real-Time** — A system with guaranteed response times.

**Reentrant** — Code that can be safely executed by multiple threads simultaneously.

**Regular Expression** — A sequence of characters defining a search pattern.

**Relocatable File** — An object file containing code and data that can be linked with other object files.

**Request Queue** — A queue of I/O requests waiting to be processed by a block device.

**Resource Leak** — A failure to release a resource after it is no longer needed.

**Resume** — Continuing execution of a suspended process or thread.

**RISC (Reduced Instruction Set Computing)** — A CPU design philosophy with a small, highly optimized set of instructions.

**RIP (Routing Information Protocol)** — A distance-vector routing protocol.

**Rootkit** — Software designed to gain unauthorized access while hiding its presence.

**RPC (Remote Procedure Call)** — A protocol for executing procedures on a remote system.

**RR (Round Robin)** — A scheduling algorithm where each process gets a fair share of CPU time.

**RSS (Resident Set Size)** — The amount of memory occupied by a process in physical memory.

**runit** — A Unix init scheme with service supervision.

**Runlevel** — A mode of operation in SysVinit that defines which services are running.

**Runtime** — The period during which a program is executing.

---

## S

**SAN (Storage Area Network)** — A dedicated high-speed network for storage devices.

**SATA (Serial ATA)** — A computer bus interface for connecting storage devices.

**Scalability** — The ability of a system to handle increased load by adding resources.

**Scheduler** — A kernel component that determines which process runs next.

**SCSI (Small Computer System Interface)** — A set of standards for connecting and transferring data between computers and devices.

**SDK (Software Development Kit)** — A collection of software development tools.

**Secure Boot** — A boot security standard that ensures only trusted software is loaded during boot.

**Segmentation Fault** — An error caused by a process attempting to access memory it is not allowed to.

**SELinux (Security-Enhanced Linux)** — A Linux security module implementing mandatory access controls.

**Semaphore** — A synchronization primitive for controlling access to shared resources.

**Session** — A group of process groups, typically associated with a terminal.

**Shadow Password** — A system where encrypted passwords are stored in a separate file accessible only by root.

**Shared Library** — A library that can be loaded into multiple processes simultaneously.

**Shared Memory** — A method of inter-process communication where multiple processes access the same memory region.

**Shell** — A command-line interface for interacting with the operating system.

**Signal** — A notification sent to a process to notify it of an event.

**SLAB** — A kernel memory allocation mechanism.

**SLUB** — The default Linux kernel memory allocator, replacing SLAB.

**SMP (Symmetric Multiprocessing)** — A system architecture where multiple identical CPUs share memory.

**SNA (Systems Network Architecture)** — IBM's proprietary networking architecture.

**Socket** — An endpoint for network communication.

**Socket Buffer** — A kernel buffer for storing network data.

**SoftIRQ** — A kernel mechanism for deferring work from interrupt context.

**Spinlock** — A lock that causes the thread trying to acquire it to simply wait in a loop.

**Spurious Wakeup** — A condition where a thread wakes from a condition variable without the condition being true.

**SSE (Streaming SIMD Extensions)** — SIMD extensions to the x86 instruction set.

**SSD (Solid State Drive)** — A storage device using flash memory.

**Stack** — A data structure that follows Last In, First Out (LIFO). Also, the memory region used for function call frames.

**Stack Trace** — See backtrace.

**Static Linking** — Linking library code directly into the executable at compile time.

**strace** — A tool for tracing system calls and signals.

**Sticky Bit** — A permission bit that restricts file deletion in shared directories.

**Stripe** — In RAID, a segment of data spread across multiple disks.

**SUID (Set User ID)** — A permission bit that causes a program to run with the file owner's privileges.

**Superblock** — A data structure on a filesystem that contains metadata about the filesystem.

**SVC (Supervisor Call)** — A mechanism for requesting services from the operating system.

**Swap** — Disk space used as an extension of physical memory.

**Symbol** — A name associated with a function or variable in a compiled program.

**Symbol Table** — A data structure mapping symbol names to addresses.

**Synchronization** — The coordination of concurrent activities to ensure correct execution.

**Syscall** — A request from a user-space program to the kernel for a service.

**sysfs** — A virtual filesystem that exports kernel data structures.

**Syslog** — A standard for message logging.

**System Call** — See syscall.

---

## T

**Target** — In SCSI, a device that responds to commands from an initiator.

**Task** — In the Linux kernel, the basic unit of execution (process or thread).

**Tasklet** — A kernel mechanism for deferring work from interrupt context.

**TCP (Transmission Control Protocol)** — A connection-oriented protocol for reliable data delivery.

**Terminal** — A device for entering data into and displaying data from a computer.

**Thread** — A lightweight process that shares its address space with other threads in the same process.

**Thread-Local Storage (TLS)** — Storage that is unique to each thread.

**Throughput** — The amount of material processed in a given time period.

**Ticket Lock** — A fair lock implementation using ticket numbers.

**Timer** — A kernel mechanism for scheduling future events.

**TLB (Translation Lookaside Buffer)** — A cache that stores recent virtual-to-physical address translations.

**TMPFS** — A temporary filesystem that uses memory and swap.

**Token** — A sequence of characters representing a unit of data.

**Toolchain** — A set of programming tools used to create software.

**Tracepoint** — A static probe point in the kernel for tracing.

**Trap** — A synchronous interrupt caused by an exception.

**Tree** — A hierarchical data structure.

**TRIM** — A command that informs an SSD which blocks of data are no longer in use.

**TSC (Time Stamp Counter)** — A CPU register that counts clock cycles.

**TSS (Task State Segment)** — A structure on x86 that stores information about a task.

**TTY (Teletypewriter)** — A terminal device.

**Tunnel** — A network technique for encapsulating one protocol within another.

---

## U

**UDP (User Datagram Protocol)** — A connectionless protocol for sending datagrams.

**UEFI (Unified Extensible Firmware Interface)** — A specification for firmware that replaces BIOS.

**UID (User Identifier)** — A unique number assigned to each user.

**UML (User-Mode Linux)** — A virtual machine that runs Linux as a user-space process.

**Unmount** — Detaching a filesystem from the directory tree.

**Unprivileged User** — A user without root or administrative privileges.

**Uptime** — The amount of time a system has been running.

**User Space** — The memory region where application programs execute.

**UTF-8** — A variable-length character encoding for Unicode.

---

## V

**VFS (Virtual File System)** — An abstraction layer in the kernel that provides a uniform interface to different filesystems.

**Virtual Address** — An address in a process's virtual address space.

**Virtual Machine** — A software emulation of a physical computer.

**Virtual Memory** — A memory management technique that provides an idealized abstraction of storage.

**VLAN (Virtual LAN)** — A logical grouping of network devices that share the same broadcast domain.

**VM (Virtual Machine)** — See Virtual Machine.

**VMA (Virtual Memory Area)** — A contiguous range of virtual addresses in a process's address space.

**VMAP** — A kernel mechanism for mapping virtually contiguous memory.

**VNODE** — A data structure representing a file or directory in the VFS layer.

**VPN (Virtual Private Network)** — A technology for creating encrypted network connections over public networks.

**VRF (Virtual Routing and Forwarding)** — A technology for creating multiple routing tables on a single router.

**VDSO (Virtual Dynamic Shared Object)** — A shared library provided by the kernel for fast system calls.

**vsyscall** — An older mechanism for fast system calls, replaced by vDSO.

---

## W

**Wait Queue** — A kernel data structure for putting processes to sleep and waking them up.

**Watchdog** — A timer that detects and recovers from system malfunctions.

**Watchpoint** — A breakpoint triggered when a specific memory location is accessed.

**WC (Write-Combining)** — A memory write policy that combines multiple writes into a single transaction.

**Weak Symbol** — A symbol that can be overridden by a non-weak symbol with the same name.

**Workqueue** — A kernel mechanism for deferring work to a later time.

**Write-Back** — A cache write policy where writes are made to the cache and written to main memory later.

**Write-Through** — A cache write policy where writes are made to both the cache and main memory simultaneously.

---

## X

**XDP (eXpress Data Path)** — A high-performance programmable network data path in the Linux kernel.

**XFS** — A high-performance journaling filesystem originally from SGI.

**XID (Transaction ID)** — An identifier for a filesystem transaction.

**XSI (X/Open System Interfaces)** — An extension to POSIX defining additional interfaces.

---

## Y

**Yield** — A voluntary relinquishment of the CPU by a process to allow other processes to run.

---

## Z

**Zero-Copy** — A technique for moving data between contexts without copying it.

**ZFS (Zettabyte Filesystem)** — A combined filesystem and logical volume manager with data integrity features.

**Zombie Process** — A process that has completed execution but still has an entry in the process table.

**Zone** — In the kernel memory allocator, a pool of memory pages with specific characteristics.

**Zone File** — A DNS file containing mappings between domain names and IP addresses.

**zswap** — A kernel feature that provides a compressed write-back cache for swap pages.

**zram** — A block device that uses compressed RAM for swap or temporary storage.

---

*This glossary covers the most commonly encountered terms in Linux systems programming and administration.*
