# Chapter 61: Build Systems — make, cmake, meson, ninja

## Overview

Build systems automate the process of compiling source code into executables and libraries. This chapter covers the major build systems used in Linux development: `make` (the classic), `cmake` (cross-platform generator), `meson` (modern generator), and `ninja` (fast executor).

---

## make — GNU Make

### Purpose

`make` automatically builds programs from source code by reading a `Makefile` that describes dependencies and build rules.

### Syntax

```
make [options] [target] [variable=value...]
```

### Key Options

| Option | Description |
|--------|-------------|
| `-f FILE` | Use FILE as makefile |
| `-C DIR` | Change to DIR |
| `-j N` | Parallel jobs |
| `-j` | Unlimited parallel jobs |
| `-k` | Keep going on error |
| `-n` | Dry run (print commands) |
| `-B` | Unconditional make |
| `-t` | Touch files (don't rebuild) |
| `-q` | Question mode (exit status) |
| `-p` | Print database |
| `-d` | Debug mode |
| `--debug=FLAGS` | Debug flags |
| `-s` | Silent mode |
| `-w` | Print working directory |
| `-W FILE` | What if FILE modified |
| `-o FILE` | Assume FILE is old |
| `-e` | Environment overrides |
| `-I DIR` | Include directory |
| `-S` | Stop on error (default) |
| `-L` | Follow symlinks |
| `-v` | Version |
| `--warn-undefined-variables` | Warn on undefined vars |
| `--always-make` | Same as `-B` |
| `--print-data-base` | Same as `-p` |
| `--no-builtin-rules` | Disable built-in rules |
| `--no-builtin-variables` | Disable built-in variables |
| `-O[TYPE]` | Output synchronization |
| `--output-sync` | Same as `-O` |
| `--shuffle` | Randomize goal order |
| `--trace` | Trace execution |

### Makefile Syntax

```makefile
# Variable assignment
CC = gcc
CFLAGS = -Wall -O2
LDFLAGS = -lm
TARGET = myprogram

# Default target
all: $(TARGET)

# Rule with dependencies
$(TARGET): main.o utils.o
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

# Pattern rule
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

# Variables
# $@ = target name
# $< = first prerequisite
# $^ = all prerequisites
# $? = prerequisites newer than target
# $* = stem (pattern match)

# Phony targets
.PHONY: all clean install

clean:
	rm -f *.o $(TARGET)

install: $(TARGET)
	install -m 755 $(TARGET) /usr/local/bin/

# Conditional
ifdef DEBUG
CFLAGS += -g -DDEBUG
endif

# Functions
SOURCES = $(wildcard *.c)
OBJECTS = $(SOURCES:.c=.o)

# Include
include config.mk

# Multi-line variable
define COMPILE
echo "Compiling $<"
$(CC) $(CFLAGS) -c $< -o $@
endef
```

### Examples

```bash
# Build default target
make

# Build specific target
make clean

# Parallel build
make -j$(nproc)

# Dry run
make -n

# Debug mode
make -d

# Specific makefile
make -f MyMakefile

# Change directory
make -C /path/to/project

# Override variable
make CC=clang CFLAGS="-Wall -O3"

# What if file modified
make -W file.c

# Touch files (mark as up to date)
make -t

# Print database
make -p

# Keep going on error
make -k -j$(nproc)

# Silent mode
make -s

# Unconditional build
make -B

# Include debug info
make DEBUG=1
```

### Advanced Features

```makefile
# Automatic variables
target: dep1 dep2
	echo $@    # target
	echo $<    # dep1
	echo $^    # dep1 dep2
	echo $?    # changed deps
	echo $+    # all deps (with duplicates)
	echo $*    # stem

# Static pattern rule
objects: main.o utils.o parser.o
$(objects): %.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

# VPATH (search path for prerequisites)
VPATH = src:include

# Target-specific variables
debug: CFLAGS += -g -DDEBUG
debug: $(TARGET)

# Grouped target
out1 out2 out3: common_dep
	touch $@

# Export variables
export CC CFLAGS

# Double-colon rules (multiple rules for same target)
clean::
	rm -f *.o
clean::
	rm -f $(TARGET)

# Define/eval
PROGRAMS = server client
define PROGRAM_template
$(1): $(1).o common.o
	$$(CC) $$^ -o $$@
endef
$(foreach prog,$(PROGRAMS),$(eval $(call PROGRAM_template,$(prog))))
```

---

## cmake — Cross-Platform Build Generator

### Purpose

`cmake` generates native build scripts (Makefiles, Ninja files, etc.) from `CMakeLists.txt` configuration files.

### Syntax

```
cmake [options] <path-to-source>
cmake [options] <path-to-existing-build>
```

### Key Options

| Option | Description |
|--------|-------------|
| `-S DIR` | Source directory |
| `-B DIR` | Build directory |
| `-G GENERATOR` | Build system generator |
| `-D VAR=VALUE` | Set cache variable |
| `-U VAR` | Remove from cache |
| `-C FILE` | Load initial cache |
| `-P FILE` | Process script mode |
| `--build DIR` | Build project |
| `--install DIR` | Install project |
| `--preset NAME` | Use preset |
| `-L` | List cache variables |
| `-LA` | List all cache variables |
| `--graphviz=FILE` | Generate dependency graph |
| `--system-information` | Print system info |
| `--debug-trycompile` | Debug try_compile |
| `--debug-output` | Debug output |
| `--trace-source=FILE` | Trace source file |
| `--warn-uninitialized` | Warn on uninitialized vars |
| `--warn-unused-cli` | Warn on unused CLI vars |
| `--no-warn-unused-cli` | Don't warn |
| `-Wdev` | Developer warnings |
| `-Wno-dev` | Suppress dev warnings |
| `--log-level=LEVEL` | Log level |
| `--fresh` | Fresh build (clear cache) |

### CMakeLists.txt Syntax

```cmake
cmake_minimum_required(VERSION 3.10)
project(MyProject VERSION 1.0 LANGUAGES C CXX)

# C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Options
option(BUILD_TESTS "Build tests" ON)
option(BUILD_SHARED_LIBS "Build shared libraries" OFF)

# Find packages
find_package(OpenSSL REQUIRED)
find_package(Boost 1.70 COMPONENTS filesystem system)

# Include directories
include_directories(${CMAKE_SOURCE_DIR}/include)

# Library
add_library(mylib src/lib.cpp)
target_include_directories(mylib PUBLIC include)
target_link_libraries(mylib OpenSSL::SSL)

# Executable
add_executable(myapp src/main.cpp)
target_link_libraries(myapp mylib)

# Install
install(TARGETS myapp DESTINATION bin)
install(TARGETS mylib DESTINATION lib)
install(DIRECTORY include/ DESTINATION include)

# Tests
if(BUILD_TESTS)
    enable_testing()
    add_subdirectory(tests)
endif()

# Conditional compilation
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    add_compile_definitions(DEBUG)
endif()

# Generate config header
configure_file(config.h.in config.h)

# Subdirectories
add_subdirectory(src)
add_subdirectory(lib)
```

### Examples

```bash
# Configure (out-of-source build)
cmake -S . -B build

# Configure with options
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTS=ON

# Build
cmake --build build

# Build with parallel jobs
cmake --build build -j$(nproc)

# Build specific target
cmake --build build --target myapp

# Install
sudo cmake --install build

# Install to prefix
cmake --install build --prefix /opt/myapp

# Clean build
rm -rf build && cmake -S . -B build

# Fresh build
cmake -S . -B build --fresh

# Ninja generator
cmake -S . -B build -G Ninja

# Debug build
cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug

# Release build
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release

# List cache variables
cmake -L build

# Print system info
cmake --system-information

# Generate dependency graph
cmake --graphviz=deps.dot build
```

### Build Types

| Type | Description |
|------|-------------|
| `Debug` | `-g -O0` (no optimization, debug symbols) |
| `Release` | `-O3 -DNDEBUG` (optimized, no debug) |
| `RelWithDebInfo` | `-O2 -g -DNDEBUG` (optimized with debug) |
| `MinSizeRel` | `-Os -DNDEBUG` (size optimized) |

---

## meson — The Meson Build System

### Purpose

`meson` is a modern build system designed for speed and usability. It generates `ninja` build files.

### Syntax

```
meson [command] [options] [arguments]
```

### Commands

| Command | Description |
|---------|-------------|
| `setup` | Configure build directory |
| `compile` | Build project |
| `install` | Install project |
| `test` | Run tests |
| `dist` | Create source archive |
| `benchmark` | Run benchmarks |
| `introspect` | Show build info |
| `configure` | Change options |
| `wrap` | Manage dependencies |
| `subprojects` | Manage subprojects |
| `init` | Create new project |
| `rewrite` | Modify build files |
| `devenv` | Create development environment |
| `env2mfile` | Convert env to cross file |

### meson.build Syntax

```meson
project('myproject', 'c',
  version : '1.0',
  default_options : ['warning_level=2', 'c_std=c11']
)

# Executable
executable('myapp', 'main.c', 'utils.c',
  dependencies : [dependency('gtk+-3.0')],
  install : true
)

# Library
mylib = library('mylib', 'lib.c',
  install : true,
  version : '1.0.0'
)

# Shared library
shared_library('mylib', 'lib.c')

# Static library
static_library('mylib', 'lib.c')

# Dependencies
zlib_dep = dependency('zlib')
ssl_dep = dependency('openssl', required : false)

# Include directories
inc = include_directories('include')

# Link
executable('myapp', 'main.c',
  link_with : mylib,
  include_directories : inc
)

# Configuration
conf = configuration_data()
conf.set('VERSION', '1.0')
configure_file(input : 'config.h.in',
               output : 'config.h',
               configuration : conf)

# Install
install_headers('mylib.h')
install_data('config.ini', install_dir : get_option('sysconfdir'))

# Tests
test('basic_test', executable('test_basic', 'test_basic.c'))

# Conditional
if get_option('tests')
  subdir('tests')
endif

# Options
option('tests', type : 'boolean', value : true, description : 'Build tests')
option('prefix', type : 'string', value : '/usr/local')

# Subprojects
subproject('dependency_project')

# pkg-config
pkg_mod = import('pkgconfig')
pkg_mod.generate(mylib, description : 'My library')
```

### Examples

```bash
# Setup build directory
meson setup build

# Setup with options
meson setup build -Dprefix=/opt/myapp -Dbuildtype=release

# Build
meson compile -C build

# Build with parallel jobs
meson compile -C build -j$(nproc)

# Install
sudo meson install -C build

# Run tests
meson test -C build

# Configure (change options)
meson configure build -Dbuildtype=debug
meson configure build -Doption=value

# List options
meson configure build

# Clean build
rm -rf build && meson setup build

# Introspect
meson introspect build
meson introspect build --targets
meson introspect build --tests

# Create new project
meson init -n myproject

# Generate compile_commands.json
meson setup build --backend=ninja  # default

# Cross compilation
meson setup build --cross-file cross.ini

# Subprojects
meson subprojects download
meson subprojects update

# Development environment
meson devenv -C build

# Dist
meson dist -C build

# Reconfigure
meson setup build --reconfigure

# Wipe and reconfigure
meson setup build --wipe
```

---

## ninja — Ninja Build System

### Purpose

`ninja` is a small build system focused on speed. It's designed to be generated by higher-level build systems like `cmake` and `meson`.

### Syntax

```
ninja [options] [targets...]
```

### Key Options

| Option | Description |
|--------|-------------|
| `-C DIR` | Change to DIR |
| `-f FILE` | Use FILE as build file |
| `-j N` | Parallel jobs |
| `-k N` | Keep going until N failures |
| `-l N` | Load average limit |
| `-n` | Dry run |
| `-v` | Verbose |
| `-d MODE` | Debug mode |
| `-t TOOL` | Subtool |
| `-w WARN` | Warning control |
| `-v` | Show commands |
| `--version` | Version |

### Build File Syntax (build.ninja)

```ninja
# Variables
cc = gcc
cflags = -Wall -O2

# Rule
rule cc
  command = $cc $cflags -c $in -o $out
  description = CC $in

rule link
  command = $cc $in -o $out
  description = LINK $out

# Build statement
build main.o: cc main.c
build utils.o: cc utils.c
build myapp: link main.o utils.o

# Default target
default myapp

# Build clean
rule clean
  command = rm -f $in

build clean_target: clean myapp main.o utils.o
```

### Examples

```bash
# Build default target
ninja

# Build specific target
ninja myapp

# Parallel build
ninja -j$(nproc)

# Dry run
ninja -n

# Verbose
ninja -v

# Build file
ninja -f build.ninja

# Change directory
ninja -C build

# Keep going on error
ninja -k 0

# Load average limit
ninja -l 4

# List targets
ninja -t targets

# List all targets
ninja -t targets all

# Clean
ninja -t clean

# Clean all
ninja -t clean -r

# Show dependency graph
ninja -t graph myapp | dot -Tpng > deps.png

# Show compilation database
ninja -t compdb > compile_commands.json

# Browse deps (generates HTML)
ninja -t browse myapp

# Query targets
ninja -t query myapp

# Rules
ninja -t rules

# Commands
ninja -t commands

# Rebuild
ninja -t restat
```

---

## Summary

### Quick Reference

```bash
# make
make -j$(nproc)                    # Parallel build
make clean                         # Clean
make install                       # Install
make -n                            # Dry run

# cmake
cmake -S . -B build                # Configure
cmake --build build                # Build
cmake --install build              # Install

# meson
meson setup build                  # Configure
meson compile -C build             # Build
meson install -C build             # Install
meson test -C build                # Test

# ninja
ninja                              # Build
ninja -j$(nproc)                   # Parallel
ninja -C build                     # Build in directory
```
