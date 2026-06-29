# Chapter 62: Compilers — gcc, clang, lld, lldb, g++

## Overview

Compilers translate human-readable source code into machine code. This chapter covers the GNU Compiler Collection (`gcc`/`g++`), the LLVM/Clang compiler, and related tools.

---

## gcc / g++ — GNU Compiler Collection

### Purpose

`gcc` compiles C programs; `g++` compiles C++ programs. They share most options and are part of the GNU Compiler Collection.

### Syntax

```
gcc [options] file...
g++ [options] file...
```

### Key Options

**Compilation Control:**

| Option | Description |
|--------|-------------|
| `-c` | Compile only (don't link) |
| `-S` | Compile to assembly |
| `-E` | Preprocess only |
| `-o FILE` | Output filename |
| `-x LANG` | Specify language |
| `-pipe` | Use pipes between stages |
| `--version` | Show version |
| `-v` | Verbose (show commands) |
| `-###` | Like `-v` but don't run |
| `--help` | Show help |
| `-save-temps` | Keep intermediate files |

**Warning Options:**

| Option | Description |
|--------|-------------|
| `-Wall` | Enable most common warnings |
| `-Wextra` | Enable extra warnings |
| `-Werror` | Treat warnings as errors |
| `-Wpedantic` | Strict ISO compliance |
| `-Wshadow` | Warn on variable shadowing |
| `-Wconversion` | Warn on implicit conversions |
| `-Wformat` | Check format strings |
| `-Wformat-security` | Security-related format checks |
| `-Wnull-dereference` | Warn on null dereference |
| `-Wdouble-promotion` | Warn on float to double |
| `-Wlogical-op` | Warn on logical ops |
| `-Wduplicated-cond` | Warn on duplicated conditions |
| `-Wduplicated-branches` | Warn on duplicated branches |
| `-Wrestrict` | Warn on restrict violations |
| `-Wno-*` | Disable specific warning |
| `-Wfatal-errors` | Stop on first error |
| `-Wunused` | Warn on unused |
| `-Wstrict-overflow=N` | Overflow warnings |

**Optimization Options:**

| Option | Description |
|--------|-------------|
| `-O0` | No optimization (default) |
| `-O1` | Basic optimization |
| `-O2` | Recommended optimization |
| `-O3` | Aggressive optimization |
| `-Os` | Optimize for size |
| `-Og` | Optimize for debugging |
| `-Ofast` | `-O3` + fast-math |
| `-Oz` | Aggressively optimize for size |
| `-flto` | Link-time optimization |
| `-march=ARCH` | Target architecture |
| `-mtune=ARCH` | Tune for architecture |
| `-mcpu=CPU` | Target CPU |
| `-funroll-loops` | Unroll loops |
| `-ffast-math` | Fast floating-point |
| `-fomit-frame-pointer` | Omit frame pointer |
| `-fno-exceptions` | Disable exceptions (C++) |
| `-fno-rtti` | Disable RTTI (C++) |

**Debug Options:**

| Option | Description |
|--------|-------------|
| `-g` | Generate debug info |
| `-gLEVEL` | Debug level (1-3) |
| `-ggdb` | GDB-specific debug info |
| `-gdwarf-VERSION` | DWARF version |
| `-fsanitize=TYPE` | Sanitizer |
| `-fsanitize=address` | AddressSanitizer |
| `-fsanitize=undefined` | UndefinedBehaviorSanitizer |
| `-fsanitize=thread` | ThreadSanitizer |
| `-fsanitize=memory` | MemorySanitizer |
| `-fsanitize=leak` | LeakSanitizer |
| `-finstrument-functions` | Function instrumentation |
| `-p` | Profiling |
| `-pg` | GNU profiling |
| `-fprofile-arcs` | Code coverage |
| `-ftest-coverage` | Code coverage |

**Preprocessor Options:**

| Option | Description |
|--------|-------------|
| `-DNAME` | Define macro |
| `-DNAME=VALUE` | Define macro with value |
| `-UNAME` | Undefine macro |
| `-IDIR` | Include directory |
| `-isystem DIR` | System include directory |
| `-include FILE` | Include file |
| `-M` | Output dependencies |
| `-MM` | Output dependencies (no system) |
| `-MF FILE` | Write deps to file |
| `-MT TARGET` | Set target name |
| `-MP` | Add phony targets |
| `-MD` | Generate deps during compilation |

**Linker Options:**

| Option | Description |
|--------|-------------|
| `-lLIBRARY` | Link library |
| `-LPATH` | Library search path |
| `-static` | Static linking |
| `-shared` | Create shared library |
| `-Wl,OPTION` | Pass to linker |
| `-Wl,-rpath=PATH` | Runtime library path |
| `-Wl,--as-needed` | Link only if needed |
| `-Wl,--gc-sections` | Remove unused sections |
| `-Wl,-z,relro` | Read-only relocations |
| `-Wl,-z,now` | Full RELRO |
| `-Wl,-z,noexecstack` | No-exec stack |
| `-pie` | Position-independent executable |
| `-fPIC` | Position-independent code (shared libs) |
| `-fPIE` | Position-independent executable |
| `-nostartfiles` | Don't link startup files |
| `-nostdlib` | Don't link standard libs |
| `-nodefaultlibs` | Don't link default libs |

### Examples

```bash
# Compile C
gcc -o program main.c

# Compile C++
g++ -o program main.cpp

# Compile with warnings
gcc -Wall -Wextra -o program main.c

# Compile with optimization
gcc -O2 -o program main.c

# Compile with debug info
gcc -g -o program main.c

# Compile multiple files
gcc -o program main.c utils.c parser.c

# Compile separately, then link
gcc -c main.c
gcc -c utils.c
gcc -o program main.o utils.o

# Preprocess only
gcc -E main.c > main.i

# Compile to assembly
gcc -S main.c

# Save intermediate files
gcc -save-temps -o program main.c

# Define macros
gcc -DDEBUG -DVERSION=2 -o program main.c

# Include directories
gcc -I./include -I/usr/local/include -o program main.c

# Link libraries
gcc -o program main.c -lm -lpthread -lssl

# Library paths
gcc -L/opt/lib -I/opt/include -o program main.c

# Static linking
gcc -static -o program main.c

# Shared library
gcc -shared -fPIC -o libfoo.so foo.c

# Position-independent executable
gcc -pie -fPIE -o program main.c

# Address sanitizer
gcc -fsanitize=address -g -o program main.c

# Undefined behavior sanitizer
gcc -fsanitize=undefined -g -o program main.c

# Thread sanitizer
gcc -fsanitize=thread -g -o program main.c

# Link-time optimization
gcc -flto -O2 -o program main.c utils.c

# Target architecture
gcc -march=x86-64-v3 -o program main.c

# Generate dependencies
gcc -M main.c

# Generate dependency file
gcc -MD -MF main.d -c main.c

# Treat warnings as errors
gcc -Wall -Werror -o program main.c

# C++17 standard
g++ -std=c++17 -o program main.cpp

# Verbose output
gcc -v -o program main.c

# Profile-guided optimization (PGO)
gcc -fprofile-generate -O2 -o program main.c
./program  # Run with representative input
gcc -fprofile-use -O2 -o program main.c

# Combine options
gcc -Wall -Wextra -Werror -O2 -g -std=c11 -o program main.c -lm
```

### Warning Presets

```bash
# Good defaults for development
gcc -Wall -Wextra -Wpedantic -Wshadow -Wconversion -Wformat=2 \
    -Wnull-dereference -Wdouble-promotion -Wstrict-overflow=2 \
    -o program main.c

# Production build
gcc -Wall -Wextra -O2 -DNDEBUG -o program main.c

# Debug build
gcc -Wall -Wextra -g -O0 -DDEBUG -fsanitize=address -o program main.c
```

---

## clang — The Clang Compiler

### Purpose

`clang` is the LLVM-based C/C++/Objective-C compiler. It's designed for fast compilation, clear error messages, and GCC compatibility.

### Key Options

`clang` supports most `gcc` options plus additional ones:

| Option | Description |
|--------|-------------|
| `--analyze` | Static analysis |
| `-Weverything` | Enable all warnings |
| `-Wno-*` | Disable specific warning |
| `-fcolor-diagnostics` | Colored output |
| `-fno-color-diagnostics` | No color |
| `-ftime-trace` | Time trace (Chrome JSON) |
| `-fsanitize-recover=TYPE` | Recover from sanitizer |
| `-fprofile-instr-generate` | PGO generate |
| `-fprofile-instr-use=FILE` | PGO use |
| `-emit-llvm` | Emit LLVM IR |
| `-S -emit-llvm` | Emit LLVM assembly |
| `-print-supported-cpus` | List supported CPUs |
| `--target=TRIPLE` | Target triple |
| `-flto=thin` | Thin LTO |

### Examples

```bash
# Compile C
clang -o program main.c

# Compile C++
clang++ -o program main.cpp

# All warnings
clang -Weverything -o program main.c

# Static analysis
clang --analyze main.c

# Colored output
clang -fcolor-diagnostics -Wall -o program main.c

# Time trace
clang -ftime-trace -o program main.c

# Emit LLVM IR
clang -emit-llvm -S main.c -o main.ll

# Thin LTO
clang -flto=thin -O2 -o program main.c

# Address sanitizer
clang -fsanitize=address -g -o program main.c

# C++20 standard
clang++ -std=c++20 -o program main.cpp

# Target specific
clang --target=x86_64-linux-gnu -o program main.c
```

### GCC vs Clang

| Feature | GCC | Clang |
|---------|-----|-------|
| License | GPLv3 | Apache 2.0 |
| Backend | GCC | LLVM |
| Error messages | Good | Excellent |
| Compilation speed | Good | Faster |
| Optimization | Excellent | Excellent |
| Debug info | DWARF | DWARF |
| Static analysis | Limited | Built-in |
| Cross-compilation | Good | Excellent |
| IDE integration | Good | Excellent (clangd) |

---

## lld — The LLVM Linker

### Purpose

`lld` is the LLVM linker, designed to be a faster alternative to GNU `ld`.

### Examples

```bash
# Use with clang
clang -fuse-ld=lld -o program main.c

# Direct usage
ld.lld -o program main.o utils.o

# Shared library
ld.lld -shared -o libfoo.so foo.o
```

---

## lldb — The LLVM Debugger

### Purpose

`lldb` is the LLVM debugger, an alternative to `gdb`.

### Key Commands

| Command | Description |
|---------|-------------|
| `run` | Start program |
| `breakpoint set -n FUNC` | Set breakpoint |
| `breakpoint set -f FILE -l LINE` | Set breakpoint at line |
| `continue` | Continue |
| `next` | Step over |
| `step` | Step into |
| `finish` | Step out |
| `print EXPR` | Print expression |
| `frame variable` | Show variables |
| `thread list` | List threads |
| `bt` | Backtrace |
| `register read` | Show registers |
| `memory read ADDR` | Read memory |
| `disassemble` | Disassemble |
| `target create FILE` | Load executable |
| `process attach -p PID` | Attach |
| `quit` | Exit |

### Examples

```bash
# Start debugger
lldb ./program

# Attach to process
lldb -p 1234

# Debug core dump
lldb -c core ./program

# Commands
(lldb) run arg1 arg2
(lldb) breakpoint set -n main
(lldb) breakpoint set -f main.c -l 42
(lldb) continue
(lldb) next
(lldb) step
(lldb) print x
(lldb) frame variable
(lldb) bt
(lldb) register read
(lldb) disassemble --frame
```

---

## Summary

### Quick Reference

```bash
# C compilation
gcc -Wall -O2 -o program main.c           # Basic
gcc -g -fsanitize=address -o program main.c # Debug
gcc -O3 -flto -o program main.c            # Optimized

# C++ compilation
g++ -std=c++17 -Wall -O2 -o program main.cpp
clang++ -std=c++20 -Weverything -o program main.cpp

# Shared library
gcc -shared -fPIC -o libfoo.so foo.c

# Static analysis
clang --analyze main.c

# Debug
gdb ./program
lldb ./program
```
