# Appendix E: Filesystem Comparison Matrix

## Overview

Linux supports numerous filesystems, each with distinct design goals, performance characteristics, and feature sets. This appendix provides a comprehensive comparison of the most commonly used Linux filesystems.

---

## 1. Feature Comparison Matrix

| Feature | ext4 | XFS | Btrfs | ZFS | F2FS |
|---------|------|-----|-------|-----|------|
| **Maximum file size** | 16 TiB | 8 EiB | 16 EiB | 16 EiB | 3.94 TiB |
| **Maximum filesystem size** | 1 EiB | 8 EiB | 16 EiB | 256 ZiB | 16 TiB |
| **Maximum filename length** | 255 bytes | 255 bytes | 255 bytes | 255 bytes | 255 bytes |
| **Block sizes** | 1K–64K | 512–64K | 4K–64K | 512–128K | 512–64K |
| **Journal** | Yes | Yes | No (COW) | No (COW) | Yes |
| **Copy-on-Write** | No | No | Yes | Yes | Partial |
| **Checksums (data)** | No | No | Yes (crc32c, xxhash, blake2b, sha256) | Yes (fletcher4, sha256, blake3) | No |
| **Checksums (metadata)** | No | Yes (v5) | Yes | Yes | Yes |
| **Inline data** | Yes | No | Yes | No | Yes |
| **Compression** | No | No | Yes (zlib, lzo, zstd) | Yes (lz4, zstd, gzip) | Yes (lz4, zstd) |
| **Deduplication** | No | No | Yes (offline) | Yes (inline/async) | No |
| **Snapshots** | No | No | Yes (COW) | Yes (COW) | No |
| **Subvolumes** | No | No | Yes | Yes (datasets) | No |
| **RAID (built-in)** | No | No | Yes (0, 1, 10, 5, 6) | Yes (0, 1, 10, Z1, Z2, Z3) | No |
| **Online resize (grow)** | Yes | Yes | Yes | Yes | No |
| **Online resize (shrink)** | Yes | No | Yes | No | No |
| **Quotas** | Yes | Yes | Yes (per-subvol) | Yes (per-dataset) | Yes |
| **ACLs** | Yes | Yes | Yes | Yes (NFSv4) | Yes |
| **SELinux labels** | Yes | Yes | Yes | Yes | Yes |
| **Reflinks** | No (v5+) | Yes | Yes | No | No |
| **Swap files** | Yes | No | Yes (v5.0+) | No | No |
| **Huge pages support** | Yes | No | No | No | No |
| **Online defrag** | Yes | Yes | No | No | No |
| **TRIM/discard** | Yes | Yes | Yes | Yes | Yes |
| **Direct I/O** | Yes | Yes | Yes | Yes | Yes |
| **Memory-mapped I/O** | Yes | Yes | Yes | Yes | Yes |
| **NFS export** | Yes | Yes | Yes | Yes | Yes |
| **Stable inodes** | Yes | Yes | Yes | Yes | Yes |
| **Creation year** | 2006 | 1993 (IRIX), 2001 (Linux) | 2009 | 2005 (Sun) | 2012 |

---

## 2. ext4 (Fourth Extended Filesystem)

### Design Philosophy

ext4 is the default filesystem for many Linux distributions. It is a mature, stable, journaled filesystem based on the ext2/ext3 lineage. Designed for reliability and backward compatibility.

### Architecture

```
┌─────────────────────────────────────────┐
│              ext4 Layout                │
├─────────┬───────┬───────┬───────────────┤
│ Boot    │ Super │ Group │ Data          │
│ Block   │ Block │ Descs │ Blocks        │
│ (1024B) │       │       │               │
│         │       │       │ ┌───────────┐ │
│         │       │       │ │ Journal   │ │
│         │       │       │ │ (inode 8) │ │
│         │       │       │ └───────────┘ │
└─────────┴───────┴───────┴───────────────┘
```

### Key Features

- **Extents**: Replaced indirect block mapping; each extent covers up to 128 MB contiguous blocks
- **Delayed allocation**: Defers block allocation to reduce fragmentation
- **Multiblock allocator**: Allocates multiple blocks in a single operation
- **Journal checksumming**: Ensures journal integrity
- **Online defragmentation**: `e4defrag` can defragment while mounted
- **Flex_bg**: Groups multiple block groups into a single metadata unit

### Best Use Cases

- General-purpose Linux systems
- Root filesystem
- Desktops and laptops
- Small to medium servers
- Where stability and maturity matter most

### Performance Characteristics

| Workload | Performance Rating |
|----------|-------------------|
| Small file I/O | ★★★★☆ |
| Large sequential I/O | ★★★★☆ |
| Random read | ★★★★☆ |
| Random write | ★★★☆☆ |
| Metadata-heavy | ★★★☆☆ |
| Concurrent I/O | ★★★☆☆ |

### Tuning

```bash
# Mount options for performance
mount -o noatime,nodiratime,data=writeback /dev/sda1 /mnt

# Adjust journal mode
tune2fs -o journal_data_writeback /dev/sda1

# Enable dir_index for large directories
tune2fs -O dir_index /dev/sda1

# Disable barriers (battery-backed RAID only)
mount -o barrier=0 /dev/sda1 /mnt

# Adjust reserved space
tune2fs -m 1 /dev/sda1  # Reduce from 5% to 1%

# Check filesystem
fsck.ext4 -f /dev/sda1
```

---

## 3. XFS

### Design Philosophy

XFS is a high-performance, 64-bit journaling filesystem originally from SGI IRIX. It excels at parallel I/O and large file handling. Default in RHEL 7+ and derivatives.

### Architecture

```
┌────────────────────────────────────────────────┐
│                XFS Layout                      │
├─────────┬──────────┬───────────────────────────┤
│ AG 0    │ AG 1     │ AG 2 ... AG N            │
│ ┌─────┐ │ ┌─────┐  │                           │
│ │ SB  │ │ │ SB  │  │  AG = Allocation Group    │
│ │ AGF │ │ │ AGF │  │  Each AG has independent  │
│ │ AGFL│ │ │ AGFL│  │  allocation structures    │
│ │ Ino │ │ │ Ino │  │                           │
│ │ Bt  │ │ │ Bt  │  │  Enables parallel         │
│ │Data │ │ │Data │  │  allocation across AGs    │
│ └─────┘ │ └─────┘  │                           │
└─────────┴──────────┴───────────────────────────┘
```

### Key Features

- **Allocation Groups (AGs)**: Enable parallel allocation and I/O across CPU cores
- **B+tree indexes**: Used for free space, inodes, and directories
- **Delayed logging**: Groups log writes for better throughput
- **Real-time devices**: Optional separate device for file data (vs metadata)
- **Reflinks**: Copy-on-write file clones (added in 2018)
- **Online repair**: `xfs_repair` can fix issues while mounted
- **DAX (Direct Access)**: Support for persistent memory

### Best Use Cases

- Large files (media, databases, VMs)
- High-concurrency workloads
- Large-capacity storage (multi-TB)
- RHEL/CentOS/Oracle Linux systems
- Database servers
- Video editing and streaming

### Performance Characteristics

| Workload | Performance Rating |
|----------|-------------------|
| Small file I/O | ★★★☆☆ |
| Large sequential I/O | ★★★★★ |
| Random read | ★★★★☆ |
| Random write | ★★★★★ |
| Metadata-heavy | ★★★★★ |
| Concurrent I/O | ★★★★★ |

### Tuning

```bash
# Mount options for database workloads
mount -o noatime,logbufs=8,logbsize=256k,allocsize=64m /dev/sda1 /mnt

# Stripe alignment for RAID
mount -o sunit=128,swidth=1024 /dev/sda1 /mnt

# Disable atime
mount -o noatime /dev/sda1 /mnt

# Increase log size
mkfs.xfs -l size=256m /dev/sda1

# Online defragment
xfs_fsr /mount/point

# Repair (offline)
xfs_repair /dev/sda1

# Grow filesystem
xfs_growfs /mount/point
```

---

## 4. Btrfs (B-tree Filesystem)

### Design Philosophy

Btrfs is a modern copy-on-write filesystem designed for advanced features like snapshots, subvolumes, built-in RAID, and data integrity. It aims to provide enterprise features while remaining in-tree.

### Architecture

```
┌─────────────────────────────────────────────┐
│              Btrfs Layout                   │
├─────────────────────────────────────────────┤
│  Superblock (multiple copies)               │
├─────────────────────────────────────────────┤
│  Chunk Tree → Maps logical→physical         │
├─────────────────────────────────────────────┤
│  Root Tree → Points to all other trees      │
│  ├── FS Tree (files and directories)        │
│  ├── Checksum Tree                          │
│  ├── Extent Tree                            │
│  ├── Chunk Tree                             │
│  ├── Device Tree                            │
│  └── Log Tree (fsync)                       │
└─────────────────────────────────────────────┘
```

### Key Features

- **Copy-on-Write (COW)**: Never overwrites data in place; always writes to new location
- **Snapshots**: Instant, read-only or writable snapshots of any subvolume
- **Subvolumes**: Independent filesystem trees within a single pool
- **Built-in RAID**: RAID 0, 1, 10, 5 (experimental), 6 (experimental)
- **Compression**: Transparent zlib, lzo, or zstd compression
- **Deduplication**: Offline dedup via `duperemove` or `bedup`
- **Send/Receive**: Incremental backup via `btrfs send`/`btrfs receive`
- **Online balancing**: Redistribute data across devices
- **Data checksumming**: Detect and repair silent data corruption
- **Quota groups**: Per-subvolume accounting and limits

### Best Use Cases

- Desktop Linux (good snapshot support)
- NAS and home servers
- Development environments (easy rollbacks)
- Backup storage (send/receive)
- Multi-device storage pools
- Where data integrity is critical

### Performance Characteristics

| Workload | Performance Rating |
|----------|-------------------|
| Small file I/O | ★★★☆☆ |
| Large sequential I/O | ★★★★☆ |
| Random read | ★★★★☆ |
| Random write | ★★★☆☆ |
| Metadata-heavy | ★★☆☆☆ |
| Concurrent I/O | ★★★☆☆ |

### Common Operations

```bash
# Create filesystem
mkfs.btrfs /dev/sda1

# Create multi-device filesystem
mkfs.btrfs -d raid1 -m raid1 /dev/sda /dev/sdb

# Create subvolume
btrfs subvolume create /mnt/data

# Create snapshot
btrfs subvolume snapshot /mnt/data /mnt/data_snap

# List subvolumes
btrfs subvolume list /mnt

# Check data integrity
btrfs scrub start /mnt

# Balance (redistribute data)
btrfs balance start /mnt

# Add device
btrfs device add /dev/sdc /mnt

# Remove device
btrfs device remove /dev/sdc /mnt

# Show filesystem info
btrfs filesystem show
btrfs filesystem df /mnt

# Enable compression
mount -o compress=zstd /dev/sda1 /mnt

# Send/receive (incremental backup)
btrfs send -p /mnt/snap1 /mnt/snap2 | btrfs receive /backup/
```

### Known Limitations

- **RAID 5/6**: Not recommended for production (known write hole issues)
- **Quotas**: Can impact performance significantly
- **Rename atomicity**: Not fully atomic across subvolumes
- **Small file performance**: Slower than ext4 for many small files
- **No swap file support**: (until kernel 5.0, still limited)

---

## 5. ZFS (Zettabyte Filesystem)

### Design Philosophy

ZFS is an enterprise-grade combined filesystem and logical volume manager originally from Sun Microsystems. Known for data integrity, scalability, and extensive feature set. Not included in mainline Linux kernel due to license incompatibility (CDDL vs GPL).

### Architecture

```
┌──────────────────────────────────────────────┐
│                ZFS Architecture              │
├──────────────────────────────────────────────┤
│  Storage Pool (zpool)                        │
│  ┌────────────────────┐                      │
│  │ Vdev (virtual dev) │                      │
│  │ ┌─────┬─────┬────┐ │                      │
│  │ │ d1  │ d2  │d3  │ │  ← RAID-Z           │
│  │ └─────┴─────┴────┘ │                      │
│  └────────────────────┘                      │
│                                              │
│  Dataset (filesystem)                        │
│  ┌────────────────────┐                      │
│  │ ZPL (ZFS Posix Layer)│                    │
│  │ DMU (Data Mgmt Unit) │                    │
│  │ SPA (Storage Pool)   │                    │
│  │ ZIO (I/O Pipeline)   │                    │
│  └────────────────────┘                      │
│                                              │
│  Zvol (block device)                         │
│  ┌────────────────────┐                      │
│  │ Block layer interface │                   │
│  └────────────────────┘                      │
└──────────────────────────────────────────────┘
```

### Key Features

- **Pooled storage**: All devices contribute to a single pool
- **RAID-Z1/Z2/Z3**: Variable-width RAID with parity (1, 2, or 3 disk failures)
- **End-to-end checksums**: Every block checksummed; silent corruption detected and repaired
- **Copy-on-Write**: Transactional model ensures consistency
- **Snapshots and clones**: Instant, space-efficient
- **Transparent compression**: lz4 (default), zstd, gzip
- **Deduplication**: Inline or async dedup (memory-intensive)
- **Send/receive**: Efficient incremental replication
- **SLOG (ZFS Intent Log)**: Separate device for synchronous write acceleration
- **L2ARC**: Read cache on SSD
- **Adaptive Replacement Cache (ARC)**: Advanced read cache in RAM
- **ZFS on Linux (ZoL/OpenZFS)**: Available via DKMS or packaged modules

### Best Use Cases

- Enterprise storage servers
- NAS (TrueNAS, FreeNAS)
- Databases requiring data integrity
- Large-scale archival storage
- Virtual machine storage
- Backup targets
- Where data integrity is paramount

### Performance Characteristics

| Workload | Performance Rating |
|----------|-------------------|
| Small file I/O | ★★★★☆ |
| Large sequential I/O | ★★★★★ |
| Random read | ★★★★★ |
| Random write | ★★★★☆ |
| Metadata-heavy | ★★★★☆ |
| Concurrent I/O | ★★★★★ |

### Common Operations

```bash
# Create pool (single disk)
zpool create tank /dev/sdb

# Create mirror pool
zpool create tank mirror /dev/sdb /dev/sdc

# Create RAID-Z2 pool
zpool create tank raidz2 /dev/sd[b-g]

# Create dataset
zfs create tank/data

# Set compression
zfs set compression=zstd tank

# Create snapshot
zfs snapshot tank/data@snap1

# List snapshots
zfs list -t snapshot

# Rollback to snapshot
zfs rollback tank/data@snap1

# Send/receive
zfs send tank/data@snap1 | ssh remote zfs receive backup/data

# Show pool status
zpool status tank

# Scrub (integrity check)
zpool scrub tank

# Add SLOG
zpool add tank log /dev/nvme0n1

# Add L2ARC cache
zpool add tank cache /dev/nvme1n1

# Set ARC size limit
echo 8589934592 >> /sys/module/zfs/parameters/zfs_arc_max
```

### Important Notes

- **Memory requirements**: Minimum 1 GB RAM per 1 TB of storage (for dedup, much more)
- **License**: CDDL license; must install via package manager (not in mainline kernel)
- **Swap**: Cannot use ZFS zvol for swap by default
- **TRIM**: Supported but needs periodic `zpool trim`

---

## 6. F2FS (Flash-Friendly Filesystem)

### Design Philosophy

F2FS is a log-structured filesystem designed specifically for NAND flash memory (SSDs, eMMC, SD cards). It minimizes write amplification and considers flash storage characteristics.

### Architecture

```
┌──────────────────────────────────────────┐
│            F2FS Layout                   │
├──────┬──────┬──────┬─────────────────────┤
│ SB   │ CP   │ SIT  │ SSA  │ Main Area   │
│      │      │      │      │             │
│ Super│Check │Seg   │Seg   │ Segments    │
│ Block│point │Info  │Summ  │ containing  │
│      │      │Table │Area  │ 6 sections  │
│      │      │      │      │             │
└──────┴──────┴──────┴──────┴─────────────┘
         ↑                              ↑
         Recovery point           Node/DATA sections
```

### Key Features

- **Log-structured**: Writes sequentially to segments, reducing write amplification
- **Multi-head logging**: Separate logs for different data types (hot/warm/cold)
- **Adaptive logging**: Switches between normal and threaded logging based on free space
- **Garbage collection**: Background cleaning of invalidated blocks
- **Inline data**: Stores very small files directly in inode
- **Compression**: lz4 and zstd support
- **Atomic writes**: Support for atomic write operations
- **Roll-forward recovery**: Fast recovery after crash
- **Discard/TRIM**: Efficient handling of flash TRIM commands

### Best Use Cases

- SSDs and NVMe drives
- eMMC storage (Android devices)
- SD cards and USB flash drives
- Embedded systems with flash storage
- Where write amplification is a concern

### Performance Characteristics

| Workload | Performance Rating |
|----------|-------------------|
| Small file I/O | ★★★★★ |
| Large sequential I/O | ★★★★☆ |
| Random read | ★★★★☆ |
| Random write | ★★★★★ |
| Metadata-heavy | ★★★★☆ |
| Concurrent I/O | ★★★★☆ |

### Common Operations

```bash
# Create filesystem
mkfs.f2fs /dev/nvme0n1p1

# Mount with options
mount -o compress_algorithm=zstd,compress_log_size=2 /dev/nvme0n1p1 /mnt

# Enable discard
mount -o discard /dev/nvme0n1p1 /mnt

# Check filesystem
fsck.f2fs /dev/nvme0n1p1

# Defragment
defrag.f2fs /dev/nvme0n1p1

# Resize
resize.f2fs /dev/nvme0n1p1

# Show statistics
cat /sys/fs/f2fs/<device>/status
```

---

## 7. Filesystem Selection Guide

### Decision Matrix

| Requirement | Recommended | Runner-up |
|-------------|-------------|-----------|
| General purpose | ext4 | XFS |
| Large files (>1TB) | XFS | ZFS |
| Data integrity | ZFS | Btrfs |
| Snapshots | Btrfs | ZFS |
| NAS/Home server | ZFS | Btrfs |
| Desktop | ext4 | Btrfs |
| Database server | XFS | ZFS |
| SSD optimization | F2FS | ext4 |
| Embedded/flash | F2FS | ext4 |
| Maximum features | ZFS | Btrfs |
| Maximum stability | ext4 | XFS |
| RAID without mdadm | ZFS | Btrfs |
| Compression | ZFS | Btrfs |
| Enterprise storage | ZFS | XFS |

### Migration Between Filesystems

```bash
# Backup and restore (safest)
rsync -aHAXS --info=progress2 /source/ /backup/
mkfs.<new-fs> /dev/sda1
mount /dev/sda1 /mnt
rsync -aHAXS --info=progress2 /backup/ /mnt/

# In-place conversion (ext2/3 → ext4 only)
tune2fs -O extents,uninit_bg,dir_index,has_journal /dev/sda1
fsck.ext4 -f /dev/sda1
```

---

## 8. Benchmarking Filesystems

### Using `fio`

```bash
# Sequential write
fio --name=seqwrite --ioengine=libaio --direct=1 \
    --bs=1M --size=4G --numjobs=4 --runtime=60 \
    --rw=write --group_reporting

# Random read (4K)
fio --name=randread --ioengine=libaio --direct=1 \
    --bs=4k --size=1G --numjobs=8 --runtime=60 \
    --rw=randread --iodepth=32 --group_reporting

# Mixed random read/write
fio --name=mixed --ioengine=libaio --direct=1 \
    --bs=4k --size=1G --numjobs=4 --runtime=60 \
    --rw=randrw --rwmixread=70 --iodepth=16 --group_reporting

# Metadata operations
fio --name=meta --ioengine=libaio --direct=1 \
    --bs=4k --size=100M --numjobs=1 --runtime=60 \
    --rw=randread --directory=/mnt/test --nrfiles=10000 \
    --openfiles=64 --group_reporting
```

### Using `bonnie++`

```bash
bonnie++ -d /mnt/test -u root -r 4096 -s 8192
```

### Using `dbench`

```bash
dbench 16 -c /usr/share/dbench/client.txt -t 60 /mnt/test
```

---

*For the latest filesystem features and kernel support, consult the kernel documentation at https://www.kernel.org/doc/html/latest/filesystems/.*
