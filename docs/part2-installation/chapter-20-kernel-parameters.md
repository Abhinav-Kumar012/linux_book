# Chapter 20: Kernel Parameters

## 20.1 Introduction

Kernel parameters (also called kernel command-line arguments or boot parameters) are settings passed to the Linux kernel at boot time that control its behavior. They can specify the root filesystem, enable debug logging, disable hardware features, configure security policies, and tune performance—before the operating system fully initializes.

Beyond boot-time parameters, the kernel exposes a vast runtime tunable interface through `/proc` and `/sys` filesystems, managed by the `sysctl` command. Understanding both boot-time and runtime kernel parameters is essential for system tuning, debugging, and security hardening.

## 20.2 Intuition: Two Layers of Control

Think of kernel parameters as two control panels:

1. **Boot parameters** — Set before the kernel starts, immutable without reboot. Control fundamental behavior: which root device, which console, which security policy.

2. **Runtime tunables** — Changeable while the system runs via `sysctl` or direct `/proc`/`/sys` writes. Control behavior: network stack tuning, memory management, security settings.

```mermaid
graph TD
    A[Power On] --> B[Bootloader: GRUB/systemd-boot]
    B --> C[Kernel Command Line]
    C --> D[Kernel parses parameters]
    D --> E[Kernel initializes]
    E --> F[Runtime tunables available]
    F --> G[sysctl -w or /proc/sys/ writes]
    F --> H[/etc/sysctl.conf persistence]
    G --> I[Effect: immediate]
    H --> J[Effect: on next boot]
```

## 20.3 Kernel Command-Line Parameters

### 20.3.1 Parameter Format

```bash
# General format:
kernel_image parameter1 parameter2 option=value ...

# Example GRUB linux line:
linux /vmlinuz-6.8.0 root=UUID=abc123 ro quiet splash console=ttyS0,115200 apparmor=1
```

**Parameter types:**
- **Boolean flags**: `quiet`, `ro`, `noapic` — presence enables the feature
- **Key=value**: `root=UUID=abc123`, `console=ttyS0` — assigns a value
- **Negation**: `noapic`, `nolapic`, `nopat` — disables a feature

### 20.3.2 Parameter Categories

```mermaid
graph LR
    subgraph Categories["Kernel Parameter Categories"]
        A[Storage & Filesystem]
        B[Memory & CPU]
        C[Networking]
        D[Security]
        E[Debug & Tracing]
        F[Hardware Control]
        G[Process & Init]
        H[Console & Display]
    end
```

### 20.3.3 Storage and Filesystem Parameters

```bash
# Root filesystem
root=UUID=xxxx-xxxx          # Root device (UUID recommended)
root=/dev/sda2               # Root device (by name, less reliable)
rootflags=subvol=@           # Root filesystem mount options (Btrfs)
ro                            # Mount root read-only initially
rw                            # Mount root read-write

# Filesystem-specific
rootfstype=ext4              # Root filesystem type (usually auto-detected)
rootdelay=10                  # Wait for root device (seconds)

# LVM
lvmwait=1                    # Wait for LVM activation

# LUKS
cryptdevice=UUID=xxxx:cryptroot  # LUKS device mapping

# I/O scheduler
elevator=mq-deadline         # I/O scheduler (legacy, now per-device)
```

### 20.3.4 Memory Parameters

```bash
# Memory limits
mem=512M                     # Limit visible memory
mem=2G                       # Useful for testing with limited memory

# NUMA
numa=off                     # Disable NUMA balancing
numa=fake=2                  # Fake NUMA nodes for testing

# Huge pages
hugepages=1024               # Reserve 1024 huge pages (2MB each)
hugepagesz=1G                # Use 1GB huge pages
transparent_hugepage=always  # THP policy (always/madvise/never)

# Swap
resume=UUID=swap-uuid        # Hibernation resume device
resume_offset=123456         # Resume offset for swap file

# Kernel memory
vmalloc=256M                 # Minimum vmalloc area size
```

### 20.3.5 CPU Parameters

```bash
# CPU control
maxcpus=4                    # Limit number of CPUs
nr_cpus=8                    # Maximum number of CPUs
isolcpus=2-7                 # Isolate CPUs from scheduler (for real-time)
nohz_full=2-7                # Tickless mode for specified CPUs
rcu_nocbs=2-7                # Offload RCU callbacks

# CPU features
nosmp                        # Disable SMP
noht                         # Disable hyperthreading
mce=off                      # Disable machine check exceptions
processor.max_cstate=1       # Limit C-states (latency-sensitive)
idle=poll                    # Busy-wait in idle (lowest latency)

# Performance
mitigations=off              # Disable all CPU vulnerability mitigations
                            # (security risk! Only for benchmarking)
```

### 20.3.6 Security Parameters

```bash
# SELinux
enforcing=1                  # SELinux enforcing mode
enforcing=0                  # SELinux permissive mode
selinux=0                    # Disable SELinux entirely

# AppArmor
apparmor=1                   # Enable AppArmor
apparmor=0                   # Disable AppArmor

# Module loading
module.sig_enforce=1         # Require signed modules
module_blacklist=mod1,mod2   # Blacklist kernel modules

# Kernel lockdown
lockdown=confidentiality     # Kernel lockdown mode
                            # (integrity|confidentiality)

# Address space layout
kaslr                         # Kernel ASLR (default enabled)
nokaslr                       # Disable kernel ASLR

# Security features
pti=on                       # Kernel page table isolation (Meltdown mitigation)
spec_store_bypass_disable=on # Spectre v4 mitigation
```

### 20.3.7 Debug and Tracing Parameters

```bash
# Boot debugging
debug                        # Enable kernel debug messages
initcall_debug               # Debug initcall execution
loglevel=7                   # Console log level (0=emerg, 7=debug)
ignore_loglevel              # Print all messages regardless of level

# Breakpoints
break=premount               # Shell before mounting root
break=postmount              # Shell after mounting root
break=init                   # Shell before executing init

# Crash dumps
crashkernel=256M             # Reserve memory for kdump

# Tracing
ftrace=function              # Enable function tracer
trace_event=sched_switch     # Trace specific events

# Panic behavior
panic=60                     # Reboot after 60 seconds on panic
panic=0                      # Immediate reboot on panic (no wait)
oops=panic                   # Treat oops as panic
```

### 20.3.8 Console and Display Parameters

```bash
# Serial console
console=ttyS0,115200         # Serial port, baud rate
console=tty0                 # VGA console
console=ttyS0,115200n8       # 8-bit, no parity

# Multiple consoles (output to all)
console=tty0 console=ttyS0,115200

# Graphics
nomodeset                    # Disable kernel mode setting
video=1920x1080             # Set framebuffer resolution
vga=0x31A                    # VESA framebuffer mode
video=efifb                  # Use EFI framebuffer
```

### 20.3.9 Networking Parameters

```bash
# Network configuration
ip=dhcp                      # DHCP for all interfaces
ip=192.168.1.100::192.168.1.1:255.255.255.0:server01:eth0:off
                             # Static IP configuration
nameserver=8.8.8.8           # DNS server

# Network debugging
net.ifnames=0                # Disable predictable network names (use eth0)
biosdevname=0                # Disable BIOS device naming
```

### 20.3.10 Hardware-Specific Parameters

```bash
# ACPI
acpi=off                     # Disable ACPI
acpi_osi="Windows 2012"      # Lie about OS to firmware
acpi_enforce_resources=lax   # Allow access to ACPI resources

# PCI
pci=noacpi                   # Disable ACPI for PCI
pci=nomsi                    # Disable MSI (Message Signaled Interrupts)
pci=nommconf                 # Disable MMCONFIG

# USB
nousb                        # Disable USB support
usb-storage.quirks=xxxx:xxxx:u  # USB storage quirks

# Disk
libata.dma=1                 # Enable DMA for ATA devices
libata.force=1.00:3.0Gb/s   # Force link speed
```

## 20.4 Runtime Kernel Parameters (sysctl)

### 20.4.1 sysctl Overview

`sysctl` reads and writes kernel parameters at runtime through the `/proc/sys/` virtual filesystem:

```bash
# Read a parameter
sysctl net.ipv4.ip_forward
# net.ipv4.ip_forward = 0

# Read via /proc
cat /proc/sys/net/ipv4/ip_forward
# 0

# Write a parameter (runtime)
sudo sysctl -w net.ipv4.ip_forward=1
# net.ipv4.ip_forward = 1

# Write via /proc
echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward

# List all parameters
sysctl -a
```

### 20.4.2 sysctl Configuration Files

```bash
# Load order:
# 1. /etc/sysctl.d/*.conf (alphabetical order)
# 2. /etc/sysctl.conf (legacy, loaded last)
# 3. /run/sysctl.d/*.conf (runtime overrides)

# Apply all settings
sudo sysctl --system

# Apply specific file
sudo sysctl -p /etc/sysctl.d/99-custom.conf
```

### 20.4.3 Network Tuning Parameters

```bash
# /etc/sysctl.d/99-network-tuning.conf

# IP forwarding (for routers/gateways)
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1

# TCP buffer sizes (min, default, max)
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216

# Connection backlog
net.core.somaxconn = 65535
net.core.netdev_max_backlog = 65536
net.ipv4.tcp_max_syn_backlog = 65536

# TCP keepalive
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_intvl = 30
net.ipv4.tcp_keepalive_probes = 5

# TCP fast reuse
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 15

# Congestion control
net.ipv4.tcp_congestion_control = bbr
net.core.default_qdisc = fq

# SYN flood protection
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_tw_buckets = 2000000

# Neighbor table (ARP)
net.ipv4.neigh.default.gc_thresh1 = 4096
net.ipv4.neigh.default.gc_thresh2 = 8192
net.ipv4.neigh.default.gc_thresh3 = 16384
```

### 20.4.4 Memory Management Parameters

```bash
# /etc/sysctl.d/99-memory.conf

# Swappiness (0-200, lower = less swap usage)
vm.swappiness = 10

# Dirty page management
vm.dirty_ratio = 20                    # % of RAM before forced writeback
vm.dirty_background_ratio = 5          # % of RAM before background writeback
vm.dirty_expire_centisecs = 3000       # Dirty page expiration (30s)
vm.dirty_writeback_centisecs = 500     # Writeback interval (5s)

# OOM killer
vm.panic_on_oom = 0                    # Don't panic on OOM (use OOM killer)
vm.overcommit_memory = 0               # Heuristic overcommit (default)
# 0 = heuristic, 1 = always, 2 = never (strict)

vm.overcommit_ratio = 50               # % of RAM for overcommit (mode 2)

# Memory compaction
vm.compaction_proactiveness = 20       # Proactive compaction aggressiveness

# Huge pages
vm.nr_hugepages = 0                    # Number of reserved huge pages
vm.hugetlb_shm_group = 0               # Group allowed to use huge pages
```

### 20.4.5 Filesystem Parameters

```bash
# /etc/sysctl.d/99-filesystem.conf

# Maximum number of open files (system-wide)
fs.file-max = 2097152

# Maximum number of inotify instances
fs.inotify.max_user_instances = 8192
fs.inotify.max_user_watches = 524288
fs.inotify.max_queued_events = 65536

# Maximum number of AIO requests
fs.aio-max-nr = 1048576

# Pipe buffer size
fs.pipe-max-size = 1048576

# Protected hardlinks/symlinks (security)
fs.protected_hardlinks = 1
fs.protected_symlinks = 1
fs.protected_fifos = 2
fs.protected_regular = 2

# PID max
kernel.pid_max = 4194304

# Threads max
kernel.threads-max = 4194304
```

### 20.4.6 Security Parameters

```bash
# /etc/sysctl.d/99-security.conf

# Disable IP forwarding (unless routing)
net.ipv4.ip_forward = 0
net.ipv6.conf.all.forwarding = 0

# Disable source routing
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0

# Disable ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv6.conf.all.accept_redirects = 0

# Enable reverse path filtering
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# Log Martian packets
net.ipv4.conf.all.log_martians = 1

# Ignore ICMP broadcasts
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1

# Disable IPv6 (if not needed)
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1

# Kernel hardening
kernel.dmesg_restrict = 1              # Restrict dmesg access
kernel.kptr_restrict = 2               # Hide kernel pointers
kernel.yama.ptrace_scope = 2           # Restrict ptrace
kernel.unprivileged_bpf_disabled = 1   # Disable unprivileged BPF
```

### 20.4.7 Performance Tuning Parameters

```bash
# /etc/sysctl.d/99-performance.conf

# Scheduler
kernel.sched_migration_cost_ns = 5000000    # 5ms migration cost
kernel.sched_autogroup_enabled = 0           # Disable autogroup for servers

# Timer resolution
kernel.timer_migration = 0                   # Disable timer migration

# Memory
vm.zone_reclaim_mode = 0                     # Disable zone reclaim (NUMA)
vm.min_free_kbytes = 262144                  # Minimum free memory (256MB)

# Huge pages for databases
vm.nr_hugepages = 1024                       # Reserve 2GB of huge pages
vm.hugetlb_shm_group = 1001                  # Group for PostgreSQL
```

## 20.5 Advanced sysctl Topics

### 20.5.1 Namespaced Parameters

Some sysctl parameters are per-network-namespace:

```bash
# View all net sysctls
sysctl -a | grep net.ipv4

# Parameters with 'all' affect all interfaces
net.ipv4.conf.all.accept_redirects = 0

# Parameters with 'default' set default for new interfaces
net.ipv4.conf.default.accept_redirects = 0

# Per-interface parameters
net.ipv4.conf.eth0.accept_redirects = 0
```

### 20.5.2 Applying Parameters

```bash
# Apply all config files
sudo sysctl --system

# Apply specific file
sudo sysctl -p /etc/sysctl.d/99-custom.conf

# Check for errors
sudo sysctl --system 2>&1 | grep -i error

# Reload specific parameter
sudo sysctl -w net.ipv4.ip_forward=1
```

### 20.5.3 Discovering Parameters

```bash
# List all available parameters
sysctl -a

# Search for specific parameter
sysctl -a | grep tcp_keepalive

# Get help on a parameter
# Check kernel documentation
ls /usr/share/doc/linux-doc/Documentation/
# Or online: https://www.kernel.org/doc/html/latest/admin-guide/sysctl/

# /proc/sys directory structure
tree /proc/sys/net/ipv4/ | head -20
```

## 20.6 Boot Parameter Management

### 20.6.1 GRUB2

```bash
# Temporary: Edit at boot menu (press 'e')
# Modify the 'linux' line

# Persistent: Edit /etc/default/grub
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"
GRUB_CMDLINE_LINUX="apparmor=1 security=apparmor"

# Regenerate config
sudo update-grub
```

### 20.6.2 systemd-boot

```bash
# Edit /boot/efi/loader/entries/*.conf
options root=UUID=abc123 ro quiet splash apparmor=1
```

### 20.6.3 Viewing Current Boot Parameters

```bash
# View current kernel command line
cat /proc/cmdline

# Parse specific parameter
grep -o 'apparmor=[^ ]*' /proc/cmdline
```

## 20.7 Common Pitfalls

### 20.7.1 Typos in Parameters

Kernel silently ignores unknown parameters. Verify with:
```bash
dmesg | grep -i "unknown parameter"
```

### 20.7.2 sysctl Not Applied

```bash
# Check if sysctl config is valid
sudo sysctl --system 2>&1

# Common error: "No such file or directory"
# Usually means the kernel doesn't have that parameter
# (compiled out or different kernel version)
```

### 20.7.3 Conflicting Parameters

Multiple config files may set the same parameter. Last one wins:
```bash
# /etc/sysctl.d/10-network.conf: net.ipv4.ip_forward = 0
# /etc/sysctl.d/99-custom.conf:  net.ipv4.ip_forward = 1
# Result: ip_forward = 1 (99-custom.conf loaded last)
```

### 20.7.4 Security Parameters Reset by Services

Some services (Docker, libvirt) may override security sysctls:
```bash
# Monitor sysctl changes
sudo auditctl -w /proc/sys/ -p wa -k sysctl
```

### 20.7.5 Performance Parameters Causing Instability

Aggressive tuning can cause OOM, network issues, or data corruption:
```bash
# Always test in staging before production
# Keep backups of default values
sysctl -a > /backup/sysctl-defaults.txt
```

## 20.8 Best Practices

1. **Document all changes** — Comment every non-default parameter with the reason
2. **Use `/etc/sysctl.d/`** — Don't edit `/etc/sysctl.conf` directly
3. **Name files descriptively** — `99-network-tuning.conf`, not `my.conf`
4. **Test before deploying** — Apply to staging/test systems first
5. **Keep defaults backed up** — `sysctl -a > defaults.txt`
6. **Use categories** — Separate files for network, memory, security
7. **Verify after changes** — `sysctl --system` and check for errors
8. **Monitor for regressions** — Watch for performance changes after tuning
9. **Read kernel docs** — Parameters change between kernel versions
10. **Use UUID-based root=** — Never use device names for root device

## 20.9 Exercises

### Exercise 1: Parameter Discovery
Write a script that lists all kernel command-line parameters, categorizes them, and identifies any non-standard or security-relevant settings.

### Exercise 2: sysctl Hardening
Create a comprehensive sysctl configuration for a public-facing web server. Include network security, memory tuning, and filesystem limits. Test each parameter.

### Exercise 3: Performance Tuning
Benchmark network throughput before and after applying TCP tuning parameters. Use `iperf3` to measure the impact of buffer size, congestion control, and keepalive settings.

### Exercise 4: Boot Parameter Debugging
Add debug boot parameters to a system and analyze the boot log. Identify which parameters provide the most useful debugging information for your hardware.

### Exercise 5: sysctl Automation
Write an Ansible playbook or shell script that applies a security-hardened sysctl configuration, validates all parameters, and reports any that failed to apply.

## 20.10 References

- [Linux Kernel Parameters (admin-guide)](https://www.kernel.org/doc/html/latest/admin-guide/kernel-parameters.html)
- [sysctl Documentation](https://www.kernel.org/doc/html/latest/admin-guide/sysctl/)
- [Arch Linux: Kernel Parameters](https://wiki.archlinux.org/title/Kernel_parameters)
- [Arch Linux: Sysctl](https://wiki.archlinux.org/title/Sysctl)
- [Red Hat: Kernel Parameters](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/html/managing_monitoring_and_updating_the_kernel/assembly_kernel-boot-parameters_managing-monitoring-and-updating-the-kernel)
- [CIS Benchmarks](https://www.cisecurity.org/cis-benchmarks)
- [Netflix: Linux Performance](https://netflixtechblog.com/linux-performance-68d44cc7f3a6)
