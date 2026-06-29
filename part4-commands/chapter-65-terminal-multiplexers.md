# Chapter 65: Terminal Multiplexers — tmux, screen

## Overview

Terminal multiplexers allow multiple terminal sessions within a single window. They're essential for remote server management, as sessions persist through disconnections. This chapter covers `tmux` (modern, recommended) and `screen` (classic).

---

## tmux — Terminal Multiplexer

### Purpose

`tmux` manages multiple terminal sessions, windows, and panes within a single terminal. Sessions persist through SSH disconnections.

### Key Options

| Option | Description |
|--------|-------------|
| `-s SESSION` | Session name |
| `-t TARGET` | Target session:window.pane |
| `-L NAME` | Socket name |
| `-S SOCKET` | Socket path |
| `-f FILE` | Config file |
| `-d` | Detach |
| `-D` | Detach others |
| `-CC` | Control mode |
| `-V` | Version |
| `-2` | 256 colors |
| `-c START-DIR` | Start directory |
| `-u` | UTF-8 |
| `-l` | Login shell |
| `-n` | No login shell |

### Architecture

```
tmux server
├── session "work"
│   ├── window 0 "editor"
│   │   ├── pane 0 (vim)
│   │   └── pane 1 (shell)
│   └── window 1 "monitor"
│       └── pane 0 (htop)
└── session "dev"
    ├── window 0 "code"
    └── window 1 "logs"
```

### Key Bindings

Default prefix: `Ctrl+b`

**Session Management:**

| Key | Action |
|-----|--------|
| `:new` | New session |
| `:kill-session` | Kill current session |
| `s` | List sessions |
| `$` | Rename session |
| `d` | Detach session |
| `(` | Previous session |
| `)` | Next session |

**Window Management:**

| Key | Action |
|-----|--------|
| `c` | New window |
| `&` | Kill window |
| `,` | Rename window |
| `w` | List windows |
| `p` | Previous window |
| `n` | Next window |
| `0-9` | Select window by number |
| `l` | Last window |
| `f` | Find window |
| `.` | Move window |

**Pane Management:**

| Key | Action |
|-----|--------|
| `%` | Split vertically |
| `"` | Split horizontally |
| `x` | Kill pane |
| `z` | Toggle pane zoom |
| `{` | Move pane left |
| `}` | Move pane right |
| `o` | Next pane |
| `;` | Last pane |
| `q` | Show pane numbers |
| `q 0-9` | Select pane by number |
| `Space` | Toggle pane layout |
| `!` | Break pane to window |
| `↑↓←→` | Navigate panes |
| `Alt+↑↓←→` | Resize panes |
| `Ctrl+↑↓←→` | Resize panes (5 cells) |
| `Ctrl+o` | Rotate panes |
| `t` | Show clock |

**Copy Mode:**

| Key | Action |
|-----|--------|
| `[` | Enter copy mode |
| `q` | Exit copy mode |
| `Space` | Start selection |
| `Enter` | Copy selection |
| `]` | Paste buffer |
| `#` | List buffers |
| `-` | Delete buffer |
| `=` | Choose buffer |

**Other:**

| Key | Action |
|-----|--------|
| `?` | List all key bindings |
| `:` | Command prompt |
| `~` | Show messages |
| `t` | Show clock |
| `Ctrl+z` | Suspend tmux |

### Command Mode

```bash
# Commands (prefix + :)
:new -s session_name            # New session
:kill-session -t session_name   # Kill session
:kill-server                    # Kill server
:source-file ~/.tmux.conf       # Reload config
:list-keys                      # List keys
:list-commands                  # List commands
:show-options -g                # Show global options
:set -g OPTION VALUE            # Set option
:capture-pane                   # Capture pane
:save-buffer buffer.txt         # Save buffer
:swap-window -s 2 -t 1         # Swap windows
:move-window -t 3               # Move window
:break-pane                     # Break pane
:join-pane -s 2 -t 1           # Join pane
:resize-pane -D 10              # Resize down 10
:select-layout tiled            # Tiled layout
```

### CLI Commands

```bash
# Start new session
tmux

# Start named session
tmux new -s work

# Start detached
tmux new -s work -d

# List sessions
tmux ls

# Attach to session
tmux attach -t work

# Attach to last session
tmux a

# Kill session
tmux kill-session -t work

# Send command to session
tmux send-keys -t work "echo hello" Enter

# Rename session
tmux rename-session -t old new

# Switch session
tmux switch -t work

# Capture pane output
tmux capture-pane -t work:0.0 -p > output.txt

# Pipe command output
tmux pipe-pane -t work "cat >> output.txt"
```

### .tmux.conf Configuration

```bash
# Prefix
unbind C-b
set -g prefix C-a
bind C-a send-prefix

# Mouse
set -g mouse on

# Colors
set -g default-terminal "screen-256color"
set -ga terminal-overrides ",*256col*:Tc"

# Status bar
set -g status-style bg=colour235,fg=colour136
set -g status-left "#[fg=green]#S "
set -g status-right "#[fg=yellow]%Y-%m-%d %H:%M"
set -g status-interval 60

# Window numbering
set -g base-index 1
setw -g pane-base-index 1
set -g renumber-windows on

# History
set -g history-limit 50000

# Vi mode
setw -g mode-keys vi

# Split panes
bind | split-window -h
bind - split-window -v

# Navigate panes
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

# Resize panes
bind -r H resize-pane -L 5
bind -r J resize-pane -D 5
bind -r K resize-pane -U 5
bind -r L resize-pane -R 5

# Reload config
bind r source-file ~/.tmux.conf \; display "Config reloaded!"

# Copy mode
bind Enter copy-mode
bind -T copy-mode-vi v send -X begin-selection
bind -T copy-mode-vi y send -X copy-selection-and-cancel

# New window in current directory
bind c new-window -c "#{pane_current_path}"

# Split in current directory
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"

# Activity monitoring
setw -g monitor-activity on
set -g visual-activity off

# Bell
setw -g monitor-bell on
set -g visual-bell off

# Escape time
set -g escape-time 0

# Focus events
set -g focus-events on

# Aggressive resize
setw -g aggressive-resize on
```

### Session Management

```bash
# Save sessions (requires tmux-resurrect or tmux-continuum)
# tmux-resurrect shortcuts:
prefix + Ctrl-s  # Save
prefix + Ctrl-r  # Restore

# Manual session save
tmux list-windows -a > sessions.txt

# tmux-continuum (auto-save/restore)
set -g @continuum-restore 'on'
set -g @continuum-save-interval '15'
```

---

## screen — Terminal Multiplexer (Classic)

### Purpose

`screen` is the classic terminal multiplexer, available on virtually all Unix systems.

### Key Options

| Option | Description |
|--------|-------------|
| `-S NAME` | Session name |
| `-r SESSION` | Reattach |
| `-d` | Detach |
| `-D` | Detach and logout |
| `-ls` | List sessions |
| `-x` | Attach to attached session |
| `-R` | Reattach or create |
| `-RR` | Reattach or create (best) |
| `-c FILE` | Config file |
| `-h N` | History lines |
| `-L` | Logging |
| `-wipe` | Clean dead sessions |

### Key Bindings

Default prefix: `Ctrl+a`

| Key | Action |
|-----|--------|
| `c` | Create window |
| `n` | Next window |
| `p` | Previous window |
| `0-9` | Select window |
| `"` | List windows |
| `A` | Rename window |
| `k` | Kill window |
| `S` | Split horizontally |
| `|` | Split vertically |
| `Tab` | Next region |
| `Q` | Close all but current |
| `X` | Close current region |
| `H` | Toggle logging |
| `[` | Copy mode |
| `]` | Paste |
| `d` | Detach |
| `D` | Detach (with power) |
| `Ctrl+a` | Last window |
| `?` | Help |
| `:` | Command |
| `s` | List sessions |
| `w` | List windows |
| `t` | Show time |
| `i` | Info |
| `v` | Version |

### CLI Commands

```bash
# Start new session
screen

# Start named session
screen -S work

# List sessions
screen -ls

# Attach to session
screen -r work

# Detach
# Ctrl+a, d

# Kill session
screen -X -S work quit

# Send command
screen -S work -X stuff "echo hello\n"

# Enable logging
screen -L

# Screen configuration (.screenrc)
defscrollback 10000
hardstatus on
hardstatus alwayslastline
hardstatus string "%{.bW}%-w%{.rW}%n %t%{-}%+w %=%{..G} %H %{..Y} %Y-%m-%d %c"
```

---

## Summary

### Quick Reference

```bash
# tmux
tmux                            # Start
tmux new -s work                # Named session
tmux ls                         # List sessions
tmux attach -t work             # Attach
tmux kill-session -t work       # Kill

# screen
screen                          # Start
screen -S work                  # Named session
screen -ls                      # List sessions
screen -r work                  # Attach
```

### tmux vs screen

| Feature | tmux | screen |
|---------|------|--------|
| Status bar | Configurable | Basic |
| Layouts | Multiple | Limited |
| Scripting | Excellent | Good |
| Mouse support | Yes | Limited |
| Split panes | Yes | Yes |
| Copy mode | Vi/Emacs | Vi/Emacs |
| Configuration | ~/.tmux.conf | ~/.screenrc |
| Plugins | Yes (TPM) | Limited |
| Activity alerts | Yes | Yes |
| Session naming | Yes | Yes |
