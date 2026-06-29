# Chapter 60: Binary Utilities — ldconfig, objcopy, strip, addr2line, c++filt

## Overview

Binary utilities are tools for manipulating compiled binaries, managing shared libraries, and analyzing executable files. They're essential for development, deployment, and debugging of compiled programs.

---

## ldconfig — Configure Dynamic Linker Run-Time Bindings

### Purpose

`ldconfig` creates, updates, and removes the necessary links and cache to the most recent shared libraries found in directories specified on the command line, in `/etc/ld.so.conf`, and in the trusted directories (`/lib` and `/usr/lib`).

### Key Options

| Option | Description |
|--------|-------------|
| `-v` | Verbose mode |
| `-n` | Only process directories on command line |
| `-N` | Don't rebuild cache |
| `-X` | Don't update links |
| `-f CONF` | Use CONF instead of `/etc/ld.so.conf` |
| `-C CACHE` | Use CACHE instead of `/etc/ld.so.cache` |
| `-p` | Print cache contents |
| `-r ROOT` | Use ROOT as root directory |
| `-l` | Interpret libraries as linkers |

### Examples

```bash
# Update library cache
sudo ldconfig

# Verbose output
sudo ldconfig -v

# Print current cache
ldconfig -p

# Add directory
echo "/opt/mylib" | sudo tee -a /etc/ld.so.conf.d/mylib.conf
sudo ldconfig

# Print libraries in specific directory
ldconfig -p | grep libssl

# Use alternative config
sudo ldconfig -f /etc/ld.so.conf.custom

# Use alternative cache
sudo ldconfig -C /etc/ld.so.cache.custom

# Process only specific directories
sudo ldconfig -n /usr/local/lib

# Don't update links
sudo ldconfig -N

# Use root directory
sudo ldconfig -r /mnt/root
```

### Configuration Files

| File | Description |
|------|-------------|
| `/etc/ld.so.conf` | Main configuration |
| `/etc/ld.so.conf.d/*.conf` | Additional configs |
| `/etc/ld.so.cache` | Binary cache |
| `/etc/ld.so.preload` | Libraries to preload |

### Example Configuration

```bash
# /etc/ld.so.conf
include /etc/ld.so.conf.d/*.conf
/usr/local/lib
/opt/mylib/lib
```

### Common Mistakes

1. **Forgetting to run `ldconfig`**: After installing libraries to non-standard locations, run `sudo ldconfig` to update the cache.

2. **Not creating config file**: Create a `.conf` file in `/etc/ld.so.conf.d/` instead of editing `/etc/ld.so.conf` directly.

3. **`LD_LIBRARY_PATH` vs `ldconfig`**: `LD_LIBRARY_PATH` is for temporary testing. Use `ldconfig` for permanent library paths.

---

## objcopy — Copy and Translate Object Files

### Purpose

`objcopy` copies and translates object files. It can convert between formats, strip sections, add/remove sections, and modify symbols.

### Key Options

| Option | Description |
|--------|-------------|
| `-I FORMAT` | Input format |
| `-O FORMAT` | Output format |
| `-F TARGET` | Target format |
| `-R SECTION` | Remove section |
| `-j SECTION` | Only copy section |
| `-S` | Strip all |
| `-g` | Strip debug info |
| `--strip-unneeded` | Strip unneeded symbols |
| `-K SYMBOL` | Keep symbol |
| `-N SYMBOL` | Strip symbol |
| `-L SYMBOL` | Localize symbol |
| `-G SYMBOL` | Globalize symbol |
| `-W SYMBOL` | Weaken symbol |
| `--redefine-sym OLD=NEW` | Rename symbol |
| `--prefix-symbols=PREFIX` | Add prefix |
| `--prefix-sections=PREFIX` | Add prefix to sections |
| `--prefix-alloc-sections=PREFIX` | Add prefix to alloc sections |
| `--add-section NAME=FILE` | Add section |
| `--set-section-flags NAME=FLAGS` | Set section flags |
| `--change-start ADDR` | Adjust start address |
| `--adjust-start ADDR` | Same as above |
| `--change-addresses ADDR` | Adjust all addresses |
| `--only-keep-debug` | Keep only debug info |
| `--add-gnu-debuglink=FILE` | Add debug link |
| `--compress-debug-sections` | Compress debug sections |
| `-p` | Preserve dates |
| `-D` | deterministic |

### Formats

| Format | Description |
|--------|-------------|
| `elf64-x86-64` | 64-bit ELF |
| `elf32-i386` | 32-bit ELF |
| `binary` | Raw binary |
| `ihex` | Intel HEX |
| `srec` | Motorola S-record |
| `verilog` | Verilog HEX |

### Examples

```bash
# Strip debug info
objcopy --strip-debug program program.stripped

# Strip all symbols
objcopy --strip-all program program.stripped

# Strip unneeded symbols
objcopy --strip-unneeded program program.stripped

# Remove specific sections
objcopy -R .comment -R .note program program.clean

# Keep only specific sections
objcopy -j .text -j .data program program.minimal

# Convert ELF to binary
objcopy -O binary program program.bin

# Convert binary to ELF
objcopy -I binary -O elf64-x86-64 data.bin data.o

# Convert to Intel HEX
objcopy -O ihex program program.hex

# Add section
objcopy --add-section .mydata=data.bin program program.withdata

# Remove section
objcopy --remove-section .comment program

# Rename symbol
objcopy --redefine-sym old_name=new_name program

# Add prefix to all symbols
objcopy --prefix-symbols=lib_ program

# Localize symbol
objcopy -L internal_function program

# Globalize symbol
objcopy -G helper_function program

# Keep only debug info
objcopy --only-keep-debug program program.debug

# Add debug link
objcopy --add-gnu-debuglink=program.debug program

# Compress debug sections
objcopy --compress-debug-sections program

# Convert architecture
objcopy -I elf32-i386 -O elf64-x86-64 program32 program64

# Extract specific section to binary
objcopy -j .rodata -O binary program rodata.bin
```

---

## strip — Discard Symbols from Object Files

### Purpose

`strip` removes symbol and debug information from object files, reducing their size.

### Key Options

| Option | Description |
|--------|-------------|
| `-s` | Strip all (default) |
| `-g` | Strip debug info |
| `-d` | Strip debugging info |
| `--strip-unneeded` | Strip symbols not needed for relocation |
| `-K SYMBOL` | Keep symbol |
| `-N SYMBOL` | Remove symbol |
| `-R SECTION` | Remove section |
| `-o FILE` | Output file |
| `-p` | Preserve dates |
| `-D` | Deterministic |
| `-v` | Verbose |
| `--keep-symbol=SYMBOL` | Same as `-K` |
| `--remove-section=SECTION` | Same as `-R` |
| `--only-keep-debug` | Keep only debug info |
| `--add-gnu-debuglink=FILE` | Add debug link |

### Examples

```bash
# Strip all symbols
strip program

# Strip debug info only
strip -g program

# Strip unneeded symbols
strip --strip-unneeded program

# Keep specific symbol
strip -K main program

# Output to different file
strip -o program.stripped program

# Strip shared library
strip libfoo.so

# Strip object file
strip file.o

# Verbose
strip -v program

# Remove specific section
strip -R .comment program

# Deterministic (reproducible builds)
strip -D program
```

### Size Reduction

```bash
# Check sizes
ls -la program program.stripped

# Typical reduction
# Debug build: 10MB → 1MB (strip -g)
# Release build: 1MB → 500KB (strip --strip-unneeded)
# Minimal: 500KB → 200KB (strip -s)
```

### Common Mistakes

1. **Stripping before debugging**: Always keep an unstripped copy for debugging. Use `objcopy --only-keep-debug` to separate debug info.

2. **Stripping shared libraries**: `strip --strip-unneeded` is safe for shared libraries. `strip -s` may break them.

3. **Not separating debug info**: For production, separate debug info:
   ```bash
   objcopy --only-keep-debug program program.debug
   strip program
   objcopy --add-gnu-debuglink=program.debug program
   ```

---

## addr2line — Convert Addresses to File Names and Line Numbers

### Purpose

`addr2line` converts program addresses into file names and line numbers. It's essential for analyzing stack traces and crash dumps.

### Key Options

| Option | Description |
|--------|-------------|
| `-e FILE` | Executable file |
| `-f` | Show function names |
| `-C` | Demangle C++ names |
| `-i` | Inlined frames |
| `-p` | Pretty print |
| `-j SECTION` | Section name |
| `-b FORMAT` | Target format |
| `--target=FORMAT` | Same as `-b` |

### Examples

```bash
# Convert address to file:line
addr2line -e program 0x400500

# With function name
addr2line -fe program 0x400500

# Pretty print
addr2line -fep program 0x400500

# With inlined frames
addr2line -fie program 0x400500

# C++ demangling
addr2line -fCe program 0x400500

# Multiple addresses
addr2line -e program 0x400500 0x400510 0x400520

# From backtrace
addr2line -fpe ./program 0x400500 0x400510

# From core dump
addr2line -e program -f 0x400500
```

### Usage with Stack Traces

```bash
# Get stack addresses from GDB
gdb -batch -ex "bt" ./program core | grep -oP '0x[0-9a-f]+' | while read addr; do
    addr2line -fpe ./program "$addr"
done

# From dmesg
dmesg | grep "program\[" | grep -oP '\[<0x[0-9a-f]+>\]' | tr -d '[]' | while read addr; do
    addr2line -fpe ./program "$addr"
done
```

---

## c++filt — Demangle C++ and Java Symbols

### Purpose

`c++filt` demangles (decodes) C++ and Java symbol names into human-readable form.

### Key Options

| Option | Description |
|--------|-------------|
| `-n` | Don't demangle (opposite) |
| `-s FORMAT` | Symbol format |
| `--strip-underscore` | Strip leading underscore |
| `-p` | No recursion |
| `-t` | Types |
| `--types` | Same as `-t` |

### Mangled vs Demangled

| Mangled | Demangled |
|---------|-----------|
| `_Z3fooi` | `foo(int)` |
| `_ZNSsC1Ev` | `std::basic_string<char>::basic_string()` |
| `_Z4funcPci` | `func(char*, int)` |
| `_ZN3Foo3barEi` | `Foo::bar(int)` |

### Examples

```bash
# Demangle symbol
echo "_Z3fooi" | c++filt

# Demangle multiple
echo -e "_Z3fooi\n_Z4barv" | c++filt

# With nm
nm program | c++filt

# With objdump
objdump -t program | c++filt

# Demangle specific symbol
c++filt _ZNSsC1Ev

# Strip underscore
c++filt -s gnu-v3 _Z3fooi

# No recursion
c++filt -p _Z3fooi

# Types only
c++filt -t i  # int
```

---

## Summary

### Quick Reference

```bash
# Library management
ldconfig                            # Update library cache
ldconfig -p                         # Print cache
echo "/opt/lib" >> /etc/ld.so.conf
sudo ldconfig                       # Add new library path

# Binary manipulation
objcopy --strip-all prog prog.stripped   # Strip symbols
objcopy -O binary prog prog.bin          # Convert to binary
strip --strip-unneeded lib.so            # Strip library

# Debug info
addr2line -fpe ./program 0x400500   # Address to file:line

# Symbol demangling
echo "_Z3fooi" | c++filt            # Demangle C++ symbol
nm program | c++filt                # Demangle nm output
```
