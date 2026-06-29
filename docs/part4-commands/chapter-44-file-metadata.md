# Chapter 44: File Metadata — file, stat, touch, readlink, realpath

## Overview

File metadata — the information *about* files rather than their contents — is essential for system administration, scripting, and understanding how Linux manages the filesystem. The tools in this chapter provide ways to inspect, modify, and resolve file metadata including file type detection, inode information, timestamps, and symbolic link resolution.

Understanding file metadata is crucial because Linux treats everything as a file, and the metadata determines how files behave: permissions control access, timestamps track modifications, file types determine how the kernel handles them, and link information reveals the filesystem structure.

---

## file — Determine File Type

### Purpose

`file` determines the type of a file by examining its contents (magic bytes) rather than relying on the filename extension. This is critical in Unix-like systems where filenames have no inherent type meaning.

### Syntax

```
file [OPTION...] [FILE...]
```

### Key Options

| Option | Description |
|--------|-------------|
| `-b` | Brief mode (don't prepend filename) |
| `-i` | MIME type output |
| `-f FILE` | Read filenames from FILE |
| `-F SEP` | Use SEP as separator between filename and type |
| `-L` | Follow symlinks |
| `-h` | Don't follow symlinks (default) |
| `-N` | Don't pad filename |
| `-0` | Use null character as separator (for `xargs -0`) |
| `-z` | Try to look inside compressed files |
| `-Z` | Try to look inside compressed files (uncompressed output) |
| `-e TEST` | Run specific test (magic, compress, soft, tar, text, tokens, cdf, elf) |
| `-m FILE` | Use FILE as magic file |
| `-d` | Use default magic file |
| `-k` | Don't stop at first match (show all matches) |
| `-C` | Create magic.mgc file |
| `--mime-type` | Only output MIME type |
| `--mime-encoding` | Only output MIME encoding |
| `-p` | Don't optimize (pedantic checking) |
| `-r` | Raw output (don't translate control characters) |
| `-s` | Read block/char special files |
| `--extension` | Print possible file extensions |

### How File Type Detection Works

The `file` command uses a layered approach:

1. **Filesystem tests**: Check if the file is a special file (symlink, device, socket, pipe, directory).
2. **Magic tests**: Examine the first bytes (magic numbers) of the file against a database of known signatures.
3. **Language tests**: If magic tests fail, check for text encoding (UTF-8, ASCII, etc.).
4. **Soft magic tests**: Look for patterns in the file contents.
5. **Default**: If nothing matches, output "data".

The magic database is stored in `/usr/share/misc/magic` (or compiled form `/usr/share/misc/magic.mgc`). Users can add custom magic entries.

### Magic Numbers Examples

| File Type | Magic Bytes (Hex) | Description |
|-----------|-------------------|-------------|
| PNG image | `89 50 4E 47 0D 0A 1A 0A` | PNG header |
| JPEG image | `FF D8 FF` | JPEG/JFIF |
| PDF | `25 50 44 46` | `%PDF` |
| ELF binary | `7F 45 4C 46` | `.ELF` |
| gzip | `1F 8B` | gzip compression |
| ZIP | `50 4B 03 04` | PK.. (ZIP/JAR/APK) |
| tar | `75 73 74 61 72` | `ustar` (at offset 257) |
| SQLite | `53 51 4C 69 74 65` | `SQLite` |
| MP3 | `FF FB` or `ID3` | MPEG audio |
| WAV | `52 49 46 46` | `RIFF` header |

### Examples

```bash
# Basic file type detection
file document.pdf
# Output: document.pdf: PDF document, version 1.7

file image.png
# Output: image.png: PNG image data, 1920 x 1080, 8-bit/color RGBA

file /bin/ls
# Output: /bin/ls: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), dynamically linked, ...

file archive.tar.gz
# Output: archive.tar.gz: gzip compressed data, from Unix

# Brief mode (no filename prefix)
file -b document.pdf

# MIME type
file --mime-type document.pdf
# Output: document.pdf: application/pdf

file --mime-encoding document.pdf
# Output: document.pdf: us-ascii

# Full MIME info
file -i document.pdf
# Output: document.pdf: application/pdf; charset=us-ascii

# Look inside compressed files
file -z archive.tar.gz
# Output: archive.tar.gz: gzip compressed data... (tar archive)

# Multiple files
file *.txt

# Read filenames from a file
find . -type f -print0 > filelist.txt
file -f filelist.txt -0

# Show all matches (not just first)
file -k suspicious_file

# Show possible extensions
file --extension archive.zip

# Check special files
file /dev/null
# Output: /dev/null: character special (1/3)

file /dev/sda
# Output: /dev/sda: block special (8/0)

# Detect symlinks
file symlink_to_file

# Follow symlinks
file -L symlink_to_file

# Custom separator
file -F ' ==> ' *.pdf

# Don't pad output
file -N *.txt

# Read block/char devices
file -s /dev/sda1
# Output: /dev/sda1: Linux rev 1.0 ext4 filesystem data...

# Use custom magic file
file -m custom.magic testfile
```

### Internals

`file` uses the `libmagic` library for type detection:

1. **Magic file loading**: On startup, loads the magic database (either source or compiled `.mgc` format).
2. **Test execution**: For each file, runs through the test hierarchy:
   - `stat()` to check file type (regular, symlink, device, etc.)
   - Read initial bytes (typically first 4KB)
   - Match against magic patterns
   - Apply language/encoding tests if magic fails
3. **Pattern matching**: Magic entries specify byte offsets, expected values, masks, and comparison operators. Nested entries allow hierarchical matching.
4. **Performance**: The compiled `.mgc` format enables binary search for fast matching.

### Performance

- **Single file**: Fast — reads only the first 4KB of each file.
- **Multiple files**: Efficiently batches reads. The magic database is loaded once.
- **Compiled magic**: Using `.mgc` (compiled magic) is significantly faster than parsing source files.

### Common Mistakes

1. **Trusting file extensions**: `file` ignores extensions by default (it checks content). This is a feature, not a bug — file extensions are unreliable in Unix.

2. **Not using `-z` for archives**: `file archive.tar.gz` reports "gzip compressed data". Use `file -z` to see what's inside the archive.

3. **Binary files with text magic**: Some binary files (like Java .class files) may be misidentified as text if magic tests don't match.

4. **Empty files**: `file empty.txt` reports "empty". No magic tests can run on an empty file.

### POSIX Compatibility

`file` is specified by POSIX but with limited options. Most options (`-b`, `-i`, `-z`, `-k`, `-m`, `-e`) are extensions. The magic database format is implementation-defined.

### GNU vs BusyBox

- **GNU `file`** (from `file` package): Full-featured with comprehensive magic database, `-z`, `-k`, `-i`, `-e`, `--extension`, `--mime-*`.
- **BusyBox `file`**: Basic type detection. Supports `-b`, `-i`, `-L`, `-s`. Limited magic database. Approximately 8KB vs ~500KB for GNU (including magic database).

---

## stat — Display File or Filesystem Status

### Purpose

`stat` displays detailed file or filesystem status information, including inode data, timestamps, permissions, ownership, and size. It's the most comprehensive tool for inspecting file metadata.

### Syntax

```
stat [OPTION]... FILE...
stat --format=FORMAT FILE...
stat -f FILE...  # Filesystem status
```

### Key Options

| Option | Description |
|--------|-------------|
| `-f` | Display filesystem status instead of file status |
| `-L` | Follow symlinks |
| `-t` | Terse output (for scripting) |
| `-c FORMAT` | Use FORMAT instead of default |
| `--format=FORMAT` | Same as `-c` |
| `--printf=FORMAT` | Like `--format` but interpret backslash escapes |
| `--dereference` | Follow symlinks (default with `-L`) |
| `--cached=MODE` | How to use cached attributes (always, never, default) |

### Format Sequences

**File metadata:**

| Sequence | Description |
|----------|-------------|
| `%a` | Access rights (octal) |
| `%A` | Access rights (human-readable) |
| `%b` | Number of blocks allocated |
| `%B` | Size in bytes per block (512) |
| `%d` | Device number (decimal) |
| `%D` | Device number (hex) |
| `%f` | Raw mode (hex) |
| `%F` | File type |
| `%g` | Group ID |
| `%G` | Group name |
| `%h` | Number of hard links |
| `%i` | Inode number |
| `%m` | Mount point |
| `%n` | File name |
| `%N` | Quoted file name with dereference if symlink |
| `%o` | Optimal I/O transfer size hint |
| `%s` | Total size (bytes) |
| `%t` | Major device type (hex) |
| `%T` | Minor device type (hex) |
| `%u` | User ID |
| `%U` | User name |
| `%w` | Time of file birth (human-readable) |
| `%W` | Time of file birth (seconds since Epoch) |
| `%x` | Time of last access |
| `%X` | Time of last access (seconds since Epoch) |
| `%y` | Time of last data modification |
| `%Y` | Time of last data modification (seconds since Epoch) |
| `%z` | Time of last status change |
| `%Z` | Time of last status change (seconds since Epoch) |

**Filesystem metadata (with `-f`):**

| Sequence | Description |
|----------|-------------|
| `%a` | Free blocks available to non-superuser |
| `%b` | Total data blocks |
| `%c` | Total file nodes |
| `%d` | Free file nodes |
| `%f` | Free blocks |
| `%i` | Filesystem ID (hex) |
| `%l` | Maximum filename length |
| `%n` | File name |
| `%s` | Block size (for optimal transfer) |
| `%S` | Fundamental block size |
| `%t` | Filesystem type (hex) |
| `%T` | Filesystem type (human-readable) |

### Examples

```bash
# Default output
stat file.txt
# Output:
#   File: file.txt
#   Size: 1234        Blocks: 8          IO Block: 4096   regular file
# Device: 803h/2051d  Inode: 12345678    Links: 1
# Access: (0644/-rw-r--r--)  Uid: ( 1000/  user)   Gid: ( 1000/  user)
# Access: 2024-01-15 10:30:00.000000000 +0000
# Modify: 2024-01-14 15:45:00.000000000 +0000
# Change: 2024-01-14 15:45:00.000000000 +0000
#  Birth: 2024-01-14 15:45:00.000000000 +0000

# Custom format
stat -c "Name: %n, Size: %s, Perms: %a, Owner: %U" file.txt

# Get just the size
stat -c %s file.txt

# Get file type
stat -c %F file.txt

# Get inode number
stat -c %i file.txt

# Get permissions in octal
stat -c %a file.txt

# Get last modification time (epoch)
stat -c %Y file.txt

# Filesystem information
stat -f /
# Output:
#   File: "/"
#     ID: 1234567890abcdef Namelen: 255     Type: ext2/ext3
# Block size: 4096       Fundamental block size: 4096
# Blocks: Total: 10000000   Free: 5000000    Available: 4500000
# Inodes: Total: 2500000    Free: 2000000

# Terse output (for scripting)
stat -t file.txt

# Follow symlinks
stat -L symlink

# Dereference symlink (show target info)
stat -L symlink_to_file

# Multiple files
stat -c "%n %s" *.txt

# Check if file exists (in script)
if stat file.txt > /dev/null 2>&1; then
    echo "File exists"
fi

# Get timestamps
stat -c "Access: %x\nModify: %y\nChange: %z" file.txt

# Compare timestamps
if [ "$(stat -c %Y file1)" -gt "$(stat -c %Y file2)" ]; then
    echo "file1 is newer"
fi

# Format with backslash escapes
stat --printf="Name: %n\nSize: %s bytes\n" file.txt

# Device type for block/char devices
stat -c "%t:%T" /dev/sda

# Filesystem type
stat -f -c %T /
```

### Internals

`stat` calls the `stat()` syscall (or `lstat()` for symlinks) and formats the returned `struct stat`:

```c
struct stat {
    dev_t     st_dev;      // Device ID
    ino_t     st_ino;      // Inode number
    mode_t    st_mode;     // File type and mode
    nlink_t   st_nlink;    // Number of hard links
    uid_t     st_uid;      // User ID
    gid_t     st_gid;      // Group ID
    dev_t     st_rdev;     // Device ID (if special file)
    off_t     st_size;     // Total size in bytes
    blksize_t st_blksize;  // Block size for filesystem I/O
    blkcnt_t  st_blocks;   // Number of 512B blocks allocated
    struct timespec st_atim;  // Time of last access
    struct timespec st_mtim;  // Time of last modification
    struct timespec st_ctim;  // Time of last status change
    struct timespec st_birthtim; // Time of file creation (not all FS)
};
```

For filesystem info (`-f`), it calls `statfs()` or `statvfs()`.

### Performance

`stat` is extremely fast — it's a single syscall per file. The overhead is negligible compared to any file I/O operation.

### Common Mistakes

1. **Symlink behavior**: `stat symlink` shows info about the symlink itself. `stat -L symlink` shows info about the target. This is a common source of confusion.

2. **Birth time**: `%w` and `%W` (birth time) are only supported on filesystems that record creation time (ext4, Btrfs, XFS). On unsupported filesystems, they show `-`.

3. **`-c` format quoting**: Format strings with spaces need quoting: `stat -c '%n %s' file`.

4. **Comparing timestamps**: Always use epoch seconds (`%Y`, `%X`, `%Z`) for comparisons, not human-readable strings.

### POSIX Compatibility

`stat` is not specified by POSIX. Use `ls` for basic file info on POSIX systems. However, `stat` is universally available on Linux and is indispensable for scripting.

### GNU vs BusyBox

- **GNU `stat`** (from `coreutils`): Full-featured with all format sequences, filesystem info, custom formatting.
- **BusyBox `stat`**: Supports `-c`, `-f`, `-L`, `-t`. Some format sequences may be missing. Approximately 5KB vs ~100KB for GNU.

---

## touch — Change File Timestamps

### Purpose

`touch` changes file access and modification timestamps, or creates empty files if they don't exist.

### Syntax

```
touch [OPTION]... FILE...
```

### Key Options

| Option | Description |
|--------|-------------|
| `-a` | Change only access time |
| `-m` | Change only modification time |
| `-c`, `--no-create` | Don't create file if it doesn't exist |
| `-d STRING` | Set time using date string |
| `-t STAMP` | Set time using `[[CC]YY]MMDDhhmm[.ss]` format |
| `-r FILE` | Use FILE's timestamps |
| `--reference=FILE` | Same as `-r` |
| `--time=WORD` | Which time to change: `access`, `atime`, `use`, `modify`, `mtime` |
| `--date=STRING` | Same as `-d` |

### Date String Formats

`-d` accepts flexible date/time strings:

```
"2024-01-15 10:30:00"    # ISO format
"2024-01-15"             # Date only
"10:30:00"               # Time only (today)
"2 days ago"             # Relative
"last Friday"            # Relative day
"next Monday"            # Relative day
"1 hour ago"             # Relative time
"yesterday"              # Yesterday
"now"                    # Current time
"2024-01-15T10:30:00"    # ISO with T separator
```

### Examples

```bash
# Create empty file
touch newfile.txt

# Update access and modification time to now
touch existingfile.txt

# Set specific date
touch -d "2024-01-15 10:30:00" file.txt

# Set using timestamp format
touch -t 202401151030.00 file.txt

# Change only access time
touch -a file.txt

# Change only modification time
touch -m file.txt

# Use another file's timestamps
touch -r reference.txt target.txt

# Don't create if missing
touch -c possibly_exists.txt

# Set to a relative time
touch -d "1 hour ago" file.txt

# Set to midnight today
touch -d "today" file.txt

# Create multiple files
touch file{1..100}.txt

# Update timestamp to match another file
touch -r template.txt copy.txt

# Set future date
touch -d "2025-12-31" file.txt

# Change modification time only
touch -m -d "2024-06-15" file.txt

# Verify timestamps with stat
stat file.txt
```

### Internals

`touch` uses `utimensat()` syscall (or `utimes()`/`utime()` on older systems) to set timestamps:

1. If the file doesn't exist, `touch` creates it with `open(O_CREAT|O_WRONLY)` then immediately closes it.
2. If the file exists, `touch` updates the specified timestamps.
3. With `-r`, it first reads the reference file's timestamps with `stat()`, then applies them.

**Timestamp granularity**: Modern Linux supports nanosecond timestamps. `touch` can set times with nanosecond precision using the `.ss` suffix in `-t` or nanoseconds in `-d`.

**Permissions**: You can change timestamps on files you own. Root can change timestamps on any file. Setting timestamps to arbitrary values (not "now") requires write permission or root.

### Performance

`touch` is O(1) per file — a single syscall. Creating many files is efficient.

### Common Mistakes

1. **`-c` vs no `-c`**: Without `-c`, `touch` creates files that don't exist. This may be unexpected in scripts where you only want to update timestamps.

2. **Date format confusion**: `-t` uses `MMDDhhmm` (no year by default), not `YYYY-MM-DD`. Use `-d` for ISO format.

3. **Symlinks**: `touch` follows symlinks by default. Use `-h` (not always available) to change the symlink's own timestamp.

### POSIX Compatibility

POSIX specifies `-a`, `-c`, `-m`, `-r`, `-t`. The `-d` option and flexible date strings are GNU extensions.

---

## readlink — Print Value of a Symbolic Link

### Purpose

`readlink` prints the target of a symbolic link. With `-f`, it resolves the full canonical path, following all symlinks and `..` components.

### Syntax

```
readlink [OPTION]... FILE...
```

### Key Options

| Option | Description |
|--------|-------------|
| `-f`, `--canonicalize` | Print absolute path, resolving all symlinks |
| `-e`, `--canonicalize-existing` | Like `-f` but fail if target doesn't exist |
| `-m`, `--canonicalize-missing` | Like `-f` but no error for missing components |
| `-n`, `--no-newline` | Don't output trailing newline |
| `-z`, `--zero` | Separate output with null character |
| `-q`, `--quiet` | Suppress error messages |
| `-s`, `--silent` | Same as `-q` |
| `--relative-to=DIR` | Print relative path from DIR |
| `--relative-base=DIR` | Print relative path only if under DIR |

### Examples

```bash
# Print symlink target
readlink symlink_name

# Resolve full canonical path
readlink -f /path/to/symlink

# Resolve with missing components (no error)
readlink -m /path/that/doesnt/exist

# Resolve only if target exists
readlink -e /path/to/symlink

# Relative path from a directory
readlink --relative-to=/home/user /home/user/documents/file.txt
# Output: documents/file.txt

# No trailing newline
readlink -n symlink

# Get script's real path (common in scripts)
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

# Resolve nested symlinks
readlink -f /usr/bin/python3
# Output: /usr/bin/python3.10 (or similar)

# Use in scripts to find the real location
REAL_PATH="$(readlink -f "$1")"

# Check if path is a symlink
if [ -L "$file" ]; then
    target="$(readlink "$file")"
    echo "$file -> $target"
fi
```

### Internals

- **Without `-f`**: Calls `readlink()` syscall directly, which returns the raw target string.
- **With `-f`**: Iteratively resolves each component of the path:
  1. Split path into components
  2. For each component, if it's a symlink, read its target
  3. Resolve `..` and `.` components
  4. Repeat until no more symlinks
  5. Return the absolute path

This iterative resolution is necessary because symlinks can point to other symlinks (chains), and `..` after a symlink resolves relative to the symlink's parent, not the current directory.

### Common Mistakes

1. **`readlink` without `-f`**: Only returns the immediate target of the symlink, not the fully resolved path. Use `-f` for canonical paths.

2. **Non-symlink input**: `readlink` on a regular file returns nothing (exit code 1). Check with `[ -L file ]` first.

3. **Portability**: `readlink -f` is a GNU extension. On macOS, use `realpath` or `readlink` with different flags. In portable scripts, use `cd "$(dirname "$file")" && echo "$(pwd)/$(basename "$file")"`.

### POSIX Compatibility

`readlink` is not specified by POSIX. The basic `readlink file` (no options) is available on most Unix-like systems. `-f`, `-e`, `-m`, `--relative-to` are GNU extensions.

---

## realpath — Print the Resolved Absolute Path

### Purpose

`realpath` prints the resolved absolute pathname, canonicalizing paths by resolving `.`  , `..`, and symbolic links.

### Syntax

```
realpath [OPTION]... FILE...
```

### Key Options

| Option | Description |
|--------|-------------|
| `-e`, `--canonicalize-existing` | All components must exist |
| `-m`, `--canonicalize-missing` | No error for missing components |
| `-L`, `--logical` | Resolve `..` logically (before symlink resolution) |
| `-P`, `--physical` | Resolve `..` physically (after symlink resolution, default) |
| `-q`, `--quiet` | Suppress error messages |
| `--relative-to=DIR` | Print relative path from DIR |
| `--relative-base=DIR` | Print relative only if under DIR |
| `-s`, `--strip` | Don't resolve symlinks (just normalize) |
| `-z`, `--zero` | Separate output with null character |

### Examples

```bash
# Get absolute path
realpath file.txt

# Resolve relative path
realpath ../documents/file.txt

# Resolve missing path (no error)
realpath -m /nonexistent/path

# All components must exist
realpath -e /etc/passwd

# Relative to a directory
realpath --relative-to=/home/user /home/user/docs/file.txt
# Output: docs/file.txt

# Don't follow symlinks (just normalize path)
realpath -s ./foo/../bar/baz

# Physical resolution (default)
realpath -P /path/to/symlink

# Logical resolution
realpath -L /path/to/symlink

# Use in scripts
PROJECT_ROOT="$(realpath "$(dirname "$0")/..")"

# Get relative path between two locations
realpath --relative-to=/source /destination

# Canonicalize without error for missing files
realpath -m ../../config/app.conf
```

### Performance

`realpath` is fast — it's a series of `stat()` and `readlink()` calls. The overhead is proportional to the number of path components and symlink chain depth.

### Common Mistakes

1. **`realpath` vs `readlink -f`**: They're similar but have subtle differences in `..` resolution with symlinks. `realpath -L` resolves `..` logically; `realpath -P` (default) resolves physically.

2. **Non-existent paths**: By default, `realpath` fails if the path doesn't exist. Use `-m` for missing paths.

3. **Trailing slash**: `realpath /path/to/dir/` and `realpath /path/to/dir` may produce different results for symlinks to directories.

### POSIX Compatibility

`realpath` is not specified by POSIX. It's available as a standalone utility on most Linux systems (from `coreutils`). Some systems have it only as a C library function.

---

## Summary

### Tool Comparison

| Tool | Purpose | Input | Key Feature |
|------|---------|-------|-------------|
| `file` | Detect file type | File contents (magic bytes) | Content-based type detection |
| `stat` | Display metadata | File path | Comprehensive inode/filesystem info |
| `touch` | Modify timestamps | File path | Create files, set arbitrary times |
| `readlink` | Resolve symlinks | Symlink path | Read symlink target |
| `realpath` | Canonicalize paths | Any path | Full path resolution |

### Common Patterns

```bash
# Check if file is a symlink, then resolve
if [ -L "$file" ]; then
    target="$(readlink -f "$file")"
    echo "Symlink: $file -> $target"
    stat -c "Target: %n, Size: %s, Type: %F" "$target"
else
    stat -c "Regular: %n, Size: %s, Type: %F" "$file"
fi

# File type detection and metadata
file_type="$(file -b --mime-type "$file")"
file_size="$(stat -c %s "$file")"
file_perms="$(stat -c %a "$file")"

# Create a file and set its timestamp
touch -d "2024-01-01" marker.txt

# Get script's real directory (works with symlinks)
SCRIPT_DIR="$(cd "$(dirname "$(realpath "$0")")" && pwd)"

# Check file type before processing
case "$(file -b "$input")" in
    *"gzip"*)  zcat "$input" ;;
    *"bzip2"*) bzcat "$input" ;;
    *"XZ"*)    xzcat "$input" ;;
    *)         cat "$input" ;;
esac

# Compare file ages
if [ "$(stat -c %Y file1)" -gt "$(stat -c %Y file2)" ]; then
    echo "file1 is newer"
fi

# Get all metadata as JSON (custom format)
stat -c '{"name":"%n","size":%s,"perms":"%a","uid":%u,"gid":%g,"mtime":%Y}' file.txt
```
