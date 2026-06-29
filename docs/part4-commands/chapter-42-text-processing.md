# Chapter 42: Text Processing — grep, ripgrep, sed, awk, cut, sort, uniq, tr, wc, paste, join

## Overview

Text processing is the heart of Unix philosophy — "everything is a file" means configuration, logs, data, and even system state are represented as text. The tools in this chapter form a pipeline-based text processing ecosystem that can handle everything from simple searches to complex data transformations.

These tools follow the Unix filter model: they read from stdin, process, and write to stdout. This enables powerful compositions through pipes (`|`). Understanding these tools — and how to combine them — is what separates casual Linux users from power users and effective system administrators.

---

## grep — Print Lines Matching a Pattern

### Purpose

`grep` (Global Regular Expression Print) searches input for lines matching a pattern. It is the most widely used text-searching utility in Unix-like systems.

### Syntax

```
grep [OPTION...] PATTERN [FILE...]
```

### Key Options

| Option | Description |
|--------|-------------|
| `-i` | Case-insensitive matching |
| `-v` | Invert match (print non-matching lines) |
| `-r`, `-R` | Recursive search through directories |
| `-n` | Print line numbers |
| `-l` | Print only filenames containing matches |
| `-c` | Count matching lines |
| `-w` | Match whole words only |
| `-x` | Match whole lines only |
| `-e PATTERN` | Specify pattern (useful for patterns starting with `-`) |
| `-f FILE` | Read patterns from FILE |
| `-A N` | Print N lines after each match (context) |
| `-B N` | Print N lines before each match |
| `-C N` | Print N lines before and after |
| `-E` | Extended regex (same as `egrep`) |
| `-F` | Fixed strings (same as `fgrep`) |
| `-P` | Perl-compatible regex (PCRE) |
| `-o` | Print only the matching part |
| `-q` | Quiet mode (no output, just exit status) |
| `-s` | Suppress error messages |
| `-m N` | Stop after N matches |
| `--include=PATTERN` | Only search files matching PATTERN |
| `--exclude=PATTERN` | Skip files matching PATTERN |
| `--exclude-dir=PATTERN` | Skip directories matching PATTERN |
| `--color` | Highlight matches |
| `-a` | Treat binary files as text |
| `-I` | Ignore binary files |
| `-Z` | Print null byte after filenames (for `xargs -0`) |
| `--max-count=N` | Maximum matches per file |
| `--binary-files=TYPE` | Handle binary files (text, without-match, binary) |
| `-H` | Print filename (default with multiple files) |
| `-h` | Suppress filename prefix |

### Regex Fundamentals

| Metacharacter | Description |
|---------------|-------------|
| `.` | Any single character |
| `*` | Zero or more of preceding |
| `+` | One or more (extended regex) |
| `?` | Zero or one (extended regex) |
| `^` | Start of line |
| `$` | End of line |
| `[abc]` | Character class |
| `[^abc]` | Negated character class |
| `\b` | Word boundary |
| `\d` | Digit (PCRE) |
| `\w` | Word character (PCRE) |
| `\s` | Whitespace (PCRE) |
| `(...)` | Grouping (extended regex) |
| `a\|b` | Alternation (extended regex) |
| `{n,m}` | Quantifier (extended regex) |

### Examples

```bash
# Basic search
grep "error" /var/log/syslog

# Case-insensitive recursive search
grep -ri "password" /etc/

# Invert match (exclude comments and blank lines)
grep -v "^#" /etc/fstab | grep -v "^$"

# Show line numbers and context
grep -n -C3 "Exception" app.log

# Count occurrences per file
grep -rc "TODO" src/

# Print only matching part
grep -oP '\d+\.\d+\.\d+\.\d+' access.log

# Search for fixed string (no regex interpretation)
grep -F "192.168.1.1" /var/log/auth.log

# Extended regex
grep -E "error|warning|critical" /var/log/syslog

# Perl regex (lookaheads, etc.)
grep -P '(?<=user=)\w+' auth.log

# Search only specific file types
grep -r --include="*.py" "import os" /project/

# Quiet mode (for scripting)
if grep -q "error" /var/log/syslog; then
    echo "Errors found!"
fi

# Show only filenames
grep -rl "pattern" /path/

# Exclude directories
grep -r --exclude-dir=".git" "TODO" /project/

# Null-delimited output for xargs
grep -rlZ "pattern" /path/ | xargs -0 sed -i 's/old/new/g'

# Word boundary search
grep -w "port" /etc/services

# Multiple patterns
grep -e "error" -e "warning" -e "critical" /var/log/syslog

# Highlight and show filenames
grep --color=always -Hn "pattern" file1 file2
```

### Internals

`grep` uses a DFA (Deterministic Finite Automaton) or NFA (Non-deterministic Finite Automaton) regex engine:

1. **DFA engine** (default for basic/extended regex): Converts the regex to a DFA. Time complexity: O(n) where n is input length. Memory: potentially exponential in pattern length (DFA state explosion).
2. **NFA engine** (backtracking, used by Perl regex): More powerful but can have O(2^n) worst-case (catastrophic backtracking). PCRE uses this.
3. **Boyer-Moore**: For fixed-string search (`grep -F`), uses Boyer-Moore algorithm for sub-linear matching.
4. **Memory-mapped I/O**: GNU `grep` uses `mmap()` for large files, avoiding double-buffering.
5. **Line buffering**: `grep` uses line-buffered output when writing to a terminal. When writing to a pipe, it uses full buffering (use `--line-buffered` to force line buffering).

### Performance

- **Fixed strings** (`grep -F`): Fastest — uses Boyer-Moore algorithm.
- **Basic regex**: Fast — DFA compilation is O(1) amortized, matching is O(n).
- **Extended regex**: Similar to basic regex performance.
- **PCRE** (`grep -P`): Can be slower due to backtracking, but more powerful.
- **Recursive search**: Single-threaded in GNU `grep`. Use `ripgrep` for parallel search.
- **Large files**: `grep` handles multi-GB files well with `mmap()`.

### Common Mistakes

1. **Forgetting to escape metacharacters**: `grep "file.txt"` matches `fileXtxt` because `.` means "any character". Use `grep "file\.txt"` or `grep -F "file.txt"`.

2. **Using `grep` for structured data**: For CSV, JSON, XML, use dedicated tools (`jq`, `csvtool`, `xmlstarlet`) instead of fragile regex patterns.

3. **Catastrophic backtracking**: Patterns like `(a+)+b` with PCRE can cause exponential runtime. Avoid nested quantifiers.

4. **Binary file interference**: `grep` treats files with null bytes as binary. Use `-a` to force text mode or `-I` to skip binary files.

5. **Not using `-Z`/`-0`**: When piping filenames to `xargs`, use `grep -lZ | xargs -0` to handle filenames with spaces.

### POSIX Compatibility

POSIX defines `grep` with basic regex (`-G`), extended regex (`-E`), and fixed strings (`-F`). Options `-i`, `-v`, `-c`, `-l`, `-n`, `-h`, `-q`, `-w`, `-x` are POSIX. `-P`, `--color`, `--include`, `--exclude`, context options (`-A`, `-B`, `-C`) are extensions.

### GNU vs BusyBox

- **GNU `grep`**: Full-featured with PCRE (`-P`), `--include`/`--exclude`, `--line-buffered`, `--max-count`, `--label`.
- **BusyBox `grep`**: Supports `-a`, `-c`, `-e`, `-f`, `-F`, `-h`, `-H`, `-i`, `-l`, `-L`, `-n`, `-o`, `-q`, `-r`, `-R`, `-v`, `-w`, `-x`, `-m`. Missing: `-P`, `--include`/`--exclude`, context options. Approximately 8KB vs ~200KB for GNU.

---

## ripgrep (rg) — A Modern, Faster grep

### Purpose

`ripgrep` (`rg`) is a line-oriented search tool that recursively searches directories for a regex pattern, similar to `grep -r` but significantly faster. It respects `.gitignore`, skips binary files, and uses parallelism by default.

### Key Options

| Option | Description |
|--------|-------------|
| `-i` | Case-insensitive |
| `-s` | Case-sensitive (default) |
| `-S` | Smart case (case-insensitive unless pattern has uppercase) |
| `-w` | Whole word |
| `-x` | Whole line |
| `-v` | Invert match |
| `-c` | Count matches |
| `-l` | Files with matches |
| `-L` | Files without matches |
| `-n` | Line numbers |
| `-o` | Only matching part |
| `-r REPLACEMENT` | Replace matches |
| `-A`, `-B`, `-C` | Context lines |
| `-t` | Search only specific file type |
| `-T` | Exclude file type |
| `-g GLOB` | Include/exclude glob patterns |
| `--hidden` | Search hidden files |
| `--no-ignore` | Don't respect ignore files |
| `--iglob` | Case-insensitive glob |
| `-m N` | Max matches per file |
| `-j N` | Number of threads |
| `--stats` | Show statistics |
| `-e PATTERN` | Pattern (for patterns starting with `-`) |
| `-F` | Fixed string |
| `-U` | Multi-line matching |
| `--pcre2` | Use PCRE2 engine |

### Examples

```bash
# Recursive search (respects .gitignore by default)
rg "pattern" /project/

# Case-insensitive with smart case
rg -S "error" /var/log/

# Search specific file types
rg -t py "import" /project/

# Exclude file types
rg -T js "function" /src/

# Replace in-place
rg "old_name" -r "new_name" --files-with-matches | xargs sed -i 's/old_name/new_name/g'

# Multi-line matching
rg -U "fn.*\{.*\}" src/

# Show statistics
rg --stats "pattern" /large/dir/

# Search hidden files
rg --hidden "secret" /home/

# Fixed string search
rg -F "192.168.1.1" /var/log/

# JSON output
rg --json "error" /var/log/

# Count per file
rg -c "TODO" /project/
```

### Performance

`ripgrep` is typically 2-10x faster than GNU `grep -r` due to:
- **Parallel directory traversal** using multiple threads
- **Memory-mapped I/O** for file reading
- **Aho-Corasick algorithm** for multi-pattern fixed-string matching
- **SIMD optimizations** in the regex engine
- **`.gitignore` awareness** — skipping irrelevant files reduces I/O

---

## sed — Stream Editor

### Purpose

`sed` (Stream Editor) performs text transformations on an input stream. It reads input line-by-line, applies specified operations, and outputs the result. It excels at search-and-replace, line deletion, insertion, and text transformation.

### Syntax

```
sed [OPTION]... {script} [input-file]...
sed [OPTION] -e {script}... [input-file]...
sed [OPTION] -f {script-file}... [input-file]...
```

### Key Options

| Option | Description |
|--------|-------------|
| `-e SCRIPT` | Add script to commands |
| `-f SCRIPT-FILE` | Read script from file |
| `-i[SUFFIX]` | Edit files in-place (with optional backup suffix) |
| `-n` | Suppress automatic printing |
| `-r`, `-E` | Use extended regex |
| `-s` | Treat files as separate (not one stream) |
| `--follow-symlinks` | Follow symlinks when editing in-place |
| `-u` | Unbuffered output |
| `-z` | Use null character as line separator (process whole file) |
| `--debug` | Annotate program execution |

### Address Syntax

```
# Single line
5          # Line 5
$          # Last line
/pattern/  # Lines matching pattern

# Range
3,7        # Lines 3 through 7
3,+5       # Line 3 and 5 following lines
/pattern1/,/pattern2/  # Between two patterns

# Step
0~2        # Every 2nd line (even lines)
1~2        # Every 2nd line starting at 1 (odd lines)

# Negation
/pattern/! # Lines NOT matching pattern
```

### Command Reference

| Command | Description |
|---------|-------------|
| `s/regex/replacement/flags` | Substitution |
| `d` | Delete pattern space |
| `p` | Print pattern space |
| `a\text` | Append text after current line |
| `i\text` | Insert text before current line |
| `c\text` | Replace current line with text |
| `y/src/dst/` | Transliterate characters |
| `r file` | Read file and append |
| `w file` | Write pattern space to file |
| `q` | Quit |
| `=` | Print line number |
| `l` | List pattern space (show non-printing chars) |
| `n` | Read next line into pattern space |
| `N` | Append next line to pattern space |
| `P` | Print first line of pattern space (with N) |
| `D` | Delete first line of pattern space |
| `h` | Copy pattern space to hold space |
| `H` | Append pattern space to hold space |
| `g` | Copy hold space to pattern space |
| `G` | Append hold space to pattern space |
| `x` | Exchange pattern and hold spaces |
| `b label` | Branch to label |
| `t label` | Branch on successful substitution |
| `T label` | Branch on failed substitution |
| `{...}` | Command grouping |

### Substitution Flags

| Flag | Description |
|------|-------------|
| `g` | Global (replace all occurrences on line) |
| `N` | Replace Nth occurrence |
| `p` | Print if substitution made |
| `w file` | Write if substitution made |
| `i`, `I` | Case-insensitive (GNU extension) |
| `e` | Execute replacement as command (GNU extension) |

### Examples

```bash
# Simple substitution
sed 's/old/new/' file

# Global substitution (all occurrences on each line)
sed 's/old/new/g' file

# In-place editing
sed -i 's/old/new/g' file

# In-place with backup
sed -i.bak 's/old/new/g' file

# Delete lines matching pattern
sed '/pattern/d' file

# Delete blank lines
sed '/^$/d' file

# Delete line range
sed '5,10d' file

# Print specific lines
sed -n '5p' file          # Line 5 only
sed -n '5,10p' file       # Lines 5-10
sed -n '/pattern/p' file  # Lines matching pattern

# Insert/Append
sed '3a\New line after 3' file    # Append after line 3
sed '3i\New line before 3' file   # Insert before line 3

# Multiple commands
sed -e 's/foo/bar/g' -e '/^$/d' file

# Using command grouping
sed '{s/foo/bar/; s/baz/qux/}' file

# Back-references in substitution
sed 's/\(Hello\) \(World\)/\2 \1/' file

# Extended regex (capture groups)
sed -E 's/([0-9]+)\.([0-9]+)/v\1.\2/g' file

# Transliterate (like tr)
sed 'y/abc/ABC/' file

# Read file and insert
sed '/pattern/r insert.txt' file

# Write matching lines to file
sed -n '/error/w errors.txt' log.txt

# Add line numbers
sed = file | sed 'N; s/\n/\t/'

# Reverse file (tac equivalent)
sed '1!G;h;$!d' file

# Join lines (remove newlines between pattern)
sed ':a;N;$!ba;s/\n/ /g' file

# Delete from pattern to end of file
sed '/pattern/,$d' file

# Replace only on specific lines
sed '3s/old/new/' file

# Case conversion (GNU sed)
sed 's/.*/\U&/' file    # Uppercase
sed 's/.*/\L&/' file    # Lowercase

# Add prefix/suffix to lines
sed 's/^/PREFIX: /' file
sed 's/$/ SUFFIX/' file

# Remove leading/trailing whitespace
sed 's/^[[:space:]]*//' file
sed 's/[[:space:]]*$//' file

# Process null-delimited input
find . -name "*.txt" -print0 | sed -z 's/\.\//removed\//g'

# Debug mode (GNU sed)
sed --debug 's/old/new/g' file

# Multi-line: join lines ending with backslash
sed ':a; /\\$/{N; s/\\\n//; ta}' file

# Add line numbers to matching lines only
sed '/pattern/=' file | sed '/pattern/{N; s/\n/: /}'
```

### Internals

`sed` processes input through a cycle:

1. **Read**: Read a line from input into the **pattern space**.
2. **Execute**: Apply all commands to the pattern space.
3. **Print**: Unless `-n`, print the pattern space.
4. **Repeat**: Clear pattern space, read next line.

**Hold space**: A secondary buffer that persists between cycles. Used for multi-line operations (e.g., reversing lines, joining adjacent lines).

**In-place editing** (`-i`): Creates a temporary file, writes output to it, then renames it over the original. This means hard links to the original are broken. With `-i.bak`, the original is preserved with the backup suffix.

### Performance

- **Single-pass**: `sed` processes input in a single pass — O(n) where n is input size.
- **Buffered I/O**: Uses buffered reads/writes for efficiency.
- **Regex compilation**: The regex is compiled once and applied to each line.
- **In-place editing**: Requires writing the entire file to a temp file, then renaming. For very large files, this doubles disk usage temporarily.
- **Multiple commands**: Multiple `-e` commands are applied sequentially to each line. Order matters for performance — put the most selective patterns first.

### Common Mistakes

1. **Forgetting the `g` flag**: `s/old/new/` replaces only the first occurrence per line. Use `s/old/new/g` for global replacement.

2. **Greedy matching**: `.*` is greedy. `sed 's/<.*>//g'` on `<a>text</a>` removes everything from `<a>` to `>`. Use `sed 's/<[^>]*>//g'` instead.

3. **Not using `-i` when intended**: `sed 's/old/new/g' file` prints to stdout without modifying the file. Use `sed -i` to edit in-place.

4. **Forgetting backup with `-i`**: On macOS, `sed -i` requires a suffix argument (`sed -i ''` for no backup). GNU sed allows `sed -i` without suffix.

5. **Line endings**: `sed` processes lines ending with `\n`. Files with `\r\n` (Windows) line endings may cause issues. Use `sed 's/\r$//'` to convert.

### POSIX Compatibility

POSIX `sed` supports basic commands: `a`, `b`, `c`, `d`, `D`, `g`, `G`, `h`, `H`, `i`, `l`, `n`, `N`, `p`, `P`, `q`, `r`, `s`, `t`, `w`, `x`, `y`, `{`, `}`, `=`, `:`. Extensions: `-i`, `-E`, `-z`, `\U`, `\L`, `\E`, `T` command, `0~N` addresses, `\w`, `\b` in regex.

---

## awk — Pattern Scanning and Processing Language

### Purpose

`awk` is a complete text processing programming language. It excels at processing structured text (columns, fields) and can handle everything from simple field extraction to complex report generation.

### Syntax

```
awk 'program' [file...]
awk -f program-file [file...]
awk [-F sep] 'program' [file...]
```

### Program Structure

```awk
BEGIN { initialization }      # Before processing input
pattern { action }              # For each matching line
END { finalization }            # After processing all input
```

### Built-in Variables

| Variable | Description |
|----------|-------------|
| `$0` | Entire current line |
| `$1`, `$2`, ... | Fields (1-indexed) |
| `NF` | Number of fields in current line |
| `NR` | Number of records (lines) processed |
| `FNR` | Record number in current file |
| `FS` | Input field separator (default: whitespace) |
| `OFS` | Output field separator (default: space) |
| `RS` | Input record separator (default: newline) |
| `ORS` | Output record separator (default: newline) |
| `FILENAME` | Current input filename |
| `ARGC` | Argument count |
| `ARGV` | Argument array |
| `ENVIRON` | Environment variables array |
| `OFMT` | Output format for numbers |
| `RSTART` | Position of match (from `match()`) |
| `RLENGTH` | Length of match |
| `SUBSEP` | Subscript separator (default: `\034`) |
| `CONVFMT` | Conversion format for numbers |
| `PROCINFO` | Process information (GNU awk) |

### Built-in Functions

**String functions**: `length()`, `substr()`, `index()`, `split()`, `match()`, `sub()`, `gsub()`, `sprintf()`, `tolower()`, `toupper()`, `gensub()` (gawk)

**Math functions**: `sin()`, `cos()`, `atan2()`, `exp()`, `log()`, `sqrt()`, `int()`, `rand()`, `srand()`

**I/O functions**: `print`, `printf`, `getline`, `close()`, `fflush()`

### Examples

```bash
# Print specific fields
awk '{print $1, $3}' file

# Custom field separator
awk -F: '{print $1, $7}' /etc/passwd

# Print lines with condition
awk '$3 > 100' file

# Pattern matching
awk '/error/ {print $0}' log.txt

# Print line numbers
awk '{print NR, $0}' file

# Sum a column
awk '{sum += $3} END {print sum}' data.txt

# Average
awk '{sum += $1; count++} END {print sum/count}' data.txt

# Format output
awk '{printf "%-20s %10d\n", $1, $2}' data.txt

# Multiple field separator (regex)
awk -F'[,;:]' '{print $1}' file

# BEGIN and END blocks
awk -F: 'BEGIN {print "Username\tShell"} {print $1"\t"$7} END {print "--- Total:", NR, "---"}' /etc/passwd

# Conditional printing
awk '$1 == "ERROR" {count++} END {print count " errors"}' log.txt

# Field manipulation
awk '{$2 = $2 * 2; print}' data.txt

# Remove duplicate lines (like uniq, but unsorted)
awk '!seen[$0]++' file

# Print last field
awk '{print $NF}' file

# Print second-to-last field
awk '{print $(NF-1)}' file

# Join lines
awk '{printf "%s ", $0}' file

# Multi-file processing
awk 'FNR == 1 {print "=== " FILENAME " ==="} {print}' file1 file2

# Array processing
awk '{for (i=1; i<=NF; i++) count[$i]++} END {for (word in count) print word, count[word]}' file

# CSV processing
awk -F'"' '{
    for (i=2; i<=NF; i+=2) gsub(/,/, "COMMA", $i)
    gsub(/,/, "\t")
    gsub(/COMMA/, ",")
    print
}' data.csv

# Math and formatting
awk 'BEGIN {
    for (i=1; i<=10; i++)
        printf "%3d %6.2f\n", i, sqrt(i)
}'

# Getline for reading additional files
awk '{
    getline line < "/etc/hostname"
    print $0, line
}' file

# User-defined functions
awk '
function abs(x) { return (x < 0) ? -x : x }
{ print $1, abs($2) }
' data.txt

# Group by and sum
awk -F, '{
    groups[$1] += $2
} END {
    for (g in groups) print g, groups[g]
}' data.csv

# Print fields in reverse order
awk '{for (i=NF; i>=1; i--) printf "%s ", $i; print ""}' file

# Process multiple delimiters
awk 'BEGIN {FS="[,:]"} {print $1, $2}' file

# Conditional replacement
awk '{$1 = ($1 > 0) ? "positive" : "negative"} 1' data.txt
```

### Internals

`awk` programs are compiled to an internal bytecode representation before execution:

1. **Parsing**: The program text is parsed into patterns and actions.
2. **Compilation**: Actions are compiled into bytecode for a virtual machine.
3. **Execution**: For each input record:
   - Split into fields using `FS`
   - Evaluate each pattern
   - Execute matching actions
4. **Field splitting**: Fields are split by `FS`. If `FS` is a single character, splitting is done by that character. If `FS` is a regex (multi-character or special), splitting uses regex matching.

**gawk extensions**: GNU awk (`gawk`) includes networking (`/inet/tcp/...`), profiling (`--profile`), debugging (`--debug`), dynamic extensions, MPFR arbitrary precision arithmetic, and more.

### Performance

- **Field processing**: `awk` is efficient for column-based processing because it only splits fields once per line.
- **Arrays**: Associative arrays (hash maps) provide O(1) lookup. gawk uses hash tables.
- **Regex matching**: Each pattern match is evaluated per line. Place most selective patterns first.
- **Memory**: gawk loads the entire program but processes input line-by-line, so memory usage is proportional to the number of unique keys in arrays, not input size.
- **gawk vs mawk**: `mawk` is a faster awk implementation for simple tasks. `gawk` is more featureful but slightly slower.

### Common Mistakes

1. **Forgetting to print**: `awk '{sum+=$1}' file` doesn't print anything. Add `END {print sum}`.

2. **Field separator not set**: `awk '{print $1}' file.csv` splits on whitespace, not commas. Use `-F,`.

3. **String vs numeric comparison**: `$1 == "123"` is string comparison; `$1 == 123` is numeric. awk auto-converts based on context.

4. **Zero-based vs one-based**: awk fields are 1-based (`$1`, `$2`), not 0-based like most programming languages.

5. **Quoting in shell**: awk programs use `{` and `}` which have special meaning in bash. Use single quotes: `awk '{print $1}'`.

### POSIX Compatibility

POSIX awk defines the core language: patterns, actions, built-in variables, built-in functions (except `gensub()`), `getline`, arrays. Extensions in gawk: `**` (exponentiation), `**=`, `func` keyword, `nextfile`, `delete array`, `PROCINFO`, `ERRNO`, `RT`, `@include`, `@load`.

---

## cut — Remove Sections from Each Line

### Purpose

`cut` extracts specific columns (fields) or byte positions from each line of input.

### Syntax

```
cut OPTION... [FILE]...
```

### Key Options

| Option | Description |
|--------|-------------|
| `-f LIST` | Select fields |
| `-d DELIM` | Use DELIM as field delimiter (default: tab) |
| `-c LIST` | Select characters by position |
| `-b LIST` | Select bytes |
| `-s` | Only print lines with delimiter |
| `--complement` | Invert selection (GNU) |
| `--output-delimiter=STRING` | Use STRING as output delimiter |

### List Format

```
1       # First field
1,3,5   # Fields 1, 3, and 5
1-5     # Fields 1 through 5
3-      # Fields 3 to end
-5      # Fields 1 through 5
```

### Examples

```bash
# Extract first and third fields (colon-delimited)
cut -d: -f1,3 /etc/passwd

# Extract characters by position
cut -c1-10 file

# Extract bytes (useful for fixed-width)
cut -b1-20 file

# Multiple fields with range
cut -d, -f1,3-5 data.csv

# Skip lines without delimiter
cut -d: -s -f1,7 /etc/passwd

# Complement (everything except field 2)
cut -d, --complement -f2 data.csv

# Custom output delimiter
cut -d: -f1,7 --output-delimiter=" => " /etc/passwd

# Extract usernames from /etc/passwd
cut -d: -f1 /etc/passwd

# Extract PATH components
echo "$PATH" | cut -d: -f1-3
```

### Common Mistakes

1. **Default delimiter is TAB, not space**: `cut -f1 file` splits on tabs. Use `-d' '` for space.

2. **Can't reorder fields**: `cut` can only select contiguous or listed fields; it cannot reorder them. Use `awk '{print $3, $1}'` for reordering.

3. **Multi-character delimiter**: `cut` only supports single-character delimiters. Use `awk -F` for multi-character.

4. **No regex support**: Unlike `awk`, `cut` doesn't support regex-based field splitting.

---

## sort — Sort Lines of Text

### Purpose

`sort` arranges lines of text in a specified order. It supports numeric, human-readable, random, and key-based sorting.

### Key Options

| Option | Description |
|--------|-------------|
| `-n` | Numeric sort |
| `-r` | Reverse sort |
| `-u` | Unique (remove duplicates after sorting) |
| `-h` | Human-numeric sort (2K, 1M, 3G) |
| `-M` | Month sort (Jan, Feb, ...) |
| `-R` | Random sort |
| `-V` | Version sort (1.2 < 1.10) |
| `-t SEP` | Field separator |
| `-k POS` | Sort by key (field) |
| `-b` | Ignore leading blanks |
| `-f` | Fold lowercase to uppercase |
| `-i` | Ignore non-printable characters |
| `-d` | Dictionary order (only alphanumeric/blank) |
| `-g` | General numeric sort (scientific notation) |
| `-c` | Check if sorted |
| `-s` | Stable sort |
| `-T DIR` | Use DIR for temporary files |
| `-S SIZE` | Memory buffer size |
| `--parallel=N` | Number of threads |
| `-o FILE` | Output to FILE (can be same as input) |
| `--files0-from=FILE` | Read file list from FILE (null-delimited) |
| `--unique` | Same as `-u` |
| `--batch-size=N` | Maximum number of inputs to merge at once |

### Examples

```bash
# Basic alphabetical sort
sort file

# Numeric sort
sort -n numbers.txt

# Reverse numeric sort
sort -rn numbers.txt

# Sort by specific field
sort -t: -k3 -n /etc/passwd

# Sort by multiple fields (field 2, then field 1)
sort -t, -k2,2 -k1,1 data.csv

# Human-readable size sort
sort -h sizes.txt

# Version sort
sort -V versions.txt

# Random shuffle
sort -R file

# Unique sorted output
sort -u file

# Check if sorted
sort -c file

# Sort and remove duplicates
sort file | uniq

# Large file sort with limited memory
sort -S 1G -T /tmp largefile.txt

# Parallel sort
sort --parallel=4 largefile.txt

# Month sort
sort -M months.txt

# Sort by field range (characters within field)
sort -t: -k3.2,3.5 /etc/passwd

# Stable sort (preserve original order of equal elements)
sort -s -k1,1 file

# Sort with custom output delimiter
sort -t, -k1,1 --output-delimiter='|' data.csv
```

### Internals

`sort` uses external merge sort when input exceeds memory:

1. **Phase 1 — Distribution**: Read input into memory buffer (`-S`), sort it, write sorted runs to temporary files.
2. **Phase 2 — Merge**: Merge sorted temporary files into the final output.
3. **Parallelism**: GNU `sort` can use multiple threads for both sorting and merging (`--parallel`).

### Common Mistakes

1. **Lexicographic vs numeric**: `sort file` sorts `9` after `10` (lexicographic). Use `sort -n` for numeric.

2. **Locale issues**: Sorting depends on locale (`LC_COLLATE`). Different locales produce different orderings. Use `LC_ALL=C sort` for consistent byte-order sorting.

3. **Not specifying `-t` with `-k`**: Without `-t`, the delimiter is whitespace and consecutive whitespace is treated as a single separator.

4. **Key ranges**: `-k2,2` sorts by field 2 only. `-k2` sorts from field 2 to end of line. This is a common source of confusion.

---

## uniq — Report or Omit Repeated Lines

### Purpose

`uniq` filters adjacent duplicate lines. It only detects duplicates that are next to each other — use `sort | uniq` for general deduplication.

### Key Options

| Option | Description |
|--------|-------------|
| `-c` | Prefix lines with count |
| `-d` | Only print duplicate lines |
| `-u` | Only print unique lines |
| `-i` | Case-insensitive comparison |
| `-f N` | Skip first N fields |
| `-s N` | Skip first N characters |
| `-w N` | Compare only first N characters |

### Examples

```bash
# Remove adjacent duplicates
sort file | uniq

# Count occurrences
sort file | uniq -c

# Sort by frequency (most common first)
sort file | uniq -c | sort -rn

# Only show duplicates
sort file | uniq -d

# Only show unique lines
sort file | uniq -u

# Case-insensitive dedup
sort -f file | uniq -i

# Count by field
awk '{print $1}' access.log | sort | uniq -c | sort -rn
```

---

## tr — Translate or Delete Characters

### Purpose

`tr` translates, squeezes, or deletes characters from stdin.

### Syntax

```
tr [OPTION]... SET1 [SET2]
```

### Key Options

| Option | Description |
|--------|-------------|
| `-d` | Delete characters in SET1 |
| `-s` | Squeeze repeated characters |
| `-c` | Complement SET1 |
| `-t` | Truncate SET1 to length of SET2 |

### Character Sets

| Notation | Description |
|----------|-------------|
| `a-z` | Range of characters |
| `A-Z` | Uppercase letters |
| `0-9` | Digits |
| `[:alnum:]` | Alphanumeric characters |
| `[:alpha:]` | Alphabetic characters |
| `[:digit:]` | Digits |
| `[:lower:]` | Lowercase letters |
| `[:upper:]` | Uppercase letters |
| `[:space:]` | Whitespace characters |
| `[:blank:]` | Space and tab |
| `[:punct:]` | Punctuation |
| `\n` | Newline |
| `\t` | Tab |
| `\0NNN` | Octal character |
| `\xNN` | Hex character |

### Examples

```bash
# Convert to uppercase
tr 'a-z' 'A-Z' < file

# Convert to lowercase
tr 'A-Z' 'a-z' < file

# Delete characters
tr -d '0-9' < file

# Squeeze repeated characters
tr -s ' ' < file

# Delete newlines
tr -d '\n' < file

# Replace characters
tr ',' '\t' < data.csv

# Delete all but digits
tr -cd '0-9' < file

# Squeeze and delete whitespace
tr -s '[:space:]' '\n' < file

# ROT13 cipher
tr 'A-Za-z' 'N-ZA-Mn-za-m' < file

# Remove non-printable characters
tr -cd '[:print:]\n' < file

# Convert Windows line endings
tr -d '\r' < dos_file.txt > unix_file.txt

# Create character frequency histogram
tr -cs '[:alpha:]' '\n' < file | sort | uniq -c | sort -rn
```

---

## wc — Word, Line, Character, and Byte Count

### Purpose

`wc` counts lines, words, characters, and bytes in files.

### Key Options

| Option | Description |
|--------|-------------|
| `-l` | Count lines |
| `-w` | Count words |
| `-c` | Count bytes |
| `-m` | Count characters (multibyte-aware) |
| `-L` | Length of longest line |

### Examples

```bash
# Full statistics
wc file.txt

# Line count
wc -l file.txt

# Multiple files
wc -l *.txt

# Count words
wc -w file.txt

# Longest line
wc -L file.txt

# Count from stdin
echo "hello world" | wc -w

# Count files in directory
ls | wc -l

# Character count (multibyte)
wc -m unicode.txt
```

---

## paste — Merge Lines of Files

### Purpose

`paste` merges corresponding lines from multiple files side-by-side.

### Key Options

| Option | Description |
|--------|-------------|
| `-d LIST` | Use LIST as delimiter (default: tab) |
| `-s` | Serial mode: merge lines from one file into one line |
| `-z` | Null-terminated lines |

### Examples

```bash
# Merge two files side by side
paste file1.txt file2.txt

# Custom delimiter
paste -d, file1.txt file2.txt

# Merge lines into one line
paste -s -d, file.txt

# Convert column to row
paste -sd'\t' data.txt

# Combine with other tools
ls *.txt | paste -sd' '

# Number lines
seq $(wc -l < file) | paste - file
```

---

## join — Join Lines of Two Files on a Common Field

### Purpose

`join` joins two sorted files on a common field (like SQL JOIN).

### Key Options

| Option | Description |
|--------|-------------|
| `-1 FIELD` | Join on FIELD of file 1 |
| `-2 FIELD` | Join on FIELD of file 2 |
| `-t SEP` | Use SEP as field separator |
| `-a FILENUM` | Print unpairable lines from FILENUM |
| `-e STRING` | Replace missing input fields with STRING |
| `-o FORMAT` | Construct output line from FORMAT |
| `-v FILENUM` | Print unpairable lines from FILENUM only |
| `-i` | Case-insensitive join |
| `--header` | Treat first line as header |

### Examples

```bash
# Join on first field (default)
join file1.txt file2.txt

# Join on specific fields
join -1 2 -2 1 file1.txt file2.txt

# Custom delimiter
join -t, data1.csv data2.csv

# Include unpairable lines
join -a 1 -a 2 file1.txt file2.txt

# Left join
join -a 1 file1.txt file2.txt

# Case-insensitive
join -i file1.txt file2.txt

# Custom output format
join -o 1.1,2.2,1.3 file1.txt file2.txt

# Header line
join --header data1.csv data2.csv
```

---

## Summary

### Tool Selection Guide

| Task | Best Tool |
|------|-----------|
| Search for patterns | `grep` / `ripgrep` |
| Replace text in files | `sed` |
| Process columns/fields | `awk` / `cut` |
| Sort data | `sort` |
| Remove duplicates | `uniq` (after sort) |
| Character translation | `tr` |
| Count lines/words | `wc` |
| Merge files side-by-side | `paste` |
| Join files on a field | `join` |

### Pipeline Examples

```bash
# Top 10 most common IPs in access log
awk '{print $1}' access.log | sort | uniq -c | sort -rn | head -10

# Find duplicate files by size
find . -type f -exec stat --printf='%s %n\n' {} + | sort | uniq -d -w 10

# Count lines of code by language
find . -name "*.py" -o -name "*.js" | xargs wc -l | sort -n

# Extract and count error types
grep -oP 'ERROR: \K\w+' app.log | sort | uniq -c | sort -rn

# Parse CSV and summarize
cut -d, -f3 data.csv | sort | uniq -c | sort -rn

# Convert column to CSV row
cat column.txt | paste -sd',' -

# Format command output into table
ps aux | awk '{printf "%-10s %-8s %-5s %-5s %s\n", $1, $2, $3, $4, $11}'
```
