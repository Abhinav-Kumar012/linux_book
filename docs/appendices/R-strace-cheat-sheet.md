# Appendix R: strace Cheat Sheet

## Overview

`strace` traces system calls and signals. This cheat sheet covers filtering, formatting, common patterns, and troubleshooting techniques.

---

## 1. Basic Usage

```bash
# Trace a command
strace ./program

# Trace with command arguments
strace ls -la /tmp

# Trace running process
strace -p 1234

# Trace with PID
strace -p 1234 -p 5678

# Trace child processes
strace -f ./program

# Trace only specific syscalls
strace -e trace=open,read,write ./program

# Trace all except specific syscalls
strace -e trace=!read,write ./program

# Output to file
strace -o trace.log ./program

# Append to file
strace -a trace.log ./program

# Follow forks
strace -f -o trace.log ./program

# Trace threads
strace -f -ff -o trace ./program  # Separate file per thread
```

---

## 2. Filtering Syscalls

### By Syscall Category

```bash
# Trace file operations
strace -e trace=file ./program

# Trace network operations
strace -e trace=network ./program

# Trace process management
strace -e trace=process ./program

# Trace signal handling
strace -e trace=signal ./program

# Trace IPC
strace -e trace=ipc ./program

# Trace memory operations
strace -e trace=memory ./program

# Trace descriptor operations
strace -e trace=desc ./program

# Trace I/O operations
strace -e trace=io ./program

# Trace filesystem operations
strace -e trace=fs ./program

# Trace all except specific category
strace -e trace=!memory ./program
```

### By Specific Syscall

```bash
# Trace specific syscalls
strace -e trace=open,openat,close ./program

# Trace with wildcards (not all versions)
strace -e trace=open* ./program

# Trace multiple categories
strace -e trace=file,network ./program

# Exclude specific syscalls
strace -e trace=!futex,!futex_wait ./program
```

---

## 3. Formatting Options

### Timestamp

```bash
# Relative timestamp (seconds since trace start)
strace -r ./program

# Absolute timestamp
strace -t ./program

# Absolute timestamp with microseconds
strace -tt ./program

# Absolute timestamp with ISO format
strace -ttt ./program

# Wall clock time
strace -T ./program  # Shows time spent in each syscall
```

### Output Control

```bash
# Abbreviate large structures
strace -s 128 ./program   # String limit to 128 chars

# Verbose (don't abbreviate)
strace -v ./program

# Very verbose
strace -vv ./program

# Show all strings
strace -s 0 ./program

# Print in hex
strace -x ./program

# Print in octal
strace -o ./program

# Print strings in hex
strace -xx ./program

# Show path of file descriptors
strace -y ./program

# Show protocol buffers
strace -e read=3 ./program  # Print read data from fd 3

# Print timestamps for each syscall
strace -T ./program

# Print syscall numbers
strace -i ./program

# Print process/thread ID
strace -f ./program

# Align output
strace -a 0 ./program  # No alignment
strace -a 40 ./program # Align at column 40
```

---

## 4. Common Patterns

### File Operations

```bash
# Trace file opens
strace -e trace=open,openat -f ./program 2>&1 | grep -v ENOENT

# Trace file reads/writes
strace -e trace=read,write ./program

# Trace specific file access
strace -e trace=open,openat ./program 2>&1 | grep "config"

# Trace file stat operations
strace -e trace=stat,lstat,fstat,statx ./program

# Trace directory operations
strace -e trace=mkdir,rmdir,rename,unlink,link,symlink ./program

# Trace file permissions
strace -e trace=chmod,fchmod,chown,fchown ./program
```

### Network Operations

```bash
# Trace network connections
strace -e trace=connect,accept,bind,listen ./program

# Trace send/recv
strace -e trace=sendto,recvfrom,sendmsg,recvmsg ./program

# Trace DNS (getaddrinfo)
strace -e trace=connect,sendto,recvfrom ./program 2>&1 | grep 53

# Trace socket creation
strace -e trace=socket,socketpair ./program

# Trace with data
strace -e read=3,write=4 -s 1000 ./program  # Show read/write data
```

### Process Management

```bash
# Trace fork/exec
strace -e trace=fork,clone,execve,wait4 ./program

# Trace signal handling
strace -e trace=signal ./program

# Trace exit
strace -e trace=exit,exit_group ./program

# Trace threads
strace -e trace=clone,futex -f ./program
```

### Memory Operations

```bash
# Trace mmap/munmap
strace -e trace=mmap,munmap,brk,mprotect ./program

# Trace memory allocation patterns
strace -e trace=mmap,munmap,brk ./program 2>&1 | head -100
```

---

## 5. Troubleshooting Recipes

### Find Missing Files

```bash
# Trace opens and find failures
strace -e trace=open,openat ./program 2>&1 | grep ENOENT

# Trace with full paths
strace -e trace=open,openat -y ./program 2>&1 | grep ENOENT

# Show all failed opens
strace -e trace=open,openat ./program 2>&1 | grep -v "= [0-9]"
```

### Debug Permission Issues

```bash
# Find permission denied errors
strace -e trace=open,openat,access,faccessat ./program 2>&1 | grep EACCES

# Trace with stat
strace -e trace=open,openat,stat,lstat,fstat ./program 2>&1 | grep -E "EACCES|EPERM"
```

### Debug Connection Issues

```bash
# Trace connect failures
strace -e trace=connect ./program 2>&1 | grep -E "ECONNREFUSED|ETIMEDOUT|ENETUNREACH"

# Trace with timing
strace -e trace=connect -T ./program 2>&1 | grep connect

# Trace DNS resolution
strace -e trace=connect,sendto,recvfrom -f ./program 2>&1 | grep -A2 "port=0035"
```

### Debug Slow Programs

```bash
# Show time spent in each syscall
strace -T ./program 2>&1 | sort -t= -k2 -rn | head -20

# Show time per syscall type
strace -T -c ./program

# Show cumulative time
strace -c ./program

# Trace with wall clock time
strace -tt -T ./program
```

### Debug Signal Issues

```bash
# Trace signal handling
strace -e trace=signal ./program

# Trace with signal details
strace -e trace=signal -v ./program

# Trace kill signals
strace -e trace=kill,tgkill,tkill ./program
```

---

## 6. Statistics Mode

```bash
# Summary of syscall counts
strace -c ./program

# Summary with time
strace -c -T ./program

# Sort by time
strace -c -S time ./program

# Sort by calls
strace -c -S calls ./program

# Sort by errors
strace -c -S errors ./program

# Summary per process
strace -c -f ./program

# Statistics with details
strace -C ./program  # Shows both summary and detailed trace
```

---

## 7. Advanced Usage

### Attach to Running Process

```bash
# Attach to process
strace -p 1234

# Attach and follow children
strace -p 1234 -f

# Attach with timestamp
strace -p 1234 -tt

# Attach for limited time
timeout 10 strace -p 1234
```

### Trace with Output Redirection

```bash
# Trace and filter output
strace -e trace=open ./program 2>&1 | grep config

# Trace to file and stderr
strace -o trace.log -e trace=open ./program

# Trace and tee output
strace ./program 2>&1 | tee trace.log
```

### Trace Multiple Processes

```bash
# Trace process tree
strace -f -o trace.log -ff ./program

# Trace specific PIDs
strace -p 1234 -p 5678 -p 9012

# Trace all processes matching pattern
pids=$(pgrep -f "my_pattern")
strace -p $(echo $pids | tr ' ' ',')
```

### Trace with Filtering

```bash
# Only show successful calls
strace -e trace=open ./program 2>&1 | grep "=[1-9]"

# Only show failed calls
strace -e trace=open ./program 2>&1 | grep "= -1"

# Filter by filename
strace -e trace=open,openat ./program 2>&1 | grep "myfile"

# Filter by return value
strace -e trace=open ./program 2>&1 | grep "ENOENT"
```

---

## 8. strace vs Other Tools

| Tool | Purpose | When to Use |
|------|---------|-------------|
| `strace` | System call tracing | Debug syscalls, file access, network |
| `ltrace` | Library call tracing | Debug library function calls |
| `perf` | Performance profiling | CPU profiling, sampling |
| `bpftrace` | eBPF tracing | Advanced kernel/user tracing |
| `dtrace` | Dynamic tracing | Solaris/illumos systems |
| `gdb` | Debugger | Step-through debugging |
| `valgrind` | Memory analysis | Memory leaks, corruption |
| `tcpdump` | Packet capture | Network packet analysis |

---

## 9. Common Syscall Reference

### File Operations

| Syscall | Description | Key Args |
|---------|-------------|----------|
| `open` / `openat` | Open file | path, flags, mode |
| `close` | Close fd | fd |
| `read` | Read from fd | fd, buf, count |
| `write` | Write to fd | fd, buf, count |
| `lseek` | Seek in fd | fd, offset, whence |
| `stat` / `lstat` / `fstat` | Get file status | path/fd, statbuf |
| `access` / `faccessat` | Check access | path, mode |
| `unlink` / `unlinkat` | Remove file | path |
| `rename` / `renameat` | Rename file | old, new |
| `mkdir` / `mkdirat` | Create directory | path, mode |
| `rmdir` | Remove directory | path |
| `getcwd` | Get working directory | buf, size |
| `chdir` | Change directory | path |
| `chmod` / `fchmod` | Change permissions | path/fd, mode |
| `chown` / `fchown` | Change ownership | path/fd, uid, gid |
| `link` / `linkat` | Create hard link | old, new |
| `symlink` / `symlinkat` | Create symlink | target, linkpath |
| `readlink` / `readlinkat` | Read symlink | path, buf, size |
| `fcntl` | File control | fd, cmd, arg |
| `ioctl` | Device control | fd, request, arg |
| `dup` / `dup2` / `dup3` | Duplicate fd | oldfd, newfd |
| `pipe` / `pipe2` | Create pipe | pipefd |

### Network Operations

| Syscall | Description | Key Args |
|---------|-------------|----------|
| `socket` | Create socket | domain, type, protocol |
| `bind` | Bind to address | sockfd, addr, addrlen |
| `listen` | Listen for connections | sockfd, backlog |
| `accept` / `accept4` | Accept connection | sockfd, addr, addrlen |
| `connect` | Connect to address | sockfd, addr, addrlen |
| `send` / `sendto` / `sendmsg` | Send data | sockfd, buf, len |
| `recv` / `recvfrom` / `recvmsg` | Receive data | sockfd, buf, len |
| `shutdown` | Shut down socket | sockfd, how |
| `setsockopt` | Set socket option | sockfd, level, optname |
| `getsockopt` | Get socket option | sockfd, level, optname |
| `select` / `pselect` | I/O multiplexing | nfds, readfds, writefds |
| `poll` / `ppoll` | I/O multiplexing | fds, nfds, timeout |
| `epoll_create` / `epoll_ctl` / `epoll_wait` | Epoll | epfd, op, fd, event |

### Process Operations

| Syscall | Description | Key Args |
|---------|-------------|----------|
| `fork` | Create child | — |
| `clone` | Create child (fine-grained) | fn, stack, flags |
| `execve` | Execute program | path, argv, envp |
| `exit` / `exit_group` | Exit process | status |
| `wait4` / `waitpid` | Wait for child | pid, status, options |
| `kill` | Send signal | pid, sig |
| `getpid` / `getppid` | Get PID | — |
| `getuid` / `geteuid` | Get user ID | — |
| `getgid` / `getegid` | Get group ID | — |
| `setsid` | Create session | — |
| `setpgid` | Set process group | pid, pgid |
| `prctl` | Process control | option, arg |

### Memory Operations

| Syscall | Description | Key Args |
|---------|-------------|----------|
| `mmap` | Map memory | addr, len, prot, flags, fd, off |
| `munmap` | Unmap memory | addr, len |
| `mprotect` | Set memory protection | addr, len, prot |
| `brk` | Set program break | addr |
| `mlock` / `munlock` | Lock/unlock memory | addr, len |
| `madvise` | Memory advice | addr, len, advice |

---

## 10. Quick Reference

```bash
# Basic trace
strace ./program

# Trace specific syscalls
strace -e trace=open,read,write ./program

# Trace file operations
strace -e trace=file ./program

# Trace network
strace -e trace=network ./program

# Trace with timing
strace -T ./program

# Trace with timestamps
strace -tt ./program

# Summary statistics
strace -c ./program

# Follow children
strace -f ./program

# Attach to process
strace -p 1234

# Output to file
strace -o trace.log ./program

# Verbose output
strace -v -s 0 ./program
```

---

*For complete `strace` documentation, consult `man strace` or the strace wiki at https://strace.io/.*
