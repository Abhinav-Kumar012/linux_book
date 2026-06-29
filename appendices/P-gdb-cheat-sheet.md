# Appendix P: GDB Cheat Sheet

## Overview

GDB (GNU Debugger) is the standard debugger for Linux. This cheat sheet covers essential commands for debugging C/C++ programs: breakpoints, inspection, stepping, scripting, and remote debugging.

---

## 1. Starting GDB

```bash
# Debug an executable
gdb ./program

# Debug with core dump
gdb ./program core.1234

# Debug running process
gdb -p 1234
gdb attach 1234

# Debug with arguments
gdb --args ./program arg1 arg2

# Debug with TUI (Text User Interface)
gdb -tui ./program

# Quiet mode (no banner)
gdb -q ./program

# Execute commands from file
gdb -x commands.gdb ./program
```

---

## 2. Breakpoints

### Setting Breakpoints

```gdb
# Break at function
break main
break my_function

# Break at file:line
break main.c:42
break src/main.c:42

# Break at address
break *0x4005a0
break *main

# Conditional breakpoint
break main if argc > 1
break my_function if x == 42

# Break on function in shared library
break mylib.so:my_function

# Break on C++ method
break MyClass::myMethod
break 'MyClass::myMethod(int, int)'

# Break on template instantiation
break 'MyClass<int>::myMethod'
```

### Managing Breakpoints

```gdb
# List breakpoints
info breakpoints
info b

# Delete breakpoint
delete 1              # By number
delete                # All
clear                 # Breakpoint at current location
clear main            # Breakpoint at function
clear main.c:42       # Breakpoint at file:line

# Disable/enable breakpoint
disable 1
enable 1

# Ignore breakpoint N times
ignore 1 10           # Ignore next 10 hits

# Make breakpoint temporary (auto-delete after hit)
tbreak main

# Set commands to run on breakpoint
commands 1
  print x
  continue
end
```

---

## 3. Watchpoints

```gdb
# Watch variable (stop when value changes)
watch my_var

# Watch expression
watch *(int*)0x601040

# Watch memory location
watch *((int*)&my_var)

# Read watchpoint (stop when value is read)
rwatch my_var

# Access watchpoint (stop on read or write)
awatch my_var

# Hardware watchpoint (faster, limited number)
hwatch my_var

# List watchpoints
info watchpoints
```

---

## 4. Running and Stepping

```gdb
# Run program
run
run arg1 arg2

# Continue execution
continue
c

# Step into (source line)
step
s

# Step over (source line)
next
n

# Step into instruction
stepi
si

# Step over instruction
nexti
ni

# Step out of current function
finish

# Continue until location
until
until main.c:42

# Run until next loop iteration
advance my_function
```

---

## 5. Inspecting Variables

```gdb
# Print variable
print my_var
print/x my_var      # Hex
print/d my_var      # Decimal
print/o my_var      # Octal
print/t my_var      # Binary
print/c my_var      # Character
print/s my_var      # String
print/f my_var      # Float
print/a my_var      # Address
print/u my_var      # Unsigned

# Print array
print *array@10     # First 10 elements
print array[0]@10   # Elements 0-9
print array[5..10]  # Elements 5-10

# Print struct
print my_struct
print *my_ptr
print my_struct.field

# Print in different format
print/x 42          # 0x2a
print/t 42          # 101010
print/c 65          # 'A'

# Pretty-print
set print pretty on

# Print array elements
set print array on

# Print object (C++)
print my_object

# Call function
print my_function(42)
call my_function(42)
```

### Display (Auto-Print)

```gdb
# Display variable every stop
display my_var
display/x my_var
display *my_ptr

# List displays
info display

# Delete display
delete display 1

# Disable/enable display
disable display 1
enable display 1
```

---

## 6. Examining Memory

```gdb
# Examine memory
x/10xw 0x400000     # 10 hex words
x/20xb 0x400000     # 20 hex bytes
x/5i 0x400000       # 5 instructions
x/s 0x400000        # String
x/10dw 0x400000     # 10 decimal words
x/10fw 0x400000     # 10 float words

# Format: x/[count][format][size] address
# Formats: x(hex), d(decimal), o(octal), t(binary),
#          f(float), a(address), i(instruction), c(char), s(string)
# Sizes: b(byte), h(halfword), w(word), g(giant/8 bytes)

# Examine registers
info registers
info all-registers
info registers rax rbx rcx

# Examine memory map
info proc mappings
```

---

## 7. Stack and Backtrace

```gdb
# Backtrace
bt
backtrace
bt full              # With local variables
bt 10                # Limit to 10 frames

# Frame navigation
frame 3             # Switch to frame 3
up                  # Move up one frame
down                # Move down one frame
up 3                # Move up 3 frames

# Frame info
info frame
info frame 3

# Function arguments
info args

# Local variables
info locals

# All variables in frame
info variables

# Select frame without switching
frame
```

---

## 8. Thread Debugging

```gdb
# List threads
info threads

# Switch thread
thread 3

# Thread-specific breakpoint
break main thread 3 if x == 42

# Apply command to all threads
thread apply all bt
thread apply all info locals

# Thread-specific info
info threads 2

# Set scheduler-locking (for multithreaded debugging)
set scheduler-locking on    # Only current thread runs
set scheduler-locking off   # All threads run
set scheduler-locking step  # Only current thread on step
```

---

## 9. Signal Handling

```gdb
# List signals
info signals

# Handle signal
handle SIGINT stop print
handle SIGINT nostop noprint
handle SIGINT pass
handle SIGINT nopass

# Send signal to program
signal SIGUSR1

# Common signal handling
handle SIGPIPE nostop noprint pass
handle SIGUSR1 stop print nopass
```

---

## 10. Modifying Variables

```gdb
# Set variable
set my_var = 42
set my_var = "hello"
set my_ptr = (int*)0x601000

# Set memory
set {int}0x601000 = 42
set {char}0x601000 = 'A'

# Modify variable
set var my_var = 42

# Set register
set $rax = 0
set $pc = 0x4005a0

# Jump to address
jump main.c:42
jump *0x4005a0

# Return from function
return
return 42
```

---

## 11. Scripting GDB

### Command Files

```gdb
# commands.gdb
set pagination off
set confirm off
file ./program
break main
run
bt full
info registers
continue
quit
```

```bash
gdb -x commands.gdb -batch
```

### Python Scripting

```python
# .gdbinit or sourced file
import gdb

class MyCommand(gdb.Command):
    """My custom GDB command"""

    def __init__(self):
        super(MyCommand__, "my-cmd")

    def invoke(self, arg, from_tty):
        frame = gdb.selected_frame()
        val = frame.read_var("my_var")
        print(f"my_var = {val}")

MyCommand()
```

### User-Defined Commands

```gdb
# Define custom command
define myinfo
  info registers
  info locals
  bt
end

# Document command
document myinfo
  Show registers, locals, and backtrace
end

# Define with arguments
define myprint
  print $arg0
  print $arg1
end

# Call with arguments
myprint my_var my_other_var
```

---

## 12. Remote Debugging

### GDB Server

```bash
# Start gdbserver on target
gdbserver :1234 ./program
gdbserver :1234 --attach 1234

# Connect from host
gdb ./program
(gdb) target remote 192.168.1.100:1234

# Or via serial
(gdb) target remote /dev/ttyUSB0
```

### Remote Commands

```gdb
# Connect to remote
target remote host:port
target remote /dev/ttyUSB0

# Disconnect
disconnect

# Upload file
remote put local_file remote_file

# Download file
remote get remote_file local_file

# Execute on remote
remote exec command
```

---

## 13. Debugging Core Dumps

```bash
# Enable core dumps
ulimit -c unlimited

# Generate core dump
kill -ABRT pid

# Analyze core dump
gdb ./program core.1234

# Inside GDB
(gdb) bt              # Where it crashed
(gdb) info registers  # Register state
(gdb) info threads    # All threads
(gdb) thread apply all bt  # All thread backtraces
```

---

## 14. Debugging Optimized Code

```gdb
# Compile with debug + optimization
gcc -g -O2 -o program program.c

# GDB commands for optimized code
set print frame-arguments all
set print raw-frame-arguments on

# Note: some variables may be optimized out
# Use 'info locals' to see which are available
```

---

## 15. TUI (Text User Interface)

```gdb
# Enter TUI mode
(gdb) tui enable

# Layouts
(gdb) layout src        # Source code
(gdb) layout asm        # Assembly
(gdb) layout split      # Source + assembly
(gdb) layout regs       # Source + registers

# Navigation
(gdb) focus src         # Focus on source window
(gdb) focus cmd         # Focus on command window
(gdb) focus regs        # Focus on register window

# Scrolling
(gdb) refresh
(gdb) update
Ctrl+x, 1          # Single layout
Ctrl+x, 2          # Two windows
Ctrl+x, a          # Toggle TUI

# TUI commands
(gdb) tui reg general   # Show general registers
(gdb) tui reg float     # Show float registers
(gdb) tui reg vector    # Show vector registers
```

---

## 16. Useful Commands

### Information Commands

```gdb
info breakpoints         # List breakpoints
info watchpoints         # List watchpoints
info registers           # CPU registers
info threads             # All threads
info frame               # Current frame
info args                # Function arguments
info locals              # Local variables
info variables           # All variables
info functions           # All functions
info sources             # Source files
info sharedlibrary       # Loaded shared libraries
info proc                # Process info
info proc mappings       # Memory map
info signals             # Signal handling
info line                # Line info
info types               # All types
info macro               # Macro definition
info os                  # OS info
info threads             # Thread info
```

### GDB Settings

```gdb
set pagination off       # No page breaks
set confirm off          # No confirmations
set print pretty on      # Pretty-print structs
set print array on       # Print array elements
set print elements 200   # Max elements to print
set print object on      # Print C++ vtables
set print vtbl on        # Print C++ vtables
set print demangle on    # Demangle C++ names
set history save on      # Save command history
set history filename ~/.gdb_history
set disassembly-flavor intel  # Intel syntax
set follow-fork-mode child    # Follow child on fork
set follow-fork-mode parent   # Follow parent on fork
set detach-on-fork off        # Keep both parent and child
```

### Logging

```gdb
# Log to file
set logging file gdb.log
set logging on
set logging off

# Redirect output
set logging overwrite on  # Overwrite existing
set logging redirect on   # Redirect only (no screen output)
```

---

## 17. Debugging Shared Libraries

```gdb
# Set shared library search path
set solib-search-path /path/to/libs

# Set sysroot
set sysroot /path/to/sysroot

# Set debug file directory
set debug-file-directory /usr/lib/debug

# List shared libraries
info sharedlibrary

# Break in shared library
break mylib.so:my_function
```

---

## 18. Common Debugging Recipes

### Find Memory Corruption

```gdb
# Compile with AddressSanitizer
gcc -fsanitize=address -g -O1 -o prog prog.c

# Or use GDB watchpoints
watch *(int*)0x601040
run
# GDB stops when value changes
bt
```

### Find Deadlock

```gdb
# Run program
run
# Press Ctrl+C when deadlocked
info threads
thread apply all bt
# Look for threads waiting on locks
```

### Find Segfault

```gdb
# Run until crash
run
# GDB stops at crash
bt full
info registers
```

### Debug Memory Leaks

```bash
# Use Valgrind
valgrind --leak-check=full ./program

# Or use AddressSanitizer
gcc -fsanitize=address -g -o prog prog.c
./prog
```

---

*For complete GDB documentation, consult `man gdb` or the GDB manual at https://sourceware.org/gdb/documentation/.*
