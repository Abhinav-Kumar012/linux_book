# Chapter 50: User Management — useradd, usermod, userdel, passwd, groups, id, sudo, su, visudo

## Overview

User management is fundamental to Linux security and multi-user operation. Every process runs as a specific user, and file access is controlled by user/group ownership and permissions. This chapter covers creating, modifying, and deleting users, managing passwords, and privilege escalation.

---

## Linux User/Group Fundamentals

### Key Files

| File | Purpose |
|------|---------|
| `/etc/passwd` | User account information (username, UID, GID, home, shell) |
| `/etc/shadow` | Encrypted passwords and password policies |
| `/etc/group` | Group information (group name, GID, members) |
| `/etc/gshadow` | Group passwords and administrators |
| `/etc/login.defs` | Login and password defaults |
| `/etc/skel/` | Skeleton directory (copied to new user homes) |
| `/etc/subuid` | subordinate UID ranges (for containers) |
| `/etc/subgid` | subordinate GID ranges |

### /etc/passwd Fields

```
username:password:UID:GID:GECOS:home_directory:shell
```

| Field | Description |
|-------|-------------|
| username | Login name |
| password | `x` (password in /etc/shadow) |
| UID | User ID (0=root, 1-999=system, 1000+=regular) |
| GID | Primary group ID |
| GECOS | Full name, contact info |
| home | Home directory |
| shell | Login shell |

### UID Ranges

| Range | Purpose |
|-------|---------|
| 0 | root |
| 1-999 | System users (daemons, services) |
| 1000-60000 | Regular users |
| 65534 | nobody |
| 65536+ | Subordinate UIDs (containers) |

---

## useradd — Create a New User

### Purpose

`useradd` creates new user accounts with specified options.

### Syntax

```
useradd [options] LOGIN
```

### Key Options

| Option | Description |
|--------|-------------|
| `-u UID` | User ID |
| `-g GROUP` | Primary group |
| `-G GROUPS` | Supplementary groups |
| `-d HOME` | Home directory |
| `-m` | Create home directory |
| `-M` | Don't create home directory |
| `-s SHELL` | Login shell |
| `-c COMMENT` | GECOS field (full name) |
| `-e DATE` | Account expiration date |
| `-f DAYS` | Password inactivity period |
| `-k SKEL` | Skeleton directory |
| `-o` | Allow non-unique UID |
| `-r` | Create system account |
| `-N` | Don't create user group |
| `-b BASE` | Base directory for home |
| `-D` | Display or change defaults |
| `--badname` | Allow non-standard names |
| `--system` | Create system account |
| `--no-log-init` | Don't touch lastlog/faillog |
| `--shell SHELL` | Login shell |
| `--create-home` | Same as `-m` |
| `--no-create-home` | Same as `-M` |
| `--uid UID` | Same as `-u` |
| `--gid GROUP` | Same as `-g` |
| `--groups GROUPS` | Same as `-G` |
| `--home HOME` | Same as `-d` |
| `--expire-date DATE` | Same as `-e` |
| `--inactive DAYS` | Same as `-f` |
| `--password PASS` | Encrypted password |
| `--skel SKEL` | Same as `-k` |

### Examples

```bash
# Basic user creation
sudo useradd john

# Create with home directory
sudo useradd -m john

# Create with specific options
sudo useradd -m -d /home/john -s /bin/bash -c "John Doe" john

# Create with specific UID and groups
sudo useradd -m -u 1001 -g users -G wheel,docker,staff john

# Create system account
sudo useradd -r -s /usr/sbin/nologin myservice

# Create with expiration
sudo useradd -m -e 2025-12-31 john

# Create with non-default shell
sudo useradd -m -s /bin/zsh john

# Create without home directory
sudo useradd -M -s /sbin/nologin ftpuser

# Display defaults
useradd -D

# Change defaults
sudo useradd -D -s /bin/zsh
sudo useradd -D -b /home
sudo useradd -D -e 2025-12-31

# Create with specific skeleton
sudo useradd -m -k /etc/skel-custom john

# Create with encrypted password
sudo useradd -m -p "$(openssl passwd -6 'password')" john
```

### Internals

`useradd` performs:
1. Validates input (username format, UID uniqueness, group existence).
2. Creates entry in `/etc/passwd`.
3. Creates entry in `/etc/shadow`.
4. Adds user to `/etc/group` (creates user group unless `-N`).
5. Creates home directory (if `-m`), copies `/etc/skel/`.
6. Sets ownership and permissions on home directory.
7. Optionally runs `/usr/sbin/useradd.local` script.

### Common Mistakes

1. **Forgetting `-m`**: Without `-m`, no home directory is created. Users can't log in without a home.

2. **Not setting password**: After `useradd`, the account is locked. Use `passwd john` to set a password.

3. **Shell set to nologin**: System accounts should have `/usr/sbin/nologin` or `/bin/false`. Don't forget for service accounts.

4. **UID conflicts**: Check existing UIDs before assigning with `cat /etc/passwd | cut -d: -f3 | sort -n`.

---

## usermod — Modify a User Account

### Purpose

`usermod` modifies existing user account properties.

### Key Options

| Option | Description |
|--------|-------------|
| `-u UID` | New UID |
| `-g GROUP` | New primary group |
| `-G GROUPS` | New supplementary groups |
| `-a -G GROUPS` | Append supplementary groups |
| `-d HOME` | New home directory |
| `-m -d HOME` | Move home directory contents |
| `-s SHELL` | New shell |
| `-c COMMENT` | New GECOS |
| `-l LOGIN` | New login name |
| `-L` | Lock account |
| `-U` | Unlock account |
| `-e DATE` | Set expiration |
| `-f DAYS` | Set inactivity |
| `--lock` | Same as `-L` |
| `--unlock` | Same as `-U` |
| `-o` | Allow non-unique UID |

### Examples

```bash
# Add user to group
sudo usermod -aG docker john

# Change primary group
sudo usermod -g developers john

# Change shell
sudo usermod -s /bin/zsh john

# Lock account
sudo usermod -L john

# Unlock account
sudo usermod -U john

# Change home directory
sudo usermod -d /home/johndoe -m john

# Change login name
sudo usermod -l johndoe john

# Set expiration
sudo usermod -e 2025-12-31 john

# Change UID
sudo usermod -u 1001 john

# Append multiple groups
sudo usermod -aG wheel,staff,developers john

# Change comment
sudo usermod -c "John Doe, Senior Dev" john

# Set shell to nologin
sudo usermod -s /usr/sbin/nologin ftpuser
```

### Common Mistakes

1. **Forgetting `-a` with `-G`**: `usermod -G group1,group2 john` REPLACES all supplementary groups. Use `usermod -aG group1,group2 john` to APPEND.

2. **Using `-d` without `-m`**: `usermod -d /new/home john` changes the home directory setting but doesn't move files. Use `-m` to move.

3. **Active sessions**: Changes to groups don't take effect until the user logs out and back in.

---

## userdel — Delete a User Account

### Purpose

`userdel` removes user accounts and associated files.

### Key Options

| Option | Description |
|--------|-------------|
| `-r` | Remove home directory and mail spool |
| `-f` | Force removal (even if logged in) |
| `-Z` | Remove SELinux user mapping |

### Examples

```bash
# Delete user (keep home)
sudo userdel john

# Delete user and home directory
sudo userdel -r john

# Force delete (even if logged in)
sudo userdel -rf john
```

---

## passwd — Change User Password

### Purpose

`passwd` changes user passwords and password policies.

### Key Options

| Option | Description |
|--------|-------------|
| `-l` | Lock account (prefix password with `!`) |
| `-u` | Unlock account |
| `-e` | Expire password (force change on next login) |
| `-i DAYS` | Set inactivity period |
| `-n DAYS` | Minimum password age |
| `-x DAYS` | Maximum password age |
| `-w DAYS` | Warning period |
| `-S` | Display password status |
| `--stdin` | Read password from stdin |
| `-d` | Delete password (passwordless login) |
| `-f` | Force operation |
| `-g` | Change group password |
| `-R CHROOT_DIR` | Chroot directory |

### Examples

```bash
# Change own password
passwd

# Change another user's password (root)
sudo passwd john

# Lock account
sudo passwd -l john

# Unlock account
sudo passwd -u john

# Expire password (force change)
sudo passwd -e john

# Set password from stdin (scripting)
echo "newpassword" | sudo passwd --stdin john

# Display password status
sudo passwd -S john

# Set minimum/maximum age
sudo passwd -n 7 -x 90 -w 14 john

# Delete password
sudo passwd -d john
```

### Password Status

```
$ sudo passwd -S john
john P 2024-01-15 7 90 14 -1
```

| Field | Meaning |
|-------|---------|
| john | Username |
| P | Password status (P=set, L=locked, NP=no password) |
| 2024-01-15 | Last password change |
| 7 | Minimum age (days) |
| 90 | Maximum age (days) |
| 14 | Warning period (days) |
| -1 | Inactivity period (-1=never) |

---

## groups — Print Group Memberships

### Purpose

`groups` prints the groups a user belongs to.

### Examples

```bash
# Current user's groups
groups

# Specific user's groups
groups john

# Multiple users
groups john jane root
```

---

## id — Print User and Group IDs

### Purpose

`id` prints real and effective UID, GID, and supplementary groups.

### Key Options

| Option | Description |
|--------|-------------|
| `-u` | Print UID only |
| `-g` | Print GID only |
| `-G` | Print all GIDs |
| `-n` | Print name instead of number |
| `-r` | Print real ID instead of effective |
| `-Z` | Print SELinux context |

### Examples

```bash
# Current user info
id
# Output: uid=1000(john) gid=1000(john) groups=1000(john),27(sudo),998(docker)

# Specific user
id john

# UID only
id -u

# GID only
id -g

# All groups
id -G

# Names only
id -un

# SELinux context
id -Z
```

---

## su — Substitute User Identity

### Purpose

`su` switches to another user's identity.

### Syntax

```
su [options] [-] [user [argument...]]
```

### Key Options

| Option | Description |
|--------|-------------|
| `-`, `-l`, `--login` | Full login (load target's environment) |
| `-c COMMAND` | Run command as user |
| `-s SHELL` | Use specified shell |
| `-p`, `--preserve-environment` | Preserve environment |
| `-m`, `--preserve-environment` | Same as `-p` |
| `--session-command=COMMAND` | Run command without session |

### Examples

```bash
# Switch to root
su -

# Switch to specific user
su - john

# Run command as user
su -c "whoami" john

# Run command as root
su -c "apt update"

# Switch shell
su -s /bin/zsh john

# Login shell (full environment)
su - root

# Non-login shell (keep current environment)
su root
```

### Common Mistakes

1. **`su` vs `su -`**: `su` keeps the current environment. `su -` loads the target user's full environment (like a fresh login). Use `su -` for root access.

2. **Using `su` for single commands**: Use `sudo command` instead of `su -c "command" root`.

---

## sudo — Execute a Command as Another User

### Purpose

`sudo` executes commands with elevated privileges (typically root) while logging the command and providing fine-grained access control.

### Key Options

| Option | Description |
|--------|-------------|
| `-u USER` | Run as specified user |
| `-g GROUP` | Run with specified group |
| `-E` | Preserve environment variables |
| `-i` | Simulate initial login (load target's environment) |
| `-s` | Run shell |
| `-k` | Invalidate cached credentials |
| `-K` | Remove cached credentials entirely |
| `-b` | Run in background |
| `-n` | Non-interactive (no password prompt) |
| `-p PROMPT` | Custom password prompt |
| `-l` | List user's privileges |
| `-v` | Validate (refresh timestamp) |
| `-C FD` | Close file descriptors |
| `-D DIRECTORY` | Change working directory |
| `--preserve-env=LIST` | Preserve specific env vars |
| `--list` | Same as `-l` |
| `--edit` | Edit files as another user |
| `--validate` | Same as `-v` |
| `--reset-timestamp` | Same as `-K` |

### Examples

```bash
# Run command as root
sudo apt update

# Run command as specific user
sudo -u www-data vim /var/www/html/index.html

# Root shell
sudo -i

# Shell with current environment
sudo -s

# Run in background
sudo -b command

# Non-interactive (fail if password needed)
sudo -n command

# List privileges
sudo -l

# Invalidate cached credentials
sudo -k

# Edit file as root
sudo -e /etc/hosts

# Preserve specific environment variables
sudo --preserve-env=HOME,PATH command

# Run with specific group
sudo -g docker command

# Custom prompt
sudo -p "[sudo] password for %u: " command

# Multiple commands
sudo bash -c 'command1 && command2'

# Redirect output as root
sudo tee /etc/config.txt << 'EOF'
content
EOF
```

### sudo Timestamp

`sudo` caches credentials for a configurable period (default: 15 minutes). During this time, subsequent `sudo` commands don't require a password.

```bash
# Refresh timestamp
sudo -v

# Invalidate timestamp
sudo -k

# Check privileges
sudo -l
```

### Common Mistakes

1. **`sudo command > /file`**: The redirect runs as the current user. Use `sudo tee /file` or `sudo sh -c 'command > /file'`.

2. **Preserving environment**: `sudo` resets `PATH` by default. Use `--preserve-env=PATH` if needed.

3. **Using `sudo su -`**: Prefer `sudo -i` over `sudo su -`.

---

## visudo — Edit the sudoers File

### Purpose

`visudo` safely edits `/etc/sudoers` by checking syntax before saving.

### Examples

```bash
# Edit sudoers
sudo visudo

# Edit sudoers.d file
sudo visudo -f /etc/sudoers.d/myconfig

# Check syntax
sudo visudo -c

# Check specific file
sudo visudo -c -f /etc/sudoers.d/myconfig
```

### sudoers Syntax

```
# User privilege specification
root    ALL=(ALL:ALL) ALL

# Allow user to run all commands
john    ALL=(ALL:ALL) ALL

# Allow without password
john    ALL=(ALL:ALL) NOPASSWD: ALL

# Allow specific commands only
john    ALL=(ALL) /usr/bin/systemctl, /usr/bin/journalctl

# Allow group
%wheel  ALL=(ALL:ALL) ALL

# Command aliases
Cmnd_Alias SERVICES = /usr/bin/systemctl, /usr/bin/journalctl
Cmnd_Alias NETWORKING = /usr/sbin/iptables, /usr/sbin/ip

# Using aliases
john    ALL=(ALL) SERVICES
jane    ALL=(ALL) NETWORKING

# Include directory
@includedir /etc/sudoers.d

# Defaults
Defaults    env_reset
Defaults    mail_badpass
Defaults    secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
Defaults    timestamp_timeout=15

# Per-user defaults
Defaults:john timestamp_timeout=0
Defaults:jane !authenticate
```

### Common Mistakes

1. **Editing directly**: Never use `vi /etc/sudoers` — always use `visudo`. It prevents syntax errors that could lock you out.

2. **Not checking syntax**: `visudo -c` should be used to validate before saving.

3. **Ordering matters**: sudoers is read top-to-bottom, last match wins.

---

## Summary

### Quick Reference

```bash
# User management
sudo useradd -m -s /bin/bash -G wheel,docker john
sudo usermod -aG sudo john
sudo userdel -r john

# Password
sudo passwd john
sudo passwd -l john    # Lock
sudo passwd -u john    # Unlock
sudo passwd -e john    # Force change

# Information
id john
groups john
cat /etc/passwd | grep john

# Privilege escalation
sudo command
sudo -i                # Root shell
su -                   # Root via su
sudo visudo            # Edit sudoers
```

### Security Best Practices

1. **Use `sudo` instead of `su`** — better logging and granularity.
2. **Use groups** instead of giving direct sudo access.
3. **Lock unused accounts** — `passwd -l`.
4. **Set password policies** — minimum age, maximum age, complexity.
5. **Use `visudo`** — always validate sudoers syntax.
6. **Disable root login** — use sudo instead.
7. **Use SSH keys** — instead of passwords for remote access.
8. **Audit `/etc/sudoers`** — regularly review who has what access.
