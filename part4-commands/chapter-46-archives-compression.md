# Chapter 46: Archives and Compression — tar, gzip, bzip2, xz, zstd, zip, unzip, 7z, cpio

## Overview

Archives and compression are fundamental to Linux system administration, software distribution, backups, and data management. Understanding the difference between **archiving** (combining multiple files into one) and **compression** (reducing file size) is essential — `tar` archives, while `gzip`, `bzip2`, `xz`, and `zstd` compress.

This chapter covers the complete toolkit for creating, extracting, and managing compressed archives on Linux.

---

## tar — Tape Archive

### Purpose

`tar` (Tape ARchive) is the standard Unix archiving utility. It combines multiple files and directories into a single archive file, optionally with compression. It preserves file permissions, ownership, timestamps, and directory structure.

### Syntax

```
tar [OPTION...] [FILE]...
```

### Operation Modes

| Flag | Description |
|------|-------------|
| `-c` | Create archive |
| `-x` | Extract archive |
| `-t` | List archive contents |
| `-r` | Append files to archive |
| `-u` | Append only newer files |
| `-d` | Compare archive with filesystem |
| `-A` | Append one archive to another |
| `--delete` | Delete from archive |

### Key Options

| Option | Description |
|--------|-------------|
| `-f FILE` | Use archive FILE |
| `-v` | Verbose output |
| `-z` | Compress/decompress with gzip |
| `-j` | Compress/decompress with bzip2 |
| `-J` | Compress/decompress with xz |
| `--zstd` | Compress/decompress with zstd |
| `-a` | Determine compression from suffix |
| `-C DIR` | Change to DIR before processing |
| `-p` | Preserve permissions |
| `--same-owner` | Preserve ownership (default for root) |
| `--no-same-owner` | Don't preserve ownership |
| `--same-permissions` | Same as `-p` |
| `-h` | Follow symlinks |
| `--exclude=PATTERN` | Exclude files matching PATTERN |
| `--exclude-from=FILE` | Read exclude patterns from FILE |
| `--include=PATTERN` | Include files matching PATTERN |
| `--strip-components=N` | Strip N leading path components |
| `--transform=EXPR` | Transform filenames with sed expression |
| `--absolute-names` | Don't strip leading `/` |
| `--recursion` | Recurse into directories (default) |
| `--no-recursion` | Don't recurse |
| `-T FILE` | Read names from FILE |
| `--null` | Null-delimited input (with `-T`) |
| `--one-file-system` | Stay on one filesystem |
| `--checkpoint[=N]` | Display progress every N records |
| `--totals` | Print total bytes written |
| `--verify` | Verify archive after writing |
| `-W` | Attempt to verify the archive after writing |
| `--remove-files` | Remove files after adding to archive |
| `--keep-newer-files` | Don't replace files that are newer |
| `--keep-old-files` | Don't overwrite existing files |
| `--overwrite` | Overwrite existing files (default) |
| `--skip-old-files` | Don't replace existing files |
| `--occurrence[=N]` | Process only Nth occurrence of each file |
| `--sort=ORDER` | Sort directory entries (ORDER: none, name, inode) |
| `--mtime=DATE` | Set modification time of added files |
| `--numeric-owner` | Always use numeric owner/group values |
| `--owner=NAME` | Set owner of added files |
| `--group=NAME` | Set group of added files |
| `--mode=MODE` | Set permissions of added files |

### Examples

```bash
# Create uncompressed archive
tar cf archive.tar file1 file2 dir/

# Create gzip-compressed archive
tar czf archive.tar.gz dir/

# Create bzip2-compressed archive
tar cjf archive.tar.bz2 dir/

# Create xz-compressed archive
tar cJf archive.tar.xz dir/

# Create zstd-compressed archive
tar --zstd -cf archive.tar.zst dir/

# Auto-detect compression from suffix
tar caf archive.tar.gz dir/

# Extract archive
tar xf archive.tar.gz

# Extract to specific directory
tar xf archive.tar.gz -C /destination/

# Extract specific files
tar xf archive.tar.gz file1 file2

# List archive contents
tar tf archive.tar.gz

# List with details
tar tvf archive.tar.gz

# Exclude patterns
tar czf backup.tar.gz --exclude='*.log' --exclude='.git' /project/

# Exclude from file
tar czf backup.tar.gz --exclude-from=exclude.txt /project/

# Strip leading path components
tar xf archive.tar.gz --strip-components=2

# Transform filenames
tar czf archive.tar.gz --transform='s|^|prefix/|' file.txt

# Preserve permissions (important for backups)
tar czpf backup.tar.gz /etc/

# Verify after writing
tar czWf backup.tar.gz /etc/

# Create from file list
find . -name "*.py" > filelist.txt
tar czf sources.tar.gz -T filelist.txt

# Null-delimited file list (safe for spaces)
find . -name "*.py" -print0 | tar czf sources.tar.gz --null -T -

# Progress indicator
tar czf backup.tar.gz --checkpoint=1000 --totals /data/

# One filesystem only
tar czf backup.tar.gz --one-file-system /

# Numeric owner (for portability)
tar czpf backup.tar.gz --numeric-owner /etc/

# Remove files after archiving
tar czf archive.tar.gz --remove-files old_files/

# Append to archive (uncompressed only, or with --concatenate)
tar rf archive.tar newfile.txt

# Compare archive with filesystem
tar df backup.tar.gz

# Extract only newer files
tar xf backup.tar.gz --keep-newer-files

# Create reproducible archive (sorted, deterministic)
tar --sort=name --mtime='2024-01-01' --owner=0 --group=0 --numeric-owner \
    -cf reproducible.tar.zst --zstd dir/
```

### Tar and Compression Pipelines

```bash
# Equivalent to tar czf (but allows custom compression)
tar cf - dir/ | gzip > archive.tar.gz

# With pigz (parallel gzip)
tar cf - dir/ | pigz > archive.tar.gz

# With custom compression level
tar cf - dir/ | gzip -9 > archive.tar.gz

# With zstd
tar cf - dir/ | zstd -T0 > archive.tar.zst

# With lz4 (fast compression)
tar cf - dir/ | lz4 > archive.tar.lz4

# Extract from pipeline
zcat archive.tar.gz | tar xf -
```

### Internals

`tar` uses the POSIX.1-1988 (ustar) or POSIX.1-2001 (pax) archive format:

1. **Archive structure**: 512-byte header blocks containing metadata (name, mode, uid, gid, size, mtime, checksum, typeflag, linkname), followed by data blocks padded to 512 bytes.
2. **Long filenames**: Stored using `././@LongLink` extension entries (GNU tar) or pax extended headers.
3. **Compression**: tar itself doesn't compress. Compression is applied as a filter (gzip, bzip2, xz, zstd) to the archive stream.
4. **Incremental backups**: GNU tar supports `--listed-incremental` for level-based incremental backups using a snapshot file.

### Performance

| Compression | Ratio | Speed (Compress) | Speed (Decompress) |
|-------------|-------|-------------------|---------------------|
| None | 1.0x | Very fast | Very fast |
| gzip | Good | Fast | Fast |
| bzip2 | Better | Slow | Medium |
| xz | Best | Very slow | Medium |
| zstd | Very good | Fast | Very fast |
| lz4 | Fair | Very fast | Very fast |

### Common Mistakes

1. **Forgetting `-f`**: `tar cz archive.tar.gz dir` won't work. The `-f` must immediately precede the filename. `tar czf archive.tar.gz dir/` is correct.

2. **Extracting as root**: `tar xpf` as root preserves ownership from the archive, which could be dangerous (malicious archives may set ownership to root).

3. **`-z` for gzip only**: Don't use `-z` for bzip2 (`-j`) or xz (`-J`). Use `-a` for auto-detection.

4. **Absolute paths**: By default, GNU tar strips leading `/` during extraction (with a warning). Use `--absolute-names` to preserve them.

5. **Trailing slashes**: `tar czf a.tar.gz dir/` includes the contents of `dir/`. `tar czf a.tar.gz dir` includes the `dir` directory entry plus its contents. Both are usually equivalent for extraction.

### POSIX Compatibility

POSIX.1-2001 (pax) defines the tar format. GNU tar supports ustar (POSIX.1-1988), oldgnu, posix (pax), and v7 formats. Options `-c`, `-r`, `-t`, `-u`, `-x`, `-f`, `-p`, `-v` are POSIX. Compression flags (`-z`, `-j`, `-J`) are extensions.

### GNU vs BusyBox

- **GNU `tar`**: Full-featured with all options above, incremental backups, `--transform`, `--sort`, `--zstd`, `--checkpoint`, tape device support.
- **BusyBox `tar`**: Supports `-c`, `-x`, `-t`, `-f`, `-v`, `-z`, `-j`, `-J`, `-p`, `--exclude`, `--strip-components`, `--numeric-owner`. Missing: `--transform`, `--sort`, `--checkpoint`, `--remove-files`, `--zstd`, incremental backups. Approximately 20KB vs ~500KB for GNU.

---

## gzip / gunzip / zcat — Compress or Expand Files

### Purpose

`gzip` compresses files using the DEFLATE algorithm (LZ77 + Huffman coding). It's the most widely used compression format on Linux.

### Key Options

| Option | Description |
|--------|-------------|
| `-1` to `-9` | Compression level (1=fast, 9=best, default=6) |
| `-d` | Decompress |
| `-k` | Keep original file |
| `-f` | Force overwrite |
| `-r` | Recursive |
| `-v` | Verbose |
| `-l` | List compressed file info |
| `-t` | Test integrity |
| `-c` | Write to stdout |
| `-n` | Save/restore original name and timestamp |
| `-S SUFFIX` | Use SUFFIX instead of `.gz` |

### Examples

```bash
# Compress a file
gzip file.txt                # Creates file.txt.gz, removes original

# Decompress
gunzip file.txt.gz           # Creates file.txt, removes .gz

# Keep original
gzip -k file.txt

# Compress to stdout
gzip -c file.txt > file.txt.gz

# Decompress to stdout
gzip -dc file.txt.gz > file.txt

# Specific compression level
gzip -9 file.txt             # Best compression
gzip -1 file.txt             # Fastest

# List info
gzip -l file.txt.gz

# Test integrity
gzip -t file.txt.gz

# View compressed file
zcat file.txt.gz

# Search compressed file
zgrep "pattern" file.txt.gz

# Recursive compression
gzip -r /directory/

# Decompress all .gz files
gunzip *.gz
```

### Internals

`gzip` uses the DEFLATE algorithm:
1. **LZ77**: Finds repeated strings and replaces them with back-references.
2. **Huffman coding**: Encodes literals and lengths using variable-length codes.
3. **Window size**: 32KB sliding window for LZ77 matching.

**File format**: gzip files have a 10-byte header, optional extra fields, original filename, comment, CRC-16 header checksum, compressed data, CRC-32 data checksum, and original size.

### Performance

- **Compression ratio**: Typically 60-70% for text files.
- **Speed**: Fast compression and decompression. At level 6 (default), ~100-300 MB/s compression, ~400-800 MB/s decompression.
- **Memory**: Uses 256KB at level 1, 4MB at level 9.

---

## bzip2 / bunzip2 / bzcat — Compress or Expand Files

### Purpose

`bzip2` uses the Burrows-Wheeler Transform (BWT) and Huffman coding for better compression ratios than gzip, at the cost of slower speed.

### Key Options

| Option | Description |
|--------|-------------|
| `-1` to `-9` | Block size (100KB to 900KB, default=9) |
| `-d` | Decompress |
| `-k` | Keep original |
| `-f` | Force |
| `-v` | Verbose |
| `-t` | Test |
| `-c` | Write to stdout |
| `-s` | Small memory mode (slower) |

### Examples

```bash
# Compress
bzip2 file.txt

# Decompress
bunzip2 file.txt.bz2

# Keep original
bzip2 -k file.txt

# Best compression
bzip2 -9 file.txt

# View compressed file
bzcat file.txt.bz2

# Test integrity
bzip2 -t file.txt.bz2
```

### Performance

- **Compression ratio**: ~10-15% better than gzip.
- **Speed**: Significantly slower than gzip (3-10x slower compression).
- **Memory**: Uses 100KB-900KB (depending on block size) for compression, 100KB-900KB for decompression.

---

## xz / unxz / xzcat — Compress or Expand Files

### Purpose

`xz` uses LZMA/LZMA2 compression for the best compression ratios among standard Linux compression tools.

### Key Options

| Option | Description |
|--------|-------------|
| `-0` to `-9` | Compression level (0=fastest, 9=best, default=6) |
| `-e` | Extreme compression (slower, slightly better ratio) |
| `-d` | Decompress |
| `-k` | Keep original |
| `-f` | Force |
| `-v` | Verbose |
| `-t` | Test |
| `-c` | Write to stdout |
| `-T N` | Number of threads (0=auto) |
| `-M SIZE` | Memory usage limit |
| `--format=FORMAT` | xz, lzma, or raw |
| `--check=TYPE` | Integrity check (crc32, crc64, sha256) |

### Examples

```bash
# Compress
xz file.txt

# Decompress
unxz file.txt.xz

# Keep original
xz -k file.txt

# Best compression
xz -9e file.txt

# Multi-threaded
xz -T0 file.txt

# View compressed file
xzcat file.txt.xz

# Test integrity
xz -t file.txt.xz

# Set memory limit
xz -M 512MiB file.txt

# Decompress to stdout
xz -dc file.txt.xz > file.txt
```

### Performance

- **Compression ratio**: ~30-50% better than gzip, ~15-30% better than bzip2.
- **Speed**: Slow compression, medium decompression.
- **Memory**: Uses 10MB-100MB+ for compression (level-dependent), 1-10MB for decompression.

---

## zstd — Zstandard Compression

### Purpose

`zstd` (Zstandard) provides excellent compression ratios with very fast compression and decompression speeds. It's increasingly the preferred compression tool on modern Linux systems.

### Key Options

| Option | Description |
|--------|-------------|
| `-1` to `-19` | Compression level (default=3) |
| `--ultra` | Levels 20-22 (high memory usage) |
| `-d` | Decompress |
| `-k` | Keep original |
| `-f` | Force |
| `-v` | Verbose |
| `-t` | Test |
| `-c` | Write to stdout |
| `-T N` | Number of threads (0=auto) |
| `-o FILE` | Output file |
| `--adapt` | Adaptive compression level |
| `--long[=N]` | Enable long-distance matching |
| `--rsyncable` | Make output rsync-friendly |
| `-M SIZE` | Memory usage limit |
| `--format=FORMAT` | zstd, gzip, xz, lzma, lz4 |

### Examples

```bash
# Compress
zstd file.txt

# Decompress
unzstd file.txt.zst

# Keep original
zstd -k file.txt

# High compression
zstd -19 file.txt

# Fast compression
zstd -1 file.txt

# Multi-threaded
zstd -T0 file.txt

# Best compression (ultra)
zstd --ultra -22 file.txt

# Decompress to stdout
zstd -dc file.txt.zst

# Test integrity
zstd -t file.txt.zst

# Adaptive compression
zstd --adapt file.txt

# Rsync-friendly
zstd --rsyncable file.txt

# With tar
tar --zstd -cf archive.tar.zst dir/

# Pipe usage
cat file.txt | zstd > file.txt.zst
zstd -dc file.txt.zst | cat
```

### Performance

- **Compression ratio**: Comparable to zlib level 9 at zstd level 3, with much faster speed.
- **Speed**: At equivalent compression ratios, zstd is 2-5x faster than gzip for both compression and decompression.
- **Memory**: Configurable from 1MB to 4GB+.
- **Parallel**: Built-in multi-threaded compression.

---

## zip / unzip — Package and Compress Files

### Purpose

`zip` creates ZIP archives (compatible with Windows/macOS). `unzip` extracts them. The ZIP format is essential for cross-platform file exchange.

### Key Options — zip

| Option | Description |
|--------|-------------|
| `-r` | Recursive |
| `-1` to `-9` | Compression level |
| `-e` | Encrypt (password-protected) |
| `-P PASSWORD` | Set password |
| `-x PATTERN` | Exclude files |
| `-i PATTERN` | Include files |
| `-q` | Quiet |
| `-v` | Verbose |
| `-u` | Update (add newer files) |
| `-f` | Freshen (update only) |
| `-j` | Store only filenames (strip path) |
| `-0` | Store only (no compression) |
| `-Z METHOD` | Compression method (deflate, bzip2, lzma, zstd) |

### Examples

```bash
# Create ZIP archive
zip archive.zip file1 file2

# Recursive
zip -r archive.zip directory/

# Password-protected
zip -e archive.zip file.txt

# Exclude patterns
zip -r archive.zip dir/ -x "*.log" "*.tmp"

# Compression level
zip -9 archive.zip file.txt

# Update existing archive
zip -u archive.zip newfile.txt

# Strip path
zip -j archive.zip /path/to/file.txt

# Extract
unzip archive.zip

# Extract to directory
unzip archive.zip -d /destination/

# List contents
unzip -l archive.zip

# Extract specific files
unzip archive.zip file1 file2

# Test integrity
unzip -t archive.zip
```

### Performance

- **Compression ratio**: Similar to gzip (deflate algorithm).
- **Speed**: Fast compression and decompression.
- **Limitation**: ZIP format has limitations on filename length (260 chars), file size (4GB for ZIP32, 16 EB for ZIP64), and doesn't preserve Unix permissions well.

---

## 7z — 7-Zip Archiver

### Purpose

`7z` is a high-compression archiver supporting multiple compression formats (LZMA, LZMA2, PPMd, BZip2) and encryption (AES-256).

### Key Options

| Option | Description |
|--------|-------------|
| `a` | Add to archive |
| `x` | Extract with full paths |
| `e` | Extract without paths |
| `l` | List contents |
| `t` | Test integrity |
| `d` | Delete from archive |
| `-tTYPE` | Archive type (7z, zip, gzip, bzip2, xz, tar) |
| `-m METHOD` | Compression method |
| `-mx=N` | Compression level (0-9) |
| `-pPASSWORD` | Set password |
| `-mhe=on` | Encrypt headers (hide filenames) |
| `-v SIZE` | Split archive into volumes |

### Examples

```bash
# Create 7z archive
7z a archive.7z directory/

# Extract
7z x archive.7z

# List contents
7z l archive.7z

# Test integrity
7z t archive.7z

# Password-protected with encrypted headers
7z a -p"password" -mhe=on archive.7z directory/

# Best compression
7z a -mx=9 archive.7z directory/

# Split into volumes
7z a -v100m archive.7z largefile/

# Create ZIP with 7z
7z a -tzip archive.zip directory/
```

---

## cpio — Copy File Archives In and Out

### Purpose

`cpio` copies files to and from archives. It's used by RPM packages, initramfs images, and is the backend for `find ... | cpio` pipelines.

### Syntax

```
cpio {-o|--create} [-0acvABLV] [-C bytes] [-H format] [-M message] [-O [[user@]host:]archive] [-F [[user@]host:]archive] [--file=[[user@]host:]archive] [--format=format] [--message=message] [--null] [--reset-access-time] [--verbose] [--dot] [--append] [--block-size=blocks] [--dereference] [--io-size=bytes] [--rsh-command=command] [--owner=[user][:.][group]] [--no-preserve-owner] [--sparse] [--force-local] [--help] [--version] < name-list [> archive]

cpio {-i|--extract} [-bcdfmnrtsuvBSV] [-C bytes] [-E file] [-H format] [-M message] [-R [user][:.][group]] [-I [[user@]host:]archive] [-F [[user@]host:]archive] [--file=[[user@]host:]archive] [--make-directories] [--nonmatching] [--preserve-modification-time] [--numeric-uid-gid] [--rename] [--list] [--reset-access-time] [--verbose] [--dot] [--pattern-file=file] [--owner=[user][:.][group]] [--no-preserve-owner] [--sparse] [--only-verify-crc] [--to-stdout] [--force-local] [--no-absolute-filenames] [--absolute-filenames] [--block-size=blocks] [--swap-bytes] [--swap-halfwords] [--io-size=bytes] [--rsh-command=command] [--restrict] [--insecure] [--secure] [--help] [--version] [pattern...] [< archive]

cpio {-p|--pass-through} [-0adlmuvLV] [-R [user][:.][group]] [--null] [--reset-access-time] [--make-directories] [--link] [--preserve-modification-time] [--preserve-owner] [--sparse] [--absolute-filenames] [--unconditional] [--verbose] [--dot] [--dereference] [--owner=[user][:.][group]] [--no-preserve-owner] [--rsh-command=command] [--help] [--version] destination-directory < name-list
```

### Examples

```bash
# Create archive from file list
find . -type f | cpio -o > archive.cpio

# Create with null-delimited input
find . -type f -print0 | cpio -o0 > archive.cpio

# Extract archive
cpio -id < archive.cpio

# List contents
cpio -t < archive.cpio

# Extract to stdout
cpio -id --to-stdout < archive.cpio

# Copy directory tree
find /source -depth | cpio -pdm /destination/

# Create initramfs
find . | cpio -o -H newc | gzip > initramfs.gz

# Extract RPM contents
rpm2cpio package.rpm | cpio -idmv
```

---

## Summary

### Compression Tool Comparison

| Tool | Ratio | Compress Speed | Decompress Speed | Use Case |
|------|-------|---------------|-------------------|----------|
| gzip | Good | Fast | Fast | General purpose, widest compatibility |
| bzip2 | Better | Slow | Medium | When ratio matters more than speed |
| xz | Best | Very slow | Medium | Distribution packages, long-term storage |
| zstd | Very good | Fast | Very fast | Modern systems, frequent compression/decompression |
| lz4 | Fair | Very fast | Very fast | Real-time, temporary files |
| zip | Good | Fast | Fast | Cross-platform compatibility |
| 7z | Best | Slow | Medium | Maximum compression, encryption |

### Quick Reference

```bash
# Create compressed archive
tar czf archive.tar.gz dir/          # gzip
tar cjf archive.tar.bz2 dir/         # bzip2
tar cJf archive.tar.xz dir/          # xz
tar --zstd -cf archive.tar.zst dir/  # zstd

# Extract compressed archive
tar xf archive.tar.gz                # Auto-detect
tar xf archive.tar.gz -C /dest/      # To directory

# List contents
tar tf archive.tar.gz

# Single file compression
gzip file.txt                         # Compress
gunzip file.txt.gz                    # Decompress
zstd file.txt                         # Compress
unzstd file.txt.zst                   # Decompress

# Cross-platform
zip -r archive.zip dir/               # Create
unzip archive.zip                     # Extract
```
