# Appendix O: GCC and Clang Flags Reference

## Overview

This appendix provides a comprehensive reference for GCC and Clang compiler flags organized by category: optimization, warning, debug, architecture, and linking flags.

---

## 1. Optimization Flags

### Basic Optimization Levels

| Flag | Description | Notes |
|------|-------------|-------|
| `-O0` | No optimization (default) | Fastest compilation, easiest debugging |
| `-O1` | Basic optimizations | Balance of speed and compile time |
| `-O2` | Moderate optimizations | Recommended for production |
| `-O3` | Aggressive optimizations | May increase code size |
| `-Os` | Optimize for size | Like `-O2` but reduces code size |
| `-Oz` | Aggressive size optimization | Clang only; minimal code size |
| `-Og` | Optimize for debugging | Good debug experience with some optimization |
| `-Ofast` | Maximum speed | `-O3` + fast-math + other aggressive opts |

### Specific Optimization Flags

| Flag | Description |
|------|-------------|
| `-fauto-inc-dec` | Auto increment/decrement |
| `-fbranch-count-reg` | Branch on count register |
| `-fcombine-stack-adjustments` | Merge stack adjustments |
| `-fcompare-elim` | Compare elimination after reload |
| `-fcprop-registers` | Copy propagation after reload |
| `-fdce` | Dead code elimination |
| `-fdelayed-branch` | Delayed branch scheduling |
| `-fdse` | Dead store elimination |
| `-fforward-propagate` | Forward propagation |
| `-fgcse` | Global common subexpression elimination |
| `-fif-conversion` | If-conversion |
| `-finline-functions` | Inline functions (enabled at -O2+) |
| `-fipa-profile` | Interprocedural profile propagation |
| `-fipa-pure-const` | Discover pure and const functions |
| `-fipa-reference` | Discover read-only and immutable args |
| `-fmerge-constants` | Merge identical constants |
| `-fmove-loop-invariants` | Move loop-invariant computations |
| `-freorder-blocks` | Reorder basic blocks |
| `-freorder-functions` | Reorder functions |
| `-frerun-cse-after-loop` | Rerun CSE after loop opts |
| `-fsched-interblock` | Instruction scheduling across blocks |
| `-fsched-spec` | Speculative scheduling |
| `-fstrict-aliasing` | Strict aliasing rules |
| `-ftree-ccp` | Sparse conditional constant propagation |
| `-ftree-ch` | Loop header copying |
| `-ftree-coalesce-vars` | SSA coalescing |
| `-ftree-copy-prop` | Copy propagation |
| `-ftree-dce` | Tree dead code elimination |
| `-ftree-dominator-opts` | Dominator optimizations |
| `-ftree-dse` | Dead store elimination |
| `-ftree-forwprop` | Forward propagation |
| `-ftree-fre` | Full redundancy elimination |
| `-ftree-loop-optimize` | Loop optimizations |
| `-ftree-pre` | Partial redundancy elimination |
| `-ftree-sra` | Scalar replacement of aggregates |
| `-ftree-ter` | Temporary expression replacement |
| `-ftree-vectorize` | Loop vectorization (-O3) |
| `-funroll-loops` | Loop unrolling |
| `-funsafe-math-optimizations` | Unsafe math optimizations |
| `-ffast-math` | Aggressive math optimizations (implies several flags) |
| `-ffinite-math-only` | Assume no NaN or infinity |
| `-fno-signed-zeros` | Assume no signed zeros |
| `-fno-trapping-math` | Assume no trapping math |
| `-freciprocal-math` | Use reciprocal instead of divide |

---

## 2. Warning Flags

### Basic Warnings

| Flag | Description |
|------|-------------|
| `-w` | Suppress all warnings |
| `-Wall` | Enable most common warnings |
| `-Wextra` | Enable extra warnings (beyond -Wall) |
| `-Wpedantic` | Warn on non-standard extensions |
| `-Weverything` | Enable ALL warnings (Clang only) |

### Specific Warnings

| Flag | Description |
|------|-------------|
| `-Wabi` | Warn about ABI changes |
| `-Waddress` | Warn about suspicious address usage |
| `-Waggregate-return` | Warn about returning structs |
| `-Warray-bounds` | Warn about out-of-bounds array access |
| `-Wattribute-alias` | Warn about attribute aliases |
| `-Wbool-compare` | Warn about boolean comparisons |
| `-Wcast-align` | Warn about pointer casts increasing alignment |
| `-Wcast-function-type` | Warn about function pointer casts |
| `-Wchar-subscripts` | Warn about char subscripts |
| `-Wcomment` | Warn about nested comments |
| `-Wconversion` | Warn about implicit type conversions |
| `-Wdangling-else` | Warn about dangling else |
| `-Wdeclaration-after-statement` | Warn about mixed declarations |
| `-Wdisabled-optimization` | Warn when optimization is skipped |
| `-Wdouble-promotion` | Warn about implicit float to double |
| `-Wduplicate-decl-specifier` | Warn about duplicate decl specifiers |
| `-Wempty-body` | Warn about empty if/else bodies |
| `-Wenum-compare` | Warn about different enum comparisons |
| `-Werror` | Treat warnings as errors |
| `-Werror=warning-name` | Treat specific warning as error |
| `-Wfatal-errors` | Stop on first error |
| `-Wformat` | Warn about printf/scanf format strings |
| `-Wformat=2` | Extra format checks |
| `-Wformat-overflow` | Warn about format string overflow |
| `-Wformat-security` | Warn about format security issues |
| `-Wformat-truncation` | Warn about format truncation |
| `-Wimplicit-function-declaration` | Warn about implicit function decls |
| `-Wimplicit-int` | Warn about implicit int |
| `-Winit-self` | Warn about self-initialization |
| `-Winline` | Warn about inlining failures |
| `-Wint-conversion` | Warn about int-pointer conversions |
| `-Wjump-misses-init` | Warn about jumps over initializers |
| `-Wlogical-op` | Warn about logical operator issues |
| `-Wmain` | Warn about incorrect main declaration |
| `-Wmaybe-uninitialized` | Warn about possibly uninitialized vars |
| `-Wmisleading-indentation` | Warn about misleading indentation |
| `-Wmissing-braces` | Warn about missing braces |
| `-Wmissing-declarations` | Warn about missing declarations |
| `-Wmissing-field-initializers` | Warn about missing field initializers |
| `-Wmissing-include-dirs` | Warn about missing include directories |
| `-Wmissing-prototypes` | Warn about missing prototypes |
| `-Wmultichar` | Warn about multi-character character constants |
| `-Wnested-externs` | Warn about nested externs |
| `-Wno-*` | Disable specific warning |
| `-Wnull-dereference` | Warn about null pointer dereferences |
| `-Wold-style-definition` | Warn about old-style function definitions |
| `-Woverlength-strings` | Warn about overlength strings |
| `-Woverride-init` | Warn about initializer overrides |
| `-Wpacked` | Warn about packed structs |
| `-Wpacked-bitfield-compat` | Warn about packed bitfield issues |
| `-Wpadded` | Warn about struct padding |
| `-Wparentheses` | Warn about missing parentheses |
| `-Wpointer-arith` | Warn about pointer arithmetic |
| `-Wredundant-decls` | Warn about redundant declarations |
| `-Wrestrict` | Warn about restrict violations |
| `-Wreturn-type` | Warn about return type issues |
| `-Wsequence-point` | Warn about sequence point issues |
| `-Wshadow` | Warn about variable shadowing |
| `-Wsign-compare` | Warn about signed/unsigned comparisons |
| `-Wsign-conversion` | Warn about sign conversions |
| `-Wstack-protector` | Warn about stack protection issues |
| `-Wstrict-aliasing` | Warn about strict aliasing violations |
| `-Wstrict-overflow` | Warn about strict overflow |
| `-Wstrict-prototypes` | Warn about non-strict prototypes |
| `-Wstringop-overflow` | Warn about string operation overflow |
| `-Wswitch` | Warn about missing switch cases |
| `-Wswitch-default` | Warn about missing default in switch |
| `-Wswitch-enum` | Warn about missing enum cases in switch |
| `-Wsync-nand` | Warn about __sync NAND |
| `-Wsystem-headers` | Warn about system header issues |
| `-Wtrampolines` | Warn about trampolines |
| `-Wtype-limits` | Warn about type limit comparisons |
| `-Wundef` | Warn about undefined macros in #if |
| `-Wuninitialized` | Warn about uninitialized variables |
| `-Wunknown-pragmas` | Warn about unknown pragmas |
| `-Wunsuffixed-float-constants` | Warn about unsuffixed float constants |
| `-Wunused` | Warn about unused entities |
| `-Wunused-but-set-variable` | Warn about unused but set variables |
| `-Wunused-function` | Warn about unused functions |
| `-Wunused-label` | Warn about unused labels |
| `-Wunused-macros` | Warn about unused macros |
| `-Wunused-parameter` | Warn about unused parameters |
| `-Wunused-value` | Warn about unused values |
| `-Wunused-variable` | Warn about unused variables |
| `-Wvariadic-macros` | Warn about variadic macros |
| `-Wvector-operation-performance` | Warn about vector ops |
| `-Wvla` | Warn about variable-length arrays |
| `-Wvolatile-register-var` | Warn about register volatile vars |
| `-Wwrite-strings` | Make string literals const |

### Recommended Warning Sets

```bash
# Development
gcc -Wall -Wextra -Wpedantic -Wshadow -Wconversion -Wno-unused-parameter

# Production
gcc -Wall -Wextra -Werror -O2

# Maximum (GCC)
gcc -Wall -Wextra -Wpedantic -Wshadow -Wconversion -Wsign-conversion \
    -Wcast-align -Wcast-qual -Wstrict-prototypes -Wmissing-prototypes \
    -Wmissing-declarations -Wredundant-decls -Wdouble-promotion

# Maximum (Clang)
clang -Weverything -Wno-padded -Wno-covered-switch-default
```

---

## 3. Debug Flags

| Flag | Description |
|------|-------------|
| `-g` | Generate debug info (default format, usually DWARF) |
| `-g1` | Minimal debug info |
| `-g2` | Normal debug info (default with -g) |
| `-g3` | Maximum debug info (includes macros) |
| `-ggdb` | Debug info in GDB's preferred format |
| `-gdwarf` | Generate DWARF debug info |
| `-gdwarf-4` | Generate DWARF version 4 |
| `-gdwarf-5` | Generate DWARF version 5 |
| `-gstrict-dwarf` | Don't emit extensions |
| `-gz` | Compress debug sections (zlib) |
| `-gz=zlib` | Compress with zlib |
| `-gz=zstd` | Compress with zstd (newer) |
| `-frecord-gcc-switches` | Record GCC switches in object |
| `-fprofile-arcs` | Generate arc profile data |
| `-ftest-coverage` | Generate test coverage data |
| `-fsanitize=address` | AddressSanitizer |
| `-fsanitize=thread` | ThreadSanitizer |
| `-fsanitize=memory` | MemorySanitizer (Clang) |
| `-fsanitize=undefined` | UndefinedBehaviorSanitizer |
| `-fsanitize=leak` | LeakSanitizer |
| `-fsanitize=hwaddress` | Hardware AddressSanitizer (Clang) |
| `-fno-omit-frame-pointer` | Keep frame pointer (better traces) |

---

## 4. Architecture Flags

### x86/x86_64

| Flag | Description |
|------|-------------|
| `-m32` | Generate 32-bit code |
| `-m64` | Generate 64-bit code |
| `-march=cpu` | Generate code for specific CPU |
| `-mtune=cpu` | Optimize for specific CPU (no ISA change) |
| `-mcpu=cpu` | Same as -mtune (some architectures) |
| `-msse` | Enable SSE instructions |
| `-msse2` | Enable SSE2 instructions |
| `-msse3` | Enable SSE3 instructions |
| `-mssse3` | Enable SSSE3 instructions |
| `-msse4.1` | Enable SSE4.1 instructions |
| `-msse4.2` | Enable SSE4.2 instructions |
| `-mavx` | Enable AVX instructions |
| `-mavx2` | Enable AVX2 instructions |
| `-mavx512f` | Enable AVX-512 Foundation |
| `-mavx512bw` | Enable AVX-512 Byte and Word |
| `-mavx512dq` | Enable AVX-512 Doubleword and Quadword |
| `-mavx512vl` | Enable AVX-512 Vector Length Extensions |
| `-mfma` | Enable FMA instructions |
| `-mbmi` | Enable BMI instructions |
| `-mbmi2` | Enable BMI2 instructions |
| `-mpopcnt` | Enable POPCNT instruction |
| `-mcx16` | Enable CMPXCHG16B instruction |
| `-msahf` | Enable SAHF instruction |
| `-mmovbe` | Enable MOVBE instruction |
| `-mcrc32` | Enable CRC32 instruction |
| `-mf16c` | Enable F16C instructions |
| `-mrdrnd` | Enable RDRND instruction |
| `-mfsgsbase` | Enable FSGSBASE instructions |
| `-mred-zone` | Use red zone (default on x86_64) |
| `-mno-red-zone` | Don't use red zone |
| `-mabi=sysv` | Use System V ABI |
| `-mabi=ms` | Use Microsoft ABI |
| `-mcmodel=small` | Small code model (default) |
| `-mcmodel=kernel` | Kernel code model |
| `-mcmodel=medium` | Medium code model |
| `-mcmodel=large` | Large code model |

### Common -march Values (x86_64)

| Value | Description |
|-------|-------------|
| `x86-64` | Generic x86-64 (baseline) |
| `x86-64-v2` | x86-64 + SSE4.2 + POPCNT + ... |
| `x86-64-v3` | x86-64-v2 + AVX2 + BMI2 + ... |
| `x86-64-v4` | x86-64-v3 + AVX-512 + ... |
| `native` | Current CPU |
| `nehalem` | Intel Nehalem |
| `sandybridge` | Intel Sandy Bridge |
| `ivybridge` | Intel Ivy Bridge |
| `haswell` | Intel Haswell |
| `broadwell` | Intel Broadwell |
| `skylake` | Intel Skylake |
| `skylake-avx512` | Intel Skylake-X |
| `icelake-server` | Intel Ice Lake |
| `znver1` | AMD Zen |
| `znver2` | AMD Zen 2 |
| `znver3` | AMD Zen 3 |
| `znver4` | AMD Zen 4 |

### ARM/AArch64

| Flag | Description |
|------|-------------|
| `-march=armv8-a` | ARMv8-A architecture |
| `-march=armv8.2-a` | ARMv8.2 architecture |
| `-march=armv8.4-a` | ARMv8.4 architecture |
| `-march=armv8.5-a` | ARMv8.5 architecture |
| `-march=armv9-a` | ARMv9 architecture |
| `-mcpu=cortex-a53` | Cortex-A53 CPU |
| `-mcpu=cortex-a72` | Cortex-A72 CPU |
| `-mcpu=cortex-a76` | Cortex-A76 CPU |
| `-mcpu=neoverse-n1` | Neoverse N1 |
| `-mcpu=neoverse-n2` | Neoverse N2 |
| `-mtune=cortex-a72` | Tune for Cortex-A72 |
| `-mgeneral-regs-only` | Use general registers only |
| `-mno-outline-atomics` | Don't use outline atomics |

---

## 5. Linking Flags

| Flag | Description |
|------|-------------|
| `-l` | Link with library |
| `-L` | Add library search path |
| `-static` | Static linking |
| `-shared` | Create shared library |
| `-pie` | Create position-independent executable |
| `-fPIC` | Position-independent code (shared libraries) |
| `-fPIE` | Position-independent code (executables) |
| `-rdynamic` | Export all symbols (for backtrace) |
| `-Wl,option` | Pass option to linker |
| `-Wl,-soname,name` | Set shared library SONAME |
| `-Wl,-rpath,path` | Set runtime library path |
| `-Wl,-z,relro` | Read-only relocations |
| `-Wl,-z,now` | Immediate binding |
| `-Wl,-z,noexecstack` | Non-executable stack |
| `-Wl,--as-needed` | Only link needed libraries |
| `-Wl,--gc-sections` | Remove unused sections |
| `-Wl,-T,script` | Use linker script |
| `-Wl,--version-script=file` | Version script for symbol visibility |
| `-Wl,--wrap=symbol` | Wrap symbol |
| `-Wl,-Map,file` | Generate map file |
| `-Wl,--whole-archive` | Include all archive members |
| `-Wl,--no-whole-archive` | Stop including all members |
| `-nodefaultlibs` | Don't link default libraries |
| `-nostartfiles` | Don't link startup files |
| `-nostdlib` | Don't link standard library |
| `-fuse-ld=gold` | Use gold linker |
| `-fuse-ld=lld` | Use LLD linker (Clang) |
| `-fuse-ld=mold` | Use mold linker |

---

## 6. Preprocessor Flags

| Flag | Description |
|------|-------------|
| `-Dname` | Define macro |
| `-Dname=value` | Define macro with value |
| `-Uname` | Undefine macro |
| `-Ipath` | Add include path |
| `-isystem path` | Add system include path |
| `-iquote path` | Add quote include path |
| `-include file` | Include file before compilation |
| `-imacros file` | Process macros from file |
| `-M` | Generate dependency info |
| `-MM` | Generate dependency info (no system headers) |
| `-MD` | Generate dependency info (continue compilation) |
| `-MF file` | Write dependency info to file |
| `-MT target` | Set dependency target |
| `-MQ target` | Set dependency target (quoted) |
| `-MP` | Generate phony targets |
| `-E` | Preprocess only |
| `-C` | Keep comments in preprocessing |
| `-P` | No line markers in preprocessing |
| `-nostdinc` | Don't search standard include paths |
| `-nostdinc++` | Don't search C++ standard includes |

---

## 7. Code Generation Flags

| Flag | Description |
|------|-------------|
| `-c` | Compile only (don't link) |
| `-S` | Generate assembly |
| `-masm=att` | Use AT&T assembly syntax |
| `-masm=intel` | Use Intel assembly syntax |
| `-ffreestanding` | Freestanding environment (no stdlib) |
| `-ffunction-sections` | Each function in own section |
| `-fdata-sections` | Each data item in own section |
| `-fno-common` | Don't use common symbols (default in GCC 10+) |
| `-fcommon` | Use common symbols (old behavior) |
| `-fshort-enums` | Use smallest enum type |
| `-fno-strict-aliasing` | Disable strict aliasing |
| `-fstrict-volatile-bitfields` | Strict volatile bitfields |
| `-fpack-struct[=n]` | Pack structures |
| `-fms-extensions` | Enable Microsoft extensions |
| `-fno-builtin` | Don't use built-in functions |
| `-fno-stack-protector` | Disable stack protection |
| `-fstack-protector` | Enable stack protection |
| `-fstack-protector-strong` | Strong stack protection |
| `-fstack-protector-all` | Protect all functions |
| `-fstack-clash-protection` | Stack clash protection |
| `-fcf-protection` | Control flow protection |
| `-ftrapv` | Trap on signed overflow |
| `-fwrapv` | Signed overflow wraps |
| `-fno-math-errno` | Don't set errno for math |
| `-fno-signed-zeros` | Ignore signed zeros |
| `-fno-trapping-math` | Assume no trapping math |
| `-fassociative-math` | Allow reassociation |
| `-freciprocal-math` | Allow reciprocal estimates |

---

## 8. Profiling Flags

| Flag | Description |
|------|-------------|
| `-pg` | Generate gprof profiling info |
| `-p` | Generate prof profiling info |
| `-fprofile-generate` | Generate profile data (PGO) |
| `-fprofile-use` | Use profile data (PGO) |
| `-fprofile-correction` | Correct profile data |
| `-fprofile-dir=path` | Set profile data directory |
| `-finstrument-functions` | Instrument function entry/exit |

---

## 9. Common Build Patterns

### Kernel Build

```bash
# Typical kernel CFLAGS
gcc -Wall -Wmissing-prototypes -Wstrict-prototypes \
    -O2 -fomit-frame-pointer -fno-common \
    -fno-strict-aliasing -fno-stack-protector \
    -mno-sse -mno-sse2 -mno-avx \
    -mcmodel=kernel -mno-red-zone \
    -ffreestanding
```

### Shared Library

```bash
# Compile
gcc -fPIC -c -o lib.o lib.c

# Link
gcc -shared -Wl,-soname,libfoo.so.1 -o libfoo.so.1.0 lib.o -lc

# Create symlinks
ln -s libfoo.so.1.0 libfoo.so.1
ln -s libfoo.so.1 libfoo.so
```

### Position-Independent Executable

```bash
gcc -fPIE -pie -o program program.c
```

### Sanitized Build

```bash
# AddressSanitizer
gcc -fsanitize=address -fno-omit-frame-pointer -g -O1 -o prog prog.c

# ThreadSanitizer
gcc -fsanitize=thread -g -O1 -o prog prog.c

# UndefinedBehaviorSanitizer
gcc -fsanitize=undefined -g -O1 -o prog prog.c
```

---

*For complete flag reference, consult `man gcc`, `man clang`, or the GCC/Clang online documentation.*
