# Chapter 59: Debugging Tools — gdb, objdump, readelf, nm, strings, ldd

## Overview

Debugging tools are essential for understanding program behavior, diagnosing crashes, analyzing binaries, and investigating issues at the machine code level. This chapter covers the GNU Debugger and related binary analysis utilities.

---

## gdb — GNU Debugger

### Purpose

`gdb` is the standard debugger for Linux. It can debug programs written in C, C++, Rust, Go, and other compiled languages.

### Syntax

```
gdb [options] [program [core|pid]]
```

### Key Options

| Option | Description |
|--------|-------------|
| `-p PID` | Attach to running process |
| `-c CORE` | Analyze core dump |
| `-q` | Quiet (no banner) |
| `-batch` | Batch mode (non-interactive) |
| `-ex CMD` | Execute command |
| `-x FILE` | Execute commands from file |
| `-d DIR` | Add source directory |
| `-se FILE` | Symbol file |
| `-symbols FILE` | Symbol file |
| `-exec FILE` | Executable |
| `-core FILE` | Core file |
| `-pid PID` | Process ID |
| `-nh` | Don't load .gdbinit |
| `-nx` | Don't load any init files |
| `-return-child-result` | Return child result |
| `-iex CMD` | Execute before init |
| `-ix FILE` | Execute before init from file |

### Running Programs

```bash
# Start program
gdb ./program

# Run with arguments
(gdb) run arg1 arg2

# Run with input redirect
(gdb) run < input.txt

# Run and stop at main
(gdb) start

# Continue execution
(gdb) continue

# Step over (next line)
(gdb) next
(gdb) n

# Step into (enter function)
(gdb) step
(gdb) s

# Step out (finish function)
(gdb) finish

# Step instruction
(gdb) stepi
(gdb) si

# Next instruction
(gdb) nexti
(gdb) ni

# Run until location
(gdb) until 42
(gdb) until filename.c:42

# Kill program
(gdb) kill

# Quit
(gdb) quit
(gdb) q
```

### Breakpoints

```bash
# Set breakpoint at function
(gdb) break main
(gdb) b main

# Set breakpoint at line
(gdb) break 42
(gdb) break filename.c:42

# Set breakpoint at address
(gdb) break *0x400500

# Conditional breakpoint
(gdb) break 42 if x == 10
(gdb) break main if argc > 1

# List breakpoints
(gdb) info breakpoints
(gdb) i b

# Delete breakpoint
(gdb) delete 1
(gdb) d 1

# Delete all
(gdb) delete

# Disable/enable breakpoint
(gdb) disable 1
(gdb) enable 1

# Break on syscall
(gdb) catch syscall open

# Break on signal
(gdb) catch signal SIGSEGV

# Break on fork
(gdb) catch fork

# Break on throw/catch (C++)
(gdb) catch throw
(gdb) catch catch

# Watchpoint (break on value change)
(gdb) watch variable
(gdb) watch *0x400500

# Read watchpoint
(gdb) rwatch variable

# Access watchpoint
(gdb) awatch variable
```

### Examining State

```bash
# Print variable
(gdb) print variable
(gdb) p variable

# Print expression
(gdb) p *pointer
(gdb) p array[0]
(gdb) p sizeof(struct_name)
(gdb) p (type)expression

# Print in hex
(gdb) p/x variable

# Print in binary
(gdb) p/t variable

# Print in octal
(gdb) p/o variable

# Print as string
(gdb) p/s string

# Print as character
(gdb) p/c char

# Print as instruction
(gdb) p/i instruction

# Print array
(gdb) p *array@10

# Print struct
(gdb) p *struct_ptr

# Display (auto-print on stop)
(gdb) display variable
(gdb) display/x variable
(gdb) display/i $pc

# Delete display
(gdb) delete display 1

# Examine memory
(gdb) x/10x $sp        # 10 hex words from stack pointer
(gdb) x/20i $pc        # 20 instructions from program counter
(gdb) x/s string       # String at address
(gdb) x/10dw variable  # 10 decimal words
(gdb) x/10gx $rsp      # 10 giant hex words from stack

# Info commands
(gdb) info locals       # Local variables
(gdb) info args         # Function arguments
(gdb) info registers    # CPU registers
(gdb) info threads      # Threads
(gdb) info frame        # Current frame
(gdb) info stack        # Stack frames (same as bt)
(gdb) info variables    # All variables
(gdb) info functions    # All functions
(gdb) info sources      # Source files
(gdb) info line         # Current line
(gdb) info program      # Program status

# Backtrace
(gdb) backtrace
(gdb) bt
(gdb) bt full          # With local variables
(gdb) bt 10            # Limit to 10 frames

# Frame navigation
(gdb) frame 3
(gdb) f 3
(gdb) up
(gdb) down

# Set variable
(gdb) set variable x = 10
(gdb) set x = 10

# Call function
(gdb) call (void)printf("hello\n")
(gdb) call (int)myfunction(arg1, arg2)
```

### Debugging Core Dumps

```bash
# Analyze core dump
gdb ./program core

# Generate core dump
ulimit -c unlimited
./program

# Core dump with systemd
coredumpctl list
coredumpctl gdb PID

# Set core pattern
echo '/tmp/core.%e.%p' | sudo tee /proc/sys/kernel/core_pattern
```

### Attach to Running Process

```bash
# Attach to PID
gdb -p 1234

# Or inside gdb
(gdb) attach 1234

# Detach
(gdb) detach
```

### Multi-threaded Debugging

```bash
# List threads
(gdb) info threads

# Switch thread
(gdb) thread 3

# Thread-specific breakpoint
(gdb) break filename.c:42 thread 3

# Apply command to all threads
(gdb) thread apply all bt

# Apply command to all threads with backtrace
(gdb) thread apply all bt full
```

### Scripting

```bash
# Execute commands from file
(gdb) -x commands.txt

# Batch mode
gdb -batch -ex "run" -ex "bt" ./program core

# Define command
(gdb) define mybt
> bt full
> info locals
> end

# Logging
(gdb) set logging on
(gdb) set logging file gdb.log
(gdb) set logging overwrite on
```

---

## objdump — Display Object File Information

### Purpose

`objdump` displays information about object files, including disassembly, headers, and sections.

### Key Options

| Option | Description |
|--------|-------------|
| `-d` | Disassemble |
| `-D` | Disassemble all |
| `-S` | Intermix source with disassembly |
| `-h` | Section headers |
| `-x` | All headers |
| `-f` | File header |
| `-p` | Program headers |
| `-t` | Symbol table |
| `-T` | Dynamic symbol table |
| `-r` | Relocation entries |
| `-R` | Dynamic relocation entries |
| `-s` | Full contents |
| `-g` | Debug info |
| `-e` | Format info |
| `-l` | Line numbers |
| `-C` | Demangle C++ names |
| `-j SECTION` | Specific section |
| `-m ARCH` | Architecture |
| `-b TARGET` | Target |
| `-M OPTION` | Disassembler options |
| `--no-show-raw-insn` | Don't show raw bytes |

### Examples

```bash
# Disassemble
objdump -d program

# Disassemble with source
objdump -S program

# Disassemble specific section
objdump -d -j .text program

# Show headers
objdump -h program

# Show all headers
objdump -x program

# Symbol table
objdump -t program

# Dynamic symbols
objdump -T program

# Demangled C++ names
objdump -Cd program

# Show specific section
objdump -s -j .rodata program

# Relocation entries
objdump -r program

# Line numbers
objdump -l program

# Intel syntax
objdump -d -M intel program

# AT&T syntax (default)
objdump -d -M att program
```

---

## readelf — Display ELF File Information

### Purpose

`readelf` displays information about ELF (Executable and Linkable Format) files.

### Key Options

| Option | Description |
|--------|-------------|
| `-h` | File header |
| `-l` | Program headers |
| `-S` | Section headers |
| `-s` | Symbol table |
| `-dyn` | Dynamic section |
| `-r` | Relocations |
| `-d` | Dynamic section |
| `-n` | Notes |
| `-c` | Archive index |
| `-a` | All |
| `-x HEX` | Hex dump of section |
| `-p STRING` | String dump of section |
| `-debug-dump=TYPE` | Debug info |
| `-wF` | Debug frames |
| `-g` | Section groups |
| `-A` | Architecture-specific |
| `-V` | Version info |

### Examples

```bash
# File header
readelf -h program

# Program headers
readelf -l program

# Section headers
readelf -S program

# Symbol table
readelf -s program

# Dynamic section
readelf -d program

# All info
readelf -a program

# Notes
readelf -n program

# Hex dump
readelf -x .rodata program

# String dump
readelf -p .rodata program

# Version info
readelf -V program
```

---

## nm — List Symbols from Object Files

### Purpose

`nm` lists symbols (functions, variables) from object files.

### Key Options

| Option | Description |
|--------|-------------|
| `-a` | All symbols (including debugger) |
| `-g` | External (global) symbols only |
| `-u` | Undefined symbols only |
| `-r` | Reverse sort |
| `-n` | Sort by address |
| `-s` | Print size |
| `-S` | Print size (BSD style) |
| `-C` | Demangle C++ names |
| `-D` | Dynamic symbols |
| `-p` | No sorting |
| `-t RADIX` | Output radix (d=decimal, x=hex, o=octal) |
| `--defined-only` | Only defined symbols |
| `-l` | Include line numbers |
| `--size-sort` | Sort by size |
| `-f FORMAT` | Output format |

### Symbol Types

| Type | Description |
|------|-------------|
| `A` | Absolute |
| `B` | BSS (uninitialized data) |
| `C` | Common |
| `D` | Initialized data |
| `G` | Initialized data (small) |
| `I` | Indirect |
| `R` | Read-only data |
| `S` | Small data |
| `T` | Text (code) |
| `U` | Undefined |
| `V` | Weak object |
| `W` | Weak symbol |
| `-` | Stabs debug symbol |
| `?` | Unknown |

### Examples

```bash
# List all symbols
nm program

# External symbols only
nm -g program

# Undefined symbols
nm -u program

# Demangled C++ names
nm -C program

# Sort by address
nm -n program

# Sort by size
nm --size-sort program

# With line numbers
nm -l program

# Dynamic symbols
nm -D program

# Decimal output
nm -t d program

# Defined only
nm --defined-only program

# Specific section
nm -S program
```

---

## strings — Print Printable Strings

### Purpose

`strings` finds and prints printable character sequences in files.

### Key Options

| Option | Description |
|--------|-------------|
| `-n N` | Minimum string length (default 4) |
| `-t FORMAT` | Radix (o=octal, x=hex, d=decimal) |
| `-e ENCODING` | Encoding (s=7-bit, S=UTF-16, l=UTF-32) |
| `-f` | Print filename |
| `-T TARGET` | Target format |
| `--data` | Printable data only |

### Examples

```bash
# Print strings
strings program

# Minimum length 8
strings -n 8 program

# With file offsets
strings -t x program

# UTF-16 strings
strings -e S program

# All files in directory
strings -f /usr/lib/*

# Search for specific string
strings program | grep "password"

# In binary
strings /dev/sda | head -20

# Memory dump
strings core
```

---

## ldd — Print Shared Library Dependencies

### Purpose

`ldd` prints the shared libraries required by a program.

### Examples

```bash
# List dependencies
ldd program

# Verbose
ldd -v program

# Unresolved symbols
ldd -u program

# Data relocations
ldd -d program
```

### Common Output

```
linux-vdso.so.1 (0x00007ffd5d1f6000)
libpthread.so.0 => /lib/x86_64-linux-gnu/libpthread.so.0 (0x00007f8a3c400000)
libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007f8a3c000000)
/lib64/ld-linux-x86-64.so.2 (0x00007f8a3c600000)
```

### Security Note

`ldd` actually runs the program (with a special environment). Never use `ldd` on untrusted binaries. Use `readelf -d` instead:

```bash
readelf -d program | grep NEEDED
```

---

## lddtree — Print Library Dependency Tree

### Purpose

`lddtree` displays library dependencies in a tree format (from `pax-utils`).

### Examples

```bash
# Show dependency tree
lddtree program

# Show all (including indirect)
lddtree -a program

# Show with paths
lddtree -l program
```

---

## Summary

### Quick Reference

```bash
# Debugging
gdb ./program                       # Start debugger
gdb -p 1234                         # Attach to process
gdb ./program core                  # Analyze core dump

# Binary analysis
objdump -d program                  # Disassemble
objdump -S program                  # With source
readelf -a program                  # ELF info
nm program                          # Symbol table
strings program                     # Printable strings
ldd program                         # Library dependencies

# Core dumps
ulimit -c unlimited                 # Enable core dumps
coredumpctl list                    # List core dumps (systemd)
coredumpctl gdb PID                 # Debug core dump
```
