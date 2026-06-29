# Chapter 43: File Viewing — cat, less, more, head, tail, tee, nl

## Overview

File viewing utilities are among the most frequently used commands in Linux. They allow users to display, paginate, monitor, and number file contents. While they seem simple, each tool has nuanced behavior, performance characteristics, and use cases that make them indispensable for daily work.

These tools range from the ubiquitous `cat` (which concatenates and displays files) to the sophisticated `less` (which provides a full-featured pager with search, navigation, and monitoring capabilities). Understanding when and how to use each tool — and their limitations — is essential for efficient Linux usage.

---

## cat — Concatenate and Display Files

### Purpose

`cat` reads files sequentially and writes them to stdout. Despite its name (short for "concatenate"), it's most commonly used to display a single file's contents. It can also number lines, squeeze blank lines, and show non-printing characters.

### Syntax

```
cat [OPTION]... [FILE]...
```

### Key Options

| Option | Description |
|--------|-------------|
| `-n` | Number all output lines |
| `-b` | Number non-empty output lines |
| `-s` | Squeeze multiple adjacent blank lines into one |
| `-v` | Display non-printing characters (using `^` and `M-` notation) |
| `-T` | Display tabs as `^I` |
| `-E` | Display `$` at end of each line |
| `-A` | Equivalent to `-vET` (show all non-printing chars, tabs, line ends) |
| `--number` | Same as `-n` |
| `--squeeze-blank` | Same as `-s` |
| `--show-nonprinting` | Same as `-v` |
| `--show-tabs` | Same as `-T` |
| `--show-ends` | Same as `-E` |

### Examples

```bash
# Display file contents
cat file.txt

# Display multiple files
cat file1.txt file2.txt

# Number all lines
cat -n file.txt

# Number non-empty lines only
cat -b file.txt

# Show non-printing characters
cat -A file.txt        # Shows tabs as ^I, line endings as $

# Show tabs explicitly
cat -T file.txt

# Squeeze blank lines
cat -s file.txt

# Display and redirect
cat input.txt > output.txt

# Concatenate multiple files
cat part1.txt part2.txt part3.txt > combined.txt

# Create a file (heredoc)
cat > newfile.txt << 'EOF'
Line 1
Line 2
EOF

# Append to a file (heredoc)
cat >> existing.txt << 'EOF'
New line
EOF

# Show line endings (useful for debugging \r\n issues)
cat -E file.txt

# Display binary file with visible control chars
cat -v /bin/ls | head -20

# Combine options
cat -nsT file.txt  # Squeeze blanks, number lines, show tabs
```

### Internals

`cat` uses a simple read-write loop:

1. Open each file argument (or stdin if no files).
2. Read blocks into a buffer (typically 8KB or larger).
3. Write blocks to stdout.
4. Repeat until EOF.

**Optimized `cat`**: Modern implementations use `sendfile()` or `splice()` kernel calls for zero-copy I/O when possible, bypassing the userspace buffer entirely. This makes `cat` extremely efficient for piping large files.

**Buffer size**: GNU `cat` uses a buffer size determined by the file system's block size (typically 4KB-1MB). The `--buffer-size` option (not in POSIX) allows tuning.

### Performance

- **Single file**: Nearly zero overhead — limited only by disk read speed.
- **Concatenation**: Each file requires an `open()`/`close()` cycle, but the data transfer is efficient.
- **Piping**: `cat file | command` is usually slower than `command < file` because it adds an extra process. However, the difference is negligible for most use cases. The "useless use of cat" (UUOC) is primarily a style concern, not a performance one.
- **Large files**: `cat` handles files of any size efficiently due to streaming I/O.

### Common Mistakes

1. **"Useless Use of Cat" (UUOC)**:
   ```bash
   # Anti-pattern (UUOC)
   cat file | grep "pattern"

   # Preferred
   grep "pattern" file

   # However, UUOC is sometimes justified:
   # - When you want to list multiple files: cat file1 file2 | command
   # - For readability in complex pipelines
   ```

2. **Using `cat` for large files to terminal**: For large files, use `less` instead of `cat` to avoid flooding the terminal.

3. **Binary files**: `cat` on binary files can corrupt terminal settings. Use `less` or `hexdump` for binary inspection.

4. **`cat file1 file2 > file1`**: This truncates `file1` before reading it, resulting in an empty file. Use a temporary file instead.

### POSIX Compatibility

POSIX `cat` supports `-u` (unbuffered output), and the basic concatenation behavior. `-n`, `-b`, `-s`, `-v`, `-T`, `-E`, `-A` are common extensions supported by virtually all implementations.

### GNU vs BusyBox

- **GNU `cat`**: Full-featured with `--number`, `--squeeze-blank`, `--show-all`, large buffer support.
- **BusyBox `cat`**: Supports `-n`, `-b`, `-e`, `-s`, `-t`, `-u`, `-v`. Very compact (~2KB). Missing `--buffer-size`.

---

## less — Opposite of more

### Purpose

`less` is an advanced pager that displays text one screen at a time, with forward and backward navigation, search, and monitoring capabilities. It's the default pager on most Linux systems (`man`, `git log`, etc. all use `less` by default).

The name is a pun: "less is more" — it does everything `more` does, and more.

### Syntax

```
less [OPTION]... [FILE]...
```

### Key Options

| Option | Description |
|--------|-------------|
| `-N` | Show line numbers |
| `-S` | Chop long lines (don't wrap) |
| `-i` | Case-insensitive search (unless pattern contains uppercase) |
| `-I` | Case-insensitive search (always) |
| `-X` | Don't clear screen on exit |
| `-F` | Quit if output fits on one screen |
| `-R` | Display ANSI color escape sequences (raw control chars) |
| `-r` | Display all raw control characters |
| `-c` | Repaint from top (clear then write) |
| `-s` | Squeeze multiple blank lines |
| `-M` | Long prompt (shows line numbers and percentage) |
| `-m` | Verbose prompt (shows percentage) |
| `-j N` | Target line for searches (N lines from top) |
| `-g` | Highlight only last search match |
| `-G` | Don't highlight any search matches |
| `-W` | Highlight first match after movement |
| `-p PATTERN` | Start at first occurrence of PATTERN |
| `-t TAG` | Start at TAG |
| `-T TAGSFILE` | Use TAGSFILE for tags |
| `-d` | Dumb terminal mode |
| `-e` | Quit at end of file |
| `-q` | Quiet (no bell) |
| `-Q` | Even quieter (no bell, ever) |
| `--follow-name` | Follow file name (like `tail -F`) |
| `--no-init` | Don't use terminal initialization |
| `--mouse` | Enable mouse scrolling |
| `--wheel-lines=N` | Lines per mouse wheel scroll |
| `+COMMAND` | Execute COMMAND on startup |

### Navigation Commands

| Key | Action |
|-----|--------|
| `Space`, `f` | Forward one screen |
| `b` | Backward one screen |
| `d` | Forward half screen |
| `u` | Backward half screen |
| `j`, `Enter` | Forward one line |
| `k` | Backward one line |
| `g` | Go to beginning |
| `G` | Go to end |
| `NG` | Go to line N |
| `50%` | Go to 50% of file |
| `q` | Quit |
| `h` | Help |
| `v` | Open file in editor |

### Search Commands

| Key | Action |
|-----|--------|
| `/pattern` | Search forward |
| `?pattern` | Search backward |
| `n` | Next match |
| `N` | Previous match |
| `&pattern` | Show only matching lines |
| `&` | Toggle filter |
| `Esc-u` | Clear search highlighting |

### Other Commands

| Key | Action |
|-----|--------|
| `-N` | Toggle line numbers |
| `-S` | Toggle line chopping |
| `-i` | Toggle case sensitivity |
| `:e file` | Open another file |
| `:n` | Next file |
| `:p` | Previous file |
| `:f` | Show current filename |
| `F` | Forward forever (like `tail -f`); Ctrl-C to stop |
| `|command` | Pipe current file to command |
| `s file` | Save input to file |
| `m letter` | Set mark |
| `' letter` | Go to mark |
| `=` | Show file info |
| `R` | Repaint screen |
| `!command` | Run shell command |

### Examples

```bash
# View a file
less file.txt

# View with line numbers
less -N file.txt

# View with no line wrap
less -S file.txt

# Case-insensitive search
less -i largefile.txt

# View with ANSI colors (for colored log output)
less -R colored-output.txt

# Start at a specific pattern
less -p "error" log.txt

# View multiple files
less file1.txt file2.txt

# Pipe output to less
dmesg | less

# View compressed file (with zless)
zless file.gz

# Follow file changes (like tail -f)
less --follow-name growing.log

# Don't clear screen on exit (preserve output)
less -X file.txt

# Combined options for log viewing
less -N -S -R -F app.log

# View git log with colors preserved
git log --oneline --color | less -R

# Set default options
export LESS="-N -S -R -i"
```

### Internals

`less` is a sophisticated program with complex internal architecture:

1. **Input processing**: Reads the file into a buffer (memory-mapped for large files).
2. **Screen management**: Maintains a screen buffer and redraws only changed regions.
3. **Search engine**: Uses regex engine for forward/backward searching with highlighting.
4. **Line number tracking**: Maintains a table of line number positions for efficient jumping.
5. **File monitoring**: The `F` command and `--follow-name` use `inotify` or periodic `stat()` checks.

**Memory management**: `less` uses a combination of memory-mapped I/O and a sliding window buffer. Very large files are handled efficiently without loading the entire file into memory.

**Signal handling**: `less` handles `SIGWINCH` (terminal resize) by recalculating screen layout. `SIGINT` (Ctrl-C) is intercepted during `F` command to return to normal mode.

### Performance

- **Startup**: Fast — only reads enough for the first screen.
- **Navigation**: Forward/backward scrolling is efficient due to buffered I/O.
- **Large files**: Handles multi-GB files well. Line number calculation may be slow for very deep jumps.
- **Search**: Forward search is fast; backward search may require scanning from the beginning for the first search.

### Common Mistakes

1. **Color output garbled**: If colored output looks wrong, use `-R` (for ANSI colors) or `-r` (for all raw control chars). `-R` is safer; `-r` can cause display issues.

2. **Can't scroll with mouse**: Add `--mouse` to enable mouse wheel scrolling.

3. **`less` clears screen on exit**: Use `-X` to keep the content visible after exiting.

4. **Not knowing `F` command**: The `F` command in `less` provides `tail -f` functionality, which is extremely useful for monitoring logs.

5. **Forgetting `!command`**: You can run shell commands from within `less` without quitting.

### POSIX Compatibility

`less` is not specified by POSIX. POSIX defines `more` as the standard pager. However, `less` is universally available on Linux systems and is the de facto standard.

### GNU vs BusyBox

- **GNU `less`**: Full-featured with all options listed above, extensive color support, mouse support, `--follow-name`.
- **BusyBox `less`**: Supports basic navigation, search, line numbers, case-insensitive search. Missing: mouse support, `--follow-name`, some search options. Approximately 15KB vs ~200KB for GNU.

---

## more — File Perusal Filter

### Purpose

`more` is a simple pager that displays text one screen at a time, with forward-only navigation. It's the POSIX-standard pager and the predecessor to `less`.

### Syntax

```
more [OPTION]... [FILE]...
```

### Key Options

| Option | Description |
|--------|-------------|
| `-d` | Display helpful prompt ("Press space to continue, 'q' to quit") |
| `-f` | Count logical lines (not screen lines) |
| `-l` | Suppress pause after form feed (^L) |
| `-c` | Repaint from top (clear then write) |
| `-s` | Squeeze multiple blank lines |
| `-u` | Suppress underlining |
| `-n N` | Lines per screenful |
| `+N` | Start at line N |
| `+/PATTERN` | Start at first occurrence of PATTERN |

### Navigation Commands

| Key | Action |
|-----|--------|
| `Space` | Forward one screen |
| `Enter` | Forward one line |
| `d` | Forward half screen |
| `q`, `Q` | Quit |
| `s` | Skip forward N lines |
| `f` | Skip forward N screenfuls |
| `b` | Backward one screen (if supported) |
| `/pattern` | Search forward |
| `n` | Next match |
| `:n` | Next file |
| `:p` | Previous file |
| `!command` | Run shell command |
| `=` | Show current line number |
| `v` | Edit current file with `$EDITOR` |
| `h` | Help |

### Examples

```bash
# View a file
more file.txt

# View with helpful prompts
more -d file.txt

# Start at line 100
more +100 file.txt

# Start at pattern
more +/error log.txt

# Squeeze blank lines
more -s file.txt

# Pipe output to more
dmesg | more
```

### Common Mistakes

1. **`more` vs `less`**: `more` can only move forward (mostly). `less` can move both forward and backward. Use `less` whenever possible.

2. **No backward navigation in some implementations**: Some versions of `more` support `b` for backward scrolling, but it's not guaranteed.

3. **Pipeline buffering**: When piped, `more` may buffer output differently than when reading files directly.

### POSIX Compatibility

`more` is specified by POSIX. The standard defines basic options (`-c`, `-f`, `-l`, `-s`, `-u`) and navigation commands. Extensions like `-d`, `+/pattern`, and backward search vary by implementation.

### GNU vs BusyBox

- **GNU `more`**: Part of `util-linux`. Supports backward navigation, search, and command execution.
- **BusyBox `more`**: Basic forward-only paging. Very compact (~3KB). Limited navigation commands.

---

## head — Output the First Part of Files

### Purpose

`head` prints the first N lines (or bytes) of each file to stdout.

### Syntax

```
head [OPTION]... [FILE]...
```

### Key Options

| Option | Description |
|--------|-------------|
| `-n N` | Print first N lines (default: 10) |
| `-c N` | Print first N bytes |
| `-q` | Suppress filename headers |
| `-v` | Always print filename headers |
| `-n -N` | Print all except last N lines |

### Examples

```bash
# First 10 lines (default)
head file.txt

# First 20 lines
head -n 20 file.txt

# First 20 lines (shorthand)
head -20 file.txt

# First 100 bytes
head -c 100 file.txt

# First 1KB
head -c 1k file.txt

# First 1MB
head -c 1M file.txt

# Multiple files with headers
head -n 5 file1.txt file2.txt

# Suppress headers
head -q -n 5 file1.txt file2.txt

# All lines except last 100 (GNU extension)
head -n -100 file.txt

# View first lines of compressed file
zcat file.gz | head -n 20

# Check first line of each CSV
for f in *.csv; do head -n 1 "$f"; done
```

### Performance

`head` reads only the requested number of lines/bytes, making it efficient even for very large files. It stops reading as soon as the count is reached.

### POSIX Compatibility

POSIX specifies `-n` and basic operation. `-c` is widely supported but technically a common extension. `-q`, `-v`, and `-n -N` are GNU extensions.

---

## tail — Output the Last Part of Files

### Purpose

`tail` prints the last N lines (or bytes) of each file. Its most powerful feature is the ability to follow file changes in real-time (`-f`).

### Syntax

```
tail [OPTION]... [FILE]...
```

### Key Options

| Option | Description |
|--------|-------------|
| `-n N` | Print last N lines (default: 10) |
| `-c N` | Print last N bytes |
| `-f` | Follow file as it grows |
| `-F` | Follow file by name (reopen if rotated/recreated) |
| `--pid=PID` | Stop following when PID dies |
| `-s N` | Sleep N seconds between iterations (default: 1) |
| `-q` | Suppress filename headers |
| `-v` | Always print filename headers |
| `-n +N` | Start at line N |

### Examples

```bash
# Last 10 lines (default)
tail file.txt

# Last 20 lines
tail -n 20 file.txt

# Last 100 bytes
tail -c 100 file.txt

# Follow file in real-time
tail -f /var/log/syslog

# Follow by name (survives log rotation)
tail -F /var/log/syslog

# Follow multiple files
tail -f file1.txt file2.txt

# Start at line 100 (lines 100 to end)
tail -n +100 file.txt

# Follow with PID (auto-stop)
tail --pid=$$ -f /var/log/app.log

# Follow with custom interval
tail -f -s 5 growing.log

# View last 5 lines with header
tail -v -n 5 file.txt

# Follow with colored output
tail -f /var/log/syslog | grep --color=always "error"

# Pipe tail -f to another command
tail -f access.log | awk '{print $1}' | sort | uniq -c | sort -rn
```

### Internals

**Following files (`-f`)**:
- `tail -f` uses `inotify` (or periodic `poll()` on older systems) to detect when new data is appended.
- It reads new data as it appears and displays it.
- If the file is truncated (log rotation), `tail -f` detects this by checking if the file size decreased.

**`-F` vs `-f`**:
- `-f` follows the file descriptor — if the file is renamed/deleted, `tail` continues reading the (now unlinked) file.
- `-F` follows the file name — if the file is rotated (renamed and a new file created with the same name), `tail -F` closes the old file and opens the new one.

### Performance

- **`tail -n N`**: Efficient for small N — reads backward from end of file.
- **`tail -n +N`**: Must read from beginning to line N, then outputs the rest.
- **`tail -f`**: Minimal CPU usage — sleeps between checks. Uses inotify for efficient wake-on-change.

### Common Mistakes

1. **`-f` vs `-F` for log rotation**: Use `-F` for log files that get rotated (most production logs). Using `-f` means you keep reading the old (renamed) file.

2. **Not following by name**: `tail -f` followed by a file that gets deleted continues to read the deleted file's data (the inode is still open). Use `-F` for robustness.

3. **Buffering issues**: `tail -f | grep` may not output immediately due to pipe buffering. Use `--line-buffered` with grep or `stdbuf -oL tail -f`.

4. **`tail -n 0 -f`**: Shows only new lines added after starting `tail`, not existing content.

### POSIX Compatibility

POSIX specifies `-n`, `-c`, and basic operation. `-f` is widely available but not strictly POSIX. `-F`, `--pid`, `-s` are extensions.

---

## tee — Read from Stdin and Write to Stdout and Files

### Purpose

`tee` reads standard input and writes it to both standard output and one or more files simultaneously. It's the key to "T-splitting" a pipeline — viewing output while also saving it to a file.

### Syntax

```
tee [OPTION]... [FILE]...
```

### Key Options

| Option | Description |
|--------|-------------|
| `-a` | Append to files instead of overwriting |
| `-i` | Ignore interrupt signals |
| `--output-error=MODE` | Error handling for write errors |

### Examples

```bash
# Save output to file while also viewing it
ls -la | tee file_list.txt

# Save to multiple files
echo "log entry" | tee file1.txt file2.txt file3.txt

# Append to file
echo "new entry" | tee -a log.txt

# Build and log simultaneously
make 2>&1 | tee build.log

# View and save command output
ping google.com | tee ping_results.txt

# Log while processing
dmesg | tee dmesg_original.txt | grep "error" | tee errors.txt

# Pipe to tee with sudo (write to root-owned file)
echo "content" | sudo tee /etc/config.txt

# Pipe to tee with sudo and append
echo "new line" | sudo tee -a /etc/config.txt

# Save both stdout and stderr
command 2>&1 | tee output.txt

# Use in script for logging
exec > >(tee -a script.log) 2>&1
echo "This goes to both terminal and log file"

# Ignore interrupts
ping google.com | tee -i results.txt

# Multiple outputs with append
process_data | tee -a output1.txt -a output2.txt
```

### Internals

`tee` is a simple but powerful utility:

1. Read from stdin into a buffer.
2. Write the buffer to stdout.
3. Write the buffer to each specified file.
4. Repeat until EOF.

**Atomicity**: Writes are not atomic — if `tee` is interrupted, partial data may be written to files.

**Buffering**: `tee` uses buffered I/O for efficiency. When writing to a terminal (stdout), it's line-buffered. When writing to a pipe, it's fully buffered.

### Common Mistakes

1. **Overwriting vs appending**: `tee` overwrites by default. Use `-a` for append mode.

2. **Permission errors with sudo**: `command | sudo tee file` works because `tee` runs as root. But `command | sudo cat > file` doesn't work because the shell redirect (`>`) runs as the current user.

3. **Buffering delays**: `tee` may buffer output. Use `tee -a --output-error=warn-exit` for strict error handling.

### POSIX Compatibility

POSIX specifies `tee` with `-a` (append) and `-i` (ignore interrupts). Extensions: `--output-error`, `--preservation` (GNU).

---

## nl — Number Lines

### Purpose

`nl` numbers lines of files with extensive formatting options. It's more flexible than `cat -n` and supports logical page sections.

### Syntax

```
nl [OPTION]... [FILE]...
```

### Key Options

| Option | Description |
|--------|-------------|
| `-b STYLE` | Body numbering style: `a` (all), `n` (none), `t` (non-empty, default), `pREGEX` (regex match) |
| `-i N` | Line number increment (default: 1) |
| `-v N` | Start numbering at N (default: 1) |
| `-w N` | Width of line number field (default: 6) |
| `-n FORMAT` | Number format: `ln` (left), `rn` (right, default), `rz` (right, zero-padded) |
| `-s STRING` | Separator between number and line (default: tab) |
| `-d CC` | Section delimiter characters (default: `\\:`) |
| `-f STYLE` | Footer numbering style |
| `-h STYLE` | Header numbering style |

### Examples

```bash
# Number all non-empty lines (default)
nl file.txt

# Number all lines including empty
nl -ba file.txt

# Number only lines matching pattern
nl -bp'^ERROR' log.txt

# Custom width and format
nl -w4 -nrz file.txt  # 0001, 0002, etc.

# Custom separator
nl -s'. ' file.txt

# Start at 100
nl -v100 file.txt

# Increment by 5
nl -i5 file.txt

# Left-aligned numbers
nl -nln file.txt

# Number non-empty lines, right-aligned in 8 chars, zero-padded
nl -w8 -nrz -bt file.txt
```

### Internals

`nl` treats the file as having logical sections: header, body, and footer, separated by delimiter characters. By default, only body lines are numbered, and only non-empty body lines. This allows selective numbering of specific sections.

### POSIX Compatibility

`nl` is specified by POSIX with options `-b`, `-d`, `-f`, `-h`, `-i`, `-l`, `-n`, `-p`, `-s`, `-v`, `-w`.

---

## Summary

### Tool Selection Guide

| Task | Best Tool |
|------|-----------|
| Display small file | `cat` |
| Browse large file | `less` |
| First N lines | `head` |
| Last N lines | `tail` |
| Follow growing file | `tail -f` / `tail -F` |
| Save and view output | `tee` |
| Number lines | `nl` / `cat -n` |
| Display with line control | `more` |
| Show non-printing chars | `cat -A` |
| Quick look at file start | `head -n 5` |
| Monitor log file | `tail -F` |
| Record command output | `command \| tee log.txt` |

### Common Patterns

```bash
# View compressed files
zcat file.gz | less
zless file.gz

# Display file with line numbers and no wrap
less -NSR file.txt

# Monitor multiple log files
tail -F /var/log/app/*.log

# Build with logging
make 2>&1 | tee build.log | grep -E "error|warning"

# Quick file inspection
head -1 data.csv          # Header
tail -1 data.csv          # Last row
wc -l data.csv            # Row count

# Debug with visible control characters
cat -A config.ini

# Save and display simultaneously
rsync -av /src/ /dest/ 2>&1 | tee rsync.log

# Follow log with filter
tail -F /var/log/syslog | grep --line-buffered "error"
```

### Pipeline Integration

```bash
# These tools are designed for pipelines:

# Count errors in real-time
tail -F app.log | grep -c "error" | while read count; do
    echo "$(date): $count errors"
done

# Extract and analyze
head -n 1000 access.log | awk '{print $1}' | sort | uniq -c | sort -rn

# Split large file
head -n 10000 large.csv > part1.csv
tail -n +10001 large.csv | head -n 10000 > part2.csv
```
