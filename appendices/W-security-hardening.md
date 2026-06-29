# Appendix W: Security Hardening Checklist

## Overview

This appendix provides a comprehensive security hardening checklist for Linux systems, covering kernel, network, filesystem, and service hardening.

---

## 1. Kernel Hardening

### sysctl Parameters

```bash
# /etc/sysctl.d/99-security.conf

# === Network Security ===
# Disable IP forwarding (unless router)
net.ipv4.ip_forward = 0
net.ipv6.conf.all.forwarding = 0

# Disable source routing
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0

# Disable ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv6.conf.all.accept_redirects = 0

# Enable SYN flood protection
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 5

# Disable ICMP broadcast responses
net.ipv4.icmp_echo_ignore_broadcasts = 1

# Ignore bogus ICMP errors
net.ipv4.icmp_ignore_bogus_error_responses = 1

# Enable reverse path filtering
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# Log Martian packets
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1

# Disable IPv6 router advertisements
net.ipv6.conf.all.accept_ra = 0
net.ipv6.conf.default.accept_ra = 0

# === Memory Protection ===
# Restrict kernel pointer leaks
kernel.kptr_restrict = 2

# Restrict dmesg access
kernel.dmesg_restrict = 1

# Restrict kernel profiling
kernel.perf_event_paranoid = 3

# Enable ASLR (full randomization)
kernel.randomize_va_space = 2

# Restrict ptrace
kernel.yama.ptrace_scope = 2

# Restrict core dumps
fs.suid_dumpable = 0

# Restrict unprivileged user namespaces
kernel.unprivileged_userns_clone = 0

# Restrict unprivileged BPF
kernel.unprivileged_bpf_disabled = 1

# Harden BPF JIT
net.core.bpf_jit_harden = 2

# Restrict userfaultfd
vm.unprivileged_userfaultfd = 0

# Restrict perf_event_open
kernel.perf_event_paranoid = 3

# Enable address space layout randomization
kernel.randomize_va_space = 2

# Restrict loading of TTY line disciplines
dev.tty.ldisc_autoload = 0

# Disable SysRq key
kernel.sysrq = 0

# Restrict kernel log access
kernel.dmesg_restrict = 1

# Restrict eBPF
kernel.unprivileged_bpf_disabled = 1
net.core.bpf_jit_harden = 2
```

### Apply sysctl

```bash
# Apply all
sudo sysctl --system

# Apply specific file
sudo sysctl -p /etc/sysctl.d/99-security.conf

# Check specific value
sysctl kernel.randomize_va_space
```

### Kernel Module Blacklisting

```bash
# /etc/modprobe.d/blacklist-security.conf
# Disable uncommon filesystems
blacklist cramfs
blacklist freevxfs
blacklist hfs
blacklist hfsplus
blacklist jffs2
blacklist squashfs
blacklist udf

# Disable uncommon network protocols
blacklist dccp
blacklist sctp
blacklist rds
blacklist tipc

# Disable USB storage (if not needed)
blacklist usb-storage

# Disable firewire
blacklist firewire-core
blacklist firewire-ohci
blacklist firewire-sbp2

# Disable uncommon drivers
blacklist bluetooth
blacklist bnep
blacklist btusb

# Disable uncommon character devices
blacklist pcspkr
```

### Kernel Boot Parameters

```bash
# /etc/default/grub
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"
GRUB_CMDLINE_LINUX="apparmor=1 security=apparmor slab_nomerge init_on_alloc=1 init_on_free=1 page_alloc.shuffle=1 pti=on randomize_kstack_offset=on vsyscall=none debugfs=off oops=panic"

# Apply
sudo update-grub
```

### Kernel Parameter Explanation

| Parameter | Description |
|-----------|-------------|
| `apparmor=1` | Enable AppArmor |
| `slab_nomerge` | Prevent slab cache merging |
| `init_on_alloc=1` | Zero memory on allocation |
| `init_on_free=1` | Zero memory on free |
| `page_alloc.shuffle=1` | Shuffle page allocator |
| `pti=on` | Page Table Isolation (Meltdown) |
| `randomize_kstack_offset=on` | Randomize kernel stack |
| `vsyscall=none` | Disable vsyscall |
| `debugfs=off` | Disable debugfs |
| `oops=panic` | Panic on oops |

---

## 2. Network Hardening

### Firewall (iptables)

```bash
#!/bin/bash
# Firewall setup script

# Flush existing rules
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X

# Default policies
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Allow loopback
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Allow established connections
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Drop invalid packets
iptables -A INPUT -m conntrack --ctstate INVALID -j DROP

# Allow SSH (rate limited)
iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW \
    -m recent --set --name SSH
iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW \
    -m recent --update --seconds 60 --hitcount 4 --name SSH -j DROP
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# Allow HTTP/HTTPS
iptables -A INPUT -p tcp -m multiport --dports 80,443 -j ACCEPT

# Allow ICMP (ping) with rate limit
iptables -A INPUT -p icmp --icmp-type echo-request \
    -m limit --limit 1/s --limit-burst 4 -j ACCEPT

# Log dropped packets
iptables -A INPUT -j LOG --log-prefix "IPT-DROP: " --log-level 4

# Drop everything else
iptables -A INPUT -j DROP

# Save rules
iptables-save > /etc/iptables/rules.v4
```

### SSH Hardening

```bash
# /etc/ssh/sshd_config

# Protocol and listening
Port 22
Protocol 2
AddressFamily inet  # IPv4 only (or inet6 or any)

# Authentication
PermitRootLogin no
MaxAuthTries 3
PubkeyAuthentication yes
PasswordAuthentication no
PermitEmptyPasswords no
ChallengeResponseAuthentication no
UsePAM yes

# Authorization
AllowUsers admin deploy
AllowGroups ssh-users
DenyUsers root

# Session
LoginGraceTime 60
ClientAliveInterval 300
ClientAliveCountMax 2
MaxSessions 2
MaxStartups 10:30:60

# Forwarding
X11Forwarding no
AllowTcpForwarding no
AllowAgentForwarding no
PermitTunnel no

# Logging
LogLevel VERBOSE
SyslogFacility AUTH

# Security
StrictModes yes
IgnoreRhosts yes
HostbasedAuthentication no

# Cryptography (modern)
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com
HostKeyAlgorithms ssh-ed25519,ssh-rsa

# Banner
Banner /etc/ssh/banner
```

### Network Interface Hardening

```bash
# /etc/sysctl.d/10-network-security.conf

# Disable unused network interfaces
# ip link set eth1 down

# Enable TCP SYN cookies
net.ipv4.tcp_syncookies = 1

# Disable IP forwarding
net.ipv4.ip_forward = 0

# Enable strict reverse path filtering
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# Log Martian packets
net.ipv4.conf.all.log_martians = 1
```

---

## 3. Filesystem Hardening

### Mount Options

```bash
# /etc/fstab

# Root filesystem
UUID=xxx  /  ext4  errors=remount-ro,ro  0 1

# /tmp (noexec, nosuid, nodev)
tmpfs  /tmp  tmpfs  defaults,noexec,nosuid,nodev,size=2G  0 0

# /var/tmp
tmpfs  /var/tmp  tmpfs  defaults,noexec,nosuid,nodev,size=1G  0 0

# /home (nosuid)
UUID=xxx  /home  ext4  defaults,nosuid  0 2

# /var (separate partition)
UUID=xxx  /var  ext4  defaults,nosuid  0 2

# /var/log (separate partition)
UUID=xxx  /var/log  ext4  defaults,nosuid,nodev  0 2

# /var/log/audit (separate partition)
UUID=xxx  /var/log/audit  ext4  defaults,nosuid,nodev,noexec  0 2

# /boot (read-only)
UUID=xxx  /boot  ext4  defaults,ro  0 2

# Disable core dumps
*  hard  core  0
```

### File Permissions

```bash
# Restrict critical files
chmod 600 /etc/shadow
chmod 600 /etc/gshadow
chmod 644 /etc/passwd
chmod 644 /etc/group
chmod 600 /etc/ssh/sshd_config
chmod 700 /root
chmod 600 /boot/grub/grub.cfg

# Restrict cron
chmod 600 /etc/crontab
chmod 700 /etc/cron.d
chmod 700 /etc/cron.daily
chmod 700 /etc/cron.hourly
chmod 700 /etc/cron.monthly
chmod 700 /etc/cron.weekly

# Set sticky bit on world-writable directories
chmod 1777 /tmp
chmod 1777 /var/tmp

# Remove world-writable from system directories
chmod o-w /usr/local
chmod o-w /opt

# Find world-writable files
find / -xdev -type f -perm -0002 -exec chmod o-w {} \;

# Find SUID/SGID files
find / -xdev -type f \( -perm -4000 -o -perm -2000 \) -exec ls -la {} \;

# Remove unnecessary SUID/SGID
chmod u-s /usr/bin/unnecessary_suid_binary
```

### Disk Encryption

```bash
# LUKS encryption
sudo cryptsetup luksFormat /dev/sdb1
sudo cryptsetup luksOpen /dev/sdb1 encrypted_vol
sudo mkfs.ext4 /dev/mapper/encrypted_vol
sudo mount /dev/mapper/encrypted_vol /mnt/encrypted

# /etc/crypttab
encrypted_vol  UUID=xxx  none  luks,discard

# Full disk encryption (during install)
# Use LVM on LUKS
```

---

## 4. Service Hardening

### systemd Service Hardening

```ini
# /etc/systemd/system/myapp.service
[Unit]
Description=My Application
After=network-online.target

[Service]
Type=simple
User=myapp
Group=myapp
WorkingDirectory=/opt/myapp

# Filesystem restrictions
ProtectSystem=strict
ProtectHome=yes
PrivateTmp=yes
PrivateDevices=yes
ProtectKernelTunables=yes
ProtectKernelModules=yes
ProtectKernelLogs=yes
ProtectControlGroups=yes
ProtectClock=yes
ProtectHostname=yes

# Capability restrictions
CapabilityBoundingSet=
NoNewPrivileges=yes

# Network restrictions
RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX
IPAddressDeny=any
IPAddressAllow=127.0.0.0/8 10.0.0.0/8

# System call restrictions
SystemCallFilter=@system-service
SystemCallArchitectures=native
SystemCallErrorNumber=EPERM

# Resource limits
MemoryMax=512M
CPUQuota=50%
TasksMax=64
LimitNOFILE=1024

# Logging
StandardOutput=journal
StandardError=journal

ExecStart=/opt/myapp/bin/server

[Install]
WantedBy=multi-user.target
```

### AppArmor Profile

```bash
# /etc/apparmor.d/usr.bin.myapp
#include <tunables/global>

/usr/bin/myapp {
  #include <abstractions/base>
  #include <abstractions/nameservice>

  # Deny everything by default
  deny /** rw,

  # Allow reading config
  /etc/myapp/** r,

  # Allow writing to log
  /var/log/myapp/** w,

  # Allow reading data
  /var/lib/myapp/** r,

  # Allow network
  network inet stream,
  network inet dgram,

  # Capabilities
  capability net_bind_service,
}
```

```bash
# Load profile
sudo apparmor_parser -r /etc/apparmor.d/usr.bin.myapp

# Set to enforce
sudo aa-enforce /usr/bin/myapp

# Set to complain
sudo aa-complain /usr/bin/myapp

# Check status
sudo aa-status
```

### SELinux

```bash
# Check status
sestatus

# Set mode
sudo setenforce 1    # Enforcing
sudo setenforce 0    # Permissive

# /etc/selinux/config
SELINUX=enforcing
SELINUXTYPE=targeted

# List contexts
ls -Z /var/www/html/
ps -eZ | grep httpd

# Restore context
sudo restorecon -Rv /var/www/html/

# Boolean settings
getsebool -a | grep httpd
sudo setsebool -P httpd_can_network_connect on

# Generate policy
sudo audit2allow -a -M myapp
sudo semodule -i myapp.pp
```

---

## 5. Authentication Hardening

### PAM Configuration

```bash
# /etc/pam.d/common-auth (Debian/Ubuntu)
# Enforce strong passwords
password requisite pam_pwquality.so retry=3 minlen=12 dcredit=-1 ucredit=-1 lcredit=-1 ocredit=-1

# Account lockout
auth required pam_tally2.so deny=5 onerr=fail unlock_time=900

# /etc/pam.d/common-password (Debian/Ubuntu)
password requisite pam_pwquality.so retry=3
password sufficient pam_unix.so sha512 shadow use_authtok
password required pam_deny.so

# /etc/security/pwquality.conf
minlen = 12
dcredit = -1
ucredit = -1
lcredit = -1
ocredit = -1
maxrepeat = 3
maxclassrepeat = 4
gecoscheck = 1
dictcheck = 1
usercheck = 1
enforcing = 1
retry = 3
```

### Password Policy

```bash
# /etc/login.defs
PASS_MAX_DAYS   90
PASS_MIN_DAYS   7
PASS_MIN_LEN    12
PASS_WARN_AGE   14
LOGIN_RETRIES   3
LOGIN_TIMEOUT   60

# Set for existing users
sudo chage -M 90 -m 7 -W 14 username
sudo chage -l username
```

### Sudo Hardening

```bash
# /etc/sudoers.d/security
# Require password
Defaults    timestamp_timeout=0

# Log sudo commands
Defaults    logfile="/var/log/sudo.log"
Defaults    log_input, log_output

# Restrict env
Defaults    env_reset
Defaults    env_keep += "LANG LC_ALL TERM"

# Limit commands
Cmnd_Alias DANGEROUS = /usr/bin/su, /usr/bin/passwd, /usr/sbin/visudo
admin ALL=(ALL:ALL) ALL, !DANGEROUS

# Require specific users
Defaults:deploy !authenticate
deploy ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart myapp
```

---

## 6. Audit and Monitoring

### auditd Configuration

```bash
# /etc/audit/rules.d/hardening.rules

# Monitor authentication
-w /etc/passwd -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/group -p wa -k identity
-w /etc/gshadow -p wa -k identity
-w /etc/sudoers -p wa -k sudoers

# Monitor SSH
-w /etc/ssh/sshd_config -p wa -k sshd_config

# Monitor cron
-w /etc/crontab -p wa -k cron
-w /etc/cron.d/ -p wa -k cron
-w /var/spool/cron/ -p wa -k cron

# Monitor system calls
-a always,exit -F arch=b64 -S execve -k exec
-a always,exit -F arch=b64 -S connect -k network
-a always,exit -F arch=b64 -S open -F exit=-EACCES -k access
-a always,exit -F arch=b64 -S open -F exit=-EPERM -k access

# Monitor privileged commands
-a always,exit -F path=/usr/bin/sudo -F perm=x -k privileged
-a always,exit -F path=/usr/bin/su -F perm=x -k privileged
-a always,exit -F path=/usr/bin/passwd -F perm=x -k privileged

# Monitor file deletion
-a always,exit -F arch=b64 -S unlink -S unlinkat -S rename -S renameat -k delete

# Make audit config immutable (requires reboot to change)
-e 2
```

```bash
# Load rules
sudo augenrules --load

# Search logs
sudo ausearch -k identity
sudo ausearch -k sudoers
sudo ausearch -m USER_LOGIN

# Generate report
sudo aureport
sudo aureport --login
sudo aureport --auth
```

### Log Monitoring

```bash
# /etc/rsyslog.d/security.conf
auth,authpriv.*    /var/log/auth.log
*.*;auth,authpriv.none    /var/log/syslog
kern.*    /var/log/kern.log

# Log rotation
# /etc/logrotate.d/security
/var/log/auth.log {
    weekly
    rotate 52
    compress
    delaycompress
    missingok
    notifempty
    create 640 root adm
}
```

---

## 7. Security Scanning

### Lynis (Security Auditing)

```bash
# Install
sudo apt install lynis

# Run audit
sudo lynis audit system

# Show warnings
sudo lynis audit system | grep "Warning"

# Show suggestions
sudo lynis audit system | grep "Suggestion"
```

### ClamAV (Antivirus)

```bash
# Install
sudo apt install clamav

# Update signatures
sudo freshclam

# Scan system
sudo clamscan -r /home

# Scan and remove infected
sudo clamscan -r --remove /home

# Scan with log
sudo clamscan -r -l /var/log/clamav.log /home
```

---

## 8. Checklist Summary

### Kernel

- [ ] Enable ASLR (`randomize_va_space = 2`)
- [ ] Restrict ptrace (`yama.ptrace_scope = 2`)
- [ ] Restrict dmesg access (`dmesg_restrict = 1`)
- [ ] Restrict kernel pointers (`kptr_restrict = 2`)
- [ ] Disable SysRq (`sysrq = 0`)
- [ ] Blacklist unused modules
- [ ] Enable kernel hardening boot params

### Network

- [ ] Configure firewall (default deny)
- [ ] Enable SYN cookies
- [ ] Disable source routing
- [ ] Enable reverse path filtering
- [ ] Rate-limit SSH connections
- [ ] Disable unused network services
- [ ] Configure SSH hardening

### Filesystem

- [ ] Set proper mount options (noexec, nosuid, nodev)
- [ ] Set restrictive permissions on critical files
- [ ] Enable disk encryption
- [ ] Remove unnecessary SUID/SGID binaries
- [ ] Set sticky bit on /tmp

### Services

- [ ] Apply systemd hardening to services
- [ ] Configure AppArmor/SELinux profiles
- [ ] Run services as non-root
- [ ] Minimize installed packages
- [ ] Disable unused services

### Authentication

- [ ] Enforce strong passwords
- [ ] Set password expiration
- [ ] Configure account lockout
- [ ] Harden sudo configuration
- [ ] Use SSH keys (disable passwords)
- [ ] Enable 2FA where possible

### Monitoring

- [ ] Configure auditd
- [ ] Monitor auth logs
- [ ] Set up log rotation
- [ ] Run regular security scans
- [ ] Monitor for SUID changes

---

*For more security guidance, see the CIS Benchmarks (https://www.cisecurity.org/cis-benchmarks/) and the NSA Hardening Guides.*
