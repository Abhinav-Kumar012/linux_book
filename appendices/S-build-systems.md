# Appendix S: Build Systems Comparison

## Overview

This appendix compares four major build systems: Make, CMake, Meson, and Bazel. Each is evaluated on syntax, features, performance, and ecosystem.

---

## 1. Feature Comparison Matrix

| Feature | Make | CMake | Meson | Bazel |
|---------|------|-------|-------|-------|
| **Language** | Makefile DSL | CMakeLists.txt | meson.build | BUILD/Starlark |
| **Generation model** | Direct | Generator | Generator + Ninja | Direct |
| **Default backend** | Self | Make/Ninja | Ninja | Self |
| **Cross-compilation** | Manual | Good | Good | Excellent |
| **Dependency management** | Manual | FetchContent/External | Wrap/Dep options | Built-in (Bzlmod) |
| **Parallel build** | `-j N` | Automatic | Automatic | Automatic |
| **Incremental builds** | Good | Good | Excellent | Excellent |
| **Reproducible builds** | Manual | Good | Good | Excellent |
| **IDE integration** | Limited | Excellent | Good | Good |
| **Learning curve** | Medium | High | Low | High |
| **Language support** | Any | C/C++, Fortran, etc. | C/C++, Rust, Java, etc. | Any (rules) |
| **Package ecosystem** | N/A | CPack, Conan | Meson packages | Bazel Central |
| **Documentation** | Excellent | Excellent | Good | Good |
| **Speed** | Good | Medium | Fast | Very fast |
| **Hermetic builds** | No | No | Partial | Yes |
| **Remote caching** | No | No | No (via Ninja) | Yes |
| **Remote execution** | No | No | No | Yes |

---

## 2. Make (GNU Make)

### Basic Makefile

```makefile
# Variables
CC = gcc
CFLAGS = -Wall -Wextra -O2
LDFLAGS = -lm
TARGET = myapp
SRCS = main.c utils.c parser.c
OBJS = $(SRCS:.c=.o)

# Default target
all: $(TARGET)

# Link
$(TARGET): $(OBJS)
	$(CC) $(OBJS) -o $(TARGET) $(LDFLAGS)

# Compile
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

# Clean
clean:
	rm -f $(OBJS) $(TARGET)

# Install
install: $(TARGET)
	install -m 755 $(TARGET) /usr/local/bin/

# Phony targets
.PHONY: all clean install

# Dependencies
main.o: main.h utils.h
utils.o: utils.h
parser.o: parser.h
```

### Automatic Dependency Generation

```makefile
CC = gcc
CFLAGS = -Wall -O2 -MMD -MP
SRCS = $(wildcard *.c)
OBJS = $(SRCS:.c=.o)
DEPS = $(OBJS:.o=.d)

myapp: $(OBJS)
	$(CC) $(OBJS) -o $@

-include $(DEPS)

clean:
	rm -f $(OBJS) $(DEPS) myapp
```

### Pattern Rules and Functions

```makefile
# List all source files
SRCS := $(wildcard src/*.c)

# Generate object file list
OBJS := $(patsubst src/%.c,build/%.o,$(SRCS))

# Filter by condition
TEST_SRCS := $(filter %_test.c,$(SRCS))
LIB_SRCS := $(filter-out %_test.c,$(SRCS))

# Recursive wildcard
rwildcard = $(foreach d,$(wildcard $1*),$(call rwildcard,$d/,$2) $(filter $(subst *,%,$2),$d))

# Conditional
ifdef DEBUG
  CFLAGS += -g -O0
else
  CFLAGS += -O2
endif

# Target-specific variables
debug: CFLAGS += -g -O0
debug: myapp

release: CFLAGS += -O2 -DNDEBUG
release: myapp
```

### Pros and Cons

| Pros | Cons |
|------|------|
| Universal availability | Syntax is error-prone (tabs vs spaces) |
| Mature and well-documented | No built-in dependency management |
| Very flexible | Verbose for large projects |
| Fast execution | No automatic parallelization |
| No external dependencies | Cross-compilation is manual |

---

## 3. CMake

### Basic CMakeLists.txt

```cmake
cmake_minimum_required(VERSION 3.16)
project(myapp VERSION 1.0 LANGUAGES C)

# C standard
set(CMAKE_C_STANDARD 17)
set(CMAKE_C_STANDARD_REQUIRED ON)

# Compile options
add_compile_options(-Wall -Wextra -O2)

# Library
add_library(mylib STATIC
    src/utils.c
    src/parser.c
)
target_include_directories(mylib PUBLIC include/)

# Executable
add_executable(myapp src/main.c)
target_link_libraries(myapp PRIVATE mylib m)

# Install
install(TARGETS myapp DESTINATION bin)
install(FILES include/mylib.h DESTINATION include)

# Tests
enable_testing()
add_test(NAME mytest COMMAND myapp --test)
```

### Modern CMake Patterns

```cmake
cmake_minimum_required(VERSION 3.20)
project(myapp VERSION 2.0 LANGUAGES C CXX)

# Find packages
find_package(OpenSSL REQUIRED)
find_package(ZLIB REQUIRED)

# Interface library (header-only)
add_library(mylib_headers INTERFACE)
target_include_directories(mylib_headers INTERFACE include/)

# Object library
add_library(mylib_objects OBJECT src/lib.c)
target_link_libraries(mylib_objects PRIVATE OpenSSL::SSL)

# Shared library
add_library(mylib SHARED $<TARGET_OBJECTS:mylib_objects>)
target_link_libraries(mylib
    PUBLIC mylib_headers
    PRIVATE OpenSSL::SSL ZLIB::ZLIB
)
set_target_properties(mylib PROPERTIES
    VERSION ${PROJECT_VERSION}
    SOVERSION 2
    POSITION_INDEPENDENT_CODE ON
)

# Executable with generator expressions
add_executable(myapp src/main.c)
target_link_libraries(myapp PRIVATE mylib)
target_compile_definitions(myapp PRIVATE
    VERSION="${PROJECT_VERSION}"
    $<$<CONFIG:Debug>:DEBUG_MODE>
)

# Conditional compilation
option(ENABLE_TESTS "Build tests" ON)
if(ENABLE_TESTS)
    add_subdirectory(tests)
endif()

# FetchContent (dependency management)
include(FetchContent)
FetchContent_Declare(
    json
    GIT_REPOSITORY https://github.com/nlohmann/json.git
    GIT_TAG v3.11.2
)
FetchContent_MakeAvailable(json)
target_link_libraries(myapp PRIVATE nlohmann_json::nlohmann_json)
```

### Cross-Compilation

```cmake
# toolchain.cmake
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)

set(CMAKE_C_COMPILER aarch64-linux-gnu-gcc)
set(CMAKE_CXX_COMPILER aarch64-linux-gnu-g++)

set(CMAKE_FIND_ROOT_PATH /usr/aarch64-linux-gnu)
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
```

```bash
cmake -DCMAKE_TOOLCHAIN_FILE=toolchain.cmake -B build
```

### Building

```bash
# Configure
cmake -B build -DCMAKE_BUILD_TYPE=Release

# Build
cmake --build build -j$(nproc)

# Install
cmake --install build --prefix /usr/local

# Test
ctest --test-dir build --output-on-failure

# With Ninja backend
cmake -G Ninja -B build
cmake --build build
```

### Pros and Cons

| Pros | Cons |
|------|------|
| Wide adoption | Complex syntax |
| Excellent IDE support | Historical baggage |
| Good cross-compilation | Steep learning curve |
| FetchContent for deps | Configuration can be slow |
| CPack for packaging | Debugging CMake is hard |

---

## 4. Meson

### Basic meson.build

```meson
project('myapp', 'c',
  version: '1.0.0',
  default_options: ['c_std=c17', 'warning_level=2', 'optimization=2'])

# Dependencies
m_dep = meson.get_compiler('c').find_library('m', required: true)

# Sources
src = files('src/main.c', 'src/utils.c', 'src/parser.c')

# Executable
executable('myapp', src,
  dependencies: m_dep,
  install: true)

# Tests
test('basic_test', executable('test_basic', 'tests/test_basic.c'))
```

### Library and Dependency

```meson
project('mylib', 'c',
  version: '2.0.0',
  default_options: ['default_library=both'])

# Library (both static and shared)
mylib = library('mylib',
  'src/lib.c',
  include_directories: include_directories('include'),
  install: true,
  version: '2.0.0',
  soversion: 2)

# Declare as dependency for other projects
mylib_dep = declare_dependency(
  include_directories: include_directories('include'),
  link_with: mylib)

# Find system dependency
openssl_dep = dependency('openssl', version: '>=1.1')

# Wrap (subproject) dependency
json_dep = dependency('nlohmann_json', fallback: ['json', 'nlohmann_json_dep'])

# Executable using dependency
executable('myapp', 'src/main.c',
  dependencies: [mylib_dep, openssl_dep, json_dep])
```

### Advanced Features

```meson
project('myapp', ['c', 'cpp'],
  version: '1.0.0')

# Configuration
conf = configuration_data()
conf.set('VERSION', meson.project_version())
conf.set_quoted('DATA_DIR', get_option('datadir'))

configure_file(
  input: 'config.h.in',
  output: 'config.h',
  configuration: conf)

# Custom options
option('feature_x', type: 'boolean', value: true,
  description: 'Enable feature X')

# Conditional compilation
if get_option('feature_x')
  src += files('src/feature_x.c')
  add_project_arguments('-DFEATURE_X', language: 'c')
endif

# Subdir
subdir('src')
subdir('tests')
```

### Building

```bash
# Configure
meson setup build

# Build
meson compile -C build

# Install
meson install -C build

# Test
meson test -C build

# Reconfigure
meson setup build --reconfigure -Doption=value

# With specific options
meson setup build -Doptimization=3 -Ddebug=false
```

### Pros and Cons

| Pros | Cons |
|------|------|
| Clean, readable syntax | Smaller ecosystem than CMake |
| Fast (uses Ninja backend) | Less IDE integration |
| Built-in dependency management | No custom build steps easily |
| Easy cross-compilation | Some features still evolving |
| Good documentation | Not as universal as Make |

---

## 5. Bazel

### Basic BUILD file

```python
# BUILD
cc_binary(
    name = "myapp",
    srcs = ["main.c", "utils.c", "parser.c"],
    copts = ["-Wall", "-Wextra", "-O2"],
    linkopts = ["-lm"],
    deps = [":mylib"],
)

cc_library(
    name = "mylib",
    srcs = ["lib.c"],
    hdrs = ["lib.h"],
    visibility = ["//visibility:public"],
)
```

### Multi-Package Project

```python
# BUILD (root)
load("@rules_cc//cc:defs.bzl", "cc_binary", "cc_library")

cc_library(
    name = "mylib",
    srcs = glob(["src/*.c"]),
    hdrs = glob(["include/*.h"]),
    includes = ["include"],
    visibility = ["//visibility:public"],
)

cc_binary(
    name = "myapp",
    srcs = ["app/main.c"],
    deps = [":mylib"],
)

cc_test(
    name = "mylib_test",
    srcs = ["test/mylib_test.c"],
    deps = [":mylib"],
)
```

### External Dependencies

```python
# MODULE.bazel (Bzlmod)
module(name = "myproject", version = "1.0")

bazel_dep(name = "rules_cc", version = "0.0.9")
bazel_dep(name = "json", version = "3.11.2")

# WORKSPACE (legacy)
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "json",
    urls = ["https://github.com/nlohmann/json/releases/download/v3.11.2/json.tar.xz"],
    sha256 = "...",
    build_file = "//third_party:json.BUILD",
)
```

### Building

```bash
# Build
bazel build //:myapp

# Test
bazel test //...

# Run
bazel run //:myapp

# Clean
bazel clean

# With options
bazel build --copt=-O3 //:myapp

# Query dependencies
bazel query 'deps(//:myapp)'

# Remote cache
bazel build --remote_cache=grpc://cache.example.com //:myapp
```

### Pros and Cons

| Pros | Cons |
|------|------|
| Hermetic, reproducible builds | Steep learning curve |
| Remote caching and execution | External dependency setup |
| Scales to massive monorepos | Starlark language limitations |
| Excellent parallelism | Large disk footprint |
| Polyglot support | Complex initial setup |

---

## 6. Selection Guide

| Scenario | Recommended | Notes |
|----------|-------------|-------|
| Simple C project | Make | Minimal setup, universal |
| Medium C/C++ project | CMake | Best tooling, wide adoption |
| New C/C++ project | Meson | Cleanest syntax, fast |
| Monorepo (Google-scale) | Bazel | Unmatched scalability |
| Cross-platform library | CMake | Best cross-compilation |
| Quick prototype | Meson | Fastest to set up |
| Legacy project | Make | Already in use |
| Rust project | Meson or Cargo | Meson has Rust support |
| Java project | Bazel or Maven | Bazel for polyglot |
| Maximum reproducibility | Bazel | Hermetic by design |

---

*Each build system has extensive documentation: Make (`info make`), CMake (https://cmake.org/cmake/help/), Meson (https://mesonbuild.com/), Bazel (https://bazel.build/).*
