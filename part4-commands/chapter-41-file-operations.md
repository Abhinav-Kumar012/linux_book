# Chapter 41: File Operations — ls, cp, mv, rm, ln, find, locate (updatedb)

## Overview

File operations form the backbone of any Unix-like operating system. The utilities covered in this chapter — `ls`, `cp`, `mv`, `rm`, `ln`, `find`, and `locate` — represent the fundamental toolkit for creating, copying, moving, removing, linking, and searching files and directories. Mastering these tools is essential for efficient system administration, development, and daily Linux usage.

Each tool interacts directly with the kernel's Virtual File System (VFS) layer, which abstracts the underlying filesystem (ext4, XFS, Btrfs, etc.) into a uniform interface. Understanding how these tools work at the syscall level — using operations like `stat()`, `open()`, `read()`, `write()`, `rename()`, `unlink()`, and `symlink()` — provides insight into their behavior, performance characteristics, and edge cases.

---

## ls — List Directory Contents

### Purpose

`ls` lists the contents of directories. It is one of the most frequently used commands in Linux, providing information about files including permissions, ownership, size, and modification time.

### Syntax

```
ls [OPTION]... [FILE]...
```

### Key Options

| Option | Description |
|--------|-------------|
| `-l` | Long listing format (permissions, owner, group, size, date, name) |
| `-a` | Show all entries including hidden files (those starting with `.`) |
| `-A` | Like `-a` but exclude `.` and `..` |
| `-h` | Human-readable sizes (e.g., 4.0K, 1.2M) when combined with `-l` |
| `-R` | Recursive listing of subdirectories |
| `-t` | Sort by modification time (newest first) |
| `-S` | Sort by file size (largest first) |
| `-r` | Reverse sort order |
| `-d` | List directories themselves, not their contents |
| `-i` | Show inode numbers |
| `-F` | Append indicator characters (`/` for dirs, `*` for executables, `@` for symlinks) |
| `--color` | Colorize output by file type |
| `--time-style` | Control date/time display format |
| `-1` | One entry per line |
| `-s` | Display allocated blocks for each file |
| `--group-directories-first` | Group directories before files |

### Examples

```bash
# Basic listing
ls

# Long format with human-readable sizes
ls -lah

# List specific directory with details
ls -la /var/log

# Sort by size, largest first
ls -lhS /tmp

# Show only directories
ls -d */

# Recursive with pattern matching
ls -R /etc/*.conf

# Show inode numbers
ls -li /home

# Sort by modification time, reverse (oldest first)
ls -ltr /var/log

# Show file context (SELinux)
ls -laZ /etc

# List with custom time format
ls -l --time-style=long-iso /tmp

# One file per line (useful for scripting)
ls -1 /etc
```

### Internals

`ls` operates through a well-defined pipeline:

1. **Argument parsing**: Files and directories are separated; files are listed first, then directory contents.
2. **Directory reading**: Uses `opendir()` and `readdir()` syscalls to enumerate entries. On modern Linux, `getdents64()` is the underlying syscall.
3. **Stat calls**: For each entry, `lstat()` (or `stat()` if following symlinks) retrieves metadata. With `-l`, each file requires a separate stat call, which is why `ls -l` on large directories is significantly slower than plain `ls`.
4. **Sorting**: Entries are sorted in memory (typically using `qsort()`). The sort key depends on options: name (default), mtime (`-t`), size (`-S`), or extension (`-X`).
5. **Output formatting**: The output is formatted into columns (for terminal) or one-per-line (for pipes, or with `-1`).

**Column width calculation**: `ls` pre-scans all entries to determine column widths for alignment. This is why `ls -l | head` still reads the entire directory — all entries must be processed to calculate the correct column widths before output begins.

**Color codes**: When `--color=auto` is set, `ls` consults `LS_COLORS` (or `dircolors` defaults) to map file extensions and types to ANSI color codes. The mapping is loaded from `$LS_COLORS` environment variable.

### Performance

- **Plain `ls`** (no `-l`): Very fast — only requires `getdents64()` syscall.
- **`ls -l`**: Requires one `lstat()` per file. On directories with millions of files, this can take several seconds.
- **`ls -R`**: Multiply by the depth of the tree. Deep recursive listings can be I/O-bound.
- **SSD vs HDD**: On SSDs, `ls -lR` is 10-100x faster than on spinning disks due to random access patterns of stat calls.

### Common Mistakes

1. **Parsing `ls` output in scripts**: Never do `for f in $(ls ...)` or `ls | while read f`. Filenames can contain spaces, newlines, and special characters. Use `find` with `-print0` and `xargs -0`, or glob patterns directly.

   ```bash
   # WRONG - breaks on spaces
   for f in $(ls /path); do echo "$f"; done

   # CORRECT - use glob
   for f in /path/*; do echo "$f"; done
   ```

2. **`ls -l | head` performance trap**: This reads the entire directory to compute column widths, even though only 10 lines are displayed. Use `ls -1 | head` instead, or `find ... -maxdepth 1 | head`.

3. **Symlink confusion**: `ls -l` shows symlinks with `→` notation. `ls -L` follows symlinks (shows info about the target). For scripting, use `readlink` to resolve symlinks.

4. **Hidden files**: Beginners forget that `ls` (without `-a`) hides files starting with `.`. Use `ls -la` to see everything.

### Real-World Usage

```bash
# Find the 10 largest files in a directory
ls -lhS /var/log | head -11

# Find recently modified config files
ls -lt /etc/nginx/*.conf

# Check directory permissions and ownership
ls -la /var/www/html/

# Count files in a directory (fast)
ls -1 /path/to/dir | wc -l

# Show file type indicators
ls -F /usr/bin | head -20
```

### Best Practices

- Use `ls --color=auto` in aliases (default on most distros via `.bashrc`).
- In scripts, prefer `stat` or `find` over parsing `ls` output.
- Use `ls -lhd` to inspect a directory without descending into it.
- For machine-readable output, use `ls -1` or `stat --format`.

### POSIX Compatibility

POSIX specifies `ls` with a minimal set of options: `-a`, `-A`, `-c`, `-d`, `-f`, `-g`, `-H`, `-i`, `-k`, `-l`, `-L`, `-m`, `-n`, `-o`, `-p`, `-q`, `-r`, `-R`, `-S`, `-t`, `-u`, `-x`, `-1`. Extensions like `--color`, `--group-directories-first`, `--time-style` are GNU-specific.

### GNU vs BusyBox

- **GNU `ls`**: Full-featured, supports all POSIX and GNU extensions, color support, `--hyperlink`, `--sort=WORD`, `--time-style`.
- **BusyBox `ls`**: Stripped down. Supports basic options (`-l`, `-a`, `-h`, `-R`, `-i`, `-n`, `-s`). Missing: `--color` (may not be compiled), `--group-directories-first`, `--time-style`, `-S` sort by size. BusyBox `ls` is approximately 3KB compiled vs ~130KB for GNU `ls`.

---

## cp — Copy Files and Directories

### Purpose

`cp` copies files and directories. It can create duplicates, preserve attributes, update selectively, and create backups.

### Syntax

```
cp [OPTION]... SOURCE DEST
cp [OPTION]... SOURCE... DIRECTORY
```

### Key Options

| Option | Description |
|--------|-------------|
| `-r`, `-R` | Recursive copy (directories) |
| `-a` | Archive mode: preserves all attributes, copies recursively, follows no symlinks |
| `-p` | Preserve mode, ownership, timestamps |
| `-u` | Copy only when SOURCE is newer than DEST or DEST is missing |
| `-v` | Verbose output |
| `-i` | Interactive prompt before overwrite |
| `-f` | Force: remove existing destinations before copying |
| `-n` | No-clobber: never overwrite existing files |
| `-l` | Create hard links instead of copying |
| `-s` | Create symbolic links instead of copying |
| `--reflink` | Copy-on-Write (CoW) copy on supported filesystems (Btrfs, XFS) |
| `--sparse` | Handle sparse files intelligently |
| `--preserve` | Preserve specified attributes (all, mode, ownership, timestamps, context, links, xattr) |
| `--backup` | Make backups of existing destination files |
| `-T` | Treat DEST as a normal file (not a directory) |
| `--no-preserve` | Don't preserve specified attributes |
| `-x` | Stay on one filesystem |
| `--parents` | Copy with full source path under DEST |

### Examples

```bash
# Copy a file
cp source.txt dest.txt

# Copy multiple files to a directory
cp file1.txt file2.txt /backup/

# Recursive copy preserving all attributes
cp -a /home/user/project /backup/project

# Copy only newer files
cp -u /source/*.conf /dest/

# Interactive copy (prompt before overwrite)
cp -i important.conf /etc/

# Copy-on-Write (instant copy on Btrfs)
cp --reflink=always largefile.img /backup/

# Create hard links instead of copies
cp -l source.txt link.txt

# Copy with backup
cp --backup=numbered config.ini /etc/app/

# Copy preserving specific attributes
cp --preserve=mode,ownership,timestamps src dst

# Copy directory structure only (no files)
cp -a --no-preserve=all /src/dir /dst/dir

# Copy staying on same filesystem
cp -ax /home/user/ /backup/

# Sparse file handling
cp --sparse=always disk.img /backup/disk.img
```

### Internals

`cp` works through a sequence of syscalls:

1. **Source stat**: `lstat()` on source to determine type and attributes.
2. **Destination check**: `lstat()` on destination (if it exists) to determine conflict handling.
3. **For files**:
   - Open source: `open(source, O_RDONLY)`
   - Create destination: `open(dest, O_WRONLY|O_CREAT|O_TRUNC)`
   - Copy data: `read()` + `write()` loop, typically in 128KB-1MB chunks
   - Modern GNU `cp` uses `copy_file_range()` syscall on Linux 4.5+ for intra-filesystem copies, avoiding userspace buffer copies entirely
   - `sendfile()` is also used when available
4. **For directories**: `mkdir()` then recurse.
5. **Attribute preservation**: `chmod()`, `chown()`, `utimensat()`, `xattr` calls to copy metadata.

**Copy-on-Write (CoW)**: With `--reflink=always` on Btrfs/XFS, `cp` uses `ioctl(FICLONE)` to create a reflink — both source and destination share the same disk blocks until one is modified. This makes the copy instantaneous regardless of file size. If the filesystem doesn't support reflinks, `--reflink=always` will fail; `--reflink=auto` falls back to regular copy.

### Performance

- **Regular copy**: Limited by disk I/O. On modern SSDs, ~500MB/s-3GB/s. On HDDs, ~80-160MB/s.
- **`cp --reflink`**: Near-instant (microseconds) — only metadata is written.
- **`cp -l`** (hard links): Near-instant — only a new directory entry is created.
- **Large directory trees**: `cp -a` with millions of files can be slow due to per-file stat/metadata operations. Consider `tar | tar` or `rsync` for very large trees.
- **Network filesystems**: `cp` over NFS/CIFS is limited by network bandwidth and protocol overhead.

### Common Mistakes

1. **`cp dir1 dir2`** — Without `-r`, this fails for directories. Always use `-r` or `-a` for directories.

2. **Overwriting with `cp`** — By default, `cp` overwrites without prompting (unless aliased with `-i`). Use `-n` for no-clobber or `-i` for interactive.

3. **Trailing slash semantics**:
   ```bash
   cp -r dir1 dir2   # Creates dir2/dir1/... (if dir2 exists)
   cp -r dir1/ dir2   # Copies contents of dir1 into dir2/
   ```

4. **Permissions not preserved**: Without `-p` or `-a`, copied files get default permissions (affected by `umask`). Use `cp -a` when exact preservation matters.

5. **Sparse file corruption**: Without `--sparse=auto`, copying a sparse file (like a virtual disk image) may inflate it to full size, wasting disk space.

### Real-World Usage

```bash
# System backup with full attribute preservation
cp -ax /etc /backup/etc-$(date +%Y%m%d)

# Deploy configuration with backup
cp --backup=simple /app/config.new /app/config.ini

# Quick clone of a VM disk on Btrfs
cp --reflink=always vm-disk.qcow2 vm-disk-clone.qcow2

# Copy only changed files (basic incremental)
cp -u /source/* /dest/
```

### Best Practices

- Always use `cp -a` for backups or when preserving permissions matters.
- Use `--reflink=auto` on Btrfs/XFS for large file copies.
- In scripts, use `cp -n` to prevent accidental overwrites.
- For complex copy operations (filters, exclude patterns), use `rsync` instead.
- Verify copies of critical data with `diff` or checksums.

### POSIX Compatibility

POSIX `cp` supports `-f`, `-i`, `-H`, `-L`, `-P`, `-R`, `-p` (limited). The `-a` option is not in POSIX but is universally supported. `--reflink`, `--sparse`, `--backup` are GNU extensions.

### GNU vs BusyBox

- **GNU `cp`**: Full-featured with `--reflink`, `--sparse`, `--backup`, `--attributes-only`, `--parents`, `copy_file_range()`.
- **BusyBox `cp`**: Supports `-a`, `-d`, `-f`, `-i`, `-l`, `-L`, `-n`, `-P`, `-p`, `-R`, `-s`, `-u`, `-v`. Missing: `--reflink`, `--sparse`, `--backup`, `--parents`. BusyBox is approximately 5KB vs ~150KB for GNU.

---

## mv — Move (Rename) Files

### Purpose

`mv` moves or renames files and directories. Within the same filesystem, it's a metadata-only operation (fast rename). Across filesystems, it's equivalent to `cp` + `rm`.

### Syntax

```
mv [OPTION]... SOURCE DEST
mv [OPTION]... SOURCE... DIRECTORY
```

### Key Options

| Option | Description |
|--------|-------------|
| `-f` | Force: don't prompt before overwrite |
| `-i` | Interactive: prompt before overwrite |
| `-n` | No-clobber: never overwrite |
| `-u` | Move only when SOURCE is newer or DEST is missing |
| `-v` | Verbose output |
| `-T` | Treat DEST as normal file |
| `-b` | Backup existing destination |
| `--strip-trailing-slashes` | Remove trailing slashes from SOURCE |
| `--suffix=S` | Override backup suffix |
| `--target-directory=D` | Move all SOURCEs into directory D |

### Examples

```bash
# Rename a file
mv oldname.txt newname.txt

# Move file to a directory
mv file.txt /home/user/documents/

# Move multiple files
mv *.log /var/log/archive/

# Interactive mode
mv -i config.ini /etc/app/

# No-clobber
mv -n new.conf /etc/app/

# Move only if source is newer
mv -u /tmp/cache.db /var/lib/app/

# Move across filesystems (implicit cp + rm)
mv /home/user/hugefile.img /mnt/backup/

# Force move (overwrite without prompt)
mv -f updated.conf /etc/app/
```

### Internals

The behavior of `mv` depends on whether the source and destination are on the same filesystem:

**Same filesystem**: Uses `rename()` syscall directly. This is atomic — if the system crashes during the operation, either the old name or the new name exists, never both. No data is copied; only the directory entry is updated. This is extremely fast (microseconds).

**Cross-filesystem**: Falls back to copy + delete:
1. `cp -a source dest` (copy with all attributes)
2. `rm source` (remove the original)
3. This is NOT atomic. If the system crashes mid-copy, you may have partial copies on both filesystems.
4. For directories, GNU `mv` creates the destination directory, moves contents recursively, then removes the source.

**Special handling**:
- Moving a file to the same directory with a different name is always a `rename()`.
- Moving to a different mount point triggers the cross-filesystem path.
- Permissions on the source directory may prevent `rename()` even if the file itself is writable.

### Performance

- **Same filesystem**: O(1) — constant time regardless of file size. Uses `rename()`.
- **Cross-filesystem**: Limited by I/O (same as `cp`). A 10GB file takes as long to move across filesystems as to copy.
- **Atomic rename**: `mv` on the same filesystem provides atomic rename, which is useful for safe file updates:
  ```bash
  # Write new config atomically
  cp config.ini config.ini.tmp
  # ... edit config.ini.tmp ...
  mv config.ini.tmp config.ini  # Atomic swap
  ```

### Common Mistakes

1. **`mv dir1 dir2`** — If `dir2` exists, `dir1` is moved *inside* `dir2` (creating `dir2/dir1`). If `dir2` doesn't exist, `dir1` is renamed to `dir2`. This is a common source of confusion.

2. **Moving across filesystems without enough space**: `mv` across filesystems copies first, then deletes. If the destination fills up, the move fails partway.

3. **Overwriting without `-i`**: Unlike some systems, Linux `mv` (without alias) overwrites silently. Set `alias mv='mv -i'` for safety.

4. **Moving symlinks**: `mv` moves the symlink itself, not the target. Use `mv -L` to dereference (move the target file).

### Best Practices

- Use `mv -i` as a default alias for interactive safety.
- For atomic updates (config files, data files), write to a temp file then `mv`.
- For cross-filesystem moves of large data, consider `rsync` + manual delete for better control.
- Use `mv --backup` for safety when overwriting is possible.

### POSIX Compatibility

POSIX specifies `-f`, `-i`, `-n` (as `-f` semantics). The `-u` option is a GNU extension. `-T` and `--target-directory` are GNU extensions.

### GNU vs BusyBox

- **GNU `mv`**: Full-featured, handles cross-device moves, `--backup`, `--strip-trailing-slashes`, `--target-directory`.
- **BusyBox `mv`**: Supports `-f`, `-i`, `-n`, `-u`, `-v`. Handles cross-device moves. Missing some long-form options. Approximately 4KB vs ~120KB for GNU.

---

## rm — Remove Files and Directories

### Purpose

`rm` removes (unlinks) files and directories. It is one of the most dangerous commands in Linux because deleted files are not moved to a trash — they are immediately unlinked from the filesystem.

### Syntax

```
rm [OPTION]... FILE...
```

### Key Options

| Option | Description |
|--------|-------------|
| `-r`, `-R` | Recursive: remove directories and their contents |
| `-f` | Force: ignore nonexistent files, don't prompt |
| `-i` | Prompt before every removal |
| `-I` | Prompt once before removing more than three files (or with `-r`) |
| `-d` | Remove empty directories |
| `-v` | Verbose output |
| `--preserve-root` | Do not remove `/` (default) |
| `--no-preserve-root` | Allow removal of `/` |
| `--one-file-system` | Stay on one filesystem when recursing |

### Examples

```bash
# Remove a single file
rm file.txt

# Remove multiple files
rm *.tmp

# Remove a directory and contents
rm -rf /tmp/build/

# Interactive removal
rm -ri /home/user/old_project/

# Safe removal with confirmation for many files
rm -I *.log

# Verbose removal
rm -v /tmp/test*

# Remove empty directory
rm -d empty_dir/

# Force remove read-only file
rm -f readonly.txt
```

### Internals

`rm` operates through the `unlink()` syscall for files and `rmdir()` for directories:

1. **For files**: `unlink(path)` removes the directory entry. The actual data is freed only when no process has the file open (reference count reaches zero).
2. **For directories**: `rmdir(path)` removes the directory (must be empty). With `-r`, `rm` recursively removes contents first.
3. **Recursive removal**: Traverses the directory tree using `opendir()`/`readdir()`/`closedir()`, unlinking files and removing directories in a depth-first order.
4. **Permissions**: `rm` requires write and execute permissions on the *parent directory* (to modify the directory listing), not on the file itself. This is why you can remove a file you don't own if you have write access to its directory.

**Important**: `rm` does NOT securely delete data. The file's data blocks remain on disk until overwritten. For secure deletion, use `shred` or full-disk encryption.

### Performance

- **Single file**: O(1) — one `unlink()` syscall.
- **Recursive deletion**: Proportional to the number of files. Each file requires one `unlink()`.
- **Large directories**: GNU `rm` with `-rf` is reasonably efficient but can be slow on very deep trees (millions of files). Alternatives:
  ```bash
  # Fast bulk delete using find
  find /path -delete

  # Or using rsync with empty directory
  mkdir /tmp/empty
  rsync -a --delete /tmp/empty/ /path/to/delete/
  ```

### Common Mistakes

1. **`rm -rf /`** — The most destructive command possible. Modern GNU `rm` has `--preserve-root` by default, but this can be bypassed with `--no-preserve-root`. Never run this.

2. **`rm -rf $VARIABLE/`** — If `$VARIABLE` is empty, this becomes `rm -rf /`. Always quote variables:
   ```bash
   # DANGEROUS
   rm -rf $HOME/project/

   # SAFE
   rm -rf "$HOME/project/"
   ```

3. **`rm *` in the wrong directory** — Always check `pwd` before running `rm *`. Use `rm -i *` for safety.

4. **Cannot recover**: Unlike Windows/macOS, `rm` doesn't use a trash can (unless using tools like `trash-cli`). Deleted files are gone immediately.

5. **`rm` on open files**: If a process has the file open, `rm` removes the directory entry but the file data persists until the process closes it. The disk space is only reclaimed when the file handle is closed.

### Best Practices

- **Alias `rm`**: `alias rm='rm -i'` for interactive safety.
- **Use `trash-cli`**: For daily use, `trash-put` instead of `rm` allows recovery.
- **Quote variables**: Always use `"$variable"` in rm commands.
- **`rm -I`**: Use this for a single confirmation when deleting many files (more practical than `-i` for each file).
- **Dry-run first**: Before `rm -rf`, run `find /path -type f | wc -l` to understand the scope.
- **Use `--one-file-system`**: Prevents accidentally deleting mount points.

### POSIX Compatibility

POSIX specifies `-f`, `-i`, `-r`, `-R`. The `-d` and `-I` options are GNU extensions. `--preserve-root` is GNU-specific (but a wise safety measure).

### GNU vs BusyBox

- **GNU `rm`**: Full-featured, `--preserve-root`, `-I` prompt-once, `--one-file-system`, `--interactive=WHEN`.
- **BusyBox `rm`**: Supports `-f`, `-i`, `-r`, `-R`, `-d`, `-v`. Approximately 3KB vs ~60KB for GNU. Does not have `--preserve-root` (be careful!).

---

## ln — Create Links

### Purpose

`ln` creates hard links and symbolic (soft) links between files. Links provide multiple names for the same data (hard links) or aliases pointing to another file (symlinks).

### Syntax

```
ln [OPTION]... TARGET LINK_NAME
ln [OPTION]... TARGET... DIRECTORY
```

### Key Options

| Option | Description |
|--------|-------------|
| `-s` | Create symbolic link (default is hard link) |
| `-f` | Force: remove existing destination |
| `-i` | Interactive: prompt before overwrite |
| `-n` | No-dereference: treat LINK_NAME as normal file if it's a symlink to a directory |
| `-v` | Verbose output |
| `-r` | Create relative symbolic links |
| `-T` | Treat LINK_NAME as normal file |
| `--backup` | Backup existing destination |
| `-d` | Allow hard links to directories (root only, dangerous) |
| `-L` | Dereference TARGET if it's a symlink |
| `-P` | Don't dereference TARGET (default) |

### Examples

```bash
# Create a hard link
ln file.txt file_link.txt

# Create a symbolic link
ln -s /usr/local/bin/app /usr/bin/app

# Create symlink in a directory
ln -s /etc/nginx/nginx.conf /home/user/nginx.conf.bak

# Create relative symlink (useful for portable paths)
ln -sr /opt/app/config.ini /etc/app/config.ini

# Force overwrite existing link
ln -sf /new/target /existing/link

# Interactive mode
ln -si /new/file /existing/link

# Backup before overwrite
ln -sb /new/file /existing/link
```

### Internals

**Hard Links**:
- A hard link creates a new directory entry pointing to the same inode.
- The file's data is shared — changes through either name are visible through the other.
- Hard links cannot cross filesystem boundaries (same device required).
- Hard links cannot link to directories (prevents cycles in the filesystem tree).
- The `link()` syscall is used.
- `ls -l` shows the link count in the second column. When it reaches zero (all names removed and no open file handles), the data is freed.

**Symbolic Links**:
- A symlink is a special file containing a pathname string.
- Created via `symlink()` syscall.
- The target can be any path (relative or absolute), even to a non-existent file (dangling symlink).
- Symlinks can cross filesystem boundaries.
- Symlinks can point to directories.
- `ls -l` shows `→ target_name`.
- Size of a symlink is the length of the target path string.

**Relative symlinks** (`ln -sr`): GNU `ln` can compute the relative path from the link location to the target using `realpath --relative-to`. This is essential for portable symlinks in source trees or mounted filesystems.

### Performance

- Creating links is O(1) — both `link()` and `symlink()` are constant-time operations.
- **Hard links**: No additional disk space (just a directory entry).
- **Symlinks**: Minimal space (the path string, typically < 4KB).
- **Following symlinks**: Each symlink resolution adds a small overhead. Deeply nested symlinks (chains of symlinks) can slow path resolution.

### Common Mistakes

1. **Symlink direction confusion**: `ln -s target link_name` — the first argument is the TARGET, the second is the LINK NAME. Easy to get backwards.

   ```bash
   # WRONG — creates a broken symlink
   ln -s /home/user/file /mnt/backup/file

   # This is correct — link points to target
   # The link (/mnt/backup/file) → points to target (/home/user/file)
   ```

2. **Relative symlinks with absolute paths**: If you move the directory containing a symlink, absolute symlinks break. Use `ln -sr` for portable relative links.

3. **Hard links to directories**: `ln dir link` fails (non-root). This is intentional to prevent filesystem cycles. Use symlinks for directories.

4. **`ln -s dir/ link`** vs **`ln -s dir link`**: The trailing slash on the target can matter. Without `-n`, creating a symlink where the link name already exists as a directory will place the link inside that directory.

### Best Practices

- Use symlinks by default; reserve hard links for specific needs (backup deduplication, keeping files alive after deletion).
- Use `ln -sr` for relative symlinks to improve portability.
- Check symlinks with `readlink -f` to resolve the full path.
- Use `find -type l` to locate symlinks, `find -xtype l` for broken symlinks.

### POSIX Compatibility

POSIX specifies `-s`, `-f`, `-i`. The `-r`, `-T`, `-n` options are GNU extensions.

### GNU vs BusyBox

- **GNU `ln`**: Full-featured with `-r` (relative), `-T`, `--backup`.
- **BusyBox `ln`**: Supports `-f`, `-i`, `-n`, `-s`, `-v`, `-d`. Missing: `-r` (relative symlinks). Approximately 3KB vs ~40KB for GNU.

---

## find — Search for Files in a Directory Hierarchy

### Purpose

`find` recursively searches directory trees for files matching criteria (name, type, size, time, permissions, etc.) and can execute actions on matches. It is one of the most powerful and flexible Unix utilities.

### Syntax

```
find [path...] [expression]
```

The expression consists of **tests** (selection criteria), **actions** (what to do with matches), **operators** (AND, OR, NOT), and **options** (global behavior modifiers).

### Key Tests (Selection Criteria)

| Test | Description |
|------|-------------|
| `-name PATTERN` | Base name matches shell pattern (case-sensitive) |
| `-iname PATTERN` | Case-insensitive name match |
| `-path PATTERN` | Full path matches pattern |
| `-regex PATTERN` | Full path matches regular expression |
| `-type TYPE` | File type: `f` (file), `d` (directory), `l` (symlink), `b` (block), `c` (char), `p` (pipe), `s` (socket) |
| `-size [+|-]n[cwbkMG]` | File size (c=bytes, w=words, k=KB, M=MB, G=GB) |
| `-mtime [+|-]n` | Modification time in days |
| `-atime [+|-]n` | Access time in days |
| `-ctime [+|-]n` | Status change time in days |
| `-mmin [+|-]n` | Modification time in minutes |
| `-newer FILE` | Modified more recently than FILE |
| `-perm MODE` | Permission mode (exact, - (all), or / (any)) |
| `-user USER` | Owned by USER |
| `-group GROUP` | Owned by GROUP |
| `-nouser` | No valid owner |
| `-nogroup` | No valid group |
| `-empty` | Empty file or directory |
| `-executable` | User has execute permission |
| `-readable` | User has read permission |
| `-writable` | User has write permission |
| `-maxdepth N` | Maximum directory depth |
| `-mindepth N` | Minimum directory depth |
| `-links N` | Hard link count |
| `-inum N` | Inode number |
| `-fstype TYPE` | Filesystem type |
| `-samefile FILE` | Same inode as FILE |
| `-used N` | Last access N days after status change |

### Key Actions

| Action | Description |
|--------|-------------|
| `-print` | Print path (default action) |
| `-print0` | Print path with null terminator (for `xargs -0`) |
| `-ls` | List with `ls -dils` format |
| `-delete` | Delete matched files |
| `-exec CMD {} \;` | Execute CMD for each match |
| `-exec CMD {} +` | Execute CMD with multiple matches as arguments |
| `-ok CMD {} \;` | Like `-exec` but prompts before each execution |
| `-execdir CMD {} \;` | Execute from the file's directory |
| `-printf FORMAT` | Print with format specifiers |
| `-quit` | Exit immediately after first match |

### Operators

| Operator | Description |
|----------|-------------|
| `-and` (implicit) | Logical AND (default between tests) |
| `-or` | Logical OR |
| `!` or `-not` | Logical NOT |
| `(...)` | Grouping (must be escaped in shell) |

### Examples

```bash
# Find files by name
find /etc -name "*.conf"

# Case-insensitive search
find /home -iname "*.jpg"

# Find by type and name
find /var -type f -name "*.log"

# Find by size (files larger than 100MB)
find / -type f -size +100M

# Find recently modified files (last 24 hours)
find /etc -type f -mtime -1

# Find by permission
find / -type f -perm 777

# Find files owned by a user
find /home -type f -user john

# Find and delete
find /tmp -type f -name "*.tmp" -mtime +7 -delete

# Find and execute command
find . -name "*.py" -exec grep -l "import os" {} +

# Find empty files
find /var -type f -empty

# Find broken symlinks
find /path -xtype l

# Find files modified between two dates
find /data -type f -newermt "2024-01-01" ! -newermt "2024-06-01"

# Find and rename (using -exec)
find . -name "*.jpeg" -exec bash -c 'mv "$1" "${1%.jpeg}.jpg"' _ {} \;

# Complex expression with grouping
find . \( -name "*.c" -o -name "*.h" \) -type f

# Find the newest file
find . -type f -printf '%T@ %p\n' | sort -n | tail -1

# Find duplicate files by size, then hash
find . -type f -exec md5sum {} + | sort | uniq -d -w 32

# Find and limit depth
find / -maxdepth 3 -name "config.ini"

# Find with format output
find . -type f -printf '%m %u %g %s %p\n'
```

### Internals

`find` uses a depth-first traversal of the directory tree:

1. **Directory traversal**: Uses `opendir()`/`readdir()`/`closedir()` to enumerate entries. On Linux, `openat()` and `getdents64()` are used for efficiency.
2. **Expression evaluation**: Tests are evaluated left-to-right with short-circuit evaluation (implicit AND). The evaluation is optimized — tests that don't require stat (like `-name`) are evaluated before those that do (like `-size`).
3. **Stat optimization**: GNU `find` caches `lstat()` results. Some tests (like `-name`) only need the directory entry (readdir), while others (like `-size`, `-mtime`) require a full stat.
4. **`-exec` vs `-execdir`**: `-exec` runs the command from the original working directory. `-execdir` changes to the directory containing the matched file before executing (more secure, avoids TOCTOU races).
5. **`-exec ... +`**: Collects multiple filenames and passes them as arguments to a single command invocation (like `xargs`). Much more efficient than `-exec ... \;` for large result sets.

### Performance

- **I/O bound**: `find` performance is dominated by disk I/O for `readdir()` and `lstat()` calls.
- **Ordering matters**: Place cheap tests (like `-name`) before expensive ones (like `-exec`) to filter early.
- **`-maxdepth`**: Significantly improves performance by pruning the traversal tree.
- **Parallel execution**: GNU `find` is single-threaded. For large trees, use `find ... | xargs -P4` for parallel processing, or use `fd` (a modern `find` alternative written in Rust).
- **Filesystem cache**: Repeated `find` runs are much faster due to the kernel's directory entry cache (dcache).

### Common Mistakes

1. **Forgetting `-print`**: When using actions like `-exec`, the default `-print` is suppressed. If you need both output and execution, add `-print`.

2. **`-exec` vs `-execdir` security**: Prefer `-execdir` in security-sensitive contexts to avoid symlink attacks.

3. **Quoting patterns**: `-name "*.txt"` needs quotes to prevent shell globbing before `find` processes it.

4. **`-mtime` sign confusion**:
   - `-mtime 0` = modified less than 24 hours ago (today)
   - `-mtime +7` = modified MORE than 7 days ago
   - `-mtime -7` = modified LESS than 7 days ago
   - `-mtime 7` = modified exactly 7*24 to 8*24 hours ago

5. **`-delete` and depth**: Always use `-depth` with `-delete` to ensure directories are emptied before removal:
   ```bash
   find /tmp -type d -empty -depth -delete
   ```

### Real-World Usage

```bash
# Find large files eating disk space
find / -type f -size +100M -exec ls -lh {} + 2>/dev/null | sort -k5 -h

# Find recently modified config files
find /etc -name "*.conf" -mtime -7 -ls

# Find world-writable files (security audit)
find / -xdev -type f -perm -0002 -ls

# Find SUID/SGID binaries
find / -xdev \( -perm -4000 -o -perm -2000 \) -type f -ls

# Find files accessed in the last hour
find /var/data -type f -amin -60

# Generate a file manifest
find /app -type f -printf '%s %p\n' | sort -rn > manifest.txt

# Find and compress old logs
find /var/log -name "*.log" -mtime +30 -exec gzip {} +

# Find duplicate filenames
find / -type f -printf '%f\n' | sort | uniq -d
```

### Best Practices

- Always quote patterns: `-name "*.txt"` not `-name *.txt`.
- Use `-print0 | xargs -0` for safe handling of filenames with spaces/special chars.
- Use `-exec +` instead of `-exec \;` when possible (fewer process forks).
- Use `-xdev` to stay on one filesystem (avoid network mounts, /proc, /sys).
- Place `-maxdepth` before other tests for efficiency.
- Use `-delete` with `-depth` for safe recursive deletion.

### POSIX Compatibility

POSIX `find` supports basic tests (`-name`, `-type`, `-size`, `-mtime`, `-user`, `-group`, `-perm`), actions (`-exec`, `-ok`, `-print`), and operators (`-a`, `-o`, `!`, `(`). Extensions: `-delete`, `-printf`, `-print0`, `-execdir`, `-maxdepth`, `-mindepth`, `-regex` are GNU/BSD extensions.

### GNU vs BusyBox

- **GNU `find`**: Full-featured with `-printf`, `-delete`, `-execdir`, `-regex`, `-samefile`, `-newerXY`, `-D debug`.
- **BusyBox `find`**: Supports core tests and actions. Has `-exec`, `-delete`, `-print0`. Missing many `-printf` format specifiers, `-execdir`, `-newerXY`. Approximately 15KB vs ~250KB for GNU.

---

## locate and updatedb — Find Files by Name Using a Database

### Purpose

`locate` searches a pre-built database of filenames for fast pattern matching. Unlike `find`, which traverses the filesystem each time, `locate` uses a database built by `updatedb`, making searches extremely fast but potentially showing stale results.

### Syntax

```
locate [OPTION]... PATTERN...
updatedb [OPTION]...
```

### Key Options — locate

| Option | Description |
|--------|-------------|
| `-i` | Case-insensitive search |
| `-r` | Use basic regular expressions |
| `--regex` | Use extended regular expressions |
| `-c` | Count matches instead of listing |
| `-l N` | Limit output to N entries |
| `-b` | Match only the base name (not the full path) |
| `-e` | Only show entries that still exist |
| `-S` | Print database statistics |
| `-d DB` | Use alternative database |

### Key Options — updatedb

| Option | Description |
|--------|-------------|
| `-o FILE` | Output database to FILE |
| `-U PATH` | Only index PATH |
| `-e PATHs` | Exclude paths (comma-separated) |
| `--prunepaths` | Paths to exclude |
| `--prunefs` | Filesystem types to exclude |

### Examples

```bash
# Search for a file by name
locate nginx.conf

# Case-insensitive search
find -i readme.md

# Use regex
locate -r '\.conf$'

# Count matches
locate -c "*.jpg"

# Limit results
locate -l 10 "*.log"

# Match base name only
locate -b "passwd"

# Only show existing files
locate -e "important.dat"

# Check database info
locate -S

# Update the database (usually run via cron)
sudo updatedb

# Update with custom exclusions
sudo updatedb --prunepaths="/tmp /var/tmp /proc /sys"
```

### Internals

**Database format**: GNU `locate` uses a compressed database format. Filenames are stored sorted and with common prefixes compressed (similar to front-coding). The database typically compresses to 30-50% of the total size of indexed pathnames.

**`updatedb` process**:
1. Traverses the entire filesystem from `/`
2. Skips excluded paths (defined in `/etc/updatedb.conf` or command-line)
3. Skips excluded filesystem types (proc, sysfs, tmpfs, etc.)
4. Writes all filenames to a sorted, compressed database (usually `/var/lib/mlocate/mlocate.db`)
5. Database is typically updated daily via cron (`/etc/cron.daily/mlocate`)

**Search algorithm**: `locate` reads the compressed database and performs a binary search or scan for matching patterns. For simple patterns (no regex), it uses the sorted nature of the database for efficient prefix matching.

**Security**: On modern systems, `locate` (specifically `mlocate`) only shows files the current user has permission to see. The database is readable only by the `mlocate` group.

### Performance

- **locate vs find**: `locate` is 100-1000x faster for name searches because it searches a pre-built index rather than traversing the filesystem.
- **Database size**: On a typical system, the `mlocate` database is 10-100MB, depending on the number of indexed files.
- **updatedb**: Can take several minutes on systems with millions of files or slow storage.
- **Memory**: `locate` loads the database index into memory for searching.

### Common Mistakes

1. **Stale results**: `locate` shows files from the last database update. Recently created or deleted files won't appear. Run `sudo updatedb` for fresh results.

2. **Missing files**: If files are on excluded paths or filesystems, `locate` won't find them. Check `/etc/updatedb.conf` for exclusion rules.

3. **Permission errors**: Non-root users may not see all files due to `mlocate` permission restrictions.

4. **Confusing `locate` with `find`**: Use `locate` for quick name lookups; use `find` for complex criteria (size, time, permissions, actions).

### Best Practices

- Run `updatedb` before using `locate` if you need fresh results.
- Use `locate -e` to filter out files that have been deleted since the last update.
- For interactive use, `locate` is ideal for finding files when you know part of the name.
- For scripting, prefer `find` because it provides real-time results.

### POSIX Compatibility

`locate` and `updatedb` are not part of POSIX. They are de facto standard utilities available on virtually all Linux distributions. The implementation varies: GNU `locate` (part of `findutils`), `mlocate` (used by most modern distros, with permission-awareness), and `plocate` (a faster replacement).

### GNU vs BusyBox

- **GNU `locate`**: Full-featured with regex, database stats, alternative databases.
- **BusyBox `locate`**: Basic pattern matching with glob support. Limited options. Approximately 5KB vs ~80KB for GNU. Some BusyBox builds omit `locate` entirely.

---

## Summary

The file operations covered in this chapter are fundamental to every aspect of Linux system administration:

| Tool | Primary Use | Speed | Recoverable |
|------|------------|-------|-------------|
| `ls` | List directory contents | Fast | N/A |
| `cp` | Copy files/directories | I/O bound | N/A |
| `mv` | Move/rename files | Fast (same FS) / I/O bound (cross FS) | No (without backups) |
| `rm` | Delete files | Fast | No |
| `ln` | Create links | Fast | N/A |
| `find` | Search filesystem | I/O bound | N/A |
| `locate` | Fast name search (indexed) | Very fast | N/A |

### Quick Reference

```bash
# List files with details
ls -lah

# Copy with preservation
cp -a source/ dest/

# Move atomically (same filesystem)
mv old new

# Remove safely
rm -ri directory/

# Create symbolic link
ln -s target link_name

# Find files by criteria
find /path -name "*.log" -mtime -7 -exec rm {} +

# Quick file search
locate filename
```
