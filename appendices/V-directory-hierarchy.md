# Appendix V: Linux Directory Hierarchy (FHS)

## Overview

The Filesystem Hierarchy Standard (FHS) defines the directory structure for Linux systems. This appendix explains the purpose and contents of each major directory.

---

## 1. Root Directory `/`

The root directory is the top of the filesystem hierarchy. Every file and directory descends from `/`.

```
/
├── bin/        → Essential user commands
├── boot/       → Boot loader files
├── dev/        → Device files
├── etc/        → System configuration
├── home/       → User home directories
├── lib/        → Essential shared libraries
├── lib64/      → 64-bit essential libraries
├── media/      → Mount points for removable media
├── mnt/        → Temporary mount points
├── opt/        → Optional application packages
├── proc/       → Kernel/process information (virtual)
├── root/       → Root user home directory
├── run/        → Runtime data
├── sbin/       → Essential system binaries
├── srv/        → Service data
├── sys/        → Kernel/device information (virtual)
├── tmp/        → Temporary files
├── usr/        → Secondary hierarchy (user programs)
└── var/        → Variable data
```

---

## 2. Essential Directories

### `/bin` — Essential User Commands

Contains essential command binaries needed in single-user mode and for all users. On modern systems, this is often a symlink to `/usr/bin`.

| Contents | Examples |
|----------|----------|
| Shell commands | `bash`, `sh`, `zsh` |
| File utilities | `ls`, `cp`, `mv`, `rm`, `cat`, `mkdir` |
| Text processing | `grep`, `sed`, `awk`, `sort` |
| System utilities | `mount`, `umount`, `kill`, `ps` |
| Compression | `gzip`, `bzip2`, `xz`, `tar` |

### `/sbin` — Essential System Binaries

Contains essential system administration binaries. On modern systems, often a symlink to `/usr/sbin`.

| Contents | Examples |
|----------|----------|
| Boot | `init`, `shutdown`, `reboot` |
| Network | `ip`, `iptables`, `route`, `ifconfig` |
| Filesystem | `mkfs`, `fsck`, `fdisk`, `mount` |
| System | `modprobe`, `sysctl`, `ldconfig` |
| User management | `useradd`, `userdel`, `passwd` |

### `/boot` — Boot Loader Files

Contains files required for booting the system.

| Contents | Description |
|----------|-------------|
| `vmlinuz-*` | Compressed kernel images |
| `initramfs-*` / `initrd-*` | Initial ramdisk images |
| `config-*` | Kernel configuration |
| `System.map-*` | Kernel symbol table |
| `grub/` | GRUB boot loader files |
| `efi/` | EFI system partition files |

### `/dev` — Device Files

Contains device files that represent hardware devices and virtual devices.

| File | Description |
|------|-------------|
| `/dev/sda`, `/dev/sdb` | SCSI/SATA disk devices |
| `/dev/nvme0n1` | NVMe devices |
| `/dev/vda` | Virtio disk devices |
| `/dev/tty` | Current terminal |
| `/dev/tty0`-`/dev/tty63` | Virtual consoles |
| `/dev/pts/*` | Pseudo-terminal slaves |
| `/dev/null` | Bit bucket (discard all writes) |
| `/dev/zero` | Zero bytes (read zeros) |
| `/dev/random` | True random numbers (blocking) |
| `/dev/urandom` | Pseudo-random numbers (non-blocking) |
| `/dev/console` | System console |
| `/dev/loop*` | Loop devices |
| `/dev/mapper/*` | Device mapper devices |
| `/dev/shm` | Shared memory (tmpfs) |
| `/dev/hugepages` | Huge pages |

### `/etc` — System Configuration

Contains system-wide configuration files. No binaries should be here.

| File/Directory | Description |
|----------------|-------------|
| `/etc/passwd` | User account information |
| `/etc/shadow` | Encrypted passwords |
| `/etc/group` | Group information |
| `/etc/fstab` | Filesystem mount table |
| `/etc/hostname` | System hostname |
| `/etc/hosts` | Hostname-to-IP mapping |
| `/etc/resolv.conf` | DNS resolver configuration |
| `/etc/nsswitch.conf` | Name service configuration |
| `/etc/mtab` → `/proc/mounts` | Currently mounted filesystems |
| `/etc/shells` | Valid login shells |
| `/etc/sudoers` | Sudo configuration |
| `/etc/crontab` | System cron table |
| `/etc/cron.d/` | Additional cron jobs |
| `/etc/sysctl.conf` | Kernel parameters |
| `/etc/modules` | Kernel modules to load |
| `/etc/fstab` | Filesystem table |
| `/etc/network/` | Network configuration (Debian) |
| `/etc/sysconfig/` | System configuration (RHEL) |
| `/etc/systemd/` | systemd configuration |
| `/etc/nginx/` | Nginx configuration |
| `/etc/apache2/` | Apache configuration |
| `/etc/ssh/` | SSH configuration |
| `/etc/ssl/` | SSL certificates |
| `/etc/X11/` | X Window System config |
| `/etc/profile` | Global shell profile |
| `/etc/bash.bashrc` | Global bash configuration |
| `/etc/environment` | Global environment variables |
| `/etc/ld.so.conf` | Dynamic linker configuration |
| `/etc/logrotate.conf` | Log rotation configuration |
| `/etc/pam.d/` | PAM configuration |

### `/home` — User Home Directories

Contains personal directories for regular users.

```
/home/
├── alice/
│   ├── .bashrc
│   ├── .bash_profile
│   ├── .ssh/
│   ├── .config/
│   ├── Documents/
│   ├── Downloads/
│   └── ...
├── bob/
└── ...
```

### `/lib` and `/lib64` — Essential Shared Libraries

Contains shared libraries needed by binaries in `/bin` and `/sbin`. On modern systems, often symlinks to `/usr/lib` and `/usr/lib64`.

| Contents | Examples |
|----------|----------|
| C library | `libc.so.6`, `libm.so.6` |
| Dynamic linker | `ld-linux-x86-64.so.2` |
| Kernel modules | `/lib/modules/*/` |
| systemd | `/lib/systemd/` |

### `/media` — Removable Media

Mount points for removable media (USB drives, CDs, DVDs).

```
/media/
├── alice/
│   ├── USB_DRIVE/
│   └── CD_ROM/
└── ...
```

### `/mnt` — Temporary Mount Points

Reserved for temporarily mounted filesystems.

### `/opt` — Optional Packages

Contains add-on application software packages.

```
/opt/
├── google/
│   └── chrome/
├── slack/
├── myapp/
│   ├── bin/
│   ├── lib/
│   ├── etc/
│   └── share/
└── ...
```

### `/proc` — Process Information (Virtual)

Virtual filesystem providing process and kernel information. Does not exist on disk.

| File | Description |
|------|-------------|
| `/proc/cpuinfo` | CPU information |
| `/proc/meminfo` | Memory information |
| `/proc/version` | Kernel version |
| `/proc/cmdline` | Kernel command line |
| `/proc/uptime` | System uptime |
| `/proc/loadavg` | Load averages |
| `/proc/filesystems` | Supported filesystems |
| `/proc/mounts` | Mounted filesystems |
| `/proc/net/` | Network statistics |
| `/proc/sys/` | Kernel parameters (sysctl) |
| `/proc/[pid]/` | Per-process information |
| `/proc/[pid]/cmdline` | Process command line |
| `/proc/[pid]/status` | Process status |
| `/proc/[pid]/fd/` | Open file descriptors |
| `/proc/[pid]/maps` | Memory maps |
| `/proc/[pid]/environ` | Environment variables |
| `/proc/[pid]/exe` | Executable symlink |
| `/proc/[pid]/cwd` | Working directory symlink |

### `/root` — Root User Home

Home directory for the root user (not `/home/root`).

### `/run` — Runtime Data

Contains runtime data since last boot. Mounted as tmpfs.

| Contents | Description |
|----------|-------------|
| `/run/lock/` | Lock files |
| `/run/user/` | Per-user runtime directories |
| `/run/user/1000/` | User 1000's runtime |
| `/run/systemd/` | systemd runtime data |
| `/run/udev/` | udev runtime data |
| `/run/mount/` | Mount runtime data |

### `/srv` — Service Data

Contains data for services provided by the system.

```
/srv/
├── www/          # Web server data
├── ftp/          # FTP server data
├── git/          # Git repositories
├── nfs/          # NFS exports
└── ...
```

### `/sys` — Kernel/Device Information (Virtual)

Virtual filesystem exporting kernel data structures.

| Directory | Description |
|-----------|-------------|
| `/sys/block/` | Block devices |
| `/sys/bus/` | Bus types |
| `/sys/class/` | Device classes |
| `/sys/devices/` | Device tree |
| `/sys/firmware/` | Firmware interface |
| `/sys/fs/` | Filesystem features |
| `/sys/kernel/` | Kernel configuration |
| `/sys/module/` | Loaded kernel modules |
| `/sys/power/` | Power management |
| `/sys/fs/cgroup/` | Cgroup hierarchy |

### `/tmp` — Temporary Files

Temporary files. Often cleared on reboot. May be tmpfs.

---

## 3. `/usr` — Secondary Hierarchy

The `/usr` directory contains the majority of user-space programs and data.

```
/usr/
├── bin/        → Most user commands
├── sbin/       → System administration commands
├── lib/        → Libraries
├── lib64/      → 64-bit libraries
├── libexec/    → Helper programs
├── include/    → C/C++ header files
├── share/      → Architecture-independent data
│   ├── man/    → Manual pages
│   ├── doc/    → Documentation
│   ├── info/   → GNU info pages
│   ├── locale/ → Locale data
│   ├── zoneinfo/ → Timezone data
│   ├── dict/   → Dictionary data
│   ├── games/  → Game data
│   ├── misc/   → Miscellaneous data
│   └── ...
├── local/      → Local hierarchy
│   ├── bin/    → Local binaries
│   ├── sbin/   → Local system binaries
│   ├── lib/    → Local libraries
│   ├── etc/    → Local configuration
│   ├── include/ → Local headers
│   ├── share/  → Local data
│   └── src/    → Local source code
├── src/        → Kernel source
├── games/      → Game binaries
└── X11R6/      → X Window System
```

---

## 4. `/var` — Variable Data

Contains variable data that changes during system operation.

```
/var/
├── log/        → System logs
│   ├── syslog
│   ├── auth.log
│   ├── kern.log
│   ├── messages
│   ├── journal/  → systemd journal
│   └── ...
├── mail/       → User mail
├── spool/      → Spool directories
│   ├── cron/   → Cron spool
│   ├── mail/   → Mail spool
│   └── printer/ → Printer spool
├── tmp/        → Temporary files (preserved between reboots)
├── cache/      → Application cache
│   ├── apt/    → APT cache
│   ├── dnf/    → DNF cache
│   └── ...
├── lib/        → Variable state information
│   ├── dpkg/   → Dpkg state
│   ├── rpm/    → RPM state
│   └── ...
├── run/        → Runtime data (symlink to /run)
├── lock/       → Lock files (symlink to /run/lock)
└── opt/        → Variable data for /opt
```

---

## 5. Mount Points and Special Filesystems

| Mount Point | Filesystem | Description |
|-------------|-----------|-------------|
| `/` | ext4/xfs/btrfs | Root filesystem |
| `/boot` | ext4 | Boot files |
| `/home` | ext4/xfs | User data |
| `/tmp` | tmpfs | Temporary files |
| `/var` | ext4/xfs | Variable data |
| `/proc` | procfs | Process/kernel info |
| `/sys` | sysfs | Device/kernel info |
| `/dev` | devtmpfs | Device files |
| `/dev/shm` | tmpfs | Shared memory |
| `/dev/pts` | devpts | Pseudo-terminals |
| `/run` | tmpfs | Runtime data |
| `/sys/fs/cgroup` | cgroup2 | Cgroup hierarchy |

---

## 6. Filesystem Permissions by Directory

| Directory | Owner | Permissions | Notes |
|-----------|-------|-------------|-------|
| `/` | root:root | 755 | World-readable |
| `/root` | root:root | 700 | Root-only |
| `/home/*` | user:user | 700/750 | Per-user |
| `/tmp` | root:root | 1777 | World-writable, sticky bit |
| `/var/tmp` | root:root | 1777 | World-writable, sticky bit |
| `/etc` | root:root | 755 | World-readable |
| `/etc/shadow` | root:shadow | 640 | Restricted |
| `/etc/ssh/*` | root:root | 600/644 | SSH keys restricted |
| `/var/log` | root:root | 755 | World-readable |
| `/boot` | root:root | 755 | World-readable |
| `/dev` | root:root | 755 | Device nodes |

---

## 7. Modern Trends

### Usr-Merge

Many distributions are merging `/bin`, `/sbin`, `/lib`, and `/lib64` into `/usr/bin`, `/usr/sbin`, `/usr/lib`, and `/usr/lib64`:

```
/bin → usr/bin
/sbin → usr/sbin
/lib → usr/lib
/lib64 → usr/lib64
```

This simplifies the hierarchy while maintaining backward compatibility via symlinks.

### Tmpfs Mounts

Modern systems mount several directories as tmpfs:

- `/tmp` — Cleared on reboot
- `/run` — Runtime data
- `/dev/shm` — Shared memory
- `/dev/pts` — Pseudo-terminals
- `/sys/fs/cgroup` — Cgroup hierarchy

### XDG Base Directory Specification

Defines standard locations for user-specific files:

| Variable | Default | Description |
|----------|---------|-------------|
| `XDG_CONFIG_HOME` | `~/.config` | User configuration |
| `XDG_DATA_HOME` | `~/.local/share` | User data |
| `XDG_STATE_HOME` | `~/.local/state` | User state |
| `XDG_CACHE_HOME` | `~/.cache` | User cache |
| `XDG_RUNTIME_DIR` | `/run/user/$UID` | User runtime |
| `XDG_DATA_DIRS` | `/usr/local/share:/usr/share` | System data |
| `XDG_CONFIG_DIRS` | `/etc/xdg` | System config |

---

*The FHS specification is maintained at https://refspecs.linuxfoundation.org/fhs.shtml. See `man hier` for a quick reference.*
