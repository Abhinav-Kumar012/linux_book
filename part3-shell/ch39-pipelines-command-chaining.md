# Chapter 39: Pipelines and Command Chaining — |, &&, ||, ;, grouping, pipefail

## Overview

Pipelines and command chaining are the fundamental mechanisms for composing complex operations from simple commands. A pipeline connects the output of one command to the input of another, creating a data processing chain. Command chaining uses logical operators and separators to control execution flow based on success, failure, or simple sequencing.

Together, these constructs embody the Unix philosophy: small, focused tools that do one thing well, combined to accomplish complex tasks. Understanding pipeline behavior, exit status propagation, and the differences between `|`, `&&`, `||`, and `;` is essential for writing efficient and correct shell scripts.

## Intuition

Think of a pipeline as a factory assembly line. Raw data enters at one end, each station (command) processes it in some way, and the finished product exits at the other end. The `|` operator connects stations, passing output from one to the next.

Command chaining with `&&` and `||` is like a decision tree: "if the previous step succeeded, do this" (`&&`), or "if it failed, do that" (`||`). The `;` separator is like a simple to-do list: "do this, then do that, regardless of whether the first one succeeded."

## Architecture

```mermaid
graph LR
    A[cmd1] -->|stdout| B[cmd2]
    B -->|stdout| C[cmd3]
    C -->|stdout| D[Output]
    
    E[cmd1 && cmd2] -->|Exit 0| F[Execute cmd2]
    E -->|Exit non-0| G[Skip cmd2]
    
    H[cmd1 || cmd2] -->|Exit 0| I[Skip cmd2]
    H -->|Exit non-0| J[Execute cmd2]
    
    K[cmd1 ; cmd2] --> L[Execute cmd1]
    L --> M[Execute cmd2 always]
```

## Pipes (|)

### Basic Pipe

```bash
# Connect stdout of cmd1 to stdin of cmd2
ls | grep ".txt"
cat file.txt | sort
ps aux | grep nginx

# Multiple pipes
cat file.txt | sort | uniq | head -20

# Practical examples
# Find largest files
du -sh * | sort -rh | head -10

# Count lines in all Python files
find . -name "*.py" | xargs wc -l | sort -n

# Monitor log in real-time
tail -f /var/log/syslog | grep "error"

# Process data
cut -d: -f1 /etc/passwd | sort | wc -l

# Network debugging
curl -s https://api.example.com | jq '.results[] | .name'
```

### Pipe Behavior

```bash
# Each command in the pipe runs in its own subshell
# Data flows left to right through stdout/stdin
# stderr is NOT piped (goes to terminal)

# stderr goes to terminal, not to grep
ls /nonexistent | grep "error"
# Error message appears on screen, grep sees nothing

# Pipe stderr too (Bash 4+)
ls /nonexistent |& grep "error"

# Or explicitly
ls /nonexistent 2>&1 | grep "error"
```

### Pipe Exit Status

```bash
# By default, pipe exit status is the exit status of the LAST command
false | true
echo $?    # 0 (true's exit status)

true | false
echo $?    #1 (false's exit status)

# With pipefail: pipe exits with status of rightmost failed command
set -o pipefail

false | true
echo $?    # 1 (false's exit status)

true | false
echo $?    # 1 (false's exit status)

false | true | true
echo $?    # 1 (first failed command)

true | false | true
echo $?    # 1 (false is rightmost failed)

# Check individual command status (not directly possible with pipes)
# Use PIPESTATUS array (Bash)
set -o pipefail
false | true | false
echo "${PIPESTATUS[@]}"    # 1 0 1
echo "${PIPESTATUS[0]}"    # 1 (first command)
echo "${PIPESTATUS[1]}"    # 0 (second command)
echo "${PIPESTATUS[2]}"    # 1 (third command)
```

### pipefail

```bash
# Enable pipefail to catch failures in pipes
set -o pipefail

# Common pattern: catch pipe failures
set -euo pipefail

# Without pipefail: only last command's status matters
grep "pattern" nonexistent_file | sort
echo $?    # 0 (sort succeeded, even though grep failed)

# With pipefail: any failure causes pipe to fail
set -o pipefail
grep "pattern" nonexistent_file | sort
echo $?    # 1 (grep failed)
```

### Pipe Subshell Behavior

```bash
# ❌ Variables modified in pipe subshells don't propagate
count=0
cat file.txt | while read -r line; do
    ((count++))
done
echo "$count"    # 0! (count modified in subshell)

# ✅ Use process substitution
count=0
while read -r line; do
    ((count++))
done < <(cat file.txt)
echo "$count"    # Correct!

# ✅ Or use lastpipe (Bash 4.2+)
shopt -s lastpipe
count=0
cat file.txt | while read -r line; do
    ((count++))
done
echo "$count"    # Correct! (last command runs in current shell)

# ✅ Or use a temporary file
count=0
while read -r line; do
    ((count++))
done < file.txt
echo "$count"    # Correct!
```

## Command Chaining

### Semicolon (;) — Sequential Execution

```bash
# Execute commands sequentially, regardless of exit status
cmd1; cmd2; cmd3
# cmd1 runs, then cmd2, then cmd3, regardless of success/failure

# Practical uses
cd /tmp; ls -la
date; echo "---"; whoami

# In scripts
echo "Step 1"; operation1
echo "Step 2"; operation2
echo "Step 3"; operation3
```

### && — Logical AND

```bash
# Execute cmd2 only if cmd1 succeeds (exit status 0)
cmd1 && cmd2
# If cmd1 fails, cmd2 is NOT executed

# Chain multiple commands
cmd1 && cmd2 && cmd3
# Each runs only if all previous ones succeeded

# Practical uses
mkdir -p /tmp/test && cd /tmp/test
make && make install
apt update && apt upgrade -y
git add -A && git commit -m "update" && git push

# Conditional with else
command && echo "Success" || echo "Failure"
```

### || — Logical OR

```bash
# Execute cmd2 only if cmd1 fails (exit status non-0)
cmd1 || cmd2
# If cmd1 succeeds, cmd2 is NOT executed

# Default values
name="${1:-default}"
file="${CONFIG:-/etc/default.conf}"

# Fallback commands
ping -c1 host1 || ping -c1 host2 || echo "Both hosts down"
mkdir dir || echo "Directory already exists"
command || exit 1
```

### Combining && and ||

```bash
# Ternary-like pattern (use with caution)
condition && echo "yes" || echo "no"

# ⚠️ This is NOT a true ternary operator!
# If the "yes" part fails, the "no" part also runs
true && false || echo "no"
# Output: no (because false failed, so || triggers)

# ✅ Use if/then/else for complex conditions
if condition; then
    echo "yes"
else
    echo "no"
fi

# ✅ Acceptable for simple, non-failing commands
[[ -f file ]] && echo "exists" || echo "not found"
```

### Grouping Commands

```bash
# Group with braces: runs in CURRENT shell
{ cmd1; cmd2; cmd3; }
# Note: spaces around braces and semicolons required

# Group with parentheses: runs in SUBSHELL
(cmd1; cmd2; cmd3)
# Variables set inside don't affect parent

# Practical uses of grouping
# Redirect output of multiple commands
{ echo "Line 1"; echo "Line 2"; echo "Line 3"; } > file.txt

# Run multiple commands in background
{ cmd1; cmd2; } &

# Conditional group
[[ condition ]] && { cmd1; cmd2; cmd3; }

# Subshell for isolation
(count=0; for i in {1..10}; do ((count++)); done; echo "$count")
# count is 10 inside subshell, unchanged outside
```

### Braces vs Parentheses

```bash
# {} — Current shell
x=1
{ x=2; }
echo "$x"    # 2 (modified)

# () — Subshell
x=1
(x=3)
echo "$x"    # 1 (unchanged)

# {} — Can redirect all commands
{ echo "stdout"; echo "stderr" >&2; } > out.txt 2> err.txt

# () — Subshell with redirection
(echo "stdout"; echo "stderr" >&2) > out.txt 2> err.txt

# {} — Cannot be used as command in pipeline directly
# ❌ { echo hello; } | cat
# ✅ { echo hello; } | cat    (actually works, but braces must be separate tokens)

# () — Can be used in pipeline
(echo hello) | cat
```

## Advanced Pipeline Patterns

### Tee — Split Output

```bash
# Output to both stdout and file
command | tee output.log

# Output to both stdout and stderr
command | tee /dev/fd/2

# Pipe through tee
command | tee intermediate.log | grep "pattern"

# Append mode
command | tee -a output.log
```

### Process Substitution in Pipelines

```bash
# Compare two command outputs
diff <(cmd1) <(cmd2)

# Feed multiple sources to one command
sort -m <(sort file1) <(sort file2) <(sort file3)

# Avoid subshell variable issues
count=0
while read -r line; do
    ((count++))
done < <(grep "pattern" file.txt)
echo "$count"
```

### Named Pipes (FIFOs)

```bash
# Create a named pipe
mkfifo /tmp/mypipe

# Writer
echo "Hello" > /tmp/mypipe &

# Reader
cat /tmp/mypipe

# Cleanup
rm /tmp/mypipe

# Practical: inter-process communication
mkfifo /tmp/logpipe
tail -f /var/log/syslog > /tmp/logpipe &
grep "error" < /tmp/logpipe
```

### Pipeline with xargs

```bash
# Feed filenames to a command
find . -name "*.tmp" | xargs rm

# Handle filenames with spaces
find . -name "*.tmp" -print0 | xargs -0 rm

# Parallel execution
find . -name "*.py" | xargs -P 4 -I {} python3 {}

# With confirmation
find . -name "*.tmp" | xargs -p rm
```

## Execution Flow Control

### Short-Circuit Evaluation

```bash
# && short-circuits on failure
false && echo "not printed"

# || short-circuits on success
true || echo "not printed"

# Combined pattern
cmd1 && cmd2 || cmd3
# If cmd1 succeeds: run cmd2. If cmd2 fails: run cmd3.
# ⚠️ cmd3 runs if EITHER cmd1 OR cmd2 fails!
```

### if/then/else vs &&/||

```bash
# ❌ && / || is not a true if/then/else
condition && echo "yes" || echo "no"
# Problem: if "echo yes" fails, "echo no" also runs

# ✅ Use if/then/else for correctness
if condition; then
    echo "yes"
else
    echo "no"
fi

# ✅ && / || is fine for simple, non-failing commands
[[ -f file ]] && echo "exists"
command || exit 1
```

### Execution Order Examples

```bash
# Sequential: all run
date; hostname; whoami

# Conditional AND: stops on failure
mkdir dir && cd dir && make
# If mkdir fails, cd and make don't run

# Conditional OR: stops on success
ping -c1 host1 || ping -c1 host2 || echo "Both down"
# If host1 responds, host2 and echo don't run

# Combined: complex logic
make && make test && make install || echo "Build failed"
# make: run
# make test: only if make succeeds
# make install: only if make test succeeds
# echo: if any of the above fails

# Grouped with redirection
{ make && make test && make install; } > build.log 2>&1
```

## Common Pitfalls

### 1. Pipe Subshell Variable Scope

```bash
# ❌ Variables lost in pipe subshell
total=0
cat file.txt | while read -r num; do
    ((total += num))
done
echo "$total"    # 0!

# ✅ Use process substitution
total=0
while read -r num; do
    ((total += num))
done < <(cat file.txt)
echo "$total"    # Correct!
```

### 2. Missing pipefail

```bash
# ❌ Without pipefail, first command failure is hidden
grep "pattern" nonexistent_file | sort
echo $?    # 0 (sort succeeded)

# ✅ Enable pipefail
set -o pipefail
grep "pattern" nonexistent_file | sort
echo $?    # 1 (grep failed)
```

### 3. && / || Not a Ternary

```bash
# ❌ This doesn't work as expected
condition && risky_operation || echo "failed"
# If risky_operation fails, echo also runs

# ✅ Use if/then/else
if condition; then
    risky_operation
else
    echo "failed"
fi
```

### 4. Braces Spacing

```bash
# ❌ Missing spaces around braces
{echo "hello"}     # Syntax error
{ echo "hello";}   # Syntax error (missing space before })

# ✅ Correct spacing
{ echo "hello"; }
```

### 5. Pipeline Buffering

```bash
# ⚠️ Pipeline commands may buffer output
# This can cause delays in real-time processing

# Use stdbuf to control buffering
stdbuf -oL command | grep "pattern"    # Line-buffered

# Or unbuffer (from expect package)
unbuffer command | grep "pattern"

# Or use --line-buffered with grep
command | grep --line-buffered "pattern"
```

## Best Practices

1. **Use `set -o pipefail`** — catch failures in pipes
2. **Use `|| exit 1` after critical commands** — fail fast
3. **Use `&&` for dependent operations** — don't proceed if previous step fails
4. **Use `||` for fallbacks** — provide alternatives on failure
5. **Use `;` for independent operations** — when order matters but not success
6. **Use `{}` for grouping in current shell** — when you need variable access
7. **Use `()` for isolation** — when you don't want side effects
8. **Use `tee` to split output** — see what's happening while logging
9. **Use process substitution over pipes when variable scope matters**
10. **Use `xargs -print0` with `find -print0`** — handle filenames with spaces

## Exercises

### Exercise 1: Pipeline Construction
Build pipelines for:
- Finding the 10 largest files in a directory
- Counting unique IP addresses in an access log
- Finding duplicate lines in a file
- Converting a CSV to a sorted, formatted table

### Exercise 2: Error Handling
Write a script that:
- Uses `set -o pipefail`
- Chains 5 commands with `&&`
- Provides meaningful error messages on failure
- Logs both stdout and stderr

### Exercise 3: Command Chaining
Implement these patterns using `&&`, `||`, and `;`:
- Try command A, fall back to command B, report failure if both fail
- Run three commands, report which ones succeeded and which failed
- Execute commands only if a specific file exists

### Exercise 4: Subshell vs Current Shell
Write a script that demonstrates:
- Variable scope differences between `{}` and `()`
- Pipe subshell behavior with variables
- Process substitution as an alternative to pipes
- The effect of `lastpipe` on pipe behavior

### Exercise 5: Advanced Pipeline
Build a log analysis pipeline that:
- Tails a log file in real-time
- Filters for errors
- Extracts timestamps and messages
- Counts occurrences per minute
- Alerts when error rate exceeds a threshold

## References

- [Bash Manual: Pipelines](https://www.gnu.org/software/bash/manual/bash.html#Pipelines)
- [Bash Manual: Lists](https://www.gnu.org/software/bash/manual/bash.html#Lists)
- [POSIX: Pipelines](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_09)
- [POSIX: Lists](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_09)
- [Greg's Wiki: Pipes](https://mywiki.wooledge.org/Pipes)
- [Greg's Wiki: BashFAQ 024](https://mywiki.wooledge.org/BashFAQ/024)
- [Bash Hackers: Pipelines](https://wiki.bash-hackers.org/syntax/pipeline)
