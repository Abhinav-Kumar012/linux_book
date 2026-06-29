# Chapter 66: Scheduling — cron, systemd timers

## Overview

Task scheduling automates recurring operations like backups, cleanup, monitoring, and maintenance. This chapter covers the traditional `cron` system and the modern `systemd` timers.

---

## cron — Time-Based Job Scheduler

### Purpose

`cron` executes commands at scheduled times. It's the traditional Unix job scheduler, running as a daemon (`crond`) that checks for scheduled tasks every minute.

### Crontab Syntax

```
# ┌───── minute (0-59)
# │ ┌───── hour (0-23)
# │ │ ┌───── day of month (1-31)
# │ │ │ ┌───── month (1-12)
# │ │ │ │ ┌───── day of week (0-6, Sunday=0)
# │ │ │ │ │
# * * * * * command
```

### Special Characters

| Character | Description |
|-----------|-------------|
| `*` | Any value |
| `,` | Value list (1,3,5) |
| `-` | Range (1-5) |
| `/` | Step (*/5 = every 5) |

### Special Strings

| String | Description |
|--------|-------------|
| `@reboot` | Run once at startup |
| `@yearly` | Once a year (0 0 1 1 *) |
| `@annually` | Same as @yearly |
| `@monthly` | Once a month (0 0 1 * *) |
| `@weekly` | Once a week (0 0 * * 0) |
| `@daily` | Once a day (0 0 * * *) |
| `@midnight` | Same as @daily |
| `@hourly` | Once an hour (0 * * * *) |

### Key Options — crontab

| Option | Description |
|--------|-------------|
| `-e` | Edit crontab |
| `-l` | List crontab |
| `-r` | Remove crontab |
| `-i` | Interactive remove |
| `-u USER` | Specify user |
| `-` | Read from stdin |

### Examples

```bash
# Edit crontab
crontab -e

# List crontab
crontab -l

# Remove crontab
crontab -r

# Edit another user's crontab (root)
sudo crontab -u john -e

# List another user's crontab (root)
sudo crontab -u john -l
```

### Crontab Examples

```bash
# Every minute
* * * * * /path/to/script.sh

# Every 5 minutes
*/5 * * * * /path/to/script.sh

# Every hour
0 * * * * /path/to/script.sh

# Every 2 hours
0 */2 * * * /path/to/script.sh

# Daily at midnight
0 0 * * * /path/to/script.sh

# Daily at 2:30 AM
30 2 * * * /path/to/script.sh

# Every Monday at 9 AM
0 9 * * 1 /path/to/script.sh

# First day of month at midnight
0 0 1 * * /path/to/script.sh

# Every weekday at 8 AM
0 8 * * 1-5 /path/to/script.sh

# Every 15 minutes during business hours
*/15 9-17 * * 1-5 /path/to/script.sh

# Twice daily (6 AM and 6 PM)
0 6,18 * * * /path/to/script.sh

# Every Sunday at 3 AM
0 3 * * 0 /path/to/script.sh

# Last day of month
59 23 28-31 * * [ "$(date -d tomorrow +\%d)" = "01" ] && /path/to/script.sh

# With environment
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
MAILTO=admin@example.com
0 2 * * * /path/to/backup.sh

# With output logging
0 2 * * * /path/to/script.sh >> /var/log/cron.log 2>&1

# With lock file (prevent overlap)
0 * * * * flock -n /tmp/script.lock /path/to/script.sh

# Run at reboot
@reboot /path/to/startup.sh

# Run once a year
@yearly /path/to/yearly.sh

# Run once a month
@monthly /path/to/monthly.sh

# Run once a week
@weekly /path/to/weekly.sh

# Run once a day
@daily /path/to/daily.sh

# Run once an hour
@hourly /path/to/hourly.sh
```

### System Crontab (/etc/crontab)

```bash
# /etc/crontab format (includes user field)
SHELL=/bin/bash
PATH=/sbin:/bin:/usr/sbin:/usr/bin
MAILTO=root

# minute hour day month weekday user command
0 2 * * * root /path/to/backup.sh
```

### Cron Directories

| Directory | Schedule |
|-----------|----------|
| `/etc/cron.d/` | Custom system crontabs |
| `/etc/cron.hourly/` | Hourly scripts |
| `/etc/cron.daily/` | Daily scripts |
| `/etc/cron.weekly/` | Weekly scripts |
| `/etc/cron.monthly/` | Monthly scripts |

```bash
# Add script to daily cron
sudo cp myscript.sh /etc/cron.daily/
sudo chmod +x /etc/cron.daily/myscript.sh

# Custom cron file in /etc/cron.d/
cat << 'EOF' | sudo tee /etc/cron.d/myapp
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin
0 2 * * * root /opt/myapp/backup.sh
EOF
```

### Common Mistakes

1. **Missing PATH**: Cron runs with minimal PATH. Always use absolute paths or set PATH in the crontab.

2. **Missing environment**: Cron doesn't load `.bashrc` or `.profile`. Set environment variables in the crontab.

3. **Output handling**: Without `MAILTO` or output redirect, cron sends email for every output. Use `>/dev/null 2>&1` to suppress.

4. **Percent signs**: `%` in cron commands is treated as newline. Escape with `\%`.

5. **Permission denied**: Scripts must be executable (`chmod +x`).

6. **Timezone**: Cron uses the system timezone. Set `CRON_TZ=Asia/Shanghai` in crontab for different timezone.

---

## systemd Timers — Modern Scheduling

### Purpose

systemd timers are the modern replacement for cron, offering more features: monotonic timers, calendar events, dependency management, logging, and resource control.

### Timer Types

| Type | Description |
|------|-------------|
| `OnCalendar` | Calendar event (like cron) |
| `OnBootSec` | After boot |
| `OnStartupSec` | After systemd start |
| `OnActiveSec` | After unit activation |
| `OnUnitActiveSec` | After unit last activated |
| `OnUnitInactiveSec` | After unit last deactivated |
| `OnCalendar` | Real-time clock events |
| `AccuracySec` | Timer accuracy |
| `RandomizedDelaySec` | Random delay |

### OnCalendar Syntax

```
# Format: DayOfWeek Year-Month-Day Hour:Minute:Second

# Examples:
*-*-* *:*:00          # Every minute
*-*-* *:00:00         # Every hour
*-*-* 00:00:00        # Every day at midnight
Mon *-*-* 09:00:00    # Every Monday at 9 AM
*-*-01 00:00:00       # First day of month
*-*-* 02,14:30:00     # 2:30 AM and 2:30 PM
Mon..Fri *-*-* 08:00:00 # Weekdays at 8 AM
Sat,Sun *-*-* 10:00:00 # Weekends at 10 AM
hourly                 # Every hour
daily                  # Every day
weekly                 # Every week
monthly                # Every month
yearly                 # Every year
```

### Timer Unit File

```ini
# /etc/systemd/system/myapp-backup.timer
[Unit]
Description=Daily backup timer

[Timer]
OnCalendar=*-*-* 02:00:00
RandomizedDelaySec=300
Persistent=true
AccuracySec=1min

[Install]
WantedBy=timers.target
```

```ini
# /etc/systemd/system/myapp-backup.service
[Unit]
Description=MyApp Backup

[Service]
Type=oneshot
ExecStart=/opt/myapp/backup.sh
User=myapp
Group=myapp
```

### Timer Options

| Option | Description |
|--------|-------------|
| `OnCalendar` | Calendar event |
| `OnBootSec` | Time after boot |
| `OnStartupSec` | Time after startup |
| `OnActiveSec` | Time after activation |
| `OnUnitActiveSec` | Time after last activation |
| `OnUnitInactiveSec` | Time after last deactivation |
| `AccuracySec` | Timer accuracy (default 1min) |
| `RandomizedDelaySec` | Random delay |
| `Persistent` | Run if missed |
| `WakeSystem` | Wake system from sleep |
| `Unit` | Unit to activate |
| `RemainAfterElapse` | Remain active after elapse |

### Examples

```bash
# List timers
systemctl list-timers
systemctl list-timers --all

# Enable timer
sudo systemctl enable myapp-backup.timer
sudo systemctl start myapp-backup.timer

# Check timer status
systemctl status myapp-backup.timer

# Check service status
systemctl status myapp-backup.service

# Disable timer
sudo systemctl disable myapp-backup.timer

# Reload after editing
sudo systemctl daemon-reload

# Show timer properties
systemctl show myapp-backup.timer
```

### Timer Examples

```ini
# Every 5 minutes
[Timer]
OnBootSec=5min
OnUnitActiveSec=5min

# Daily at 2 AM
[Timer]
OnCalendar=*-*-* 02:00:00
Persistent=true

# Every Monday at 9 AM
[Timer]
OnCalendar=Mon *-*-* 09:00:00

# Every hour
[Timer]
OnCalendar=hourly

# After boot, then every hour
[Timer]
OnBootSec=5min
OnUnitActiveSec=1h

# Weekdays at 8 AM
[Timer]
OnCalendar=Mon..Fri *-*-* 08:00:00

# First Monday of month
[Timer]
OnCalendar=Mon *-*-01..07 09:00:00

# With random delay
[Timer]
OnCalendar=*-*-* 02:00:00
RandomizedDelaySec=30min
Persistent=true

# With accuracy
[Timer]
OnCalendar=*-*-* 02:00:00
AccuracySec=1h
```

### Calendar Event Syntax

```
# Components:
# DayOfWeek Year-Month-Day Hour:Minute:Second

# Special strings:
minutely    # *-*-* *:*:00
hourly      # *-*-* *:00:00
daily       # *-*-* 00:00:00
weekly      # Mon *-*-* 00:00:00
monthly     # *-*-01 00:00:00
yearly      # *-01-01 00:00:00
quarterly   # *-01,04,07,10-01 00:00:00
semi-annually # *-01,07-01 00:00:00

# Ranges:
Mon..Fri    # Monday through Friday
01..05      # 1st through 5th

# Lists:
Mon,Wed,Fri # Monday, Wednesday, Friday

# Wildcards:
*           # Any value
```

### Monitoring

```bash
# Show timer schedule
systemctl list-timers

# Show all timers
systemctl list-timers --all

# Show specific timer
systemctl show myapp-backup.timer

# View logs
journalctl -u myapp-backup.service
journalctl -u myapp-backup.timer

# Check when timer last ran
systemctl show myapp-backup.timer -p LastTriggerUSec

# Check next run
systemctl show myapp-backup.timer -p NextElapseUSecRealtime
```

---

## Comparison: cron vs systemd timers

| Feature | cron | systemd timers |
|---------|------|----------------|
| Calendar events | ✓ | ✓ |
| Monotonic timers | ✗ | ✓ |
| Dependencies | ✗ | ✓ |
| Resource control | ✗ | ✓ |
| Logging | Manual | Built-in (journal) |
| Missed runs | ✗ | ✓ (Persistent) |
| Random delay | ✗ | ✓ |
| Accuracy | 1 minute | Configurable |
| Calendar syntax | Crontab | OnCalendar |
| User jobs | ✓ | ✓ |
| System jobs | ✓ | ✓ |
| Logging | Syslog | Journal |

---

## Summary

### Quick Reference

```bash
# cron
crontab -e                              # Edit crontab
crontab -l                              # List crontab
sudo crontab -u user -e                 # Edit user's crontab

# systemd timers
systemctl list-timers                   # List timers
systemctl enable myapp.timer            # Enable
systemctl start myapp.timer             # Start
journalctl -u myapp.service             # View logs
```

### Best Practices

1. **Use absolute paths** in cron commands.
2. **Redirect output** or set MAILTO.
3. **Use lock files** to prevent overlapping runs.
4. **Set PATH** in crontab for cron jobs.
5. **Use Persistent=true** for systemd timers.
6. **Add RandomizedDelaySec** to prevent thundering herd.
7. **Log everything** for debugging.
8. **Test manually** before scheduling.
9. **Use systemd timers** for new projects (better logging, dependencies).
10. **Document** scheduled tasks.
