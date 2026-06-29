# Chapter 45: Permissions — chmod, chown, chgrp, umask, getfacl, setfacl

## Overview

Linux permissions control who can access files and directories, and what operations they can perform. The permission system is fundamental to Linux security — it prevents unauthorized access, protects system integrity, and enables multi-user operation.

Linux has two permission systems:

1. **Traditional Unix permissions** (owner/group/other with read/write/execute)
2. **Access Control Lists (ACLs)** — an extension that provides fine-grained per-user and per-group permissions

This chapter covers the tools that manage both systems: `chmod`, `chown`, `chgrp`, `umask`, `getfacl`, and `setfacl`.

---

## Permission Fundamentals

### Traditional Unix Permissions

Every file and directory has three permission sets, each for a different category of user:

```
-rwxr-xr-- 1 user group 4096 Jan 15 10:30 file.txt
│├─┤├─┤├─┤
│ │   │  │
│ │   │  └── Other permissions (everyone else)
│ │   └───── Group permissions
│ └───────── Owner permissions
└─────────── File type (- regular, d directory, l symlink, etc.)
```

**Permission meanings:**

| Permission | On Files | On Directories |
|-----------|----------|----------------|
| `r` (read) | Can read file contents | Can list directory contents |
| `w` (write) | Can modify file contents | Can create/delete files in directory |
| `x` (execute) | Can run as program | Can enter (cd into) the directory |
| `s` (setuid/setgid) | Run with owner's/group's privileges | Files created inherit group |
| `t` (sticky) | — | Only owner can delete files in directory |
| `-` | Permission denied | Permission denied |

**Octal representation:**

| Octal | Binary | Permissions |
|-------|--------|-------------|
| 0 | 000 | `---` |
| 1 | 001 | `--x` |
| 2 | 010 | `-w-` |
| 3 | 011 | `-wx` |
| 4 | 100 | `r--` |
| 5 | 101 | `r-x` |
| 6 | 110 | `rw-` |
| 7 | 111 | `rwx` |

A permission string like `rwxr-xr--` is represented as `754` in octal.

**Special permission bits:**

| Bit | Octal | On Executables | On Directories |
|-----|-------|----------------|----------------|
| Setuid | 4000 | Run with file owner's UID | — |
| Setgid | 2000 | Run with file's group GID | New files inherit directory's group |
| Sticky | 1000 | — | Only file owner can delete files |

### How Permission Checking Works

When a process tries to access a file, the kernel checks permissions in order:

1. If the process UID matches the file's UID → **owner** permissions apply
2. If the process GID (or any supplementary group) matches the file's GID → **group** permissions apply
3. Otherwise → **other** permissions apply

**Important**: Only the first matching set is used. If you're the owner, group permissions don't matter (even if they're more permissive).

For directories, execute (`x`) permission means "can enter the directory." Without `x` on a directory, you can't access any file inside it, regardless of the file's own permissions.

---

## chmod — Change File Permissions

### Purpose

`chmod` changes the file mode bits (permissions) of files and directories.

### Syntax

```
chmod [OPTION]... MODE[,MODE]... FILE...
chmod [OPTION]... OCTAL-MODE FILE...
chmod [OPTION]... --reference=RFILE FILE...
```

### Symbolic Mode

Format: `[ugoa...][[+-=][perms...]...]`

| Character | Meaning |
|-----------|---------|
| `u` | User (owner) |
| `g` | Group |
| `o` | Others |
| `a` | All (equivalent to `ugo`) |
| `+` | Add permission |
| `-` | Remove permission |
| `=` | Set exact permission |
| `r` | Read |
| `w` | Write |
| `x` | Execute |
| `X` | Execute only if directory or already has execute |
| `s` | Setuid/setgid |
| `t` | Sticky bit |
| `u+x` | Add execute for owner |
| `g-w` | Remove write for group |
| `o=r` | Set other to read-only |
| `a+r` | Add read for all |
| `ug+rw` | Add read+write for owner and group |

### Octal Mode

| Mode | Description |
|------|-------------|
| `755` | rwxr-xr-x (standard for executables/directories) |
| `644` | rw-r--r-- (standard for files) |
| `700` | rwx------ (private directory) |
| `600` | rw------- (private file) |
| `777` | rwxrwxr-x (world-writable, dangerous) |
| `000` | --------- (no permissions) |
| `4755` | rwsr-xr-x (setuid executable) |
| `2755` | rwxr-sr-x (setgid executable) |
| `1777` | rwxrwxrwt (sticky directory, like /tmp) |

### Key Options

| Option | Description |
|--------|-------------|
| `-R` | Recursive |
| `-v` | Verbose (describe every change) |
| `-c` | Verbose (only report changes) |
| `-f` | Suppress error messages |
| `--preserve-root` | Don't operate on `/` (default) |
| `--reference=RFILE` | Use RFILE's mode |

### Examples

```bash
# Symbolic modes
chmod u+x script.sh          # Add execute for owner
chmod g-w file.txt            # Remove write for group
chmod o=r file.txt            # Set other to read-only
chmod a+r file.txt            # Add read for all
chmod ug+rw,o-rwx file.txt    # Owner/group: rw, other: none
chmod u=rwx,g=rx,o=r file.txt # Explicit setting

# Octal modes
chmod 755 script.sh           # rwxr-xr-x
chmod 644 config.txt          # rw-r--r--
chmod 700 ~/.ssh              # rwx------ (private directory)
chmod 600 ~/.ssh/id_rsa       # rw------- (private key)

# Special permissions
chmod u+s /usr/bin/program    # Setuid
chmod g+s /shared/directory   # Setgid (new files inherit group)
chmod +t /tmp                 # Sticky bit
chmod 4755 /usr/bin/sudo      # Setuid with 755
chmod 2755 /shared/dir        # Setgid with 755
chmod 1777 /tmp               # Sticky with 777

# Recursive
chmod -R 755 /var/www/html/
chmod -R u+rwX,go+rX,go-w /var/www/html/  # Directories get +x, files get +x only if already executable

# Using reference file
chmod --reference=template.txt target.txt

# Verbose output
chmod -v 644 *.txt

# Only report changes
chmod -c 644 *.txt

# X (execute only for directories or already-executable files)
chmod -R a+X /project/        # Directories get +x, files keep their current execute state

# Multiple modes
chmod u+rwx,g+rx,o+r file    # Combine multiple changes

# Remove all permissions
chmod 000 private_file

# Set permissions with umask consideration
chmod $(printf '%04o' $((0777 & ~$(printf '%04o' 0022)))) file
```

### Internals

`chmod` uses the `chmod()` syscall (or `fchmodat()` for relative paths):

1. `stat()` the file to check current permissions (optional, for verbose output).
2. Compute the new mode based on the specified mode expression.
3. Call `chmod()` syscall with the new mode.

**Permission computation**: The kernel applies the mode change to the file's current mode:
- `+` adds bits (OR)
- `-` removes bits (AND NOT)
- `=` sets exact bits

**Restrictions**: Non-root users cannot set the setuid or setgid bits on files they don't own. The sticky bit can only be set by the directory owner or root.

### Common Mistakes

1. **`chmod 777`**: Makes files world-writable. This is almost never appropriate and is a security risk. Use `755` for directories and executables, `644` for regular files.

2. **`chmod -R 777 /`**: Recursively makes the entire filesystem world-writable. This will break the system.

3. **Forgetting `-R` on directories**: `chmod 755 /var/www` only changes the directory itself, not its contents. Use `chmod -R` for recursive changes.

4. **Using octal on symlinks**: `chmod` on symlinks follows the symlink by default (changes the target). On Linux, `chmod` always follows symlinks.

5. **X vs x**: `chmod a+X file` only adds execute if the file is a directory or already has execute for some user. `chmod a+x file` always adds execute. Using `X` in recursive operations prevents accidentally making all files executable.

6. **Not preserving setuid/setgid**: `chmod 755 setuid-file` removes the setuid bit. Use `chmod u+s` or `chmod 4755` to preserve it.

### Best Practices

- Use `755` for directories and executables.
- Use `644` for regular files.
- Use `700` for private directories (home, `.ssh`).
- Use `600` for private files (keys, credentials).
- Use `a+X` (capital X) in recursive operations to avoid making non-executable files executable.
- Never use `777` — if you need group write, use `775` with proper group ownership.
- Use `chmod -c` for scripting (only reports changes).

### POSIX Compatibility

POSIX specifies `chmod` with symbolic and octal modes, `-R`, and `--`. The `-v`, `-c`, `-f`, `--reference`, `--preserve-root` options are extensions.

### GNU vs BusyBox

- **GNU `chmod`**: Full-featured with `-v`, `-c`, `--reference`, `--preserve-root`, `--recursive`.
- **BusyBox `chmod`**: Supports `-R`, `-v`, `-c`, `-f`. Handles symbolic and octal modes. Approximately 4KB vs ~80KB for GNU.

---

## chown — Change File Owner and Group

### Purpose

`chown` changes the user and/or group ownership of files and directories.

### Syntax

```
chown [OPTION]... [OWNER][:[GROUP]] FILE...
chown [OPTION]... --reference=RFILE FILE...
```

### Key Options

| Option | Description |
|--------|-------------|
| `-R` | Recursive |
| `-c` | Verbose (only report changes) |
| `-v` | Verbose (describe every change) |
| `-f` | Suppress error messages |
| `-h` | Don't follow symlinks (change symlink itself) |
| `--dereference` | Follow symlinks (default) |
| `--preserve-root` | Don't operate on `/` |
| `--reference=RFILE` | Use RFILE's owner and group |
| `--from=CURRENT_OWNER:CURRENT_GROUP` | Only change if current owner/group matches |

### Owner:Group Syntax

| Syntax | Meaning |
|--------|---------|
| `user` | Change owner only |
| `:group` | Change group only |
| `user:group` | Change both |
| `user:` | Change owner to user, group to user's login group |
| `:` | No change (same as `:current_group`) |

### Examples

```bash
# Change owner
chown john file.txt

# Change group
chown :developers file.txt

# Change both
chown john:developers file.txt

# Change owner to john, group to john's login group
chown john: file.txt

# Recursive
chown -R www-data:www-data /var/www/html/

# Don't follow symlinks
chown -h user:group symlink

# Using reference file
chown --reference=template.txt target.txt

# Only change if current owner matches
chown --from=olduser:newuser file.txt

# Only change if current group matches
chown --from=:oldgroup:newuser file.txt

# Verbose
chown -v john:group *.txt

# Suppress errors
chown -f john file.txt 2>/dev/null

# Change ownership of directory tree
chown -R mysql:mysql /var/lib/mysql/

# Use numeric IDs
chown 1000:1000 file.txt

# Change only group recursively (preserve owner)
chown -R :www-data /var/www/
```

### Internals

`chown` uses the `chown()` syscall (or `lchown()` for symlinks, `fchownat()` for relative paths):

1. Parse the `owner:group` specification.
2. Resolve usernames to UIDs via `getpwnam()` (reads `/etc/passwd`).
3. Resolve group names to GIDs via `getgrnam()` (reads `/etc/group`).
4. Call `chown()` syscall.

**Restrictions**:
- Non-root users can only change the group of files they own, and only to groups they belong to.
- Only root can change file ownership (to prevent giving away files and disk quota).
- Changing ownership clears the setuid and setgid bits (security measure).

### Common Mistakes

1. **Recursive on root**: `chown -R user /` changes ownership of the entire filesystem. Use `--preserve-root` (default on GNU).

2. **Clearing setuid/setgid**: `chown` removes setuid/setgid bits. After changing ownership, re-set these bits if needed.

3. **Symlink behavior**: By default, `chown` follows symlinks (changes the target). Use `-h` to change the symlink itself.

4. **`:group` syntax**: `chown :group file` changes only the group. `chown group file` changes the owner (interprets "group" as a username). Don't confuse the two.

### POSIX Compatibility

POSIX specifies `chown` with `[owner][:[group]]` syntax, `-R`, `-h`. The `-v`, `-c`, `-f`, `--reference`, `--from` options are extensions.

---

## chgrp — Change Group Ownership

### Purpose

`chgrp` changes only the group ownership of files. It's a specialized version of `chown :group`.

### Syntax

```
chgrp [OPTION]... GROUP FILE...
chgrp [OPTION]... --reference=RFILE FILE...
```

### Key Options

| Option | Description |
|--------|-------------|
| `-R` | Recursive |
| `-c` | Verbose (only report changes) |
| `-v` | Verbose |
| `-f` | Suppress errors |
| `-h` | Don't follow symlinks |
| `--reference=RFILE` | Use RFILE's group |

### Examples

```bash
# Change group
chgrp developers file.txt

# Recursive
chgrp -R www-data /var/www/

# Don't follow symlinks
chgrp -h group symlink

# Reference file
chgrp --reference=template.txt target.txt

# Verbose
chgrp -v group *.txt
```

### Internals

`chgrp` is essentially `chown :group`. It resolves the group name to a GID via `getgrnam()` and calls `chown()` syscall.

**Restrictions**: Same as `chown` — non-root users can only change group to groups they belong to.

### POSIX Compatibility

POSIX specifies `chgrp` with `-R`, `-h`, `--reference` (though the last is an extension).

---

## umask — Set Default File Creation Permissions

### Purpose

`umask` sets or displays the file creation mask, which determines the default permissions for newly created files and directories. It subtracts permissions from the maximum (777 for directories, 666 for files).

### Syntax

```
umask [mode]
umask -p
umask -S
```

### How umask Works

The umask is a bitmask that *removes* permissions from the default:

```
Default for files:    666 (rw-rw-rw-)
Default for dirs:     777 (rwxrwxrwx)
Umask:                022 (----w--w-)
                      ─────────────
Result for files:     644 (rw-r--r--)
Result for dirs:      755 (rwxr-xr-x)
```

**Common umask values:**

| Umask | File Perms | Dir Perms | Use Case |
|-------|-----------|-----------|----------|
| 0022 | 644 (rw-r--r--) | 755 (rwxr-xr-x) | Default on most systems |
| 0002 | 664 (rw-rw-r--) | 775 (rwxrwxr-x) | Collaborative group directories |
| 0027 | 640 (rw-r-----) | 750 (rwxr-x---) | Private group access |
| 0077 | 600 (rw-------) | 700 (rwx------) | Private (no group/other access) |
| 0000 | 666 (rw-rw-rw-) | 777 (rwxrwxr-x) | No masking (dangerous) |
| 0077 | 600 (rw-------) | 700 (rwx------) | Recommended for sensitive environments |

### Examples

```bash
# Display current umask
umask
# Output: 0022

# Display in symbolic form
umask -S
# Output: u=rwx,g=rx,o=rx

# Set umask (octal)
umask 027

# Set umask (symbolic)
umask u=rwx,g=rx,o=

# Set umask for current shell session
umask 077

# Set in .bashrc for permanent effect
echo "umask 077" >> ~/.bashrc

# Set umask for a specific command (subshell)
(umask 077; touch secure_file.txt)

# Get umask in script
current_umask=$(umask)
echo "Current umask: $current_umask"

# Portable symbolic output
umask -p
# Output: umask 0022

# Set restrictive umask temporarily
umask 077
touch newfile.txt        # Will be 600
mkdir newdir             # Will be 700
umask 022                # Restore
```

### Internals

The umask is stored in the process's `struct cred` (kernel credential structure). It's inherited by child processes via `fork()`.

**Kernel behavior**: When creating a file with `open()` or a directory with `mkdir()`, the kernel computes:
```
requested_mode & ~umask
```

For example, `open("file", O_CREAT, 0666)` with umask `0022` results in mode `0644`.

**Important**: The umask only affects new file creation. It does not affect `chmod`, `cp` (with `-p`), or other explicit permission-setting operations.

### Common Mistakes

1. **Setting umask in wrong file**: `umask` in a script only affects that script. Set it in `~/.bashrc`, `~/.profile`, or `/etc/profile` for persistent effect.

2. **umask 0000**: Makes all new files world-writable. Never use in production.

3. **Expecting umask to affect existing files**: `umask` only applies to newly created files. Use `chmod` to change existing file permissions.

4. **File execute bit**: The default file creation mode is `0666` (no execute). Even with umask `0000`, new files won't have execute permission. Use `chmod +x` after creation.

### POSIX Compatibility

POSIX specifies `umask` with octal mode and `-S` option. The `-p` option is also POSIX.

---

## getfacl — Get File Access Control Lists

### Purpose

`getfacl` displays the Access Control List (ACL) of files and directories. ACLs extend traditional Unix permissions to allow per-user and per-group permission specifications.

### Syntax

```
getfacl [OPTION]... FILE...
```

### Key Options

| Option | Description |
|--------|-------------|
| `-a` | Display the access ACL |
| `-d` | Display the default ACL |
| `-c` | Omit the comment header |
| `-e` | Print effective permissions |
| `-R` | Recursive |
| `-L` | Follow symlinks |
| `-P` | Don't follow symlinks |
| `-t` | Use tabular output format |
| `--absolute-names` | Don't strip leading `/` |
| `--skip-base` | Skip files with no ACL |

### ACL Entry Types

| Entry | Format | Description |
|-------|--------|-------------|
| User ACL | `user:username:perms` | Per-user permissions |
| Group ACL | `group:groupname:perms` | Per-group permissions |
| Mask | `mask::perms` | Maximum effective permissions |
| Other | `other::perms` | Permissions for everyone else |
| Default | `default:type:perms` | Default ACL for new files in directory |

### Examples

```bash
# Show ACL of a file
getfacl file.txt
# Output:
# # file: file.txt
# # owner: user
# # group: group
# user::rw-
# user:john:rw-
# group::r--
# group:developers:r-x
# mask::rw-
# other::r--

# Show without comments
getfacl -c file.txt

# Show default ACL (for directories)
getfacl -d /shared/directory

# Show effective permissions
getfacl -e file.txt

# Recursive
getfacl -R /project/

# Tabular format
getfacl -t file.txt

# Show only default ACLs
getfacl -d -c /shared/directory

# Save ACLs to file
getfacl -R /project/ > acl_backup.txt

# Show ACL for multiple files
getfacl *.txt
```

---

## setfacl — Set File Access Control Lists

### Purpose

`setfacl` sets, modifies, or removes Access Control Lists (ACLs) on files and directories.

### Syntax

```
setfacl [OPTION]... [-m|-x ACL_SPEC]... FILE...
setfacl [OPTION]... --set ACL_SPEC... FILE...
```

### Key Options

| Option | Description |
|--------|-------------|
| `-m ACL_SPEC` | Modify ACL (add/change entries) |
| `-x ACL_SPEC` | Remove specific ACL entries |
| `-b` | Remove all ACL entries |
| `--set ACL_SPEC` | Set ACL (replaces entire ACL) |
| `-d` | Set default ACL (directories only) |
| `-k` | Remove default ACL |
| `-R` | Recursive |
| `-L` | Follow symlinks |
| `-P` | Don't follow symlinks |
| `--mask` | Recalculate effective mask |
| `-n` | Don't recalculate effective mask |
| `--restore=FILE` | Restore ACLs from file |
| `--test` | Test mode (don't modify) |

### ACL Specification Format

```
[user|group]:[name]:[perms]    # Access ACL
default:[user|group]:[name]:[perms]  # Default ACL
```

Permissions: `r` (read), `w` (write), `x` (execute), `-` (none).

### Examples

```bash
# Add user permission
setfacl -m u:john:rw file.txt

# Add group permission
setfacl -m g:developers:r-x file.txt

# Set mask
setfacl -m m::rw file.txt

# Remove specific ACL entry
setfacl -x u:john file.txt

# Remove all ACLs
setfacl -b file.txt

# Set default ACL for directory (new files inherit)
setfacl -d -m u:john:rw /shared/directory

# Remove default ACL
setfacl -d -k /shared/directory

# Recursive
setfacl -R -m u:www-data:rx /var/www/html/

# Restore from backup
setfacl --restore=acl_backup.txt

# Set ACL (replaces entire ACL)
setfacl --set u::rw,u:john:rw,g::r--,g:dev:rx,m::rw,o::r-- file.txt

# Modify multiple entries
setfacl -m u:alice:rwx,u:bob:rx,g:team:rw file.txt

# Combine with chmod mask
setfacl -m g:developers:rw file.txt
chmod 640 file.txt  # Sets mask to rw-

# Test mode
setfacl --test -m u:john:rw file.txt

# Remove all default ACLs recursively
setfacl -R -d -k /shared/
```

### Internals

ACLs are stored as extended attributes (xattrs) on the filesystem:

- **xattr name**: `system.posix_acl_access` (access ACL), `system.posix_acl_default` (default ACL)
- **Format**: Binary-encoded ACL entries
- **Filesystem support**: ext4, XFS, Btrfs, and most modern Linux filesystems support ACLs. Some network filesystems (NFS) may have limited ACL support.

**Mask computation**: The mask entry represents the maximum effective permissions for the group class (group entries and named user/group entries). When you set ACLs, the mask is automatically calculated unless you use `-n` (no mask recalculation).

**Effective permissions**: A process's effective permissions are the intersection of the ACL entry and the mask: `effective = ACL_entry & mask`.

**Default ACLs**: Only applicable to directories. When a file is created in a directory with a default ACL, the file's access ACL is initialized from the directory's default ACL. This inheritance is automatic and provides a powerful way to set permissions for new files.

### Common Mistakes

1. **Forgetting mask**: The mask limits effective permissions. Setting `u:john:rwx` without updating the mask may result in only `rw-` effective permissions.

2. **Not using `-d` for defaults**: Without `-d`, ACLs are set as access ACLs, not default ACLs. Default ACLs require `-d`.

3. **ACL vs traditional permissions**: Setting ACLs changes the file's group permissions to reflect the mask. This can confuse tools that expect traditional permissions.

4. **Not supported on all filesystems**: Some filesystems (tmpfs, certain network FS) don't support ACLs. Use `getfacl` to verify.

5. **Recursive without `-R`**: Setting ACLs on a directory without `-R` only affects the directory itself, not existing contents.

### Best Practices

- Use ACLs when traditional owner/group/other permissions aren't sufficient.
- Set default ACLs on shared directories so new files automatically inherit the right permissions.
- Back up ACLs with `getfacl -R` before major changes.
- Use `setfacl --restore` for atomic ACL restoration.
- Combine ACLs with traditional permissions — ACLs extend, not replace, the traditional model.

### POSIX Compatibility

POSIX.1e (draft, never finalized) defines the ACL specification. Linux implements a subset of this draft. The tools `getfacl` and `setfacl` are from the `acl` package and are standard on most Linux distributions.

---

## Summary

### Permission Model Overview

```
Traditional:  owner (rwx) | group (rwx) | other (rwx)
ACLs:         owner (rwx) | named_users (rwx) | named_groups (rwx) | mask | other (rwx)
```

### Quick Reference

```bash
# Common permission settings
chmod 755 /path/to/directory    # Standard directory
chmod 644 /path/to/file         # Standard file
chmod 700 ~/.ssh                # Private directory
chmod 600 ~/.ssh/id_rsa         # Private key
chmod 4755 /usr/bin/sudo        # Setuid executable
chmod 1777 /tmp                 # Sticky directory

# Ownership
chown user:group file           # Change owner and group
chown -R www-data:www-data /var/www/  # Recursive ownership change

# Umask
umask 022                       # Standard (dirs: 755, files: 644)
umask 077                       # Private (dirs: 700, files: 600)

# ACLs
setfacl -m u:john:rw file.txt   # Grant user access
setfacl -d -m g:dev:rx /shared/ # Default ACL for new files
getfacl file.txt                # View ACL
```

### Security Best Practices

1. **Principle of least privilege**: Grant only the minimum permissions needed.
2. **Avoid 777**: World-writable files are a security risk.
3. **Use 077 umask**: For sensitive environments, default to private permissions.
4. **Audit permissions regularly**: Use `find -perm` to find overly permissive files.
5. **Use ACLs for complex scenarios**: When traditional permissions aren't sufficient.
6. **Secure SSH keys**: `chmod 600 ~/.ssh/id_rsa`, `chmod 700 ~/.ssh/`.
7. **Setgid for shared directories**: Use `chmod g+s` so new files inherit the directory's group.
8. **Sticky bit for shared writable directories**: Use `chmod +t /shared` to prevent users from deleting each other's files.
