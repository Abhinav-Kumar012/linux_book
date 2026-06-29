# Appendix X: Performance Tuning Checklist

## Overview

This appendix provides a comprehensive performance tuning checklist for Linux systems, covering CPU, memory, I/O, and network optimization.

---

## 1. CPU Tuning

### CPU Governor

```bash
# Check current governor
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# Set performance governor (maximum speed)
for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    echo performance | sudo tee $cpu
done

# Set powersave governor (minimum power)
for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    echo powersave | sudo tee $cpu
done

# Set ondemand governor (dynamic)
for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    echo ondemand | sudo tee $cpu
done

# Make persistent (cpupower)
sudo cpupower frequency-set -g performance

# Check available governors
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors
```

### CPU Affinity

```bash
# Set CPU affinity for process
taskset -c 0,1 ./program

# Set for running process
taskset -pc 0,1 1234

# Check affinity
taskset -p 1234

# Using cpuset cgroup
sudo cgcreate -g cpuset:/mygroup
echo 0-3 | sudo tee /sys/fs/cgroup/cpuset/mygroup/cpuset.cpus
echo 0 | sudo tee /sys/fs/cgroup/cpuset/mygroup/cpuset.mems
echo 1234 | sudo tee /sys/fs/cgroup/cpuset/mygroup/tasks
```

### NUMA Optimization

```bash
# Show NUMA topology
numactl --hardware

# Bind process to NUMA node
numactl --cpunodebind=0 --membind=0 ./program

# Interleave memory across nodes
numactl --interleave=all ./program

# Show NUMA statistics
numastat
numastat -p 1234

# Show per-node memory
cat /sys/devices/system/node/node*/meminfo
```

### Process Priority

```bash
# Run with lower priority (higher nice value)
nice -n 10 ./program

# Change priority of running process
renice -n -5 -p 1234

# Real-time priority
chrt -f 50 ./program
chrt -r 50 ./program

# Set CPU bandwidth (cgroups)
sudo cgcreate -g cpu:/mygroup
echo 50000 | sudo tee /sys/fs/cgroup/cpu/mygroup/cpu.cfs_quota_us
echo 100000 | sudo tee /sys/fs/cgroup/cpu/mygroup/cpu.cfs_period_us
```

### CPU Monitoring

```bash
# CPU usage
top -bn1 | head -5
mpstat -P ALL 1

# Per-process CPU
pidstat 1

# CPU cache misses
perf stat -e cache-misses,cache-references ./program

# CPU frequency
cpupower frequency-info
watch -n 1 "cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq"
```

---

## 2. Memory Tuning

### Virtual Memory Settings

```bash
# /etc/sysctl.d/10-memory.conf

# Swappiness (0-100, lower = less swap)
vm.swappiness = 10

# Dirty page settings
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5
vm.dirty_expire_centisecs = 3000
vm.dirty_writeback_centisecs = 500

# Overcommit memory
vm.overcommit_memory = 0  # Heuristic (default)
vm.overcommit_ratio = 50

# VFS cache pressure
vm.vfs_cache_pressure = 50

# Minimum free memory
vm.min_free_kbytes = 65536

# Huge pages
vm.nr_hugepages = 1024

# Zone reclaim mode (NUMA)
vm.zone_reclaim_mode = 0

# Apply
sudo sysctl --system
```

### Transparent Huge Pages (THP)

```bash
# Check current setting
cat /sys/kernel/mm/transparent_hugepage/enabled

# Disable THP (recommended for databases)
echo never | sudo tee /sys/kernel/mm/transparent_hugepage/enabled
echo never | sudo tee /sys/kernel/mm/transparent_hugepage/defrag

# Enable THP
echo always | sudo tee /sys/kernel/mm/transparent_hugepage/enabled

# Make persistent (systemd)
# /etc/systemd/system/disable-thp.service
```

### Huge Pages Configuration

```bash
# Allocate huge pages
echo 1024 | sudo tee /proc/sys/vm/nr_hugepages

# Check huge page status
cat /proc/meminfo | grep -i huge

# Mount huge pages
sudo mount -t hugetlbfs nodev /dev/hugepages

# Per-group huge pages
echo 512 | sudo tee /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages

# Use in application (mmap)
# void *ptr = mmap(NULL, size, PROT_READ|PROT_WRITE,
#                  MAP_PRIVATE|MAP_ANONYMOUS|MAP_HUGETLB, -1, 0);
```

### Memory Limits (cgroups v2)

```bash
# Create cgroup
sudo mkdir /sys/fs/cgroup/mygroup

# Set memory limit
echo 2G | sudo tee /sys/fs/cgroup/mygroup/memory.max
echo 1G | sudo tee /sys/fs/cgroup/mygroup/memory.high

# Add process
echo 1234 | sudo tee /sys/fs/cgroup/mygroup/cgroup.procs

# Check memory usage
cat /sys/fs/cgroup/mygroup/memory.current
cat /sys/fs/cgroup/mygroup/memory.stat
```

### Memory Monitoring

```bash
# Memory overview
free -h
vmstat 1

# Detailed memory
cat /proc/meminfo

# Per-process memory
smem -t -k -s pss
ps aux --sort=-%mem | head -10

# Memory allocation profiling
perf record -e 'cycles:u' --call-graph dwarf ./program
perf report --sort symbol

# Page fault monitoring
perf stat -e page-faults,minor-faults,major-faults ./program

# Slab info
sudo cat /proc/slabinfo | sort -k3 -rn | head -20

# Memory fragmentation
cat /proc/buddyinfo
cat /proc/pagetypeinfo
```

---

## 3. I/O Tuning

### I/O Scheduler

```bash
# Check current scheduler
cat /sys/block/sda/queue/scheduler

# Set scheduler
echo mq-deadline | sudo tee /sys/block/sda/queue/scheduler
echo bfq | sudo tee /sys/block/sda/queue/scheduler
echo kyber | sudo tee /sys/block/sda/queue/scheduler
echo none | sudo tee /sys/block/sda/queue/scheduler  # NVMe

# Make persistent (udev)
# /etc/udev/rules.d/60-io-scheduler.rules
ACTION=="add|change", KERNEL=="sd*", ATTR{queue/scheduler}="mq-deadline"
ACTION=="add|change", KERNEL=="nvme*", ATTR{queue/scheduler}="none"
```

### Queue Parameters

```bash
# Queue depth
echo 256 | sudo tee /sys/block/sda/queue/nr_requests

# Read-ahead
echo 256 | sudo tee /sys/block/sda/queue/read_ahead_kb

# Max sectors
echo 1024 | sudo tee /sys/block/sda/queue/max_sectors_kb

# Disable merging (for SSDs)
echo none | sudo tee /sys/block/sda/queue/nomerges

# Rotational (SSD vs HDD)
echo 0 | sudo tee /sys/block/sda/queue/rotational  # SSD
echo 1 | sudo tee /sys/block/sda/queue/rotational  # HDD

# TRIM/Discard
echo 1 | sudo tee /sys/block/sda/queue/discard_max_bytes
```

### Filesystem Tuning

```bash
# ext4 tuning
# Mount options
mount -o noatime,nodiratime,data=writeback,barrier=0 /dev/sda1 /mnt

# Tune filesystem
tune2fs -o journal_data_writeback /dev/sda1
tune2fs -O dir_index /dev/sda1
tune2fs -m 1 /dev/sda1  # Reduce reserved space

# XFS tuning
mount -o noatime,logbufs=8,logbsize=256k,allocsize=64m /dev/sda1 /mnt

# Btrfs tuning
mount -o noatime,compress=zstd,ssd,discard=async /dev/sda1 /mnt
```

### I/O Priority

```bash
# Set I/O priority (ionice)
ionice -c 1 -n 0 ./program    # Real-time, highest
ionice -c 2 -n 0 ./program    # Best-effort, highest
ionice -c 3 ./program          # Idle

# Set for running process
ionice -p 1234 -c 2 -n 5

# Check I/O priority
ionice -p 1234

# Using cgroups
sudo cgcreate -g blkio:/mygroup
echo "8:0 1048576" | sudo tee /sys/fs/cgroup/blkio/mygroup/blkio.throttle.read_bps_device
```

### I/O Monitoring

```bash
# I/O statistics
iostat -xz 1

# Per-process I/O
iotop -oP

# Block I/O tracing
biolatency 10 1
biosnoop

# I/O latency histogram
perf stat -e block:block_rq_issue -- sleep 10

# Disk utilization
iostat -xd 1

# Filesystem cache hit ratio
cachestat 1

# Count I/O operations
perf stat -e block:block_rq_complete -- sleep 10
```

---

## 4. Network Tuning

### TCP/IP Stack Tuning

```bash
# /etc/sysctl.d/10-network-performance.conf

# === Socket Buffer Sizes ===
# Maximum socket send buffer
net.core.wmem_max = 16777216

# Maximum socket receive buffer
net.core.rmem_max = 16777216

# Default socket send buffer
net.core.wmem_default = 1048576

# Default socket receive buffer
net.core.rmem_default = 1048576

# === TCP Buffer Sizes (min, default, max) ===
net.ipv4.tcp_rmem = 4096 1048576 16777216
net.ipv4.tcp_wmem = 4096 1048576 16777216

# === Connection Backlog ===
net.core.somaxconn = 65535
net.core.netdev_max_backlog = 65535
net.ipv4.tcp_max_syn_backlog = 65535

# === TCP Keepalive ===
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_intvl = 60
net.ipv4.tcp_keepalive_probes = 3

# === TCP Connection Reuse ===
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 15

# === TCP Fast Open ===
net.ipv4.tcp_fastopen = 3

# === TCP Window Scaling ===
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_sack = 1

# === Congestion Control ===
net.ipv4.tcp_congestion_control = bbr
net.core.default_qdisc = fq

# === Ephemeral Ports ===
net.ipv4.ip_local_port_range = 1024 65535

# === TCP Memory ===
net.ipv4.tcp_mem = 786432 1048576 1572864
net.ipv4.tcp_max_orphans = 16384

# === UDP ===
net.ipv4.udp_mem = 65536 131072 262144

# Apply
sudo sysctl --system
```

### BBR Congestion Control

```bash
# Check available congestion control
sysctl net.ipv4.tcp_available_congestion_control

# Load BBR module
sudo modprobe tcp_bbr

# Set BBR
echo bbr | sudo tee /proc/sys/net/ipv4/tcp_congestion_control
echo fq | sudo tee /proc/sys/net/core/default_qdisc

# Verify
sysctl net.ipv4.tcp_congestion_control

# Make persistent
echo "tcp_bbr" | sudo tee /etc/modules-load.d/bbr.conf
```

### Network Interface Tuning

```bash
# Increase ring buffer
ethtool -g eth0
ethtool -G eth0 rx 4096 tx 4096

# Enable offloading
ethtool -K eth0 tso on
ethtool -K eth0 gro on
ethtool -K eth0 gso on
ethtool -K eth0 lro on

# Increase TX queue length
ip link set eth0 txqueuelen 10000

# Set MTU (jumbo frames)
ip link set eth0 mtu 9000

# Check offloading status
ethtool -k eth0

# RSS (Receive Side Scaling)
ethtool -l eth0
ethtool -L eth0 combined 8

# Interrupt coalescing
ethtool -c eth0
ethtool -C eth0 rx-usecs 50 tx-usecs 50
```

### Network Monitoring

```bash
# Network throughput
iftop -n
nload eth0

# Connection statistics
ss -s
ss -tnp

# TCP retransmissions
netstat -s | grep retransmit
nstat -z | grep Retrans

# Packet drops
ethtool -S eth0 | grep drop
cat /proc/net/dev

# Network latency
ping -c 100 gateway
mtr -n gateway

# Bandwidth test
iperf3 -s  # Server
iperf3 -c server_ip  # Client
```

---

## 5. Disk and Filesystem Tuning

### SSD Optimization

```bash
# Enable TRIM (periodic)
sudo systemctl enable fstrim.timer

# Manual TRIM
sudo fstrim -v /

# Mount options for SSD
mount -o noatime,discard /dev/nvme0n1p1 /mnt

# I/O scheduler for SSD
echo none | sudo tee /sys/block/nvme0n1/queue/scheduler

# Disable swap (if enough RAM)
sudo swapoff -a
```

### RAID Optimization

```bash
# RAID stripe cache
echo 32768 | sudo tee /sys/block/md0/md/stripe_cache_size

# RAID read-ahead
sudo blockdev --setra 65536 /dev/md0

# RAID speed limits
echo 200000 | sudo tee /proc/sys/dev/raid/speed_limit_min
echo 500000 | sudo tee /proc/sys/dev/raid/speed_limit_max
```

### LVM Optimization

```bash
# Read-ahead
sudo lvchange --readahead 256 /dev/vg0/lv0

# Stripe alignment
lvcreate -L 100G -n lv0 --stripes 4 --stripesize 256K vg0
```

---

## 6. Application-Level Tuning

### Database Tuning (PostgreSQL)

```bash
# postgresql.conf
shared_buffers = 4GB          # 25% of RAM
effective_cache_size = 12GB   # 75% of RAM
work_mem = 256MB
maintenance_work_mem = 1GB
wal_buffers = 64MB
checkpoint_completion_target = 0.9
random_page_cost = 1.1        # For SSDs
effective_io_concurrency = 200 # For SSDs
max_connections = 200
```

### Web Server Tuning (Nginx)

```bash
# nginx.conf
worker_processes auto;
worker_cpu_affinity auto;
worker_rlimit_nofile 65535;

events {
    worker_connections 65535;
    use epoll;
    multi_accept on;
}

http {
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    keepalive_requests 1000;

    # Buffers
    client_body_buffer_size 16K;
    client_header_buffer_size 1k;
    client_max_body_size 8m;
    large_client_header_buffers 4 8k;

    # Compression
    gzip on;
    gzip_comp_level 5;
    gzip_min_length 256;

    # Caching
    open_file_cache max=10000 inactive=60s;
    open_file_cache_valid 60s;
    open_file_cache_min_uses 2;
    open_file_cache_errors on;
}
```

---

## 7. Performance Monitoring Tools

### System Overview

```bash
# CPU, memory, I/O, network
dstat
glances
nmon

# Detailed system stats
sar -u 1 10    # CPU
sar -r 1 10    # Memory
sar -d 1 10    # Disk
sar -n DEV 1 10  # Network
```

### CPU Profiling

```bash
# CPU usage by process
top -bn1 -o %CPU | head -20
pidstat 1

# CPU cache and branch misses
perf stat -e cycles,instructions,cache-misses,branch-misses ./program

# CPU flame graph
perf record -g -F 99 ./program
perf script | stackcollapse-perf.pl | flamegraph.pl > cpu.svg
```

### Memory Profiling

```bash
# Memory usage
free -h
vmstat 1

# Per-process memory
smem -t -k -s pss
ps aux --sort=-%mem | head -20

# Memory leaks
valgrind --leak-check=full ./program

# Memory flame graph
perf record -e 'cycles:u' --call-graph dwarf -g ./program
perf script | stackcollapse-perf.pl | flamegraph.pl > mem.svg
```

### I/O Profiling

```bash
# I/O statistics
iostat -xz 1
iotop -oP

# I/O latency
biolatency 10 1

# I/O flame graph
perf record -e block:block_rq_issue -a -g sleep 10
perf script | stackcollapse-perf.pl | flamegraph.pl > io.svg
```

### Network Profiling

```bash
# Network throughput
iftop -n
nload eth0

# TCP analysis
ss -tnp
nstat | grep -i retrans

# Packet capture
tcpdump -i eth0 -w capture.pcap
```

---

## 8. Benchmarking

### CPU Benchmarking

```bash
# sysbench CPU
sysbench cpu --threads=$(nproc) --time=60 run

# stress-ng
stress-ng --cpu $(nproc) --timeout 60s --metrics

# dd (simple)
dd if=/dev/zero of=/dev/null bs=1M count=10000
```

### Memory Benchmarking

```bash
# sysbench memory
sysbench memory --threads=$(nproc) --time=60 run

# stress-ng memory
stress-ng --vm 2 --vm-bytes 1G --timeout 60s

# STREAM benchmark
./stream
```

### Disk Benchmarking

```bash
# fio sequential write
fio --name=seqwrite --ioengine=libaio --direct=1 \
    --bs=1M --size=4G --numjobs=4 --runtime=60 \
    --rw=write --group_reporting

# fio random read
fio --name=randread --ioengine=libaio --direct=1 \
    --bs=4k --size=1G --numjobs=8 --runtime=60 \
    --rw=randread --iodepth=32 --group_reporting

# fio mixed workload
fio --name=mixed --ioengine=libaio --direct=1 \
    --bs=4k --size=1G --numjobs=4 --runtime=60 \
    --rw=randrw --rwmixread=70 --iodepth=16 --group_reporting

# hdparm
sudo hdparm -Tt /dev/sda
```

### Network Benchmarking

```bash
# iperf3
iperf3 -s                    # Server
iperf3 -c server_ip          # Client (TCP)
iperf3 -c server_ip -u -b 1G  # Client (UDP)

# netperf
netperf -H server_ip -t TCP_RR  # Request/response
netperf -H server_ip -t TCP_STREAM  # Throughput

# ping latency
ping -c 1000 server_ip
```

---

## 9. Checklist Summary

### CPU

- [ ] Set appropriate CPU governor
- [ ] Configure NUMA for multi-socket systems
- [ ] Set process CPU affinity for critical workloads
- [ ] Use cgroups for CPU bandwidth limiting
- [ ] Monitor CPU cache misses and branch mispredictions

### Memory

- [ ] Set swappiness appropriately (low for databases)
- [ ] Configure dirty page ratios
- [ ] Enable/disable THP based on workload
- [ ] Configure huge pages for large memory applications
- [ ] Set memory limits with cgroups
- [ ] Monitor page faults and memory fragmentation

### I/O

- [ ] Set appropriate I/O scheduler per device type
- [ ] Configure queue depth and read-ahead
- [ ] Optimize filesystem mount options
- [ ] Enable TRIM for SSDs
- [ ] Monitor I/O latency and utilization

### Network

- [ ] Tune TCP buffer sizes
- [ ] Enable BBR congestion control
- [ ] Configure connection backlog
- [ ] Set TCP keepalive parameters
- [ ] Optimize network interface offloading
- [ ] Monitor retransmissions and drops

---

*For detailed performance analysis, use `perf`, `bpftrace`, and the BCC tools suite. See Brendan Gregg's performance tools map at https://www.brendangregg.com/linuxperf.html.*
