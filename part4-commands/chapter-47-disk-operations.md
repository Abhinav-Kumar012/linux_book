# Chapter 47: Disk Operations — dd, mount, umount, df, du, lsblk, blkid, findmnt

## Overview

Disk operations are critical for system administration — from low-level block device manipulation to filesystem mounting and space monitoring. The tools in this chapter provide comprehensive control over Linux storage: `dd` for raw block I/O, `mount`/`umount` for filesystem attachment, `df`/`du` for space analysis, and `lsblk`/`blkid`/`findmnt` for device discovery.

---

## dd — Convert and Copy a File

### Purpose

`dd` copies data at the byte level, with control over block size, count, and conversion. It's the standard tool for creating disk images, writing bootable media, and performing low-level data operations.

### Syntax

```
dd [OPERAND]...
```

### Key Operands

| Operand | Description |
|---------|-------------|
| `if=FILE` | Input file (default: stdin) |
| `of=FILE` | Output file (default: stdout) |
| `bs=BYTES` | Block size for both read and write |
| `ibs=BYTES` | Input block size |
| `obs=BYTES` | Output block size |
| `count=N` | Copy N blocks |
| `skip=N` | Skip N blocks at start of input |
| `seek=N` | Skip N blocks at start of output |
| `conv=CONVERSION` | Apply conversions |
| `status=LEVEL` | Progress: `none`, `noxfer`, `progress` |
| `iflag=FLAG` | Input flags |
| `oflag=FLAG` | Output flags |

### Conversion Values

| Value | Description |
|-------|-------------|
| `noerror` | Continue on read errors |
| `sync` | Pad each block to ibs with NUL |
| `fdatasync` | Physically write output at end |
| `fsync` | Physically write and flush output |
| `notrunc` | Don't truncate output file |
| `ucase` | Convert to uppercase |
| `lcase` | Convert to lowercase |
| `ascii` | Convert EBCDIC to ASCII |
| `ebcdic` | Convert ASCII to EBCDIC |
| `swab` | Swap every pair of bytes |

### Flag Values

| Flag | Description |
|------|-------------|
| `direct` | Use direct I/O |
| `fullblock` | Fill each block (for pipes) |
| `count_bytes` | count is in bytes, not blocks |
| `skip_bytes` | skip is in bytes |
| `seek_bytes` | seek is in bytes |

### Examples

```bash
# Create disk image
dd if=/dev/sda of=/backup/sda.img bs=4M status=progress

# Restore disk image
dd if=/backup/sda.img of=/dev/sda bs=4M status=progress

# Create bootable USB
dd if=linux.iso of=/dev/sdb bs=4M status=progress conv=fdatasync

# Create empty file (1GB)
dd if=/dev/zero of=empty.img bs=1M count=1024

# Create random file
dd if=/dev/urandom of=random.bin bs=1M count=100

# Backup MBR (first 512 bytes)
dd if=/dev/sda of=mbr_backup.bin bs=512 count=1

# Restore MBR
dd if=mbr_backup.bin of=/dev/sda bs=512 count=1

# Wipe disk (zero fill)
dd if=/dev/zero of=/dev/sdb bs=4M status=progress

# Wipe with random data
dd if=/dev/urandom of=/dev/sdb bs=4M status=progress

# Skip first 1MB, copy next 10MB
dd if=largefile of=part bs=1M skip=1 count=10

# Convert text case
dd if=input.txt of=output.txt conv=ucase

# Create swap file
dd if=/dev/zero of=/swapfile bs=1M count=2048
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile

# Backup partition table
dd if=/dev/sda of=pt_backup.bin bs=512 count=1

# Clone disk with progress
dd if=/dev/sda of=/dev/sdb bs=4M status=progress conv=noerror,sync

# Pad file to specific size
dd if=/dev/zero of=padded.bin bs=1M count=0 seek=100

# Read specific offset
dd if=/dev/sda of=sector.bin bs=512 skip=2048 count=1

# Pipe to compression
dd if=/dev/sda bs=4M | gzip > sda_backup.img.gz

# Verify written data
dd if=/dev/sdb bs=512 count=1 | md5sum
```

### Internals

`dd` operates through a simple read-write loop:

1. Allocate buffer of `bs` (or `ibs`) bytes.
2. Read `count` blocks from input.
3. Apply conversions.
4. Write blocks to output.
5. Report statistics.

**Direct I/O**: With `iflag=direct` and `oflag=direct`, `dd` bypasses the kernel's page cache, performing raw disk I/O. This is useful for benchmarking and avoiding cache pollution.

**Error handling**: By default, `dd` stops on read errors. With `conv=noerror`, it continues. With `conv=sync`, it pads short blocks with NUL bytes to maintain block alignment.

### Performance

- **Block size matters**: Larger `bs` values (4M, 8M) are significantly faster than small ones (512 bytes) because they reduce syscall overhead.
- **Direct I/O**: `iflag=direct` avoids page cache, useful for large copies that would evict useful cached data.
- **Progress**: `status=progress` shows transfer rate and ETA (GNU extension).
- **Typical speeds**: SSD → SSD: ~500MB/s. HDD → HDD: ~100MB/s. Network: depends on bandwidth.

### Common Mistakes

1. **Swapping `if` and `of`**: `dd if=/dev/sda of=/dev/sdb` → `dd if=/dev/sdb of=/dev/sda` is a devastating mistake. Always double-check.

2. **Small block size**: Using `bs=512` instead of `bs=4M` makes copies 10-100x slower.

3. **Missing `status=progress`**: Without it, `dd` shows nothing until completion. Always use it for large operations.

4. **Not using `conv=fdatasync`**: For bootable USB creation, `conv=fdatasync` ensures all data is written before `dd` returns.

### POSIX Compatibility

`dd` is specified by POSIX with `if`, `of`, `ibs`, `obs`, `bs`, `cbs`, `skip`, `seek`, `count`, `conv`. Extensions: `status=progress`, `iflag`, `oflag`, `direct`, `count_bytes`, `skip_bytes`, `seek_bytes`.

---

## mount / umount — Mount and Unmount Filesystems

### Purpose

`mount` attaches a filesystem to the directory tree. `umount` detaches it. These are fundamental operations for accessing storage devices, network shares, and virtual filesystems.

### mount Syntax

```
mount [-lhV]
mount -a [-fFnrsvw] [-t fstype] [-O optlist]
mount [-fnrsvw] [-o options] device|mountpoint
mount [-fnrsvw] [-t fstype] [-o options] device mountpoint
```

### Key Options — mount

| Option | Description |
|--------|-------------|
| `-t TYPE` | Filesystem type |
| `-o OPTIONS` | Mount options |
| `-a` | Mount all filesystems in fstab |
| `-r` | Read-only mount |
| `-w` | Read-write mount (default) |
| `-n` | Don't write to /etc/mtab |
| `-L LABEL` | Mount by label |
| `-U UUID` | Mount by UUID |
| `-l` | Show labels in output |
| `-v` | Verbose |
| `-f` | Fake mount (don't actually mount) |
| `--bind` | Bind mount |
| `--rbind` | Recursive bind mount |
| `--make-shared` | Make mount point shared |
| `--make-private` | Make mount point private |
| `--move` | Move mount point |
| `-T FILE` | Use alternative fstab |

### Common Mount Options

| Option | Description |
|--------|-------------|
| `defaults` | rw, suid, dev, exec, auto, nouser, async |
| `ro` | Read-only |
| `rw` | Read-write |
| `noexec` | Don't allow execution of binaries |
| `nosuid` | Ignore setuid/setgid bits |
| `nodev` | Don't interpret device files |
| `noatime` | Don't update access time |
| `relatime` | Update access time if older than modify (default) |
| `nodiratime` | Don't update directory access time |
| `sync` | Synchronous I/O |
| `async` | Asynchronous I/O |
| `auto` | Mount with `mount -a` |
| `noauto` | Don't mount with `mount -a` |
| `user` | Allow non-root to mount |
| `nouser` | Only root can mount (default) |
| `exec` | Allow execution |
| `_netdev` | Device requires network |
| `loop` | Mount as loop device |
| `offset=N` | Start at byte offset N |
| `size=N` | Limit tmpfs size |
| `mode=MODE` | Set permissions for tmpfs/devfs |
| `uid=N` | Set owner UID |
| `gid=N` | Set owner GID |

### Examples

```bash
# Mount filesystem
mount /dev/sdb1 /mnt/usb

# Mount with type
mount -t ext4 /dev/sdb1 /mnt/usb

# Mount with options
mount -o rw,noexec,nosuid /dev/sdb1 /mnt/usb

# Mount by UUID
mount -U "uuid-string" /mnt/data

# Mount by label
mount -L "DATA" /mnt/data

# Mount ISO image
mount -o loop linux.iso /mnt/iso

# Mount with offset (partition in image)
mount -o loop,offset=1048576 disk.img /mnt/part

# Bind mount
mount --bind /source /destination

# Recursive bind mount
mount --rbind /proc /chroot/proc

# Mount tmpfs
mount -t tmpfs -o size=2G tmpfs /mnt/ramdisk

# Mount all in fstab
mount -a

# Read-only mount
mount -r /dev/sdb1 /mnt/usb

# Mount NFS share
mount -t nfs server:/share /mnt/nfs

# Mount CIFS/SMB share
mount -t cifs //server/share /mnt/smb -o username=user,password=pass

# Mount with noatime (performance)
mount -o noatime /dev/sda1 /mnt/data

# Show mounted filesystems
mount

# Show specific filesystem
mount | grep /dev/sda

# Move mount point
mount --move /old/mount /new/mount

# Make mount shared (for containers)
mount --make-shared /mount/point

# Remount with different options
mount -o remount,ro /mnt/data

# Mount overlay filesystem
mount -t overlay overlay -o lowerdir=/lower,upperdir=/upper,workdir=/work /merged
```

### umount Syntax and Options

```bash
# Unmount filesystem
umount /mnt/usb

# Unmount by device
umount /dev/sdb1

# Lazy unmount (detach immediately, cleanup when free)
umount -l /mnt/usb

# Force unmount (for unreachable NFS)
umount -f /mnt/nfs

# Unmount all (except root)
umount -a

# Unmount specific type
umount -t nfs

# Recursive unmount
umount -R /mnt/parent
```

### /etc/fstab Format

```
# Device        Mount Point    Type    Options           Dump  Pass
/dev/sda1       /              ext4    defaults          1     1
/dev/sda2       /home          ext4    defaults,noatime  1     2
UUID=xxx        /boot/efi      vfat    umask=0077        0     2
tmpfs           /tmp           tmpfs   defaults,size=2G  0     0
//server/share  /mnt/smb       cifs    credentials=/etc/samba/creds 0 0
server:/share   /mnt/nfs       nfs     defaults,_netdev  0     0
/dev/sdb1       /mnt/backup    ext4    defaults,noauto   0     0
```

### Internals

**Mount process**:
1. `mount` reads `/etc/fstab` (for `-a` or when given a mountpoint).
2. Verifies the device exists and the mountpoint exists.
3. Calls `mount()` syscall with device, mountpoint, filesystem type, and flags.
4. Kernel's VFS layer calls the filesystem driver's `mount` function.
5. The filesystem is attached to the directory tree at the mountpoint.

**Virtual filesystems**: `/proc`, `/sys`, `/dev`, `tmpfs` are virtual — they don't have backing devices. The kernel creates them in memory.

### Common Mistakes

1. **Forgetting to create mountpoint**: `mount /dev/sdb1 /mnt/usb` fails if `/mnt/usb` doesn't exist.

2. **Busy filesystem**: `umount /mnt/usb` fails if any process has files open. Use `lsof +D /mnt/usb` to find them, or `umount -l` for lazy unmount.

3. **Mount over existing files**: Mounting on a non-empty directory hides the existing contents. They reappear after unmount.

4. **fstab errors**: Typos in `/etc/fstab` can prevent boot. Always test with `mount -a` before rebooting.

---

## df — Report Filesystem Disk Space Usage

### Purpose

`df` reports filesystem disk space usage — total, used, available, and percentage used.

### Key Options

| Option | Description |
|--------|-------------|
| `-h` | Human-readable sizes |
| `-H` | Human-readable (SI units, powers of 1000) |
| `-T` | Show filesystem type |
| `-i` | Show inode usage |
| `-a` | Include pseudo-filesystems |
| `-x TYPE` | Exclude filesystem type |
| `-t TYPE` | Include only filesystem type |
| `--total` | Show total line |
| `--output=FIELD` | Show specific fields |
| `-B SIZE` | Block size |
| `-k` | 1KB blocks (default) |
| `-m` | 1MB blocks |
| `--sync` | Call `sync` before reporting |

### Examples

```bash
# Basic disk usage
df

# Human-readable
df -h

# Show filesystem type
df -hT

# Inode usage
df -i

# Specific filesystem
df -h /home

# Exclude virtual filesystems
df -h -x tmpfs -x devtmpfs -x squashfs

# Include all filesystems
df -ha

# Show total
df -h --total

# Specific output fields
df --output=source,size,used,avail,pcent,target

# Custom block size
df -BM /home

# Check specific partition
df -h /dev/sda1
```

### Performance

`df` reads `/proc/mounts` and calls `statfs()` for each filesystem. It's fast but can be slow if network filesystems are mounted and unreachable.

---

## du — Estimate File Space Usage

### Purpose

`du` estimates disk usage of files and directories, showing how much space each directory tree consumes.

### Key Options

| Option | Description |
|--------|-------------|
| `-h` | Human-readable |
| `-s` | Summary (total only) |
| `-a` | Include files (not just directories) |
| `-c` | Show grand total |
| `--max-depth=N` | Limit directory depth |
| `-x` | Stay on one filesystem |
| `-S` | Don't include subdirectory sizes |
| `--apparent-size` | Show apparent size (not disk usage) |
| `--exclude=PATTERN` | Exclude files |
| `-b` | Bytes |
| `-k` | 1KB blocks |
| `-m` | 1MB blocks |
| `--time` | Show modification time |
| `--inodes` | Show inode count |

### Examples

```bash
# Current directory summary
du -sh

# Directory sizes, sorted
du -h --max-depth=1 /var | sort -hr

# Top space consumers
du -h --max-depth=1 / 2>/dev/null | sort -hr | head -20

# Specific directory
du -sh /home/user/*

# Include files
du -ah /tmp | sort -hr | head -20

# Grand total
du -shc /var/log/*

# Stay on one filesystem
du -sx /

# Apparent size (actual file size, not disk blocks)
du -sh --apparent-size /home/user

# Exclude patterns
du -sh --exclude='.git' --exclude='node_modules' /project

# Show modification time
du -h --time --max-depth=1 /var/log

# Inode count
du --inodes -s /home

# Find large directories
du -h --max-depth=2 / 2>/dev/null | sort -hr | head -30
```

### Common Mistakes

1. **`du` vs `df`**: `du` shows actual file usage; `df` shows filesystem-level usage. They can differ due to deleted-but-open files, filesystem metadata, and reserved blocks.

2. **Not using `--max-depth`**: `du -h /` without depth limit produces overwhelming output. Always use `--max-depth`.

3. **Permissions**: `du` without `2>/dev/null` shows many "Permission denied" errors when scanning `/`.

---

## lsblk — List Block Devices

### Purpose

`lsblk` lists all block devices in a tree format, showing their relationships (parent devices, partitions, logical volumes).

### Key Options

| Option | Description |
|--------|-------------|
| `-a` | Include empty devices |
| `-b` | Bytes |
| `-d` | Don't show holders/slaves |
| `-e EXCLUDE` | Exclude by major number |
| `-f` | Show filesystems |
| `-i` | ASCII output |
| `-J` | JSON output |
| `-l` | List format (not tree) |
| `-m` | Show permissions |
| `-n` | No header |
| `-o COLUMNS` | Output columns |
| `-p` | Full device path |
| `-P` | Key-value pairs |
| `-r` | Raw output |
| `-t` | Topology info |
| `-S` | Show SCSI devices |
| `-I` | Show specific devices |

### Examples

```bash
# List all block devices
lsblk

# Show filesystems
lsblk -f

# Show with full paths
lsblk -p

# Show specific columns
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,FSTYPE

# Show permissions and ownership
lsblk -m

# JSON output
lsblk -J

# List format
lsblk -l

# Show topology
lsblk -t

# Show SCSI devices
lsblk -S

# Exclude devices
lsblk -e 7  # Exclude loop devices

# Show UUIDs
lsblk -o NAME,UUID,LABEL,SIZE,TYPE,MOUNTPOINT
```

---

## blkid — Locate/Print Block Device Attributes

### Purpose

`blkid` displays attributes of block devices (UUID, LABEL, TYPE, PARTUUID).

### Examples

```bash
# Show all devices
blkid

# Specific device
blkid /dev/sda1

# By UUID
blkid -U "uuid-string"

# By label
blkid -L "LABEL"

# Output specific tags
blkid -o value -s UUID /dev/sda1

# Full output
blkid -o full /dev/sda1

# Export format
blkid -o export /dev/sda1

# List all with cache
blkid -c /dev/null
```

---

## findmnt — Find a Filesystem

### Purpose

`findmnt` searches and displays mounted filesystems. It's a modern replacement for parsing `/proc/mounts`.

### Examples

```bash
# Show all mounts
findmnt

# Tree format
findmnt --tree

# Specific target
findmnt /home

# Specific source
findmnt /dev/sda1

# Show only real filesystems
findmnt -D

# JSON output
findmnt -J

# List format
findmnt -l

# Show specific columns
findmnt -o TARGET,SOURCE,FSTYPE,OPTIONS

# Filter by type
findmnt -t ext4

# Show fstab entries
findmnt --fstab

# Show kernel mountinfo
findmnt -m

# Evaluate LABEL/UUID
findmnt --evaluate

# Poll for changes
findmnt --poll

# Show only mounted on /
findmnt -T /
```

---

## Summary

### Quick Reference

```bash
# Disk usage
df -h                    # Filesystem usage
du -sh /path             # Directory size
du -h --max-depth=1 /    # Top-level sizes

# Block devices
lsblk                    # List devices
lsblk -f                 # With filesystems
blkid                    # Device UUIDs/labels

# Mounting
mount /dev/sdb1 /mnt     # Mount
umount /mnt              # Unmount
mount -a                 # Mount all in fstab
findmnt                  # Show mounted

# dd operations
dd if=/dev/sda of=img bs=4M status=progress  # Backup
dd if=img of=/dev/sdb bs=4M status=progress  # Restore
dd if=/dev/zero of=file bs=1M count=1024     # Create file
```
