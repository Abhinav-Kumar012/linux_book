# Appendix Q: perf Cheat Sheet

## Overview

`perf` is the standard Linux profiling tool. This cheat sheet covers `perf stat`, `perf record`, `perf report`, `perf top`, `perf annotate`, `perf mem`, and `perf sched`.

---

## 1. perf stat — Performance Counters

### Basic Usage

```bash
# Count events for a command
perf stat ./program

# Count events for a running process
perf stat -p 1234

# Count for specific duration
perf stat -p 1234 sleep 10

# Specific events
perf stat -e cycles,instructions,cache-misses ./program

# Per-CPU stats
perf stat -a sleep 5

# Per-thread stats
perf stat -t 1234 sleep 5

# Verbose output
perf stat -v ./program

# CSV output
perf stat -x, ./program

# Output to file
perf stat -o stats.txt ./program

# Append to file
perf stat -a -o stats.txt --append sleep 5

# Group events (counted together)
perf stat -e '{cycles,instructions}' ./program

# Repeat and show statistics
perf stat -r 5 ./program  # Run 5 times
```

### Common Events

```bash
# CPU cycles and instructions
perf stat -e cycles,instructions,cycles:u,instructions:u ./program

# Cache events
perf stat -e L1-dcache-loads,L1-dcache-load-misses \
          -e L1-dcache-stores,L1-dcache-store-misses \
          -e LLC-loads,LLC-load-misses ./program

# Branch prediction
perf stat -e branches,branch-misses ./program

# Context switches and page faults
perf stat -e context-switches,page-faults ./program

# Memory events
perf stat -e dTLB-loads,dTLB-load-misses \
          -e iTLB-loads,iTLB-load-misses ./program

# All hardware events
perf stat -a -e 'cycles,instructions,cache-misses,branch-misses,context-switches,page-faults' sleep 5
```

---

## 2. perf record — Record Profile Data

### Basic Usage

```bash
# Record profiling data
perf record ./program

# Record with call graph
perf record -g ./program

# Record system-wide
perf record -a sleep 10

# Record specific process
perf record -p 1234 sleep 10

# Record with frequency
perf record -F 99 ./program    # 99 Hz sampling

# Record specific events
perf record -e cycles ./program

# Record with DWARF call graph
perf record --call-graph dwarf ./program

# Record with frame pointer call graph
perf record --call-graph fp ./program

# Record with LBR (Last Branch Record, Intel)
perf record --call-graph lbr ./program

# Record kernel and user
perf record -a -g sleep 10

# Record user-space only
perf record -u ./program

# Record kernel-space only
perf record -k ./program

# Record with source line info
perf record -g --source ./program

# Record with timestamp
perf record -T ./program

# Record specific CPU
perf record -C 0,1 sleep 10

# Record with event multiplexing
perf record -e 'cycles:pp,instructions:pp' ./program

# Output to specific file
perf record -o mydata.data ./program
```

---

## 3. perf report — Analyze Profile Data

### Basic Usage

```bash
# Interactive report
perf report

# Report from specific data file
perf report -i mydata.data

# Sort by overhead
perf report --sort comm,dso,symbol

# Sort by function
perf report --sort symbol

# Sort by shared object
perf report --sort dso

# Sort by source file
perf report --sort srcline

# Annotated source
perf report --stdio

# TUI (interactive)
perf report --tui

# Graphical (browser)
perf report --gtk

# Show call graph
perf report --call-graph

# Limit output
perf report --stdio --max-stack 10

# Filter by symbol
perf report --symbol-filter=my_function

# Percentages
perf report --percent-limit 1
```

---

## 4. perf top — Real-Time Profiling

```bash
# Real-time system profiling
perf top

# Profile specific process
perf top -p 1234

# Specific events
perf top -e cycles

# With call graph
perf top -g

# Sort by overhead
perf top --sort comm,dso,symbol

# Kernel symbols
perf top -k

# User symbols
perf top -u

# Specific CPU
perf top -C 0

# Refresh rate
perf top -F 50
```

---

## 5. perf annotate — Source/Assembly Annotation

```bash
# Annotate specific function
perf annotate my_function

# Annotate from data file
perf annotate -i mydata.data my_function

# Annotated assembly
perf annotate --asm

# Annotated source
perf annotate --source

# Intel assembly syntax
perf annotate --asm --intel

# Percentages
perf annotate --percent-limit 1
```

---

## 6. perf mem — Memory Access Profiling

```bash
# Record memory access profile
perf mem record ./program

# Report memory accesses
perf mem report

# TUI report
perf mem report --tui

# Sort by memory level
perf mem report --sort mem,symbol,dso

# Sort by NUMA node
perf mem report --sort symbol,mem,snoop

# Data address sampling
perf record -e 'cpu/mem-loads/pp' ./program
perf record -e 'cpu/mem-stores/pp' ./program
```

---

## 7. perf sched — Scheduler Profiling

```bash
# Record scheduler events
perf sched record sleep 10

# Show scheduler latency
perf sched latency

# Show scheduler map
perf sched map

# Show scheduler timehist
perf sched timehist

# Show scheduler statistics
perf sched stat

# Show per-task scheduling
perf sched timehist -p 1234

# Show context switch details
perf sched timehist --summary
```

---

## 8. perf trace — System Call Tracing

```bash
# Trace all syscalls
perf trace ./program

# Trace specific process
perf trace -p 1234

# Trace specific syscalls
perf trace -e 'read,write,open,close' ./program

# Trace with duration
perf trace -p 1234 --duration 10

# Trace with call graph
perf trace -g ./program

# Trace system-wide
perf trace -a sleep 5

# Count syscalls
perf trace --summary ./program

# Trace with timestamps
perf trace -T ./program

# Trace specific syscalls with args
perf trace -e 'openat' --string-size 128 ./program
```

---

## 9. perf lock — Lock Profiling

```bash
# Record lock events
perf lock record sleep 10

# Report lock contention
perf lock report

# Show lock statistics
perf lock report --sort acquired,contended

# Show lock contention latency
perf lock report --sort wait_total
```

---

## 10. perf probe — Dynamic Tracing

```bash
# Add probe at function
perf probe --add my_function

# Add probe with arguments
perf probe --add 'my_function arg1 arg2'

# Add probe at line
perf probe --add 'my_source.c:42'

# Add probe with return value
perf probe --add 'my_function%return $retval'

# List probes
perf probe -l

# Record probe events
perf record -e probe:my_function -aR sleep 10

# Remove probes
perf probe --del my_function

# Remove all probes
perf probe --del='*'
```

---

## 11. perf list — List Events

```bash
# List all events
perf list

# List hardware events
perf list hw

# List software events
perf list sw

# List cache events
perf list cache

# List tracepoint events
perf list tracepoint

# List specific category
perf list 'block:*'

# List PMU events
perf list pmu
```

---

## 12. Flame Graphs

```bash
# Record with call graph
perf record -g -F 99 ./program

# Generate stack collapse
perf script | stackcollapse-perf.pl > out.stacks

# Generate flame graph
flamegraph.pl out.stacks > profile.svg

# One-liner
perf script | stackcollapse-perf.pl | flamegraph.pl > profile.svg

# System-wide flame graph
perf record -a -g -F 99 sleep 30
perf script | stackcollapse-perf.pl | flamegraph.pl > system.svg

# Differential flame graph
difffolded.pl base.stacks new.stacks | flamegraph.pl > diff.svg
```

---

## 13. Common Profiling Recipes

### CPU Profiling

```bash
# Profile CPU usage
perf record -g -F 99 ./program
perf report --call-graph

# Profile specific function
perf record -g -F 99 -e cycles:u ./program
perf annotate my_function
```

### Cache Profiling

```bash
# Cache miss analysis
perf stat -e 'L1-dcache-loads,L1-dcache-load-misses' ./program
perf stat -e 'LLC-loads,LLC-load-misses' ./program

# Record cache misses
perf record -e cache-misses -g ./program
perf report --sort symbol,dso
```

### Branch Prediction

```bash
# Branch miss analysis
perf stat -e 'branches,branch-misses' ./program

# Record branch misses
perf record -e branch-misses -g ./program
perf report
```

### I/O Profiling

```bash
# Block I/O analysis
perf record -e 'block:block_rq_issue' -a sleep 10
perf report --sort comm,device

# Network I/O
perf record -e 'net:net_dev_xmit' -a sleep 10
```

### Context Switch Analysis

```bash
# Context switch profiling
perf stat -e context-switches ./program

# Record context switches
perf record -e context-switches -g ./program
perf report

# Scheduler analysis
perf sched record sleep 10
perf sched latency
perf sched timehist
```

---

## 14. perf Events Reference

### Hardware Events

| Event | Description |
|-------|-------------|
| `cpu-cycles` / `cycles` | CPU cycles |
| `instructions` | Instructions retired |
| `cache-references` | Cache accesses |
| `cache-misses` | Cache misses |
| `branch-instructions` / `branches` | Branch instructions |
| `branch-misses` | Branch mispredictions |
| `bus-cycles` | Bus cycles |
| `stalled-cycles-frontend` | Frontend stall cycles |
| `stalled-cycles-backend` | Backend stall cycles |
| `ref-cycles` | Reference cycles |

### Software Events

| Event | Description |
|-------|-------------|
| `cpu-clock` | CPU clock |
| `task-clock` | Task clock |
| `page-faults` / `faults` | Page faults |
| `context-switches` / `cs` | Context switches |
| `cpu-migrations` | CPU migrations |
| `minor-faults` | Minor page faults |
| `major-faults` | Major page faults |
| `alignment-faults` | Alignment faults |
| `emulation-faults` | Emulation faults |
| `dummy` | Dummy event |

### Cache Events

| Event | Description |
|-------|-------------|
| `L1-dcache-loads` | L1 data cache loads |
| `L1-dcache-load-misses` | L1 data cache load misses |
| `L1-dcache-stores` | L1 data cache stores |
| `L1-dcache-store-misses` | L1 data cache store misses |
| `L1-dcache-prefetches` | L1 data cache prefetches |
| `L1-icache-loads` | L1 instruction cache loads |
| `L1-icache-load-misses` | L1 instruction cache load misses |
| `LLC-loads` | Last level cache loads |
| `LLC-load-misses` | Last level cache load misses |
| `LLC-stores` | Last level cache stores |
| `LLC-store-misses` | Last level cache store misses |
| `dTLB-loads` | Data TLB loads |
| `dTLB-load-misses` | Data TLB load misses |
| `dTLB-stores` | Data TLB stores |
| `dTLB-store-misses` | Data TLB store misses |
| `iTLB-loads` | Instruction TLB loads |
| `iTLB-load-misses` | Instruction TLB load misses |
| `branch-loads` | Branch loads |
| `branch-load-misses` | Branch load misses |
| `node-loads` | NUMA node loads |
| `node-load-misses` | NUMA node load misses |

---

*For complete `perf` documentation, consult `man perf` or the perf wiki at https://perf.wiki.kernel.org/.*
