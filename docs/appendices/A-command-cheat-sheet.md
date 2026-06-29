# Appendix A: Linux Command Cheat Sheet

## Overview

This appendix provides a categorized quick reference of essential Linux commands. Commands are grouped by function with brief descriptions and common usage patterns.

---

## 1. File and Directory Operations

### Navigation and Listing

| Command | Description | Example |
|---------|-------------|---------|
| `ls` | List directory contents | `ls -lah /etc` |
| `cd` | Change directory | `cd /var/log` |
| `pwd` | Print working directory | `pwd` |
| `tree` | Display directory tree | `tree -L 2 /home` |
| `find` | Search for files | `find / -name "*.conf" -type f` |
| `locate` | Find files by name (database) | `locate -i kernel` |
| `which` | Locate a command | `which python3` |
| `whereis` | Locate binary, source, man page | `whereis gcc` |
| `file` | Determine file type | `file /bin/ls` |
| `stat` | Display file status | `stat /etc/passwd` |

### Creating and Deleting

| Command | Description | Example |
|---------|-------------|---------|
| `touch` | Create empty file / update timestamp | `touch newfile.txt` |
| `mkdir` | Create directory | `mkdir -p /tmp/a/b/c` |
| `cp` | Copy files/directories | `cp -r src/ dest/` |
| `mv` | Move/rename files | `mv old.txt new.txt` |
| `rm` | Remove files | `rm -rf /tmp/junk` |
| `ln` | Create links | `ln -s /usr/bin/python3 /usr/bin/python` |
| `install` | Copy with permissions | `install -m 755 script.sh /usr/local/bin/` |
| `mktemp` | Create temporary file | `mktemp /tmp/tmp.XXXXXX` |

### Permissions and Ownership

| Command | Description | Example |
|---------|-------------|---------|
| `chmod` | Change file permissions | `chmod 755 script.sh` |
| `chown` | Change file ownership | `chown user:group file` |
| `chgrp` | Change group ownership | `chgrp developers file` |
| `umask` | Set default permissions mask | `umask 022` |
| `getfacl` | Get file ACL | `getfacl /srv/data` |
| `setfacl` | Set file ACL | `setfacl -m u:john:rw file` |

### Viewing Files

| Command | Description | Example |
|---------|-------------|---------|
| `cat` | Concatenate and display | `cat /etc/hostname` |
| `less` | View file with pagination | `less /var/log/syslog` |
| `more` | View file page by page | `more largefile.txt` |
| `head` | Display first lines | `head -n 20 /etc/passwd` |
| `tail` | Display last lines | `tail -f /var/log/syslog` |
| `wc` | Count lines, words, chars | `wc -l /etc/passwd` |
| `od` | Octal dump | `od -x /bin/ls` |
| `hexdump` | Hex dump | `hexdump -C file.bin` |
| `xxd` | Hex dump (vim) | `xxd file.bin | head` |

### Compression and Archiving

| Command | Description | Example |
|---------|-------------|---------|
| `tar` | Archive files | `tar czf archive.tar.gz dir/` |
| `gzip` | Compress with gzip | `gzip file.txt` |
| `gunzip` | Decompress gzip | `gunzip file.txt.gz` |
| `bzip2` | Compress with bzip2 | `bzip2 file.txt` |
| `xz` | Compress with xz | `xz -9 file.txt` |
| `zip` | Create zip archive | `zip -r archive.zip dir/` |
| `unzip` | Extract zip archive | `unzip archive.zip` |
| `zcat` | View gzipped file | `zcat file.gz` |
| `zgrep` | Search in gzipped files | `zgrep "error" log.gz` |

---

## 2. Text Processing

### Searching and Filtering

| Command | Description | Example |
|---------|-------------|---------|
| `grep` | Search text patterns | `grep -rn "TODO" src/` |
| `egrep` / `grep -E` | Extended regex search | `grep -E "error|fail" log` |
| `fgrep` / `grep -F` | Fixed string search | `grep -F "192.168.1.1" log` |
| `ag` | The Silver Searcher (fast grep) | `ag "pattern" src/` |
| `rg` | ripgrep (fastest grep) | `rg "pattern" src/` |

### Text Transformation

| Command | Description | Example |
|---------|-------------|---------|
| `sed` | Stream editor | `sed -i 's/old/new/g' file` |
| `awk` | Pattern scanning/processing | `awk -F: '{print $1}' /etc/passwd` |
| `cut` | Extract columns | `cut -d: -f1,3 /etc/passwd` |
| `tr` | Translate/delete characters | `tr 'a-z' 'A-Z' < file` |
| `sort` | Sort lines | `sort -t: -k3 -n /etc/passwd` |
| `uniq` | Remove duplicate lines | `sort file | uniq -c` |
| `paste` | Merge lines | `paste file1 file2` |
| `join` | Join lines on common field | `join -t: file1 file2` |
| `column` | Format as columns | `mount | column -t` |
| `fmt` | Reformat paragraphs | `fmt -w 72 file.txt` |
| `pr` | Format for printing | `pr -l 60 file.txt` |
| `expand` | Convert tabs to spaces | `expand -t 4 file.txt` |
| `unexpand` | Convert spaces to tabs | `unexpand -t 4 file.txt` |
| `tee` | Read stdin, write to stdout and file | `cmd | tee output.log` |
| `xargs` | Build command lines from stdin | `find . -name "*.o" | xargs rm` |
| `basename` | Strip directory prefix | `basename /usr/bin/ls` |
| `dirname` | Strip filename | `dirname /usr/bin/ls` |

### Comparing Files

| Command | Description | Example |
|---------|-------------|---------|
| `diff` | Compare files line by line | `diff file1 file2` |
| `diff3` | Three-way diff | `diff3 mine base yours` |
| `comm` | Compare sorted files | `comm -23 file1 file2` |
| `cmp` | Compare files byte by byte | `cmp file1 file2` |
| `md5sum` | Compute MD5 hash | `md5sum file.iso` |
| `sha256sum` | Compute SHA-256 hash | `sha256sum file.iso` |

---

## 3. Networking

### Configuration

| Command | Description | Example |
|---------|-------------|---------|
| `ip addr` | Show/manipulate addresses | `ip addr show eth0` |
| `ip link` | Show/manipulate interfaces | `ip link set eth0 up` |
| `ip route` | Show/manipulate routes | `ip route show` |
| `ip neigh` | Show ARP/NDP table | `ip neigh show` |
| `nmcli` | NetworkManager CLI | `nmcli dev status` |
| `ethtool` | Query network interface | `ethtool eth0` |
| `iwconfig` | Configure wireless | `iwconfig wlan0` |
| `brctl` | Bridge management | `brctl show` |

### Diagnostics

| Command | Description | Example |
|---------|-------------|---------|
| `ping` | Test connectivity | `ping -c 4 8.8.8.8` |
| `traceroute` | Trace packet route | `traceroute google.com` |
| `mtr` | Combines ping + traceroute | `mtr google.com` |
| `nslookup` | DNS lookup | `nslookup google.com` |
| `dig` | DNS lookup (advanced) | `dig +short google.com` |
| `host` | DNS lookup (simple) | `host google.com` |
| `whois` | Domain registration info | `whois google.com` |
| `ss` | Socket statistics | `ss -tlnp` |
| `netstat` | Network statistics | `netstat -tlnp` |
| `lsof -i` | List open network files | `lsof -i :80` |

### Transfer

| Command | Description | Example |
|---------|-------------|---------|
| `curl` | Transfer data from URLs | `curl -O https://example.com/file` |
| `wget` | Download files | `wget https://example.com/file` |
| `scp` | Secure copy over SSH | `scp file user@host:/path` |
| `rsync` | Remote sync | `rsync -avz src/ user@host:dest/` |
| `ftp` | FTP client | `ftp ftp.example.com` |
| `ssh` | Secure shell | `ssh user@host` |
| `nc` / `ncat` | Netcat utility | `nc -zv host 80` |

### Packet Analysis

| Command | Description | Example |
|---------|-------------|---------|
| `tcpdump` | Capture packets | `tcpdump -i eth0 port 80` |
| `tshark` | Wireshark CLI | `tshark -i eth0 -f "port 80"` |
| `nmap` | Network scanner | `nmap -sV 192.168.1.0/24` |

---

## 4. Process Management

### Viewing Processes

| Command | Description | Example |
|---------|-------------|---------|
| `ps` | Process snapshot | `ps aux` |
| `top` | Real-time process viewer | `top -o %MEM` |
| `htop` | Interactive process viewer | `htop` |
| `pgrep` | Find processes by name | `pgrep -a nginx` |
| `pidof` | Get PID of process | `pidof systemd` |
| `pstree` | Process tree | `pstree -p` |
| `fuser` | Identify processes using files | `fuser -v /dev/sda1` |
| `lsof` | List open files | `lsof -p 1234` |

### Controlling Processes

| Command | Description | Example |
|---------|-------------|---------|
| `kill` | Send signal to process | `kill -9 1234` |
| `killall` | Kill by process name | `killall firefox` |
| `pkill` | Kill by pattern | `pkill -f "python server"` |
| `nice` | Start with priority | `nice -n 10 ./task.sh` |
| `renice` | Change priority | `renice -n -5 -p 1234` |
| `nohup` | Immune to hangups | `nohup ./server &` |
| `bg` | Resume in background | `bg %1` |
| `fg` | Bring to foreground | `fg %1` |
| `jobs` | List background jobs | `jobs -l` |
| `wait` | Wait for background job | `wait %1` |
| `timeout` | Run with time limit | `timeout 10s ./long-task` |
| `watch` | Run command repeatedly | `watch -n 2 df -h` |

### Systemd Process Control

| Command | Description | Example |
|---------|-------------|---------|
| `systemctl start` | Start service | `systemctl start nginx` |
| `systemctl stop` | Stop service | `systemctl stop nginx` |
| `systemctl restart` | Restart service | `systemctl restart nginx` |
| `systemctl status` | Check service status | `systemctl status nginx` |
| `systemctl enable` | Enable at boot | `systemctl enable nginx` |
| `systemctl disable` | Disable at boot | `systemctl disable nginx` |
| `journalctl` | View systemd logs | `journalctl -u nginx -f` |

---

## 5. Disk and Storage

### Disk Usage

| Command | Description | Example |
|---------|-------------|---------|
| `df` | Report filesystem usage | `df -hT` |
| `du` | Estimate file space usage | `du -sh /home/*` |
| `lsblk` | List block devices | `lsblk -f` |
| `blkid` | Print block device attributes | `blkid /dev/sda1` |
| `fdisk` | Partition table manipulator | `fdisk -l /dev/sda` |
| `parted` | Partition manipulation | `parted /dev/sda print` |
| `findmnt` | Find mount points | `findmnt -t ext4` |
| `mount` | Mount filesystem | `mount /dev/sdb1 /mnt` |
| `umount` | Unmount filesystem | `umount /mnt` |

### Filesystem Operations

| Command | Description | Example |
|---------|-------------|---------|
| `mkfs.ext4` | Create ext4 filesystem | `mkfs.ext4 /dev/sdb1` |
| `mkfs.xfs` | Create XFS filesystem | `mkfs.xfs /dev/sdb1` |
| `mkfs.btrfs` | Create Btrfs filesystem | `mkfs.btrfs /dev/sdb1` |
| `fsck` | Check filesystem | `fsck -f /dev/sda1` |
| `tune2fs` | Adjust ext4 parameters | `tune2fs -l /dev/sda1` |
| `xfs_info` | Display XFS info | `xfs_info /dev/sda1` |
| `btrfs` | Btrfs management | `btrfs filesystem show` |

### LVM

| Command | Description | Example |
|---------|-------------|---------|
| `pvcreate` | Create physical volume | `pvcreate /dev/sdb` |
| `vgcreate` | Create volume group | `vgcreate vg0 /dev/sdb` |
| `lvcreate` | Create logical volume | `lvcreate -L 10G -n lv0 vg0` |
| `pvdisplay` | Display PV info | `pvdisplay` |
| `vgdisplay` | Display VG info | `vgdisplay` |
| `lvdisplay` | Display LV info | `lvdisplay` |

### RAID

| Command | Description | Example |
|---------|-------------|---------|
| `mdadm --create` | Create RAID array | `mdadm --create /dev/md0 --level=1 --raid-devices=2 /dev/sd[ab]` |
| `mdadm --detail` | Show RAID details | `mdadm --detail /dev/md0` |
| `cat /proc/mdstat` | RAID status | `cat /proc/mdstat` |

---

## 6. User and Group Management

### User Operations

| Command | Description | Example |
|---------|-------------|---------|
| `whoami` | Current username | `whoami` |
| `id` | Print user/group IDs | `id username` |
| `who` | Who is logged in | `who` |
| `w` | Who is logged in and doing what | `w` |
| `last` | Show login history | `last -n 10` |
| `useradd` | Create user | `useradd -m -s /bin/bash john` |
| `usermod` | Modify user | `usermod -aG sudo john` |
| `userdel` | Delete user | `userdel -r john` |
| `passwd` | Change password | `passwd john` |
| `chage` | Change password aging | `chage -l john` |
| `su` | Switch user | `su - john` |
| `sudo` | Execute as another user | `sudo command` |
| `visudo` | Edit sudoers file | `visudo` |

### Group Operations

| Command | Description | Example |
|---------|-------------|---------|
| `groups` | Show user's groups | `groups john` |
| `groupadd` | Create group | `groupadd developers` |
| `groupmod` | Modify group | `groupmod -n devs developers` |
| `groupdel` | Delete group | `groupdel developers` |
| `gpasswd` | Administer group | `gpasswd -a john developers` |

### Authentication and Security

| Command | Description | Example |
|---------|-------------|---------|
| `ssh-keygen` | Generate SSH key pair | `ssh-keygen -t ed25519` |
| `ssh-copy-id` | Copy SSH key to server | `ssh-copy-id user@host` |
| `gpg` | GNU Privacy Guard | `gpg --gen-key` |
| `openssl` | SSL/TLS toolkit | `openssl req -x509 -newkey rsa:4096` |

---

## 7. System Information

### Hardware Info

| Command | Description | Example |
|---------|-------------|---------|
| `uname` | System information | `uname -a` |
| `hostname` | Print/set hostname | `hostnamectl` |
| `lscpu` | CPU information | `lscpu` |
| `lsmem` | Memory information | `lsmem` |
| `lspci` | List PCI devices | `lspci -vv` |
| `lsusb` | List USB devices | `lsusb -v` |
| `lshw` | List hardware | `lshw -short` |
| `dmidecode` | DMI/SMBIOS table | `dmidecode -t memory` |
| `hdparm` | HDD/SSD parameters | `hdparm -I /dev/sda` |
| `smartctl` | SMART disk health | `smartctl -a /dev/sda` |
| `inxi` | System info script | `inxi -Fxz` |

### System Status

| Command | Description | Example |
|---------|-------------|---------|
| `uptime` | System uptime and load | `uptime` |
| `free` | Memory usage | `free -h` |
| `vmstat` | Virtual memory stats | `vmstat 1 5` |
| `iostat` | I/O statistics | `iostat -xz 1` |
| `mpstat` | Multiprocessor stats | `mpstat -P ALL 1` |
| `sar` | System activity reporter | `sar -u 1 5` |
| `dmesg` | Kernel ring buffer | `dmesg | tail` |
| `lsof` | Open files | `lsof +D /var/log` |
| `sysctl` | Kernel parameters | `sysctl -a | grep swap` |

---

## 8. Package Management

### Debian/Ubuntu (apt)

| Command | Description | Example |
|---------|-------------|---------|
| `apt update` | Update package index | `sudo apt update` |
| `apt upgrade` | Upgrade packages | `sudo apt upgrade` |
| `apt install` | Install package | `sudo apt install nginx` |
| `apt remove` | Remove package | `sudo apt remove nginx` |
| `apt search` | Search packages | `apt search nginx` |
| `apt show` | Show package info | `apt show nginx` |
| `dpkg -l` | List installed packages | `dpkg -l | grep nginx` |
| `apt autoremove` | Remove unused dependencies | `sudo apt autoremove` |

### RHEL/Fedora (dnf)

| Command | Description | Example |
|---------|-------------|---------|
| `dnf install` | Install package | `sudo dnf install nginx` |
| `dnf remove` | Remove package | `sudo dnf remove nginx` |
| `dnf update` | Update packages | `sudo dnf update` |
| `dnf search` | Search packages | `dnf search nginx` |
| `dnf info` | Show package info | `dnf info nginx` |
| `rpm -qa` | List installed packages | `rpm -qa | grep nginx` |

### Arch Linux (pacman)

| Command | Description | Example |
|---------|-------------|---------|
| `pacman -S` | Install package | `sudo pacman -S nginx` |
| `pacman -R` | Remove package | `sudo pacman -R nginx` |
| `pacman -Syu` | Full system upgrade | `sudo pacman -Syu` |
| `pacman -Ss` | Search packages | `pacman -Ss nginx` |
| `pacman -Q` | List installed packages | `pacman -Q | grep nginx` |

---

## 9. Environment and Shell

| Command | Description | Example |
|---------|-------------|---------|
| `env` | Print environment | `env` |
| `printenv` | Print variable | `printenv PATH` |
| `export` | Set environment variable | `export EDITOR=vim` |
| `set` | Set shell options | `set -euo pipefail` |
| `alias` | Create alias | `alias ll='ls -lah'` |
| `type` | Identify command type | `type ls` |
| `history` | Command history | `history | tail -20` |
| `source` / `.` | Execute script in current shell | `source ~/.bashrc` |
| `eval` | Evaluate arguments as command | `eval "$cmd"` |
| `exec` | Replace shell with command | `exec /bin/bash` |
| `date` | Print/set date | `date "+%Y-%m-%d %H:%M:%S"` |
| `cal` | Display calendar | `cal 2026` |
| `bc` | Arbitrary precision calculator | `echo "scale=2; 10/3" | bc` |
| `expr` | Evaluate expressions | `expr 5 + 3` |

---

## 10. Job Scheduling and Automation

| Command | Description | Example |
|---------|-------------|---------|
| `cron` | Daemon for scheduled jobs | See `crontab -e` |
| `crontab` | Edit cron jobs | `crontab -l` |
| `at` | Schedule one-time job | `echo "reboot" | at now + 5 min` |
| `atq` | List pending at jobs | `atq` |
| `batch` | Execute when load permits | `batch` |
| `systemd-run` | Run transient unit | `systemd-run --on-calendar="*-*-* 02:00" /opt/backup.sh` |

### Crontab Time Format

```
┌───────────── minute (0 - 59)
│ ┌───────────── hour (0 - 23)
│ │ ┌───────────── day of month (1 - 31)
│ │ │ ┌───────────── month (1 - 12)
│ │ │ │ ┌───────────── day of week (0 - 6) (Sunday=0)
│ │ │ │ │
* * * * * command
```

**Common cron expressions:**

| Expression | Description |
|------------|-------------|
| `0 * * * *` | Every hour |
| `0 0 * * *` | Every day at midnight |
| `0 0 * * 0` | Every Sunday at midnight |
| `0 0 1 * *` | First day of month |
| `*/5 * * * *` | Every 5 minutes |
| `0 9-17 * * 1-5` | Every hour 9-5, Mon-Fri |

---

## 11. Quick One-Liners

### File Operations
```bash
# Find largest files
find / -type f -exec du -h {} + 2>/dev/null | sort -rh | head -20

# Count files by extension
find . -type f | sed 's/.*\.//' | sort | uniq -c | sort -rn

# Remove files older than 30 days
find /tmp -type f -mtime +30 -delete

# Batch rename files
for f in *.txt; do mv "$f" "${f%.txt}.md"; done

# Find and replace in multiple files
find . -name "*.py" -exec sed -i 's/old/new/g' {} +

# Watch a file for changes
inotifywait -m -e modify /var/log/syslog
```

### System Monitoring
```bash
# Top 10 memory consumers
ps aux --sort=-%mem | head -11

# Top 10 CPU consumers
ps aux --sort=-%cpu | head -11

# Monitor disk I/O in real-time
iostat -xz 1

# Show open ports
ss -tlnp

# Check memory by process
smem -t -k -s pss

# Real-time process tree
watch -n 1 pstree -p
```

### Text Processing
```bash
# Extract IP addresses from a file
grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' file

# Sort IPs numerically
sort -t. -k1,1n -k2,2n -k3,3n -k4,4n ips.txt

# CSV column extraction
awk -F, '{print $2, $5}' data.csv

# Remove blank lines
sed '/^$/d' file.txt

# Convert Windows line endings
sed -i 's/\r$//' file.txt

# Count occurrences of each word
tr ' ' '\n' < file.txt | sort | uniq -c | sort -rn
```

---

## 12. Escape Sequences and Special Characters

### Shell Escape Sequences

| Sequence | Description |
|----------|-------------|
| `\n` | Newline |
| `\t` | Tab |
| `\r` | Carriage return |
| `\\` | Backslash |
| `\'` | Single quote |
| `\"` | Double quote |
| `\0` | Null character |

### Shell Special Variables

| Variable | Description |
|----------|-------------|
| `$0` | Script name |
| `$1`-`$9` | Positional parameters |
| `$#` | Number of arguments |
| `$@` | All arguments (separate) |
| `$*` | All arguments (single string) |
| `$?` | Exit status of last command |
| `$$` | Current PID |
| `$!` | PID of last background command |
| `$_` | Last argument of last command |
| `$-` | Current shell options |

---

*This cheat sheet covers the most commonly used Linux commands. For detailed information on any command, consult its man page with `man command` or the info page with `info command`.*
