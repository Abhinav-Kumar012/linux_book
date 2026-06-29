# Chapter 63: Version Control — git

## Overview

Git is the dominant distributed version control system. This chapter covers the essential git commands for daily workflow, branching, merging, and advanced operations.

---

## git — Distributed Version Control

### Purpose

`git` tracks changes in source code, enabling collaboration, history tracking, and code management.

### Key Options

| Option | Description |
|--------|-------------|
| `--version` | Show version |
| `-C DIR` | Run as if started in DIR |
| `-c NAME=VALUE` | Set config value |
| `--exec-path[=PATH]` | Show/set exec path |
| `--html-path` | Show HTML path |
| `--man-path` | Show man path |
| `--info-path` | Show info path |
| `--paginate` | Pipe through pager |
| `--no-pager` | Don't use pager |
| `--bare` | Bare repository |
| `--git-dir=DIR` | Repository directory |
| `--work-tree=DIR` | Working tree directory |
| `--namespace=NAME` | Namespace |

---

## Repository Setup

```bash
# Initialize new repository
git init

# Initialize with branch name
git init -b main

# Initialize bare repository
git init --bare

# Clone repository
git clone https://github.com/user/repo.git

# Clone to specific directory
git clone https://github.com/user/repo.git mydir

# Clone specific branch
git clone -b develop https://github.com/user/repo.git

# Clone with depth (shallow)
git clone --depth 1 https://github.com/user/repo.git

# Clone specific tag
git clone -b v1.0 --depth 1 https://github.com/user/repo.git

# Clone with submodules
git clone --recursive https://github.com/user/repo.git

# Clone using SSH
git clone git@github.com:user/repo.git
```

---

## Configuration

```bash
# Set user info
git config --global user.name "Your Name"
git config --global user.email "you@example.com"

# Set editor
git config --global core.editor vim

# Set default branch name
git config --global init.defaultBranch main

# Set merge tool
git config --global merge.tool vimdiff

# Set pull behavior
git config --global pull.rebase true

# Set push behavior
git config --global push.default current

# Set alias
git config --global alias.st status
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.ci commit
git config --global alias.lg "log --oneline --graph --decorate --all"

# List all config
git config --list

# Show specific config
git config user.name

# Edit config file
git config --global --edit
```

---

## Staging and Committing

```bash
# Check status
git status
git status -s                    # Short format
git status -sb                  # Short with branch

# Add files to staging
git add file.txt                # Specific file
git add .                       # All changes
git add -A                      # All changes (including deletions)
git add -p                      # Interactive (patch mode)
git add -u                      # Only tracked files
git add *.c                     # Glob pattern
git add dir/                    # Directory

# Remove from staging
git reset file.txt              # Unstage file
git reset                       # Unstage all

# Commit
git commit -m "message"         # With message
git commit -am "message"        # Add tracked files and commit
git commit --amend              # Amend last commit
git commit --amend -m "new"     # Amend with new message
git commit --amend --no-edit    # Amend without changing message
git commit --allow-empty -m "msg" # Empty commit
git commit -S -m "signed"       # Signed commit
git commit -v                   # Show diff in editor

# Commit all changes
git add -A && git commit -m "message"
```

---

## Branching

```bash
# List branches
git branch                      # Local branches
git branch -a                   # All branches
git branch -r                   # Remote branches
git branch -v                   # Verbose (with last commit)
git branch -vv                  # With tracking info
git branch --merged             # Merged branches
git branch --no-merged          # Unmerged branches
git branch --contains COMMIT    # Containing commit

# Create branch
git branch feature              # Create (don't switch)
git checkout -b feature         # Create and switch
git switch -c feature           # Create and switch (modern)

# Switch branch
git checkout feature            # Switch
git switch feature              # Switch (modern)
git switch -                    # Switch to previous

# Delete branch
git branch -d feature           # Delete (merged only)
git branch -D feature           # Force delete

# Rename branch
git branch -m old-name new-name # Rename
git branch -m new-name          # Rename current

# Set upstream
git branch -u origin/feature    # Set tracking
git branch --set-upstream-to=origin/feature

# Push branch
git push -u origin feature      # Push and set upstream
git push origin feature         # Push

# Delete remote branch
git push origin --delete feature
```

---

## Merging and Rebasing

### Merge

```bash
# Merge branch into current
git merge feature

# Merge with message
git merge -m "Merge feature" feature

# Merge without fast-forward (always create merge commit)
git merge --no-ff feature

# Abort merge
git merge --abort

# Continue after resolving conflicts
git merge --continue

# Squash merge
git merge --squash feature
git commit -m "Add feature"
```

### Rebase

```bash
# Rebase current branch onto main
git rebase main

# Interactive rebase
git rebase -i HEAD~5            # Last 5 commits
git rebase -i HEAD~3            # Last 3 commits

# Continue rebase
git rebase --continue

# Abort rebase
git rebase --abort

# Skip commit
git rebase --skip

# Rebase onto specific commit
git rebase --onto main feature

# Autosquash
git rebase -i --autosquash HEAD~5

# Interactive rebase commands
# pick = use commit
# reword = use commit, but edit message
# edit = use commit, but stop for amending
# squash = use commit, but meld into previous
# fixup = like squash, but discard message
# drop = remove commit
# exec = run command
```

---

## Remote Operations

```bash
# Show remotes
git remote -v

# Add remote
git remote add upstream https://github.com/original/repo.git

# Remove remote
git remote remove upstream

# Rename remote
git remote rename origin upstream

# Fetch
git fetch                       # All remotes
git fetch origin                # Specific remote
git fetch --all                 # All remotes
git fetch --prune               # Remove stale branches

# Pull
git pull                        # Fetch and merge
git pull --rebase               # Fetch and rebase
git pull origin main            # Specific branch

# Push
git push                        # Push to upstream
git push origin feature         # Specific branch
git push -u origin feature      # Set upstream
git push --force                # Force push (DANGEROUS)
git push --force-with-lease     # Safer force push
git push --tags                 # Push tags
git push origin :feature        # Delete remote branch
```

---

## Stashing

```bash
# Stash changes
git stash                       # Stash tracked files
git stash -u                    # Include untracked
git stash -a                    # Include all (even ignored)
git stash -m "message"          # With message
git stash -p                    # Interactive (patch mode)

# List stashes
git stash list

# Apply stash
git stash apply                 # Apply latest (keep stash)
git stash apply stash@{2}       # Apply specific
git stash pop                   # Apply and remove
git stash pop stash@{2}         # Apply and remove specific

# Show stash
git stash show                  # Summary
git stash show -p               # Full diff
git stash show stash@{2}        # Specific

# Drop stash
git stash drop                  # Drop latest
git stash drop stash@{2}        # Drop specific
git stash clear                 # Drop all

# Create branch from stash
git stash branch new-branch     # Create branch from stash
git stash branch new-branch stash@{2}
```

---

## History and Log

```bash
# Show log
git log                         # Full log
git log --oneline               # One line per commit
git log --graph                 # Graph
git log --graph --oneline --decorate --all  # Beautiful graph
git log -n 10                   # Last 10 commits
git log --since="2024-01-01"    # Since date
git log --until="2024-06-01"    # Until date
git log --author="John"         # By author
git log --grep="fix"            # Search message
git log -S "function_name"      # Search code (pickaxe)
git log -G "regex"              # Search code (regex)
git log --stat                  # Show file stats
git log --shortstat             # Short stats
git log -p                      # Show patches
git log --follow file.txt       # Follow renames
git log --diff-filter=A         # Added files
git log --diff-filter=M         # Modified files
git log --merges                # Only merges
git log --no-merges             # No merges
git log --first-parent          # First parent only
git log --all                   # All branches
git log --ancestry-path A..B    # Path between commits

# Show specific commit
git show COMMIT                 # Show commit
git show --stat COMMIT          # With stats
git show COMMIT:file.txt       # File at commit

# Blame
git blame file.txt              # Show who changed each line
git blame -L 10,20 file.txt    # Specific lines
git blame -w file.txt           # Ignore whitespace

# Diff
git diff                        # Unstaged changes
git diff --staged               # Staged changes
git diff HEAD                   # All changes
git diff main..feature          # Between branches
git diff COMMIT1..COMMIT2       # Between commits
git diff --stat                 # Stats only
git diff --name-only            # File names only
git diff --name-status          # File status
git diff --cached               # Same as --staged
```

---

## Cherry-Pick

```bash
# Cherry-pick a commit
git cherry-pick COMMIT

# Cherry-pick without committing
git cherry-pick -n COMMIT

# Cherry-pick range
git cherry-pick COMMIT1..COMMIT2

# Cherry-pick multiple
git cherry-pick COMMIT1 COMMIT2 COMMIT3

# Abort cherry-pick
git cherry-pick --abort

# Continue after conflict resolution
git cherry-pick --continue
```

---

## Bisect

```bash
# Start bisect
git bisect start

# Mark bad commit
git bisect bad                  # Current
git bad bad COMMIT              # Specific

# Mark good commit
git bisect good COMMIT

# Skip commit
git bisect skip

# Reset
git bisect reset

# Automated bisect
git bisect start HEAD v1.0
git bisect run ./test_script.sh
```

---

## Worktree

```bash
# Create worktree
git worktree add ../feature-branch feature

# Create new branch in worktree
git worktree add -b new-feature ../new-feature

# List worktrees
git worktree list

# Remove worktree
git worktree remove ../feature-branch

# Prune stale worktrees
git worktree prune
```

---

## Tags

```bash
# List tags
git tag
git tag -l "v1.*"

# Create tag
git tag v1.0                    # Lightweight
git tag -a v1.0 -m "Release"   # Annotated
git tag -s v1.0 -m "Signed"    # Signed

# Tag specific commit
git tag -a v1.0 COMMIT

# Push tags
git push origin v1.0
git push --tags

# Delete tag
git tag -d v1.0
git push origin --delete v1.0
```

---

## Reset and Restore

```bash
# Reset (move HEAD)
git reset --soft HEAD~1         # Undo commit, keep staged
git reset --mixed HEAD~1        # Undo commit, unstage
git reset --hard HEAD~1         # Undo commit, discard changes

# Restore (working tree)
git restore file.txt            # Discard changes
git restore --staged file.txt   # Unstage
git restore --source=COMMIT file.txt  # Restore from commit

# Clean
git clean -f                    # Remove untracked files
git clean -fd                   # Remove untracked files and dirs
git clean -fX                   # Remove ignored files
git clean -fx                   # Remove all untracked
git clean -n                    # Dry run
```

---

## Summary

### Quick Reference

```bash
# Daily workflow
git status                      # Check status
git add -A                      # Stage all
git commit -m "message"         # Commit
git push                        # Push

# Branching
git switch -c feature           # Create and switch
git switch main                 # Switch to main
git merge feature               # Merge
git branch -d feature           # Delete

# History
git log --oneline --graph       # Visual log
git diff                        # Changes
git blame file.txt              # Who changed what

# Stashing
git stash                       # Stash
git stash pop                   # Apply

# Advanced
git rebase -i HEAD~5            # Interactive rebase
git cherry-pick COMMIT          # Cherry-pick
git bisect start                # Find bug
git worktree add ../branch branch # Worktree
```
