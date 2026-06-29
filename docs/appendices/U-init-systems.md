# Appendix U: Init Systems Comparison

## Overview

This appendix compares four Linux init systems: systemd, OpenRC, SysVinit, and runit. Each is evaluated on features, performance, and philosophy.

---

## 1. Feature Comparison Matrix

| Feature | systemd | OpenRC | SysVinit | runit |
|---------|---------|--------|----------|-------|
| **Default in** | Most distros | Gentoo, Alpine | Debian (old), Slackware | Void Linux |
| **PID 1** | Yes | No (uses `/sbin/init`) | Yes | Yes |
| **Parallel startup** | Yes | Yes | No | Yes |
| **Dependency management** | Excellent | Good | Basic (LSB headers) | Minimal |
| **Socket activation** | Yes | No | No | No |
| **D-Bus activation** | Yes | No | No | No |
| **Device management** | Yes (udev) | Separate (mdev/eudev) | Separate (udev) | Separate (mdev) |
| **Journal/logging** | journald | syslog | syslog | syslog |
| **Timer/cron** | timers | cron | cron | cron |
| **Cgroups** | Integrated | Optional | No | No |
| **Resource limits** | Integrated | PAM limits | PAM limits | PAM limits |
| **Watchdog** | Integrated | External | External | External |
| **Container support** | systemd-nspawn | No | No | No |
| **User services** | Yes | No | No | No |
| **Network management** | systemd-networkd | netifrc | Separate | Separate |
| **DNS resolution** | systemd-resolved | Separate | Separate | Separate |
| **Boot charting** | systemd-analyze | bootchart | bootchart | bootchart |
| **Service supervision** | Yes | Yes (with start-stop-daemon) | No | Yes |
| **Process tracking** | cgroups | pidfiles | pidfiles | Direct |
| **Re-exec** | Yes | No | No | No |
| **API/IPC** | D-Bus | Shell | Shell | Shell |
| **Complexity** | High | Medium | Low | Very low |
| **POSIX compliance** | No | Yes | Yes | Yes |

---

## 2. systemd

### Unit Types

| Type | Extension | Description |
|------|-----------|-------------|
| Service | `.service` | System services |
| Socket | `.socket` | Socket-activated services |
| Timer | `.timer` | Scheduled tasks (like cron) |
| Mount | `.mount` | Filesystem mounts |
| Automount | `.automount` | On-demand mounts |
| Target | `.target` | Grouping of units |
| Device | `.device` | Device units |
| Swap | `.swap` | Swap partitions/files |
| Path | `.path` | Path-based activation |
| Slice | `.slice` | Cgroup management |
| Scope | `.scope` | Externally created processes |

### Service Unit Example

```ini
# /etc/systemd/system/myapp.service
[Unit]
Description=My Application
Documentation=https://example.com/docs
After=network-online.target
Wants=network-online.target
Requires=postgresql.service

[Service]
Type=notify
User=myapp
Group=myapp
WorkingDirectory=/opt/myapp
ExecStartPre=/opt/myapp/pre-start.sh
ExecStart=/opt/myapp/bin/server --config /etc/myapp/config.yml
ExecReload=/bin/kill -HUP $MAINPID
ExecStop=/opt/myapp/bin/server --stop
Restart=on-failure
RestartSec=5
TimeoutStartSec=30
TimeoutStopSec=30

# Security
NoNewPrivileges=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=/var/lib/myapp /var/log/myapp
PrivateTmp=yes
ProtectKernelTunables=yes
ProtectKernelModules=yes
ProtectControlGroups=yes
RestrictSUIDSGID=yes
MemoryMax=1G
CPUQuota=80%

# Environment
Environment=NODE_ENV=production
EnvironmentFile=/etc/myapp/env

# Logging
StandardOutput=journal
StandardError=journal
SyslogIdentifier=myapp

[Install]
WantedBy=multi-user.target
```

### Common Commands

```bash
# Service management
sudo systemctl start nginx
sudo systemctl stop nginx
sudo systemctl restart nginx
sudo systemctl reload nginx
sudo systemctl status nginx

# Enable/disable at boot
sudo systemctl enable nginx
sudo systemctl disable nginx
sudo systemctl enable --now nginx  # Enable and start

# List units
systemctl list-units
systemctl list-units --type=service
systemctl list-units --state=running
systemctl list-unit-files

# Journal
journalctl -u nginx
journalctl -u nginx -f           # Follow
journalctl -u nginx --since today
journalctl -u nginx -n 100       # Last 100 lines
journalctl -u nginx -p err       # Errors only

# System analysis
systemd-analyze
systemd-analyze blame
systemd-analyze critical-chain
systemd-analyze plot > boot.svg

# Mask/unmask
sudo systemctl mask nginx        # Prevent starting
sudo systemctl unmask nginx

# Edit unit
sudo systemctl edit nginx        # Override
sudo systemctl edit --full nginx # Full edit

# Reload systemd
sudo systemctl daemon-reload

# Power management
sudo systemctl reboot
sudo systemctl poweroff
sudo systemctl suspend
sudo systemctl hibernate
```

### Timer Unit Example

```ini
# /etc/systemd/system/backup.timer
[Unit]
Description=Daily backup timer

[Timer]
OnCalendar=*-*-* 02:00:00
Persistent=true
RandomizedDelaySec=1800

[Install]
WantedBy=timers.target
```

```ini
# /etc/systemd/system/backup.service
[Unit]
Description=Backup service

[Service]
Type=oneshot
ExecStart=/opt/backup/backup.sh
User=backup
```

---

## 3. OpenRC

### Init Scripts

```bash
#!/sbin/openrc-run
# /etc/init.d/myapp

description="My Application"
command="/usr/bin/myapp"
command_args="--config /etc/myapp/config.yml"
command_user="myapp:myapp"
command_background=true
pidfile="/run/myapp.pid"

depend() {
    need net
    after postgresql
    use logger
}

start_pre() {
    checkpath --directory --owner myapp:myapp /run/myapp
    /usr/bin/myapp --check-config || return 1
}

start() {
    ebegin "Starting myapp"
    start-stop-daemon --start --exec $command \
        --user $command_user \
        --pidfile $pidfile \
        --background \
        --make-pidfile \
        -- $command_args
    eend $?
}

stop() {
    ebegin "Stopping myapp"
    start-stop-daemon --stop --pidfile $pidfile --retry TERM/30/KILL/5
    eend $?
}

reload() {
    ebegin "Reloading myapp"
    start-stop-daemon --signal HUP --pidfile $pidfile
    eend $?
}
```

### Common Commands

```bash
# Service management
sudo rc-service nginx start
sudo rc-service nginx stop
sudo rc-service nginx restart
sudo rc-service nginx status

# Enable/disable at boot
sudo rc-update add nginx default
sudo rc-update del nginx default
sudo rc-update show

# List services
rc-status -a

# Runlevel management
sudo rc-update add nginx boot
sudo rc-update add nginx default
sudo rc-update add nginx nonetwork

# Check service status
rc-status -s

# Interactive
sudo /etc/init.d/nginx start
```

### Configuration

```bash
# /etc/conf.d/myapp
MYAPP_OPTS="--config /etc/myapp/config.yml"
MYAPP_USER="myapp"
MYAPP_LOG="/var/log/myapp.log"

# /etc/rc.conf
rc_parallel="YES"
rc_logger="YES"
rc_sys=""
```

---

## 4. SysVinit

### Init Scripts

```bash
#!/bin/bash
# /etc/init.d/myapp
### BEGIN INIT INFO
# Provides:          myapp
# Required-Start:    $network $postgresql
# Required-Stop:     $network
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: My Application
# Description:       My Application Server
### END INIT INFO

NAME="myapp"
DAEMON="/usr/bin/myapp"
DAEMON_ARGS="--config /etc/myapp/config.yml"
PIDFILE="/var/run/myapp.pid"
USER="myapp"

. /lib/lsb/init-functions

case "$1" in
    start)
        log_daemon_msg "Starting $NAME"
        start-stop-daemon --start --quiet --background \
            --make-pidfile --pidfile $PIDFILE \
            --chuid $USER --exec $DAEMON -- $DAEMON_ARGS
        log_end_msg $?
        ;;
    stop)
        log_daemon_msg "Stopping $NAME"
        start-stop-daemon --stop --quiet --pidfile $PIDFILE \
            --retry=TERM/30/KILL/5
        log_end_msg $?
        rm -f $PIDFILE
        ;;
    restart)
        $0 stop
        sleep 1
        $0 start
        ;;
    status)
        status_of_proc -p $PIDFILE $DAEMON $NAME
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status}"
        exit 1
        ;;
esac

exit 0
```

### Common Commands

```bash
# Service management
sudo service nginx start
sudo service nginx stop
sudo service nginx restart
sudo service nginx status

# Enable/disable at boot
sudo update-rc.d nginx enable
sudo update-rc.d nginx disable
sudo update-rc.d nginx defaults

# RHEL/CentOS
sudo chkconfig nginx on
sudo chkconfig nginx off
sudo chkconfig --list nginx

# Runlevel management
sudo runlevel
sudo telinit 3

# List services
ls /etc/init.d/
service --status-all
```

---

## 5. runit

### Service Directories

```bash
# /etc/sv/myapp/run
#!/bin/sh
exec chpst -u myapp:myapp /usr/bin/myapp --config /etc/myapp/config.yml 2>&1
```

```bash
# /etc/sv/myapp/finish
#!/bin/sh
# Optional cleanup on exit
```

```bash
# /etc/sv/myapp/log/run
#!/bin/sh
exec svlogd -tt /var/log/myapp/
```

### Common Commands

```bash
# Service management
sudo sv start nginx
sudo sv stop nginx
sudo sv restart nginx
sudo sv status nginx

# Enable service
sudo ln -s /etc/sv/nginx /var/service/

# Disable service
sudo rm /var/service/nginx

# List services
ls /var/service/

# Check status
sv status /var/service/*

# Send signals
sv hup nginx      # SIGHUP
sv term nginx      # SIGTERM
sv kill nginx      # SIGKILL
sv pause nginx     # SIGSTOP
sv cont nginx      # SIGCONT
sv alarm nginx     # SIGALRM
sv 1 nginx         # SIGUSR1

# Control
sv once nginx      # Run once
sv check nginx     # Check if running
sv exit nginx      # Exit service

# Supervise specific service
sv -v start nginx

# Log service
svlogd /var/log/myapp/
```

---

## 6. Service Type Comparison

### Starting a Service at Boot

| Init System | Command |
|-------------|---------|
| systemd | `systemctl enable nginx` |
| OpenRC | `rc-update add nginx default` |
| SysVinit | `update-rc.d nginx enable` |
| runit | `ln -s /etc/sv/nginx /var/service/` |

### Restarting a Service

| Init System | Command |
|-------------|---------|
| systemd | `systemctl restart nginx` |
| OpenRC | `rc-service nginx restart` |
| SysVinit | `service nginx restart` |
| runit | `sv restart nginx` |

### Checking Service Status

| Init System | Command |
|-------------|---------|
| systemd | `systemctl status nginx` |
| OpenRC | `rc-service nginx status` |
| SysVinit | `service nginx status` |
| runit | `sv status nginx` |

### Viewing Logs

| Init System | Command |
|-------------|---------|
| systemd | `journalctl -u nginx` |
| OpenRC | `cat /var/log/nginx/error.log` |
| SysVinit | `cat /var/log/nginx/error.log` |
| runit | `cat /var/log/nginx/current` |

---

## 7. Selection Guide

| Scenario | Recommended | Notes |
|----------|-------------|-------|
| Desktop/Server (general) | systemd | Most features, best tooling |
| Minimal/Embedded | runit | Tiny footprint, simple |
| Gentoo/Alpine | OpenRC | Native support |
| Legacy systems | SysVinit | Maximum compatibility |
| Containers | runit | Minimal overhead |
| Service supervision | runit or systemd | Both handle restarts well |
| Complex dependencies | systemd | Best dependency management |
| POSIX compliance | OpenRC/SysVinit/runit | Shell scripts, portable |

---

*Each init system has documentation in its respective man pages and online resources.*
