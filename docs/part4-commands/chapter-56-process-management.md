# Chapter 56: Process Management — ps, top, htop, pstree, kill, killall, pkill, pgrep

## Overview

Process management is fundamental to Linux system administration. Every running program is a process, and understanding how to list, monitor, signal, and control processes is essential for troubleshooting, performance tuning, and system maintenance.

---

## ps — Process Status

### Purpose

`ps` displays information about running processes.

### Syntax Styles

```bash
# BSD style (no dash)
ps aux
ps axjf

# UNIX style (single dash)
ps -ef
ps -ejH

# GNU style (double dash)
ps --forest
```

### Key Options (BSD Style)

| Option | Description |
|--------|-------------|
| `a` | All processes on terminal |
| `u` | User-oriented format |
| `x` | Include processes without controlling terminal |
| `f` | Forest (tree) format |
| `j` | Jobs format |
| `l` | Long format |
| `v` | Virtual memory format |
| `s` | Signal format |
| `m` | Show threads |
| `e` | Show environment |
| `c` | Show command name only |
| `w` | Wide output |
| `ww` | Unlimited width |

### Key Options (UNIX Style)

| Option | Description |
|--------|-------------|
| `-e` | All processes |
| `-f` | Full format |
| `-F` | Extra full format |
| `-H` | Forest (tree) |
| `-j` | Jobs format |
| `-l` | Long format |
| `-o FORMAT` | Custom format |
| `-p PID` | Specific PID |
| `-u USER` | Specific user |
| `-t TTY` | Specific terminal |
| `-C NAME` | By command name |
| `--sort KEY` | Sort by key |
| `--no-headers` | No header |
| `--cols N` | Set width |
| `--rows N` | Set height |

### Output Columns

| Column | Description |
|--------|-------------|
| `PID` | Process ID |
| `PPID` | Parent PID |
| `USER` | Process owner |
| `%CPU` | CPU usage |
| `%MEM` | Memory usage |
| `VSZ` | Virtual memory size (KB) |
| `RSS` | Resident set size (KB) |
| `TTY` | Controlling terminal |
| `STAT` | Process state |
| `START` | Start time |
| `TIME` | CPU time |
| `CMD` | Command |

### Process States

| State | Description |
|-------|-------------|
| `R` | Running or runnable |
| `S` | Sleeping (interruptible) |
| `D` | Sleeping (uninterruptible, usually I/O) |
| `Z` | Zombie (terminated, not waited on) |
| `T` | Stopped (by signal) |
| `t` | Traced (stopped by debugger) |
| `I` | Idle kernel thread |

### State Modifiers

| Modifier | Description |
|----------|-------------|
| `<` | High priority |
| `N` | Low priority |
| `L` | Has pages locked in memory |
| `s` | Session leader |
| `l` | Multi-threaded |
| `+` | Foreground process group |

### Custom Format (`-o`)

| Format | Description |
|--------|-------------|
| `pid` | Process ID |
| `ppid` | Parent PID |
| `user` | Username |
| `uid` | User ID |
| `group` | Group name |
| `gid` | Group ID |
| `comm` | Command name |
| `args` | Full command |
| `%cpu` | CPU percentage |
| `%mem` | Memory percentage |
| `vsz` | Virtual size |
| `rss` | Resident size |
| `stat` | State |
| `tty` | Terminal |
| `etime` | Elapsed time |
| `time` | CPU time |
| `nice` | Nice value |
| `pri` | Priority |
| `nlwp` | Thread count |
| `psr` | Processor |
| `pcpu` | Same as `%cpu` |
| `pmem` | Same as `%mem` |
| `thcount` | Thread count |
| `start` | Start time |
| `lstart` | Full start time |
| `sz` | Size in pages |

### Examples

```bash
# All processes (BSD style)
ps aux

# All processes (UNIX style)
ps -ef

# User's processes
ps -u username

# By PID
ps -p 1234,5678

# By command name
ps -C nginx

# By terminal
ps -t pts/0

# Custom format
ps -eo pid,ppid,user,%cpu,%mem,stat,cmd

# Sort by CPU
ps aux --sort=-%cpu

# Sort by memory
ps aux --sort=-%mem

# Tree view
ps auxf
ps -ejH
ps --forest

# Show threads
ps -eLf
ps -m

# Wide output
ps auxww

# No headers
ps -eo pid,user,cmd --no-headers

# Show environment
ps -e | head -5

# Zombie processes
ps aux | awk '$8 ~ /Z/'

# Top 10 CPU consumers
ps aux --sort=-%cpu | head -11

# Top 10 memory consumers
ps aux --sort=-%mem | head -11

# Process tree
ps axjf

# Show thread count
ps -eo pid,nlwp,comm

# Elapsed time
ps -eo pid,etime,comm

# Specific format with separator
ps -eo pid=,user=,comm= --no-headers

# Long start time
ps -eo pid,lstart,comm

# Show all processes as a tree
ps -ejH --forest

# Custom wide format
ps -eo pid,ppid,user,%cpu,%mem,vsz,rss,tty,stat,start,time,comm --sort=-%cpu
```

---

## top — Task Manager

### Purpose

`top` displays real-time system process information, including CPU usage, memory usage, and running processes.

### Key Options

| Option | Description |
|--------|-------------|
| `-d SECS` | Refresh delay |
| `-n NUM` | Number of iterations |
| `-p PID` | Monitor specific PID |
| `-u USER` | Monitor specific user |
| `-b` | Batch mode |
| `-c` | Show full command line |
| `-H` | Show threads |
| `-i` | Hide idle processes |
| `-S` | Cumulative mode |
| `-o FIELD` | Sort by field |
| `-w [N]` | Set width |

### Interactive Commands

| Key | Action |
|-----|--------|
| `1` | Toggle individual CPU cores |
| `M` | Sort by memory |
| `P` | Sort by CPU |
| `T` | Sort by time |
| `N` | Sort by PID |
| `R` | Reverse sort |
| `k` | Kill process |
| `r` | Renice process |
| `u` | Filter by user |
| `f` | Select fields |
| `o` | Set sort field |
| `c` | Toggle command line |
| `H` | Toggle threads |
| `i` | Toggle idle |
| `S` | Toggle cumulative |
| `V` | Toggle forest view |
| `W` | Save configuration |
| `q` | Quit |
| `h` | Help |
| `Space` | Refresh |
| `d` | Change delay |
| `=` | Remove filters |
| `A` | Alternate display |
| `B` | Bold enable |
| `z` | Color toggle |

### Header Information

```
top - 14:30:00 up 10 days,  3:15,  2 users,  load average: 0.50, 0.75, 0.80
Tasks: 250 total,   2 running, 248 sleeping,   0 stopped,   0 zombie
%Cpu(s):  5.0 us,  2.0 sy,  0.0 ni, 92.5 id,  0.3 wa,  0.0 hi,  0.2 si,  0.0 st
MiB Mem :  16000.0 total,   8000.0 free,   4000.0 used,   4000.0 buff/cache
MiB Swap:   4096.0 total,   4000.0 free,     96.0 used.  11000.0 avail Mem
```

| Field | Description |
|-------|-------------|
| `us` | User-space CPU time |
| `sy` | Kernel CPU time |
| `ni` | Nice (low-priority) CPU time |
| `id` | Idle CPU |
| `wa` | I/O wait |
| `hi` | Hardware interrupt |
| `si` | Software interrupt |
| `st` | Steal time (virtualization) |

### Examples

```bash
# Basic usage
top

# Specific refresh rate
top -d 0.5

# Monitor specific PID
top -p 1234

# Monitor specific user
top -u john

# Show threads
top -H

# Batch mode (for scripting)
top -bn1

# Batch mode with specific count
top -bn5 -d 2

# Sort by memory
top -o %MEM

# Full command
top -c

# Hide idle
top -i

# Wide mode
top -w 512
```

---

## htop — Interactive Process Viewer

### Purpose

`htop` is an enhanced interactive process viewer with better UI than `top`.

### Key Options

| Option | Description |
|--------|-------------|
| `-d DELAY` | Refresh delay |
| `-u USER` | Filter by user |
| `-p PID` | Monitor specific PID |
| `-t` | Tree view |
| `-s COLUMN` | Sort by column |
| `-C COLUMN` | Highlight sort column |
| `--no-color` | Monochrome |
| `--no-mouse` | Disable mouse |
| `--pid=PID,...` | Monitor specific PIDs |
| `-H` | Show threads |

### Interactive Commands

| Key | Action |
|-----|--------|
| `F1` | Help |
| `F2` | Setup |
| `F3` | Search |
| `F4` | Filter |
| `F5` | Tree view |
| `F6` | Sort by |
| `F9` | Kill |
| `F10` | Quit |
| `Space` | Tag process |
| `U` | Untag all |
| `c` | Tag/collapse tree |
| `u` | Filter by user |
| `H` | Toggle threads |
| `K` | Hide kernel threads |
| `p` | Show full path |
| `t` | Tree view |
| `s` | Strace |
| `l` | Lsof |
| `e` | Environment |
| `a` | Set CPU affinity |

---

## pstree — Process Tree

### Purpose

`pstree` displays running processes as a tree.

### Examples

```bash
# Basic tree
pstree

# With PIDs
pstree -p

# Specific user
pstree john

# Specific PID
pstree 1234

# Show parent PID
pstree -p -s 1234

# Compact output
pstree -c

# Highlight current process
pstree -h

# Show process groups
pstree -g

# ASCII characters
pstree -A
```

---

## kill — Send Signal to Process

### Purpose

`kill` sends signals to processes.

### Common Signals

| Signal | Number | Description |
|--------|--------|-------------|
| `SIGHUP` | 1 | Hangup (reload config) |
| `SIGINT` | 2 | Interrupt (Ctrl+C) |
| `SIGQUIT` | 3 | Quit (with core dump) |
| `SIGKILL` | 9 | Force kill (uncatchable) |
| `SIGTERM` | 15 | Graceful termination (default) |
| `SIGSTOP` | 19 | Stop process (uncatchable) |
| `SIGCONT` | 18 | Continue stopped process |
| `SIGUSR1` | 10 | User-defined 1 |
| `SIGUSR2` | 12 | User-defined 2 |
| `SIGCHLD` | 17 | Child terminated |
| `SIGPIPE` | 13 | Broken pipe |
| `SIGALRM` | 14 | Timer |
| `SIGTSTP` | 20 | Terminal stop (Ctrl+Z) |

### Examples

```bash
# Graceful kill (default SIGTERM)
kill 1234

# Force kill
kill -9 1234
kill -KILL 1234

# Send SIGHUP (reload)
kill -HUP 1234

# Send SIGUSR1
kill -USR1 1234

# List signals
kill -l

# Send to process group
kill -TERM -1234

# Multiple PIDs
kill 1234 5678
```

---

## killall — Kill by Name

### Purpose

`killall` kills processes by name.

### Examples

```bash
# Kill by name
killall nginx

# Force kill
killall -9 nginx

# Kill by user
killall -u john nginx

# Interactive (ask before kill)
killall -i nginx

# Case-insensitive
killall -I nginx

# Verbose
killall -v nginx

# Exact match
killall -e nginx

# Signal
killall -HUP nginx
```

---

## pkill — Kill by Pattern

### Purpose

`pkill` kills processes based on name and other attributes.

### Examples

```bash
# Kill by name
pkill nginx

# Kill by full command
pkill -f "python app.py"

# Kill by user
pkill -u john

# Force kill
pkill -9 nginx

# Signal
pkill -HUP nginx

# Interactive
pkill -i nginx

# Newest
pkill -n nginx

# Oldest
pkill -o nginx

# Exact match
pkill -x nginx

# Verbose
pkill -v nginx
```

---

## pgrep — Find Process by Name

### Purpose

`pgrep` finds processes based on name and attributes.

### Examples

```bash
# Find by name
pgrep nginx

# Find with full info
pgrep -a nginx

# Find with command line
pgrep -f "python app.py"

# Find by user
pgrep -u john

# Count processes
pgrep -c nginx

# Newest only
pgrep -n nginx

# Oldest only
pgrep -o nginx

# List PIDs and names
pgrep -l nginx

# Full command
pgrep -a nginx

# Exact match
pgrep -x nginx

# Inverse match
pgrep -v nginx

# With parent PID
pgrep -P 1234
```

---

## Summary

### Quick Reference

```bash
# List processes
ps aux                          # All processes
ps aux --sort=-%cpu | head      # Top CPU
ps aux --sort=-%mem | head      # Top memory
ps axjf                         # Process tree

# Monitor
top                             # Interactive
htop                            # Enhanced
pstree -p                       # Tree with PIDs

# Signal processes
kill -TERM 1234                 # Graceful
kill -9 1234                    # Force
killall nginx                   # By name
pkill -f "python app.py"       # By pattern

# Find processes
pgrep nginx                     # PIDs by name
pgrep -a nginx                  # With names
pgrep -f "pattern"             # Full command match
```
