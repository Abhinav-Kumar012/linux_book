# Chapter 51: Remote Access — ssh, scp, sftp, rsync, ssh-keygen, ssh-agent, sshd_config

## Overview

Remote access is essential for managing Linux servers, transferring files, and automating administration tasks. SSH (Secure Shell) is the standard protocol for encrypted remote access, replacing insecure tools like telnet and rsh.

---

## ssh — OpenSSH Client

### Purpose

`ssh` connects to remote machines securely over an encrypted channel. It supports password authentication, key-based authentication, port forwarding, and tunneling.

### Syntax

```
ssh [options] [user@]hostname [command]
```

### Key Options

| Option | Description |
|--------|-------------|
| `-p PORT` | Connect to port |
| `-i KEY` | Identity file (private key) |
| `-l USER` | Login user |
| `-v` | Verbose (multiple `-v` for more detail) |
| `-q` | Quiet mode |
| `-X` | X11 forwarding |
| `-Y` | Trusted X11 forwarding |
| `-A` | Agent forwarding |
| `-J JUMP` | Jump host (proxy) |
| `-L [LOCAL:]REMOTE` | Local port forwarding |
| `-R [REMOTE:]LOCAL` | Remote port forwarding |
| `-D PORT` | Dynamic port forwarding (SOCKS proxy) |
| `-N` | No remote command (tunnel only) |
| `-f` | Go to background after authentication |
| `-t` | Force pseudo-terminal allocation |
| `-T` | Disable pseudo-terminal |
| `-o OPTION` | Set config option |
| `-C` | Enable compression |
| `-4` | Force IPv4 |
| `-6` | Force IPv6 |
| `-W HOST:PORT` | Forward stdin/stdout to host:port |
| `-E FILE` | Log to file |
| `-G` | Print configuration |
| `-Q QUERY` | Query capabilities |

### Examples

```bash
# Basic connection
ssh user@server

# Connect to specific port
ssh -p 2222 user@server

# Run command remotely
ssh user@server "ls -la /var/log"

# X11 forwarding
ssh -X user@server

# SSH tunnel (local port forwarding)
ssh -L 8080:localhost:80 user@server
# Now http://localhost:8080 → server:80

# Remote port forwarding
ssh -R 9090:localhost:3000 user@server
# server:9090 → local:3000

# SOCKS proxy
ssh -D 1080 user@server

# Jump host
ssh -J bastion user@internal-server

# With specific key
ssh -i ~/.ssh/mykey user@server

# Multiple jump hosts
ssh -J jump1,jump2 user@final-server

# Background tunnel
ssh -f -N -L 8080:localhost:80 user@server

# Force pseudo-terminal (for sudo)
ssh -t user@server "sudo systemctl restart nginx"

# Disable pseudo-terminal (for scripts)
ssh -T user@server "echo hello"

# With environment variables
ssh user@server "VAR=value command"

# Compression
ssh -C user@server

# Agent forwarding
ssh -A user@server
```

### SSH Tunneling

```bash
# Local port forwarding (access remote service locally)
ssh -L [local_addr:]local_port:remote_addr:remote_port user@server
ssh -L 3306:localhost:3306 user@db-server  # MySQL tunnel

# Remote port forwarding (expose local service remotely)
ssh -R [remote_addr:]remote_port:local_addr:local_port user@server
ssh -R 8080:localhost:3000 user@server  # Expose local web app

# Dynamic port forwarding (SOCKS proxy)
ssh -D 1080 user@server
# Configure browser to use SOCKS proxy: localhost:1080

# Unix socket forwarding
ssh -L /tmp/local.sock:/var/run/docker.sock user@server

# Reverse tunnel with autossh (persistent)
autossh -M 0 -f -N -R 2222:localhost:22 user@server
```

### ~/.ssh/config

```
# Global defaults
Host *
    ServerAliveInterval 60
    ServerAliveCountMax 3
    AddKeysToAgent yes
    IdentityFile ~/.ssh/id_ed25519

# Specific host
Host myserver
    HostName 192.168.1.100
    User admin
    Port 2222
    IdentityFile ~/.ssh/myserver_key

# Jump host
Host internal
    HostName 10.0.0.5
    ProxyJump bastion
    User deploy

# Wildcard
Host *.example.com
    User admin
    ForwardAgent yes
```

### Internals

SSH connection process:
1. TCP connection to server (default port 22).
2. Protocol version exchange (SSH-2.0).
3. Key exchange (Diffie-Hellman or ECDH) to establish shared secret.
4. Server authentication (verify host key against `~/.ssh/known_hosts`).
5. User authentication (password, public key, keyboard-interactive).
6. Channel establishment (session, direct-tcpip, forwarded-tcpip).
7. Data transfer (encrypted with AES, ChaCha20, etc.).

---

## scp — Secure Copy

### Purpose

`scp` copies files between hosts over SSH.

### Key Options

| Option | Description |
|--------|-------------|
| `-r` | Recursive |
| `-P PORT` | Port |
| `-i KEY` | Identity file |
| `-C` | Compression |
| `-l LIMIT` | Bandwidth limit (Kbit/s) |
| `-p` | Preserve timestamps and permissions |
| `-q` | Quiet |
| `-v` | Verbose |
| `-o OPTION` | SSH option |
| `-S PROGRAM` | Encryption program |
| `-3` | Route through local host |

### Examples

```bash
# Copy file to remote
scp file.txt user@server:/path/

# Copy file from remote
scp user@server:/path/file.txt ./

# Recursive copy
scp -r directory/ user@server:/path/

# Copy between two remote hosts (via local)
scp -3 user1@server1:/file user2@server2:/path/

# Specific port
scp -P 2222 file.txt user@server:/path/

# With compression
scp -C largefile.tar.gz user@server:/path/

# Preserve permissions
scp -p file.txt user@server:/path/

# Multiple files
scp file1.txt file2.txt user@server:/path/

# Bandwidth limit
scp -l 1000 largefile.tar.gz user@server:/path/
```

### Common Mistakes

1. **`scp` vs `rsync`**: `rsync` is generally better — it supports delta transfers, resume, and preserves more metadata. Use `scp` for simple one-off transfers.

2. **Using `-r` without `-p`**: Use `-rp` to preserve permissions when copying directories.

3. **Port flag**: `scp` uses `-P` (uppercase) for port, while `ssh` uses `-p` (lowercase).

---

## sftp — Secure File Transfer Protocol

### Purpose

`sftp` provides an interactive file transfer session over SSH.

### Commands

| Command | Description |
|---------|-------------|
| `get [-r] remote [local]` | Download file/directory |
| `put [-r] local [remote]` | Upload file/directory |
| `ls [-la]` | List remote directory |
| `lls` | List local directory |
| `cd path` | Change remote directory |
| `lcd path` | Change local directory |
| `mkdir dir` | Create remote directory |
| `rmdir dir` | Remove remote directory |
| `rm file` | Remove remote file |
| `rename old new` | Rename file |
| `chmod mode file` | Change permissions |
| `chown user file` | Change owner |
| `df [-h]` | Disk usage |
| `!command` | Run local command |
| `exit`, `quit` | Exit |
| `!` | Drop to local shell |

### Examples

```bash
# Connect to remote
sftp user@server

# Use specific port
sftp -P 2222 user@server

# Batch mode
sftp -b commands.txt user@server

# Download files
sftp> get file.txt
sftp> get -r directory/

# Upload files
sftp> put file.txt
sftp> put -r directory/

# Interactive commands
sftp> ls -la
sftp> cd /var/log
sftp> lcd /tmp
sftp> mkdir backup
sftp> get *.log

# Run local command
sftp> !ls /tmp
```

---

## rsync — Remote File Synchronization

### Purpose

`rsync` efficiently synchronizes files and directories locally or remotely, using delta-transfer algorithm to send only differences.

### Key Options

| Option | Description |
|--------|-------------|
| `-a` | Archive mode (recursive, preserve everything) |
| `-v` | Verbose |
| `-z` | Compress during transfer |
| `-r` | Recursive |
| `-l` | Copy symlinks as symlinks |
| `-p` | Preserve permissions |
| `-t` | Preserve modification times |
| `-g` | Preserve group |
| `-o` | Preserve owner |
| `-D` | Preserve device files |
| `-H` | Preserve hard links |
| `-A` | Preserve ACLs |
| `-X` | Preserve extended attributes |
| `-S` | Handle sparse files |
| `--delete` | Delete files not in source |
| `--dry-run`, `-n` | Dry run |
| `--progress` | Show progress |
| `--stats` | Transfer statistics |
| `-e SSH` | Remote shell (default: ssh) |
| `--exclude=PATTERN` | Exclude files |
| `--include=PATTERN` | Include files |
| `--exclude-from=FILE` | Read exclude patterns |
| `--include-from=FILE` | Read include patterns |
| `--bwlimit=RATE` | Bandwidth limit (KB/s) |
| `--timeout=SECONDS` | I/O timeout |
| `--partial` | Keep partial transfers |
| `--append` | Append to partial files |
| `--backup`, `-b` | Backup existing files |
| `--backup-dir=DIR` | Backup directory |
| `--suffix=SUFFIX` | Backup suffix |
| `--link-dest=DIR` | Hardlink unchanged files |
| `--compare-dest=DIR` | Skip files in DIR |
| `--copy-dest=DIR` | Copy from DIR if unchanged |
| `--size-only` | Skip based on size |
| `--checksum`, `-c` | Skip based on checksum |
| `--ignore-existing` | Skip existing files |
| `--remove-source-files` | Delete source after transfer |
| `--max-size=SIZE` | Skip files larger than SIZE |
| `--min-size=SIZE` | Skip files smaller than SIZE |
| `--files-from=FILE` | Read file list |
| `--from0`, `-0` | Null-delimited input |
| `--chmod=MODE` | Set permissions |
| `--usermap=USER` | Map usernames |
| `--groupmap=GROUP` | Map groups |
| `-P` | Same as `--partial --progress` |
| `--info=FLAGS` | Information output |
| `--debug=FLAGS` | Debug output |

### Examples

```bash
# Local sync
rsync -av /source/ /destination/

# Remote sync (to remote)
rsync -av /local/path/ user@server:/remote/path/

# Remote sync (from remote)
rsync -av user@server:/remote/path/ /local/path/

# With compression
rsync -avz /source/ user@server:/destination/

# Dry run (see what would happen)
rsync -avzn /source/ /destination/

# Delete files not in source
rsync -av --delete /source/ /destination/

# Exclude patterns
rsync -av --exclude='*.log' --exclude='.git' /source/ /destination/

# Exclude from file
rsync -av --exclude-from=exclude.txt /source/ /destination/

# Show progress
rsync -av --progress /source/ /destination/

# Bandwidth limit
rsync -av --bwlimit=5000 /source/ user@server:/destination/

# Resume partial transfers
rsync -avP /source/ user@server:/destination/

# Checksum-based comparison
rsync -avc /source/ /destination/

# Size-only comparison
rsync -av --size-only /source/ /destination/

# Hardlink backups
rsync -av --link-dest=/backup/latest /source/ /backup/$(date +%Y%m%d)/

# Remove source files after transfer
rsync -av --remove-source-files /source/ /destination/

# With specific SSH key
rsync -av -e "ssh -i ~/.ssh/mykey" /source/ user@server:/dest/

# With specific port
rsync -av -e "ssh -p 2222" /source/ user@server:/dest/

# Compress and show stats
rsync -avz --stats /source/ user@server:/destination/

# Backup with suffix
rsync -av --backup --suffix=.$(date +%Y%m%d) /source/ /destination/

# Include/exclude pattern matching
rsync -av --include='*/' --include='*.conf' --exclude='*' /etc/ /backup/

# Custom SSH options
rsync -av -e "ssh -o StrictHostKeyChecking=no" /source/ user@server:/dest/

# Use rsync daemon
rsync -av /source/ rsync://server/module/

# Archive with all attributes
rsync -aHAXv /source/ /destination/
```

### Internals

`rsync` uses a sophisticated algorithm:

1. **File list**: Sender generates a list of files with metadata.
2. **Delta detection**: For each file, uses a rolling checksum (Adler-32) to find matching blocks, then transfers only the differences.
3. **Transfer**: Only changed blocks are sent, not entire files.
4. **Verification**: Files are verified after transfer.

**Trailing slash**: `/source/` copies contents of source. `/source` copies the source directory itself.

### Common Mistakes

1. **Trailing slash confusion**: `rsync -av /source /dest/` creates `/dest/source/`. `rsync -av /source/ /dest/` copies contents directly into `/dest/`.

2. **Using `--delete` carelessly**: `--delete` removes files in destination that aren't in source. Always do a `--dry-run` first.

3. **Not using `-a`**: Without `-a`, permissions, ownership, and timestamps aren't preserved.

4. **Large directory trees**: For very large trees, use `--info=progress2` for overall progress instead of per-file.

---

## ssh-keygen — Generate SSH Key Pairs

### Purpose

`ssh-keygen` generates, manages, and converts SSH authentication keys.

### Key Options

| Option | Description |
|--------|-------------|
| `-t TYPE` | Key type (rsa, ed25519, ecdsa, dsa) |
| `-b BITS` | Key size in bits |
| `-f FILE` | Output filename |
| `-C COMMENT` | Comment (usually email) |
| `-N PASSPHRASE` | Passphrase (empty for none) |
| `-P PASSPHRASE` | Old passphrase |
| `-e` | Export key (RFC 4716 format) |
| `-i` | Import key |
| `-l` | Show fingerprint |
| `-y` | Read private key, output public |
| `-F HOST` | Find host in known_hosts |
| `-R HOST` | Remove host from known_hosts |
| `-H` | Hash known_hosts |
| `-q` | Quiet |
| `-v` | Verbose |
| `-m FORMAT` | Key format (PEM, PKCS8, RFC4716) |
| `-p` | Change passphrase |
| `-N` | New passphrase |
| `-A` | Generate missing host keys |
| `-a ROUNDS` | KDF rounds |

### Examples

```bash
# Generate Ed25519 key (recommended)
ssh-keygen -t ed25519 -C "user@example.com"

# Generate RSA key (4096 bits)
ssh-keygen -t rsa -b 4096 -C "user@example.com"

# Generate with specific filename
ssh-keygen -t ed25519 -f ~/.ssh/mykey -C "my key"

# Generate without passphrase
ssh-keygen -t ed25519 -N ""

# Show fingerprint
ssh-keygen -l -f ~/.ssh/id_ed25519.pub

# Change passphrase
ssh-keygen -p -f ~/.ssh/id_ed25519

# Remove host from known_hosts
ssh-keygen -R server.example.com

# Hash known_hosts
ssh-keygen -H

# Generate host keys
sudo ssh-keygen -A

# Export public key
ssh-keygen -e -f ~/.ssh/id_ed25519.pub

# Show all fingerprints
ssh-keygen -l -f /etc/ssh/ssh_host_ed25519_key.pub
```

---

## ssh-agent — SSH Key Manager

### Purpose

`ssh-agent` manages SSH keys in memory, so you don't need to enter passphrases repeatedly.

### Examples

```bash
# Start agent and add key
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# List loaded keys
ssh-add -l

# Delete specific key
ssh-add -d ~/.ssh/id_ed25519.pub

# Delete all keys
ssh-add -D

# Add with lifetime
ssh-add -t 3600 ~/.ssh/id_ed25519  # 1 hour

# Add with confirmation requirement
ssh-add -c ~/.ssh/id_ed25519

# Kill agent
eval "$(ssh-agent -k)"
```

### Auto-start in .bashrc

```bash
# Start ssh-agent if not running
if [ -z "$SSH_AUTH_SOCK" ]; then
    eval "$(ssh-agent -s)" > /dev/null 2>&1
    ssh-add ~/.ssh/id_ed25519 2>/dev/null
fi
```

---

## sshd_config — SSH Server Configuration

### Purpose

`/etc/ssh/sshd_config` configures the OpenSSH server daemon.

### Key Settings

| Setting | Description | Recommended |
|---------|-------------|-------------|
| `Port` | Listening port | 22 (or custom) |
| `PermitRootLogin` | Allow root login | `no` |
| `PasswordAuthentication` | Allow password auth | `no` (use keys) |
| `PubkeyAuthentication` | Allow key auth | `yes` |
| `AuthorizedKeysFile` | Key file location | `.ssh/authorized_keys` |
| `MaxAuthTries` | Max auth attempts | 3 |
| `LoginGraceTime` | Auth timeout | 60 |
| `AllowUsers` | Allowed users | List specific users |
| `AllowGroups` | Allowed groups | List specific groups |
| `DenyUsers` | Denied users | — |
| `DenyGroups` | Denied groups | — |
| `ListenAddress` | Bind address | 0.0.0.0 / :: |
| `Protocol` | SSH protocol | 2 |
| `X11Forwarding` | X11 forwarding | `no` |
| `AllowTcpForwarding` | TCP forwarding | `no` (if not needed) |
| `GatewayPorts` | Remote forwarding | `no` |
| `ClientAliveInterval` | Keep-alive interval | 300 |
| `ClientAliveCountMax` | Keep-alive count | 3 |
| `MaxSessions` | Max sessions per connection | 10 |
| `MaxStartups` | Max unauthenticated connections | 10:30:60 |
| `Banner` | Login banner | /etc/issue.net |
| `PrintMotd` | Print MOTD | `no` |
| `Subsystem sftp` | SFTP subsystem | internal-sftp |
| `UsePAM` | Use PAM | `yes` |
| `ChallengeResponseAuthentication` | Keyboard-interactive | `no` |
| `UseDNS` | DNS lookup | `no` |
| `PermitEmptyPasswords` | Empty passwords | `no` |
| `StrictModes` | Check file permissions | `yes` |
| `TCPKeepAlive` | TCP keep-alive | `yes` |
| `Compression` | Compression | `delayed` |
| `LogLevel` | Log verbosity | `VERBOSE` |

### Example sshd_config

```bash
# /etc/ssh/sshd_config
Port 22
Protocol 2
ListenAddress 0.0.0.0
ListenAddress ::

# Authentication
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
MaxAuthTries 3
LoginGraceTime 60

# Security
AllowUsers admin deploy
AllowGroups sshusers
DenyUsers guest

# Session
ClientAliveInterval 300
ClientAliveCountMax 3
MaxSessions 10

# Disable unnecessary features
X11Forwarding no
AllowTcpForwarding no
GatewayPorts no

# Logging
LogLevel VERBOSE

# Use PAM
UsePAM yes
UseDNS no

# SFTP
Subsystem sftp internal-sftp -l VERBOSE
```

### After Editing

```bash
# Test configuration
sudo sshd -t

# Reload (doesn't disconnect existing sessions)
sudo systemctl reload sshd

# Restart (disconnects existing sessions)
sudo systemctl restart sshd
```

---

## Summary

### Quick Reference

```bash
# Remote access
ssh user@server
ssh -p 2222 user@server
ssh -t user@server "sudo command"

# File transfer
scp file.txt user@server:/path/
rsync -avz /source/ user@server:/dest/
sftp user@server

# Key management
ssh-keygen -t ed25519
ssh-copy-id user@server
ssh-add ~/.ssh/id_ed25519

# Server config
sudo vim /etc/ssh/sshd_config
sudo sshd -t          # Test config
sudo systemctl reload sshd
```

### Security Best Practices

1. **Disable root login**: `PermitRootLogin no`
2. **Use key-based auth**: `PasswordAuthentication no`
3. **Use Ed25519 keys**: Strongest and fastest
4. **Limit users**: `AllowUsers` or `AllowGroups`
5. **Non-standard port**: Reduces log noise (but doesn't improve security)
6. **Fail2ban**: Install to block brute-force attempts
7. **2FA**: Consider TOTP with `google-authenticator-libpam`
8. **Audit logs**: Monitor `/var/log/auth.log`
