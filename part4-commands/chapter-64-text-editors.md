# Chapter 64: Text Editors — vim, nano, emacs

## Overview

Text editors are essential tools for every Linux user. This chapter covers the three most important editors: `vim` (powerful modal editor), `nano` (simple beginner-friendly), and `emacs` (extensible editor/IDE).

---

## vim — Vi IMproved

### Purpose

`vim` is a powerful, modal text editor. It's the default editor on most Linux systems and is essential for system administration.

### Modes

| Mode | Description | Enter | Exit |
|------|-------------|-------|------|
| Normal | Navigation, commands | `Esc` | — |
| Insert | Text input | `i`, `a`, `o`, etc. | `Esc` |
| Visual | Selection | `v`, `V`, `Ctrl+v` | `Esc` |
| Command-line | Commands | `:`, `/`, `?` | `Enter`/`Esc` |
| Replace | Replace text | `R` | `Esc` |

### Starting vim

```bash
# Open file
vim file.txt

# Open at specific line
vim +42 file.txt

# Open at last line
vim + file.txt

# Open in read-only mode
vim -R file.txt

# Open multiple files
vim file1.txt file2.txt

# Open in diff mode
vim -d file1.txt file2.txt

# Open in recovery mode
vim -r file.txt
```

### Normal Mode — Movement

| Key | Action |
|-----|--------|
| `h` | Left |
| `j` | Down |
| `k` | Up |
| `l` | Right |
| `w` | Next word |
| `b` | Previous word |
| `e` | End of word |
| `0` | Start of line |
| `^` | First non-blank character |
| `$` | End of line |
| `gg` | First line |
| `G` | Last line |
| `NG` | Go to line N |
| `%` | Matching bracket |
| `(` | Previous sentence |
| `)` | Next sentence |
| `{` | Previous paragraph |
| `}` | Next paragraph |
| `Ctrl+f` | Page down |
| `Ctrl+b` | Page up |
| `Ctrl+d` | Half page down |
| `Ctrl+u` | Half page up |
| `H` | Top of screen |
| `M` | Middle of screen |
| `L` | Bottom of screen |
| `zt` | Scroll current line to top |
| `zz` | Scroll current line to middle |
| `zb` | Scroll current line to bottom |

### Normal Mode — Editing

| Key | Action |
|-----|--------|
| `i` | Insert before cursor |
| `I` | Insert at start of line |
| `a` | Append after cursor |
| `A` | Append at end of line |
| `o` | Open line below |
| `O` | Open line above |
| `x` | Delete character |
| `X` | Delete character before |
| `dd` | Delete line |
| `D` | Delete to end of line |
| `dw` | Delete word |
| `d$` | Delete to end of line |
| `d0` | Delete to start of line |
| `dG` | Delete to end of file |
| `dgg` | Delete to start of file |
| `yy` | Yank (copy) line |
| `Y` | Yank line |
| `yw` | Yank word |
| `y$` | Yank to end of line |
| `p` | Paste after |
| `P` | Paste before |
| `u` | Undo |
| `Ctrl+r` | Redo |
| `.` | Repeat last command |
| `r` | Replace character |
| `R` | Replace mode |
| `~` | Toggle case |
| `J` | Join lines |
| `gJ` | Join lines (no space) |
| `>>` | Indent line |
| `<<` | Unindent line |
| `=` | Auto-indent |
| `cw` | Change word |
| `cc` | Change line |
| `C` | Change to end of line |
| `c$` | Change to end of line |
| `c0` | Change to start of line |
| `s` | Substitute character |
| `S` | Substitute line |
| `Ctrl+a` | Increment number |
| `Ctrl+x` | Decrement number |

### Text Objects

| Object | Description |
|--------|-------------|
| `iw` | Inner word |
| `aw` | A word (with space) |
| `iW` | Inner WORD |
| `aW` | A WORD |
| `is` | Inner sentence |
| `as` | A sentence |
| `ip` | Inner paragraph |
| `ap` | A paragraph |
| `i"` | Inner double quotes |
| `a"` | A double quotes |
| `i'` | Inner single quotes |
| `a'` | A single quotes |
| `i(` | Inner parentheses |
| `a(` | A parentheses |
| `i[` | Inner brackets |
| `a[` | A brackets |
| `i{` | Inner braces |
| `a{` | A braces |
| `it` | Inner tag (HTML/XML) |
| `at` | A tag |

### Operators + Text Objects

```bash
# Delete inner word
diw

# Change inner word
ciw

# Delete inner quotes
di"

# Change inside parentheses
ci(

# Delete a paragraph
dap

# Yank inner block
yi{

# Change a tag (HTML)
cat
```

### Visual Mode

| Key | Action |
|-----|--------|
| `v` | Character-wise visual |
| `V` | Line-wise visual |
| `Ctrl+v` | Block visual |
| `o` | Other end of selection |
| `O` | Other corner (block) |
| `aw` | Select a word |
| `ab` | Select a block |
| `at` | Select a tag |
| `>` | Indent |
| `<` | Unindent |
| `d` | Delete |
| `y` | Yank |
| `c` | Change |
| `~` | Toggle case |
| `U` | Uppercase |
| `u` | Lowercase |
| `J` | Join |

### Search and Replace

```bash
# Search forward
/pattern

# Search backward
?pattern

# Next match
n

# Previous match
N

# Search with regex
/\vpattern          # Very magic
/\cpattern          # Case insensitive
/\Cpattern          # Case sensitive

# Search and replace
:%s/old/new/g       # Global
:%s/old/new/gc      # With confirmation
:%s/old/new/gi      # Case insensitive
:5,10s/old/new/g    # Lines 5-10
:'<,'>s/old/new/g   # Visual selection
:s/old/new/g        # Current line

# Special characters
:%s/\v(\w+) (\w+)/\2 \1/g  # Swap words
:%s/\n/\r/g                 # Newlines
:%s/\s\+$//                 # Trailing whitespace
```

### Commands

```bash
# Save
:w
:w filename

# Quit
:q
:q!                     # Force quit

# Save and quit
:wq
:x
ZZ                      # Normal mode

# Write with sudo
:w !sudo tee %

# Read file
:r filename

# Run shell command
:!command

# Insert command output
:r !command

# Multiple files
:e filename             # Edit file
:bn                     # Next buffer
:bp                     # Previous buffer
:bd                     # Close buffer
:ls                     # List buffers

# Splits
:sp filename            # Horizontal split
:vsp filename           # Vertical split
Ctrl+w h/j/k/l         # Navigate splits
Ctrl+w H/J/K/L         # Move splits
Ctrl+w =                # Equalize splits
Ctrl+w _                # Maximize height
Ctrl+w |                # Maximize width
Ctrl+w q                # Close split

# Tabs
:tabnew filename        # New tab
:tabn                   # Next tab
:tabp                   # Previous tab
:tabclose               # Close tab
gt                      # Next tab
gT                      # Previous tab

# Marks
ma                      # Set mark 'a'
'a                      # Jump to mark 'a'
'A                      # Jump to mark 'a' (line + column)
:marks                  # List marks

# Registers
"ayy                    # Yank to register a
"ap                     # Paste from register a
"+y                     # Yank to system clipboard
"+p                     # Paste from system clipboard
:reg                    # List registers

# Folding
za                      # Toggle fold
zR                      # Open all folds
zM                      # Close all folds
zo                      # Open fold
zc                      # Close fold
zf                      # Create fold

# Macros
qa                      # Record macro 'a'
q                       # Stop recording
@a                      # Play macro 'a'
@@                      # Repeat last macro
10@a                    # Play macro 10 times

# Abbreviations
:ab teh the             # Auto-correct
:ab email user@example.com
```

### .vimrc Configuration

```vim
" Basic settings
set nocompatible
set encoding=utf-8
set fileencoding=utf-8

" Display
set number              " Line numbers
set relativenumber      " Relative numbers
set cursorline          " Highlight current line
set showmatch           " Show matching brackets
set showmode            " Show mode
set showcmd             " Show command
set ruler               " Show cursor position
set laststatus=2        " Always show statusline
set scrolloff=5         " Keep 5 lines visible
set sidescrolloff=5     " Keep 5 columns visible
set display=lastline    " Show as much as possible
set signcolumn=yes      " Always show sign column

" Colors
syntax on
set background=dark
colorscheme desert

" Search
set hlsearch            " Highlight search
set incsearch           " Incremental search
set ignorecase          " Case insensitive
set smartcase           " Case sensitive if uppercase

" Indentation
set autoindent          " Auto indent
set smartindent         " Smart indent
set tabstop=4           " Tab width
set shiftwidth=4        " Indent width
set softtabstop=4       " Soft tab width
set expandtab           " Spaces instead of tabs
set smarttab            " Smart tab

" Files
set autoread            " Auto reload
set hidden              " Hide buffers
set noswapfile          " No swap file
set nobackup            " No backup
set nowritebackup       " No write backup

" Completion
set wildmenu            " Command completion
set wildmode=longest:list,full
set completeopt=menuone,noinsert,noselect

" Mouse
set mouse=a             " Enable mouse

" Clipboard
set clipboard=unnamedplus

" Split
set splitbelow          " Split below
set splitright          " Split right

" Statusline
set statusline=%f\ %m%r%h%w\ [%{&ff}]\ [%Y]\ [%l,%c]\ [%p%%]

" Key mappings
let mapleader=","       " Leader key
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>
nnoremap <leader>e :e 
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Auto commands
autocmd BufWritePre * :%s/\s\+$//e  " Remove trailing whitespace
autocmd FileType python setlocal tabstop=4 shiftwidth=4
autocmd FileType javascript setlocal tabstop=2 shiftwidth=2
```

---

## nano — Simple Text Editor

### Purpose

`nano` is a simple, user-friendly terminal text editor.

### Key Options

| Option | Description |
|--------|-------------|
| `+LINE` | Start at line |
| `-B` | Backup files |
| `-C DIR` | Backup directory |
| `-D` | Bold text |
| `-E` | Convert tabs to spaces |
| `-F` | Enable multiple buffers |
| `-G` | Show cursor |
| `-H` | Smart home key |
| `-I` | Auto-indent |
| `-K` | Cut from cursor |
| `-L` | Don't add newline |
| `-M` | Mouse support |
| `-N` | No conversion |
| `-O` | Log to file |
| `-P` | Preserve attributes |
| `-Q REGEX` | Quoting regex |
| `-R` | Restricted mode |
| `-S` | Smooth scrolling |
| `-T NUM` | Tab size |
| `-U` | Quick blank |
| `-V` | View mode |
| `-W` | Word wrap |
| `-X STR` | Status key |
| `-Y SYNTAX` | Syntax |
| `-c` | Constant cursor |
| `-h` | Show help |
| `-i` | Auto-indent |
| `-k` | Cut to end |
| `-l` | Line numbers |
| `-m` | Mouse |
| `-n` | No conversion |
| `-o DIR` | Operating directory |
| `-p` | Preserve |
| `-q` | Quiet |
| `-r NUM` | Wrap column |
| `-s PROG` | Spell checker |
| `-t` | Save on exit |
| `-u` | Undo |
| `-v` | View |
| `-w` | No wrap |
| `-x` | No help |
| `-z` | Suspend |
| `--boldtext` | Bold text |
| `--constantshow` | Constant show |
| `--fill=NUM` | Fill column |
| `--guidestripe=NUM` | Guide stripe |
| `--historylog` | History log |
| `--jumpyscrolling` | Jump scrolling |
| `--linenumbers` | Line numbers |
| `--magic` | Magic keys |
| `--minibar` | Minibar |
| `--nohelp` | No help |
| `--positionlog` | Position log |
| `--quickblank` | Quick blank |
| `--rawsequences` | Raw sequences |
| `--rebinddelete` | Rebind delete |
| `--saveonexit` | Save on exit |
| `--softwrap` | Soft wrap |
| `--stateflags` | State flags |
| `--tabsize=NUM` | Tab size |
| `--theme=THEME` | Color theme |
| `--wordbounds` | Word bounds |

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Ctrl+G` | Help |
| `Ctrl+O` | Save |
| `Ctrl+X` | Exit |
| `Ctrl+R` | Read file |
| `Ctrl+J` | Justify |
| `Ctrl+K` | Cut line |
| `Ctrl+U` | Paste |
| `Ctrl+C` | Cursor position |
| `Ctrl+T` | Spell check |
| `Ctrl+W` | Search |
| `Ctrl+\` | Search and replace |
| `Ctrl+A` | Start of line |
| `Ctrl+E` | End of line |
| `Ctrl+Y` | Page up |
| `Ctrl+V` | Page down |
| `Ctrl+D` | Delete character |
| `Ctrl+H` | Backspace |
| `Ctrl+I` | Tab |
| `Ctrl+M` | Enter |
| `Ctrl+L` | Refresh |
| `Ctrl+P` | Previous line |
| `Ctrl+N` | Next line |
| `Ctrl+F` | Forward |
| `Ctrl+B` | Backward |
| `Alt+A` | Start mark |
| `Alt+6` | Copy |
| `Alt+U` | Undo |
| `Alt+E` | Redo |
| `Alt+<` | Previous buffer |
| `Alt+>` | Next buffer |
| `Alt+G` | Go to line |

---

## emacs — The extensible, customizable, self-documenting editor

### Purpose

`emacs` is a powerful, extensible text editor with a built-in Lisp interpreter.

### Starting emacs

```bash
# Open file
emacs file.txt

# No window (terminal)
emacs -nw file.txt

# Open multiple files
emacs file1.txt file2.txt

# Batch mode
emacs --batch -l script.el

# No init file
emacs -q
```

### Basic Commands

| Shortcut | Action |
|----------|--------|
| `Ctrl+x Ctrl+f` | Open file |
| `Ctrl+x Ctrl+s` | Save |
| `Ctrl+x Ctrl+c` | Quit |
| `Ctrl+x Ctrl+w` | Save as |
| `Ctrl+x k` | Kill buffer |
| `Ctrl+x b` | Switch buffer |
| `Ctrl+x Ctrl-b` | List buffers |
| `Ctrl+x 2` | Split horizontally |
| `Ctrl+x 3` | Split vertically |
| `Ctrl+x 1` | Close other windows |
| `Ctrl+x 0` | Close current window |
| `Ctrl+x o` | Other window |
| `Ctrl+x 4 f` | Open in other window |
| `Ctrl+k` | Kill line |
| `Ctrl+y` | Yank (paste) |
| `Ctrl+w` | Kill region |
| `Alt+w` | Copy region |
| `Ctrl+space` | Set mark |
| `Ctrl+x h` | Select all |
| `Ctrl+f` | Forward char |
| `Ctrl+b` | Backward char |
| `Ctrl+n` | Next line |
| `Ctrl+p` | Previous line |
| `Alt+f` | Forward word |
| `Alt+b` | Backward word |
| `Ctrl+a` | Start of line |
| `Ctrl+e` | End of line |
| `Alt+<` | Start of buffer |
| `Alt+>` | End of buffer |
| `Ctrl+s` | Search forward |
| `Ctrl+r` | Search backward |
| `Alt+%` | Search and replace |
| `Ctrl+/` | Undo |
| `Ctrl+g` | Cancel |
| `Alt+x` | Execute command |
| `Ctrl+h ?` | Help |
| `Ctrl+h t` | Tutorial |
| `Ctrl+h k` | Describe key |
| `Ctrl+h f` | Describe function |
| `Ctrl+h v` | Describe variable |

---

## Summary

### Quick Reference

```bash
# vim
vim file.txt                    # Open
:wq                             # Save and quit
i                               # Insert mode
Esc                             # Normal mode
/pattern                        # Search
:%s/old/new/g                   # Replace

# nano
nano file.txt                   # Open
Ctrl+O                          # Save
Ctrl+X                          # Exit
Ctrl+W                          # Search

# emacs
emacs file.txt                  # Open
Ctrl+x Ctrl+s                   # Save
Ctrl+x Ctrl+c                   # Quit
Ctrl+x Ctrl+f                   # Open file
```
