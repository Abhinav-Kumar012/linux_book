# Chapter 48: Partitioning — fdisk, parted, sfdisk, mkfs, fsck, e2fsck

## Overview

Disk partitioning divides a physical disk into logical sections, each usable as an independent storage unit. This chapter covers the tools for creating and managing partitions (`fdisk`, `parted`, `sfdisk`), creating filesystems (`mkfs`), and checking/repairing them (`fsck`, `e2fsck`).

---

## Partition Table Formats

### MBR (Master Boot Record)

- **Location**: First 512 bytes of the disk
- **Max partitions**: 4 primary, or 3 primary + 1 extended (with logical partitions)
- **Max disk size**: 2TB
- **Max partition size**: 2TB
- **Boot**: BIOS boot

### GPT (GUID Partition Table)

- **Location**: Header at LBA 1, backup at end of disk
- **Max partitions**: 128 (default, expandable)
- **Max disk size**: 8 ZiB
- **Max partition size**: 8 ZiB
- **Boot**: UEFI boot (with EFI System Partition)

---

## fdisk — Manipulate Disk Partition Table

### Purpose

`fdisk` is the classic interactive partitioning tool. It supports both MBR and GPT partition tables.

### Syntax

```
fdisk [options] device
fdisk -l [device...]
```

### Key Options

| Option | Description |
|--------|-------------|
| `-l` | List partition tables |
| `-s PARTITION` | Print partition size in blocks |
| `-b SIZE` | Sector size (512, 1024, 2048, 4096) |
| `-c MODE` | DOS compatibility mode |
| `-u[=UNIT]` | Display units: sectors (default) or cylinders |
| `--type TYPE` | Specify partition type |
| `--json` | JSON output |
| `-L` | Color output |
| `-w WIDTH` | Screen width |

### Interactive Commands

| Command | Description |
|---------|-------------|
| `n` | New partition |
| `d` | Delete partition |
| `p` | Print partition table |
| `t` | Change partition type |
| `a` | Toggle boot flag |
| `w` | Write changes and exit |
| `q` | Quit without saving |
| `v` | Verify partition table |
| `u` | Change display units |
| `g` | Create new GPT partition table |
| `o` | Create new MBR partition table |
| `i` | Print information about a partition |
| `x` | Expert mode |
| `m` | Help |

### Examples

```bash
# List all partitions
fdisk -l

# List specific disk
fdisk -l /dev/sda

# Interactive partitioning
fdisk /dev/sdb

# Print partition size
fdisk -s /dev/sda1

# JSON output
fdisk --json /dev/sda

# Non-interactive: create GPT with one partition
echo -e "g\nn\n\n\n\nw" | fdisk /dev/sdb

# Non-interactive: create MBR with one partition
echo -e "o\nn\np\n1\n\n\nw" | fdisk /dev/sdb
```

### Interactive Session Example

```bash
$ fdisk /dev/sdb

Command (m for help): g       # Create GPT
Created a new GPT disklabel.

Command (m for help): n       # New partition
Partition number (1-128, default 1): 1
First sector (2048-..., default 2048): 
Last sector (..., default ...): +50G   # 50GB partition

Created a new partition 1 of type 'Linux filesystem' and of size 50 GiB.

Command (m for help): n       # Another partition
Partition number (2-128, default 2): 2
First sector (..., default ...): 
Last sector (..., default ...):        # Use remaining space

Command (m for help): t       # Change type
Partition number (1,2, default 2): 1
Partition type or alias: 1    # EFI System Partition

Command (m for help): p       # Print table
...
Command (m for help): w       # Write and exit
```

### Internals

`fdisk` operates on the disk's partition table:
1. Reads the partition table from the disk (sector 0 for MBR, LBA 1 for GPT).
2. Presents an interactive interface for modifications.
3. On `w`, writes the modified partition table back to disk.
4. Calls `ioctl(BLKRRPART)` to tell the kernel to re-read the partition table.

**Kernel re-read**: The kernel may not re-read the partition table while any partition on the disk is in use. In that case, reboot or use `partprobe`.

---

## parted — A Partition Manipulation Program

### Purpose

`parted` is a more advanced partitioning tool supporting both MBR and GPT, with scripting capabilities and resize operations.

### Syntax

```
parted [options] [device [command [options...]...]]
```

### Key Options

| Option | Description |
|--------|-------------|
| `-l`, `--list` | List all partition tables |
| `-s`, `--script` | Script mode (no prompts) |
| `-a ALIGNMENT` | Alignment: none, cylinder, minimal, optimal |
| `-j`, `--json` | JSON output |
| `-v`, `--version` | Version |
| `-m`, `--machine` | Machine-parseable output |

### Commands

| Command | Description |
|---------|-------------|
| `mklabel LABEL` | Create partition table (msdos/gpt) |
| `mkpart PART_TYPE [FS_TYPE] START END` | Create partition |
| `print [free\|all]` | Display partition table |
| `rm PARTITION` | Remove partition |
| `resizepart PARTITION END` | Resize partition |
| `move PARTITION START END` | Move partition |
| `set PARTITION FLAG STATE` | Set flag (boot, lvm, raid) |
| `mkfs PARTITION FS_TYPE` | Create filesystem |
| `name PARTITION NAME` | Name partition (GPT) |
| `check PARTITION` | Check filesystem |
| `rescue START END` | Rescue lost partition |
| `unit UNIT` | Set unit (s, B, MB, GB, %) |
| `select DEVICE` | Select device |
| `disk_set FLAG STATE` | Set disk flag |
| `align-check TYPE PARTITION` | Check alignment |
| `mkpartfs PART_TYPE FS_TYPE START END` | Create with filesystem |
| `version` | Display version |

### Examples

```bash
# List all partitions
parted -l

# Interactive mode
parted /dev/sdb

# Script: create GPT with partitions
parted -s /dev/sdb mklabel gpt
parted -s /dev/sdb mkpart primary ext4 1MiB 50GiB
parted -s /dev/sdb mkpart primary linux-swap 50GiB 52GiB
parted -s /dev/sdb mkpart primary ext4 52GiB 100%

# Print partition table
parted /dev/sdb print

# Set partition flags
parted /dev/sdb set 1 boot on
parted /dev/sdb set 1 esp on

# Resize partition
parted /dev/sdb resizepart 1 100GiB

# Remove partition
parted /dev/sdb rm 2

# Check alignment
parted /dev/sdb align-check optimal 1

# Use percentage
parted -s /dev/sdb mkpart primary ext4 0% 50%
parted -s /dev/sdb mkpart primary ext4 50% 100%

# JSON output
parted -l -j
```

### Performance

`parted` is fast for partitioning operations. The actual time is dominated by filesystem operations (mkfs, resize), not partitioning.

---

## sfdisk — Scriptable Partition Tool

### Purpose

`sfdisk` is a scriptable partition tool, ideal for automated partitioning in scripts and configuration management.

### Syntax

```
sfdisk [options] device
```

### Key Options

| Option | Description |
|--------|-------------|
| `-d` | Dump partition table |
| `-g` | Show geometry |
| `-l` | List partitions |
| `-s PARTITION` | Print size |
| `-V` | Verify |
| `-q` | Quiet |
| `-J` | JSON output |
| `--json` | JSON output |
| `-w WIDTH` | Screen width |
| `-W` | Show what would be written |
| `-X TYPE` | Partition table type |
| `-N PARTITION` | Change single partition |

### Examples

```bash
# Dump partition table
sfdisk -d /dev/sda

# Restore partition table
sfdisk /dev/sda < partition_backup.txt

# List partitions
sfdisk -l /dev/sda

# Create partitions from script
echo 'label: gpt
name=boot, size=512M, type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B
name=root, size=50G, type=0FC63DAF-8483-4772-8E79-3D69D8477DE4
name=swap, size=4G, type=0657FD6D-A4AB-43C4-84E5-0933C84B4F4F
name=home, type=0FC63DAF-8483-4772-8E79-3D69D8477DE4' | sfdisk /dev/sdb

# JSON output
sfdisk -J /dev/sda

# Verify partition table
sfdisk -V /dev/sda

# Backup and restore
sfdisk -d /dev/sda > sda_backup.txt
sfdisk /dev/sda < sda_backup.txt

# Change single partition
echo ', +' | sfdisk -N 2 /dev/sdb  # Grow partition 2

# Print sizes
sfdisk -s /dev/sda1
```

---

## mkfs — Build a Linux Filesystem

### Purpose

`mkfs` creates a filesystem on a partition. It's a front-end that calls specific filesystem tools (`mkfs.ext4`, `mkfs.xfs`, `mkfs.btrfs`).

### Syntax

```
mkfs [-V] [-t fstype] [fs-options] device [size]
```

### Common Filesystem Types

| Type | Command | Use Case |
|------|---------|----------|
| ext4 | `mkfs.ext4` | General purpose, most common |
| xfs | `mkfs.xfs` | Large files, high performance |
| btrfs | `mkfs.btrfs` | CoW, snapshots, compression |
| vfat | `mkfs.vfat` | EFI partition, USB drives |
| ntfs | `mkfs.ntfs` | Windows compatibility |
| exfat | `mkfs.exfat` | Large USB drives, cross-platform |
| swap | `mkswap` | Swap partition |

### mkfs.ext4

```bash
# Basic ext4
mkfs.ext4 /dev/sdb1

# With label
mkfs.ext4 -L "DATA" /dev/sdb1

# With reserved blocks percentage
mkfs.ext4 -m 1 /dev/sdb1  # 1% reserved (default 5%)

# Block size
mkfs.ext4 -b 4096 /dev/sdb1

# Inode size
mkfs.ext4 -I 256 /dev/sdb1

# Disable journal (for testing)
mkfs.ext4 -O ^has_journal /dev/sdb1

# Enable features
mkfs.ext4 -O extent,uninit_bg,dir_index /dev/sdb1

# Dry run
mkfs.ext4 -n /dev/sdb1

# Specific inode ratio
mkfs.ext4 -i 8192 /dev/sdb1  # One inode per 8KB
```

### mkfs.xfs

```bash
# Basic XFS
mkfs.xfs /dev/sdb1

# With label
mkfs.xfs -L "DATA" /dev/sdb1

# Block size
mkfs.xfs -b size=4096 /dev/sdb1

# Disable lazy initialization
mkfs.xfs -K /dev/sdb1

# Specify log size
mkfs.xfs -l size=128m /dev/sdb1

# Force overwrite
mkfs.xfs -f /dev/sdb1
```

### mkfs.btrfs

```bash
# Basic Btrfs
mkfs.btrfs /dev/sdb1

# With label
mkfs.btrfs -L "DATA" /dev/sdb1

# RAID1 across multiple devices
mkfs.btrfs -d raid1 -m raid1 /dev/sdb1 /dev/sdc1

# Single device, different metadata profile
mkfs.btrfs -d single -m single /dev/sdb1

# Compression
mkfs.btrfs -O compress=zstd /dev/sdb1

# Mixed mode (data and metadata on same block group)
mkfs.btrfs --mixed /dev/sdb1
```

### mkfs General Options

| Option | Description |
|--------|-------------|
| `-t TYPE` | Filesystem type |
| `-V` | Verbose (or version) |
| `-c` | Check device for bad blocks |
| `-l FILE` | Read bad blocks from FILE |
| `-v` | Verbose |
| `-q` | Quiet |

---

## fsck — Check and Repair a Linux Filesystem

### Purpose

`fsck` (File System Consistency Check) checks and optionally repairs filesystems. It's a front-end for filesystem-specific tools.

### Syntax

```
fsck [-lsAVRTMNP] [-C [fd]] [-t fstype] [filesys...] [--] [fs-specific-options]
```

### Key Options

| Option | Description |
|--------|-------------|
| `-t TYPE` | Filesystem type |
| `-A` | Check all filesystems in fstab |
| `-R` | Skip root filesystem (with `-A`) |
| `-P` | Check root and other filesystems in parallel (with `-A`) |
| `-M` | Don't check mounted filesystems |
| `-N` | Don't execute, just show what would be done |
| `-T` | Don't show title |
| `-V` | Verbose |
| `-a` | Auto-repair (no questions) |
| `-y` | Auto-repair (answer yes to all) |
| `-n` | No-repair mode (read-only) |
| `-r` | Interactive repair |
| `-C` | Show progress bar |
| `-p` | Auto-repair (safe operations only) |
| `-f` | Force check even if clean |

### Examples

```bash
# Check specific filesystem
fsck /dev/sda1

# Check all in fstab
fsck -A

# Auto-repair
fsck -y /dev/sda1

# Check with progress
fsck -C /dev/sda1

# Force check
fsck -f /dev/sda1

# Don't modify (read-only)
fsck -n /dev/sda1

# Skip mounted
fsck -M -A

# Verbose
fsck -V /dev/sda1

# Specify type
fsck -t ext4 /dev/sda1

# Check during boot (typically automatic)
# /etc/fstab: pass=1 for root, pass=2 for others
```

---

## e2fsck — Check ext2/ext3/ext4 Filesystem

### Purpose

`e2fsck` is the specific checker for ext2/ext3/ext4 filesystems.

### Key Options

| Option | Description |
|--------|-------------|
| `-y` | Auto-answer yes |
| `-n` | Read-only (no changes) |
| `-p` | Auto-repair safe operations |
| `-f` | Force check |
| `-v` | Verbose |
| `-b SUPERBLOCK` | Use alternative superblock |
| `-B SIZE` | Block size |
| `-C` | Progress bar |
| `-D` | Optimize directories |
| `-E EXTENDED` | Extended options |
| `-j` | Set journal location |
| `-k` | Keep corrupted blocks in lost+found |
| `-l FILE` | Add bad blocks from FILE |
| `-L FILE` | Set bad blocks list |
| `-t` | Show timing |
| `-c` | Bad block scan |
| `-z FILE` | Undo file |

### Examples

```bash
# Check ext4 filesystem
e2fsck /dev/sda1

# Force check
e2fsck -f /dev/sda1

# Auto-repair
e2fsck -y /dev/sda1

# Use alternative superblock (if primary is corrupted)
e2fsck -b 32768 /dev/sda1

# Bad block scan
e2fsck -c /dev/sda1

# Optimize directories
e2fsck -D /dev/sda1

# Verbose with progress
e2fsck -vf /dev/sda1

# Find alternative superblock location
mkfs.ext4 -n /dev/sdb1  # Shows superblock locations
```

### Finding Alternative Superblocks

If the primary superblock is corrupted:

```bash
# Find superblock locations
mke2fs -n /dev/sdb1

# Use alternative superblock
e2fsck -b 32768 /dev/sdb1

# Or mount with alternative superblock
mount -o sb=32768 /dev/sdb1 /mnt
```

---

## Summary

### Partitioning Workflow

```bash
# 1. List disks
lsblk
fdisk -l

# 2. Create partition table (GPT recommended)
parted -s /dev/sdb mklabel gpt

# 3. Create partitions
parted -s /dev/sdb mkpart primary ext4 1MiB 50GiB
parted -s /dev/sdb mkpart primary linux-swap 50GiB 54GiB
parted -s /dev/sdb mkpart primary ext4 54GiB 100%

# 4. Create filesystems
mkfs.ext4 -L "ROOT" /dev/sdb1
mkswap -L "SWAP" /dev/sdb2
mkfs.ext4 -L "HOME" /dev/sdb3

# 5. Mount
mount /dev/sdb1 /mnt
mount /dev/sdb3 /mnt/home
swapon /dev/sdb2

# 6. Add to fstab
echo 'UUID=xxx / ext4 defaults 0 1' >> /etc/fstab
echo 'UUID=yyy none swap sw 0 0' >> /etc/fstab
echo 'UUID=zzz /home ext4 defaults 0 2' >> /etc/fstab

# 7. Check filesystems
fsck -f /dev/sdb1
e2fsck -f /dev/sdb3
```

### Safety Reminders

- **Always backup** before partitioning operations.
- **Double-check device names** — partitioning the wrong disk is catastrophic.
- **Use `parted -s`** for scripts to avoid interactive prompts.
- **Unmount before checking** — never run `fsck` on a mounted filesystem.
- **Test in VM first** — practice partitioning in a virtual machine before real hardware.
