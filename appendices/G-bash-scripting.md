# Appendix G: Bash Scripting Handbook

## Overview

This handbook covers Bash scripting fundamentals through advanced techniques: variables, conditionals, loops, functions, arrays, traps, and parameter expansion.

---

## 1. Script Basics

### Shebang and Headers

```bash
#!/bin/bash
# Description: Brief description of the script
# Author: Author Name
# Date: 2024-01-01
# Usage: ./script.sh [options] <arguments>

set -euo pipefail
# -e: Exit on error
# -u: Treat unset variables as errors
# -o pipefail: Pipeline fails on first error
```

### Making Scripts Executable

```bash
chmod +x script.sh
./script.sh arg1 arg2
bash script.sh arg1 arg2
```

---

## 2. Variables

### Variable Assignment

```bash
# Simple assignment (no spaces around =)
name="John"
age=30
readonly PI=3.14159

# Command substitution
current_date=$(date +%Y-%m-%d)
file_count=$(ls | wc -l)

# Arithmetic
result=$((5 + 3))
result=$(expr 5 + 3)
```

### Variable Expansion

```bash
# Basic expansion
echo "$name"
echo "${name}"

# Default values
echo "${var:-default}"    # Use default if var is unset or empty
echo "${var:=default}"    # Assign default if var is unset or empty
echo "${var:+alternate}"  # Use alternate if var is set and non-empty
echo "${var:?error msg}"  # Error if var is unset or empty

# String length
echo "${#name}"

# Substring
echo "${name:0:4}"       # First 4 characters
echo "${name:2}"         # From index 2 to end

# Pattern removal
filename="archive.tar.gz"
echo "${filename%.gz}"       # Remove shortest .gz suffix → archive.tar
echo "${filename%%.*}"       # Remove longest .* suffix → archive
echo "${filename#*.}"        # Remove shortest *. prefix → tar.gz
echo "${filename##*.}"       # Remove longest *. prefix → gz

# Pattern replacement
text="Hello World World"
echo "${text/World/Earth}"    # Replace first → Hello Earth World
echo "${text//World/Earth}"   # Replace all → Hello Earth Earth
echo "${text/#Hello/Hi}"     # Replace at beginning → Hi World World
echo "${text/%World/Earth}"  # Replace at end → Hello World Earth

# Case modification (Bash 4+)
echo "${name^^}"    # Uppercase → JOHN
echo "${name,,}"    # Lowercase → john
echo "${name^}"     # Capitalize first → John
```

### Environment Variables

```bash
# Export to environment
export PATH="$PATH:/usr/local/bin"
export EDITOR=vim
export LANG=en_US.UTF-8

# Common environment variables
echo $HOME        # Home directory
echo $USER        # Current username
echo $SHELL       # Current shell
echo $PWD         # Current directory
echo $OLDPWD      # Previous directory
echo $HOSTNAME    # Machine hostname
echo $RANDOM      # Random number 0-32767
echo $LINENO      # Current line number
echo $SECONDS     # Seconds since script started
echo $BASHPID     # Current bash process ID
echo $BASH_VERSION # Bash version
echo $FUNCNAME    # Current function name (array)
echo $BASH_SOURCE  # Current script source (array)
```

---

## 3. Conditionals

### if/elif/else

```bash
if [[ condition ]]; then
    # true block
elif [[ condition2 ]]; then
    # elif block
else
    # else block
fi
```

### Test Operators

#### String Tests

```bash
[[ -z "$str" ]]      # True if string is empty
[[ -n "$str" ]]      # True if string is non-empty
[[ "$a" == "$b" ]]   # String equality
[[ "$a" != "$b" ]]   # String inequality
[[ "$a" < "$b" ]]    # Lexicographic less than
[[ "$a" > "$b" ]]    # Lexicographic greater than
[[ "$a" =~ pattern ]] # Regex match (Bash 3+)
[[ "$a" == glob* ]]   # Glob match
```

#### File Tests

```bash
[[ -e "$file" ]]     # Exists
[[ -f "$file" ]]     # Is regular file
[[ -d "$dir" ]]      # Is directory
[[ -L "$link" ]]     # Is symbolic link
[[ -r "$file" ]]     # Is readable
[[ -w "$file" ]]     # Is writable
[[ -x "$file" ]]     # Is executable
[[ -s "$file" ]]     # Has non-zero size
[[ -b "$dev" ]]      # Is block device
[[ -c "$dev" ]]      # Is character device
[[ -p "$file" ]]     # Is named pipe (FIFO)
[[ -S "$file" ]]     # Is socket
[[ "$a" -nt "$b" ]]  # $a is newer than $b
[[ "$a" -ot "$b" ]]  # $a is older than $b
[[ "$a" -ef "$b" ]]  # $a and $b are same file (hard link)
```

#### Numeric Tests

```bash
[[ "$a" -eq "$b" ]]  # Equal
[[ "$a" -ne "$b" ]]  # Not equal
[[ "$a" -lt "$b" ]]  # Less than
[[ "$a" -le "$b" ]]  # Less than or equal
[[ "$a" -gt "$b" ]]  # Greater than
[[ "$a" -ge "$b" ]]  # Greater than or equal
```

### Arithmetic in Conditionals

```bash
if (( a > b )); then
    echo "a is greater"
fi

if (( a == 0 && b != 0 )); then
    echo "complex condition"
fi
```

### Logical Operators

```bash
# Inside [[ ]]
[[ "$a" == 1 && "$b" == 2 ]]    # AND
[[ "$a" == 1 || "$b" == 2 ]]    # OR
[[ ! "$a" == 1 ]]                # NOT

# Inside (( ))
(( a > 0 && b > 0 ))

# Combining conditions
if [[ -f "$file" && -r "$file" ]]; then
    echo "File exists and is readable"
fi
```

### case Statement

```bash
case "$1" in
    start)
        start_service
        ;;
    stop)
        stop_service
        ;;
    restart)
        stop_service
        start_service
        ;;
    status)
        check_status
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status}"
        exit 1
        ;;
esac
```

### Pattern Matching in case

```bash
case "$filename" in
    *.tar.gz|*.tgz)
        echo "Gzipped tarball"
        ;;
    *.tar.bz2|*.tbz2)
        echo "Bzip2 tarball"
        ;;
    *.tar.xz|*.txz)
        echo "Xz tarball"
        ;;
    *.zip)
        echo "Zip archive"
        ;;
    *)
        echo "Unknown format"
        ;;
esac
```

---

## 4. Loops

### for Loops

```bash
# List iteration
for item in apple banana cherry; do
    echo "$item"
done

# C-style for loop
for ((i = 0; i < 10; i++)); do
    echo "$i"
done

# Range (brace expansion)
for i in {1..10}; do
    echo "$i"
done

# Range with step
for i in {0..100..5}; do
    echo "$i"
done

# Glob expansion
for file in *.txt; do
    [[ -f "$file" ]] || continue
    echo "Processing: $file"
done

# Command output
for user in $(cut -d: -f1 /etc/passwd); do
    echo "$user"
done

# Read lines from file
while IFS= read -r line; do
    echo "Line: $line"
done < /etc/hosts

# Read CSV
while IFS=, read -r name age city; do
    echo "$name is $age years old, lives in $city"
done < data.csv
```

### while Loops

```bash
# Basic while
count=0
while [[ $count -lt 10 ]]; do
    echo "$count"
    ((count++))
done

# Read command output
while read -r pid name; do
    echo "PID: $pid, Name: $name"
done < <(ps -eo pid,comm)

# Infinite loop
while true; do
    echo "Running..."
    sleep 1
done

# Until loop (opposite of while)
until [[ -f /tmp/ready ]]; do
    echo "Waiting for ready file..."
    sleep 1
done
```

### Loop Control

```bash
# break — exit loop
for i in {1..100}; do
    [[ $i -eq 50 ]] && break
    echo "$i"
done

# continue — skip iteration
for i in {1..10}; do
    [[ $((i % 2)) -eq 0 ]] && continue
    echo "$i"  # Only odd numbers
done

# break N — break out of N loops
for i in {1..5}; do
    for j in {1..5}; do
        [[ $j -eq 3 ]] && break 2
        echo "$i $j"
    done
done
```

---

## 5. Functions

### Function Definition

```bash
# Style 1
function greet() {
    echo "Hello, $1!"
}

# Style 2 (POSIX-compatible)
greet() {
    echo "Hello, $1!"
}

# Calling
greet "World"
```

### Return Values

```bash
# Return exit status (0-255)
is_even() {
    (( $1 % 2 == 0 ))
    return $?  # 0 = true, 1 = false
}

if is_even 4; then
    echo "4 is even"
fi

# Return string via stdout
get_hostname() {
    hostname -f
}

result=$(get_hostname)

# Return via global variable
parse_config() {
    CONFIG_KEY="value"
}
parse_config
echo "$CONFIG_KEY"

# Return via nameref (Bash 4.3+)
get_info() {
    local -n result_ref=$1
    result_ref["name"]="John"
    result_ref["age"]=30
}

declare -A info
get_info info
echo "${info[name]} is ${info[age]}"
```

### Local Variables

```bash
my_func() {
    local count=0        # Local to function
    local -r CONST=42    # Read-only local
    local -a arr=(1 2 3) # Local array
    local -A map=([a]=1 [b]=2) # Local associative array
    local -i num=0       # Integer local

    ((count++))
    echo "Count: $count"
}
```

### Function Arguments

```bash
# $1, $2, ... — positional parameters
# $@ — all arguments (separate)
# $* — all arguments (single string)
# $# — argument count

process_files() {
    local verbose=0
    local files=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -v|--verbose)
                verbose=1
                shift
                ;;
            -o|--output)
                output="$2"
                shift 2
                ;;
            -*)
                echo "Unknown option: $1" >&2
                return 1
                ;;
            *)
                files+=("$1")
                shift
                ;;
        esac
    done

    for file in "${files[@]}"; do
        [[ $verbose -eq 1 ]] && echo "Processing: $file"
        # Process file...
    done
}

process_files -v -o result.txt file1.txt file2.txt
```

---

## 6. Arrays

### Indexed Arrays

```bash
# Declaration
declare -a arr
arr=(apple banana cherry)

# Individual assignment
arr[0]="apple"
arr[1]="banana"
arr[2]="cherry"

# Append
arr+=(date elderberry)

# Access
echo "${arr[0]}"       # First element
echo "${arr[-1]}"      # Last element (Bash 4.3+)
echo "${arr[@]}"       # All elements
echo "${arr[*]}"       # All elements (single string)
echo "${#arr[@]}"      # Number of elements
echo "${!arr[@]}"      # All indices

# Slice
echo "${arr[@]:1:3}"   # Elements 1-3

# Iterate
for item in "${arr[@]}"; do
    echo "$item"
done

# Iterate with index
for i in "${!arr[@]}"; do
    echo "$i: ${arr[$i]}"
done

# Delete element
unset arr[1]

# Delete entire array
unset arr
```

### Associative Arrays (Bash 4+)

```bash
# Declaration
declare -A map

# Assignment
map[name]="John"
map[age]=30
map[city]="New York"

# Literal declaration
declare -A map=([name]="John" [age]=30 [city]="New York")

# Access
echo "${map[name]}"
echo "${map[@]}"       # All values
echo "${!map[@]}"      # All keys
echo "${#map[@]}"      # Number of entries

# Iterate
for key in "${!map[@]}"; do
    echo "$key = ${map[$key]}"
done

# Check if key exists
[[ -v map[name] ]] && echo "Key exists"
[[ ${map[missing]+_} ]] && echo "Key exists"

# Delete entry
unset map[age]
```

---

## 7. Parameter Expansion Advanced

### String Manipulation

```bash
str="Hello World"

# Length
${#str}                    # 11

# Substring
${str:0:5}                 # Hello
${str:6}                   # World
${str: -5}                 # World (from end, note space before -)
${str:(-5)}                # World (alternative syntax)

# Case modification
${str^^}                   # HELLO WORLD
${str,,}                   # hello world
${str^}                    # Hello World (capitalize first)
${str,}                    # hello World (lowercase first)

# Pattern removal
file="path/to/archive.tar.gz"
${file##*/}                # archive.tar.gz (basename)
${file%/*}                 # path/to (dirname)
${file%%.*}                # path/to/archive (remove all extensions)
${file#*/}                 # to/archive.tar.gz (remove first directory)

# Replacement
${str/World/Earth}         # Hello Earth (first match)
${str//l/L}                # HeLLo WorLd (all matches)
${str/#Hello/Hi}           # Hi World (prefix match)
${str/%World/Earth}        # Hello Earth (suffix match)

# Indirect expansion
varname="HOME"
${!varname}                # Value of $HOME

# Transformations with patterns
path="/usr/local/bin/bash"
${path//\//.}              # usr.local.bin.bash (replace / with .)
```

### Conditional Expansion Patterns

```bash
# Use default
${var:-default}            # Use default if unset or empty
${var-default}             # Use default if unset only

# Assign default
${var:=default}            # Assign and use default if unset or empty
${var=default}             # Assign and use default if unset only

# Use alternate
${var:+alternate}          # Use alternate if set and non-empty
${var+alternate}           # Use alternate if set (even if empty)

# Error
${var:?error message}      # Error if unset or empty
${var?error message}       # Error if unset only
```

---

## 8. Input/Output

### Reading Input

```bash
# Basic read
read -p "Enter name: " name

# Read with default
read -p "Enter name [John]: " name
name=${name:-John}

# Silent read (password)
read -sp "Password: " password
echo

# Read into array
read -ra words <<< "one two three"

# Read with timeout
read -t 5 -p "Quick! Enter something: " input

# Read with delimiter
read -d ':' -p "Enter colon-separated: " field1 field2

# Read single character
read -n 1 -p "Continue? (y/n): " answer
echo

# Read from here document
cat <<EOF
Hello, $name!
Today is $(date +%Y-%m-%d)
EOF

# Read from here string
grep "pattern" <<< "$variable"
```

### Output Formatting

```bash
# printf (formatted output)
printf "Name: %-20s Age: %d\n" "$name" "$age"
printf "%05d\n" 42            # 00042
printf "%.2f\n" 3.14159       # 3.14
printf "%-10s %10s\n" "Left" "Right"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'  # No Color
echo -e "${RED}Error:${NC} something failed"
echo -e "${GREEN}Success!${NC}"

# Log to stderr
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >&2
}
```

---

## 9. Traps and Cleanup

### Basic Traps

```bash
# Run on exit (normal or error)
cleanup() {
    echo "Cleaning up..."
    rm -f "$temp_file"
}
trap cleanup EXIT

# Run on specific signals
trap 'echo "Caught SIGINT"; exit 1' INT
trap 'echo "Caught SIGTERM"; exit 1' TERM
trap 'echo "Caught SIGHUP"' HUP

# Ignore signal
trap '' INT

# Reset trap to default
trap - INT
```

### Common Trap Patterns

```bash
# Temp file cleanup
temp_file=$(mktemp)
trap 'rm -f "$temp_file"' EXIT

# Temp directory cleanup
temp_dir=$(mktemp -d)
trap 'rm -rf "$temp_dir"' EXIT

# Multiple cleanup actions
cleanup() {
    local exit_code=$?
    rm -f "$temp_file"
    rm -rf "$temp_dir"
    # Kill background processes
    jobs -p | xargs -r kill 2>/dev/null
    exit "$exit_code"
}
trap cleanup EXIT

# Signal-aware cleanup
cleanup() {
    echo "Received signal, cleaning up..."
    rm -f "$temp_file"
}
trap cleanup INT TERM HUP
trap 'rm -f "$temp_file"; exit' EXIT

# Debug trap (trace execution)
set -o functrace
trap 'echo "DEBUG: $BASH_COMMAND"' DEBUG
```

---

## 10. Error Handling

### Strict Mode

```bash
#!/bin/bash
set -euo pipefail

# -e: Exit immediately on error
# -u: Treat unset variables as errors
# -o pipefail: Return value of pipeline is last non-zero exit code
```

### Error Handling Patterns

```bash
# Exit on error with message
die() {
    echo "Error: $*" >&2
    exit 1
}

# Try/catch pattern
try() {
    local exit_code=0
    "$@" || exit_code=$?
    return "$exit_code"
}

# Or simply
command || die "Command failed"

# Check return code explicitly
if ! some_command; then
    echo "Command failed"
    exit 1
fi

# Allow specific commands to fail
set +e
risky_command
result=$?
set -e

# Or
risky_command || true

# ERR trap (fires on any error in strict mode)
trap 'echo "Error on line $LINENO" >&2' ERR

# Detailed ERR trap
trap 'echo "Error at ${BASH_SOURCE[0]}:${LINENO}: command \"${BASH_COMMAND}\" failed with exit code $?" >&2' ERR
```

---

## 11. Process Substitution and Pipelines

### Process Substitution

```bash
# Compare output of two commands
diff <(sort file1) <(sort file2)

# Read from command output
while read -r line; do
    echo "$line"
done < <(find /etc -name "*.conf")

# Multiple inputs
paste <(cut -d: -f1 /etc/passwd) <(cut -d: -f3 /etc/passwd)

# Redirect stderr and stdout separately
command > >(tee stdout.log) 2> >(tee stderr.log >&2)
```

### Pipelines

```bash
# Simple pipeline
cat /var/log/syslog | grep error | wc -l

# Pipeline with process substitution
grep -r "TODO" src/ | sort | uniq -c | sort -rn | head -20

# Named pipe (FIFO)
mkfifo /tmp/mypipe
echo "data" > /tmp/mypipe &
cat /tmp/mypipe
rm /tmp/mypipe
```

---

## 12. Here Documents and Here Strings

### Here Documents

```bash
# Basic
cat <<EOF
Hello, $USER!
Current date: $(date)
EOF

# Indented (tabs stripped)
cat <<-EOF
	Indented text
	More text
	EOF

# Quoted (no variable expansion)
cat <<'EOF'
$USER is literal
$(date) is literal
EOF

# Redirect to file
cat > /tmp/config.txt <<EOF
server=192.168.1.1
port=8080
EOF

# Pipe to command
ssh server <<'EOF'
ls -la /var/log
df -h
EOF
```

### Here Strings

```bash
# Pass string to command
grep "pattern" <<< "$variable"

# Read from string
read -r first last <<< "John Doe"

# Arithmetic
bc <<< "scale=2; 10/3"
```

---

## 13. Job Control

### Background Jobs

```bash
# Run in background
command &

# Background with nohup (survives terminal close)
nohup command &

# Background with output redirect
command > /dev/null 2>&1 &

# Check background jobs
jobs -l

# Bring to foreground
fg %1

# Send to background
bg %1

# Wait for all background jobs
wait

# Wait for specific job
wait %1

# Wait for specific PID
wait $pid
```

### Parallel Execution

```bash
# Run commands in parallel
command1 &
command2 &
command3 &
wait

# xargs parallel
find . -name "*.txt" | xargs -P 4 -I {} process_file {}

# GNU parallel
parallel -j 4 process_file ::: *.txt
```

---

## 14. Debugging

### Debug Options

```bash
# Run with debug output
bash -x script.sh

# Enable debug in script
set -x

# Disable debug
set +x

# Debug specific section
set -x
debug_section
set +x

# Debug function
debug() {
    [[ "${DEBUG:-0}" == "1" ]] && echo "DEBUG: $*" >&2
}

# Trace with timestamp
export PS4='+ $(date "+%H:%M:%S") ${BASH_SOURCE}:${LINENO}: '
set -x
```

### Common Debugging Patterns

```bash
# Print variable contents
declare -p varname

# Show function definition
declare -f function_name

# List all functions
declare -F

# List all variables
declare -p

# Show array contents
declare -p array_name

# Check if command exists
type -t command_name
```

---

## 15. Best Practices

### Style Guide

```bash
# 1. Always quote variables
echo "$var"          # Good
echo $var            # Bad (word splitting, globbing)

# 2. Use [[ ]] instead of [ ]
[[ -f "$file" ]]     # Good
[ -f "$file" ]       # Bad (limited, unsafe)

# 3. Use $() instead of backticks
result=$(command)    # Good
result=`command`     # Bad (no nesting)

# 4. Use local variables in functions
my_func() {
    local var="value"
}

# 5. Use readonly for constants
readonly CONFIG_FILE="/etc/myapp.conf"

# 6. Use arrays for lists
files=(file1.txt file2.txt file3.txt)
for file in "${files[@]}"; do
    process "$file"
done

# 7. Check return codes
if ! command; then
    echo "Failed" >&2
    exit 1
fi

# 8. Use shellcheck
# shellcheck disable=SC2086
# Install: apt install shellcheck
```

### Security Practices

```bash
# 1. Don't use eval with user input
# Bad
eval "$user_input"

# 2. Use mktemp for temp files
temp_file=$(mktemp)

# 3. Set restrictive umask
umask 077

# 4. Don't put passwords in command line
# Bad
curl -u "user:password" https://example.com

# Good
curl -u "user" https://example.com  # Will prompt for password

# 5. Use full paths for cron jobs
/usr/bin/find /tmp -mtime +7 -delete

# 6. Validate input
validate_input() {
    local input="$1"
    if [[ ! "$input" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo "Invalid input" >&2
        return 1
    fi
}
```

---

*This handbook covers the essential Bash scripting concepts. For complete reference, consult `man bash` or the Bash Reference Manual at https://www.gnu.org/software/bash/manual/.*
