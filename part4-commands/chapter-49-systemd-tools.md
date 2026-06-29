# Chapter 49: systemd Tools — systemctl, journalctl, loginctl, hostnamectl, timedatectl, localectl

## Overview

systemd is the init system and service manager for modern Linux. It manages system startup, services, logging, sessions, hostname, time, locale, and much more. The tools in this chapter provide the command-line interface to systemd's capabilities.

---

## systemctl — Control the systemd System and Service Manager

### Purpose

`systemctl` is the primary tool for managing systemd units (services, timers, mounts, devices, sockets, etc.). It controls starting, stopping, enabling, disabling, and inspecting units.

### Syntax

```
systemctl [OPTIONS...] COMMAND [UNIT...]
```

### Key Commands

**Unit Commands:**

| Command | Description |
|---------|-------------|
| `start UNIT` | Start a unit |
| `stop UNIT` | Stop a unit |
| `restart UNIT` | Restart a unit |
| `reload UNIT` | Reload configuration (without restart) |
| `try-restart UNIT` | Restart only if running |
| `reload-or-restart UNIT` | Reload if possible, else restart |
| `condrestart UNIT` | Restart only if enabled |
| `isolate UNIT` | Start unit and stop all others |
| `kill UNIT` | Send signal to unit's processes |
| `clean UNIT` | Clean runtime, cache, state data |
| `freeze UNIT` | Freeze unit's cgroup |
| `thaw UNIT` | Thaw unit's cgroup |

**Unit File Commands:**

| Command | Description |
|---------|-------------|
| `enable UNIT` | Enable unit (start at boot) |
| `disable UNIT` | Disable unit |
| `reenable UNIT` | Re-enable (update symlinks) |
| `preset UNIT` | Apply preset policy |
| `mask UNIT` | Mask unit (prevent all starts) |
| `unmask UNIT` | Unmask unit |
| `link FILE` | Link unit file |
| `is-enabled UNIT` | Check if enabled |

**Query Commands:**

| Command | Description |
|---------|-------------|
| `status UNIT` | Show unit status |
| `show UNIT` | Show unit properties |
| `show -p PROPERTY UNIT` | Show specific property |
| `cat UNIT` | Show unit file contents |
| `list-units` | List loaded units |
| `list-unit-files` | List installed unit files |
| `list-dependencies UNIT` | Show dependency tree |
| `list-timers` | List timer units |
| `list-sockets` | List socket units |
| `list-jobs` | List active jobs |
| `is-active UNIT` | Check if active |
| `is-failed UNIT` | Check if failed |
| `check UNIT` | Check if running |

**System Commands:**

| Command | Description |
|---------|-------------|
| `daemon-reload` | Reload systemd configuration |
| `daemon-reexec` | Re-execute systemd |
| `systemctl reboot` | Reboot |
| `systemctl poweroff` | Shutdown |
| `systemctl suspend` | Suspend |
| `systemctl hibernate` | Hibernate |
| `systemctl rescue` | Enter rescue mode |
| `systemctl emergency` | Enter emergency mode |
| `systemctl default` | Enter default mode |
| `systemctl set-default TARGET` | Set default target |
| `systemctl get-default` | Get default target |
| `systemctl rescue` | Switch to rescue mode |

### Key Options

| Option | Description |
|--------|-------------|
| `--type=TYPE` | Filter by unit type (service, socket, timer, etc.) |
| `--state=STATE` | Filter by state (active, inactive, failed) |
| `--all` | Show all units (including inactive) |
| `--full` | Don't truncate output |
| `--no-pager` | Don't use pager |
| `--no-wall` | Don't send wall message |
| `--now` | Also start/stop (with enable/disable) |
| `--force` | Force operation |
| `--runtime` | Make changes temporary (until reboot) |
| `--global` | Operate on global user configuration |
| `--user` | Operate on user service manager |
| `--system` | Operate on system service manager |
| `--failed` | Show failed units |
| `-H HOST` | Operate on remote host |
| `-M MACHINE` | Operate on container |
| `-l` | Don't truncate status output |
| `-n N` | Show N lines of journal output |
| `-o FORMAT` | Journal output format |
| `-q` | Suppress output |
| `--wait` | Wait until unit stops |
| `--job-mode=MODE` | Job queuing mode |

### Examples

```bash
# Service management
systemctl start nginx
systemctl stop nginx
systemctl restart nginx
systemctl reload nginx
systemctl status nginx

# Enable/disable at boot
systemctl enable nginx
systemctl disable nginx
systemctl enable --now nginx    # Enable and start

# Check status
systemctl is-active nginx
systemctl is-enabled nginx
systemctl is-failed nginx

# View unit file
systemctl cat nginx.service

# Show properties
systemctl show nginx
systemctl show -p ActiveState nginx
systemctl show -p MainPID nginx

# List units
systemctl list-units                        # Active units
systemctl list-units --type=service         # Services only
systemctl list-units --state=failed         # Failed units
systemctl list-units --all                  # All units

# List unit files
systemctl list-unit-files
systemctl list-unit-files --type=service

# Dependencies
systemctl list-dependencies nginx.service
systemctl list-dependencies --reverse nginx.service

# Mask/unmask (prevent start)
systemctl mask nginx.service
systemctl unmask nginx.service

# Reload systemd (after editing unit files)
systemctl daemon-reload

# Kill unit processes
systemctl kill nginx.service
systemctl kill -s KILL nginx.service

# System operations
systemctl reboot
systemctl poweroff
systemctl suspend
systemctl hibernate

# Set default target
systemctl set-default multi-user.target
systemctl get-default

# Show timers
systemctl list-timers
systemctl list-timers --all

# User services
systemctl --user start myservice
systemctl --user enable myservice
systemctl --user status myservice

# Show logs
systemctl status nginx -n 50    # Last 50 lines
systemctl status nginx -n 0     # No journal output

# Wait for unit to stop
systemctl start --wait myservice

# Runtime-only changes (lost on reboot)
systemctl --runtime enable myservice
```

### Unit File Locations

| Path | Description |
|------|-------------|
| `/etc/systemd/system/` | Local system units (highest priority) |
| `/run/systemd/system/` | Runtime units |
| `/usr/lib/systemd/system/` | Package-installed units |
| `~/.config/systemd/user/` | User units |

### Common Unit File Structure

```ini
[Unit]
Description=My Service
Documentation=https://example.com/docs
After=network.target
Wants=network-online.target
Requires=postgresql.service

[Service]
Type=simple
ExecStart=/usr/bin/myapp --config /etc/myapp/config.ini
ExecReload=/bin/kill -HUP $MAINPID
ExecStop=/bin/kill -TERM $MAINPID
Restart=on-failure
RestartSec=5
User=myapp
Group=myapp
WorkingDirectory=/var/lib/myapp
Environment=NODE_ENV=production
EnvironmentFile=/etc/myapp/env
LimitNOFILE=65536
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

---

## journalctl — Query the systemd Journal

### Purpose

`journalctl` queries and displays logs from the systemd journal. It replaces traditional syslog with a structured, indexed logging system.

### Key Options

| Option | Description |
|---------|-------------|
| `-u UNIT` | Show logs for specific unit |
| `-f` | Follow (tail) logs |
| `-e` | Jump to end |
| `-n N` | Show last N lines |
| `--since TIME` | Show since time |
| `--until TIME` | Show until time |
| `--no-pager` | Don't use pager |
| `-o FORMAT` | Output format |
| `-p PRIORITY` | Filter by priority |
| `-k` | Show kernel messages |
| `-b` | Show current boot |
| `-b N` | Show boot N |
| `--list-boots` | List all boots |
| `-D DIR` | Journal directory |
| `--disk-usage` | Show journal disk usage |
| `--vacuum-size=SIZE` | Reduce journal to SIZE |
| `--vacuum-time=TIME` | Remove entries older than TIME |
| `--verify` | Verify journal integrity |
| `-x` | Add explanatory text |
| `-r` | Reverse output |
| `-q` | Suppress notices |
| `--field=FIELD` | Show all values of a field |
| `-g PATTERN` | Grep (search) |
| `--cursor=CURSOR` | Start at cursor |
| `--after-cursor=CURSOR` | After cursor |
| `--show-cursor` | Show cursor |
| `_PID=PID` | Filter by PID |
| `_UID=UID` | Filter by UID |
| `_GID=GID` | Filter by GID |
| `_COMM=COMMAND` | Filter by command name |
| `_EXE=PATH` | Filter by executable |
| `_SYSTEMD_UNIT=UNIT` | Filter by systemd unit |

### Output Formats

| Format | Description |
|--------|-------------|
| `short` | Default, traditional syslog-like |
| `short-iso` | ISO 8601 timestamps |
| `short-precise` | Microsecond precision |
| `short-monotonic` | Monotonic timestamps |
| `verbose` | All fields |
| `json` | JSON format |
| `json-pretty` | Pretty-printed JSON |
| `json-sse` | JSON Server-Sent Events |
| `cat` | Message only, no metadata |
| `with-unit` | Include unit name |

### Time Specifications

```
"2024-01-15 10:30:00"    # Absolute
"2024-01-15"             # Date only
"10:30:00"               # Time today
"-2h"                    # 2 hours ago
"-1h30m"                 # 1 hour 30 minutes ago
"yesterday"              # Yesterday
"today"                  # Today
"2 days ago"             # 2 days ago
```

### Examples

```bash
# View all logs
journalctl

# Follow logs
journalctl -f

# Unit-specific logs
journalctl -u nginx.service

# Follow unit logs
journalctl -u nginx -f

# Last 100 lines
journalctl -n 100

# Since specific time
journalctl --since "2024-01-15 10:00:00"

# Since 1 hour ago
journalctl --since "-1h"

# Between times
journalctl --since "2024-01-15" --until "2024-01-16"

# Current boot
journalctl -b

# Previous boot
journalctl -b -1

# List boots
journalctl --list-boots

# Kernel messages
journalctl -k

# Filter by priority
journalctl -p err           # Errors and above
journalctl -p warning       # Warnings and above
journalctl -p..err          # Up to errors

# JSON output
journalctl -o json

# Verbose (all fields)
journalctl -o verbose

# Search (grep)
journalctl -g "error|warning"

# Filter by PID
journalctl _PID=1234

# Filter by command
journalctl _COMM=sshd

# Multiple units
journalctl -u nginx -u php-fpm

# Show disk usage
journalctl --disk-usage

# Vacuum by size
journalctl --vacuum-size=500M

# Vacuum by time
journalctl --vacuum-time=30d

# Verify journal
journalctl --verify

# Add explanatory text
journalctl -x -u nginx

# Reverse order
journalctl -r

# Specific field values
journalctl -F _SYSTEMD_UNIT

# No pager (for scripting)
journalctl --no-pager -u nginx

# Remote host
journalctl -H user@host

# Container
journalctl -M container_name

# Custom journal directory
journalctl -D /var/log/journal/
```

---

## loginctl — Control the systemd Login Manager

### Purpose

`loginctl` manages user sessions, seats, and user states.

### Key Commands

| Command | Description |
|---------|-------------|
| `list-sessions` | List sessions |
| `list-users` | List users |
| `list-seats` | List seats |
| `show-session SESSION` | Show session properties |
| `show-user USER` | Show user properties |
| `show-seat SEAT` | Show seat properties |
| `activate SESSION` | Activate session |
| `lock-session SESSION` | Lock session |
| `unlock-session SESSION` | Unlock session |
| `lock-sessions` | Lock all sessions |
| `terminate-session SESSION` | Terminate session |
| `terminate-user USER` | Terminate user's sessions |
| `kill-session SESSION` | Kill session processes |
| `enable-linger USER` | Enable lingering |
| `disable-linger USER` | Disable lingering |
| `user-status USER` | Show user status |
| `session-status SESSION` | Show session status |

### Examples

```bash
# List sessions
loginctl list-sessions

# List users
loginctl list-users

# Show session details
loginctl show-session 1

# Show user details
loginctl show-user root

# Terminate session
loginctl terminate-session 1

# Lock session
loginctl lock-session 1

# Enable lingering (user services start at boot)
loginctl enable-linger username
loginctl disable-linger username

# Show session status
loginctl session-status

# Kill session processes
loginctl kill-session 1

# User status
loginctl user-status username
```

---

## hostnamectl — Control the System Hostname

### Purpose

`hostnamectl` queries and changes the system hostname and related settings.

### Key Commands

| Command | Description |
|---------|-------------|
| `status` | Show hostname info (default) |
| `set-hostname NAME` | Set hostname |
| `set-icon-name NAME` | Set icon name |
| `set-chassis TYPE` | Set chassis type |
| `set-deployment ENV` | Set deployment environment |
| `set-location LOC` | Set location |

### Examples

```bash
# Show hostname info
hostnamectl
hostnamectl status

# Set hostname
sudo hostnamectl set-hostname myserver

# Set pretty hostname
sudo hostnamectl set-hostname "My Web Server" --pretty

# Set static hostname
sudo hostnamectl set-hostname myserver --static

# Set chassis type
sudo hostnamectl set-chassis server

# Set deployment
sudo hostnamectl set-chassis production
```

---

## timedatectl — Control the System Clock

### Purpose

`timedatectl` queries and changes the system clock, timezone, and NTP settings.

### Key Commands

| Command | Description |
|---------|-------------|
| `status` | Show clock status (default) |
| `set-time TIME` | Set system time |
| `set-timezone TZ` | Set timezone |
| `list-timezones` | List available timezones |
| `set-local-rtc BOOL` | Set RTC to local time |
| `set-ntp BOOL` | Enable/disable NTP |
| `show-timesync` | Show NTP sync status |
| `timesync-status` | Show NTP status |
| `show` | Show properties |

### Examples

```bash
# Show time status
timedatectl

# Set timezone
sudo timedatectl set-timezone Asia/Shanghai

# List timezones
timedatectl list-timezones

# Set time
sudo timedatectl set-time "2024-01-15 10:30:00"

# Enable NTP
sudo timedatectl set-ntp true

# Show NTP status
timedatectl timesync-status
timedatectl show-timesync

# Set RTC to UTC
sudo timedatectl set-local-rtc 0

# Show properties
timedatectl show
```

---

## localectl — Control System Locale and Keyboard Layout

### Purpose

`localectl` queries and changes the system locale and keyboard layout.

### Key Commands

| Command | Description |
|---------|-------------|
| `status` | Show locale status (default) |
| `set-locale LOCALE` | Set system locale |
| `list-locales` | List available locales |
| `set-keymap MAP` | Set keyboard layout |
| `list-keymaps` | List available keymaps |
| `set-x11-keymap LAYOUT` | Set X11 keyboard layout |
| `list-x11-keymaps` | List X11 layouts |

### Examples

```bash
# Show locale
localectl

# Set locale
sudo localectl set-locale LANG=en_US.UTF-8

# List available locales
localectl list-locales

# Set keyboard layout
sudo localectl set-keymap us

# List keymaps
localectl list-keymaps

# Set X11 keyboard layout
sudo localectl set-x11-keymap us
```

---

## Summary

### Quick Reference

```bash
# Service management
systemctl start|stop|restart|reload|status SERVICE
systemctl enable|disable|mask|unmask SERVICE
systemctl daemon-reload
systemctl list-units --type=service

# Logs
journalctl -u SERVICE -f        # Follow service logs
journalctl --since "-1h"        # Last hour
journalctl -p err               # Errors only
journalctl -b -1                # Previous boot

# System configuration
hostnamectl set-hostname NAME
timedatectl set-timezone TZ
timedatectl set-ntp true
localectl set-locale LANG=en_US.UTF-8

# Session management
loginctl list-sessions
loginctl terminate-session ID
loginctl enable-linger USER
```
