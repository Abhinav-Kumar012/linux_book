# Chapter 36: Quoting — Single Quotes, Double Quotes, Backslash, ANSI-C $'', Here-Docs

## Overview

Quoting is the mechanism that tells the shell to treat special characters literally rather than interpreting them. Without quoting, the shell expands variables, performs globbing, splits words, and substitutes commands. Quoting suppresses some or all of these expansions, giving you precise control over what the shell sees.

Understanding quoting is essential for writing correct shell scripts. A missing quote can cause word splitting, glob expansion, or command injection. An extra quote can suppress necessary expansion. The four quoting mechanisms — single quotes, double quotes, backslash, and ANSI-C `$''` — each serve different purposes and have different rules.

## Intuition

Think of quoting as escaping from the shell's interpretation layer. When you write `echo $HOME`, the shell replaces `$HOME` with your home directory before `echo` sees it. When you write `echo '$HOME'`, the shell passes the literal string `$HOME` to `echo`. Quoting is how you tell the shell "don't interpret this — pass it through as-is."

The challenge is that each quoting mechanism preserves or suppresses different things. Single quotes preserve everything literally. Double quotes preserve most things but still expand variables and command substitutions. Backslashes preserve a single character. ANSI-C quotes interpret C-style escape sequences. Choosing the right one requires understanding what you want to preserve and what you want to expand.

## Quoting Mechanisms Comparison

| Feature | `'single'` | `"double"` | `\backslash` | `$'ANSI-C'` | `$"locale"` |
|---------|-----------|-----------|-------------|------------|------------|
| Variable expansion | ❌ | ✅ | ❌ (single char) | ❌ | ❌ |
| Command substitution | ❌ | ✅ | ❌ | ❌ | ❌ |
| Arithmetic expansion | ❌ | ✅ | ❌ | ❌ | ❌ |
| Glob expansion | ❌ | ❌ | ❌ | ❌ | ❌ |
| Word splitting | ❌ | ❌ | ❌ | ❌ | ❌ |
| `\n`, `\t` escapes | ❌ | ❌ | ❌ | ✅ | ❌ |
| Literal `'` | ❌ | ✅ | ✅ | ✅ | ✅ |
| Literal `"` | ✅ | ❌ | ✅ | ✅ | ✅ |
| Literal `$` | ✅ | ❌ | ✅ | ✅ | ✅ |
| Locale translation | ❌ | ❌ | ❌ | ❌ | ✅ |

## Single Quotes

Single quotes preserve everything literally. Nothing is interpreted inside single quotes.

```bash
# Everything is literal
echo 'Hello, World!'         # Hello, World!
echo '$HOME'                 # $HOME
echo '$(hostname)'           # $(hostname)
echo '*.txt'                 # *.txt
echo 'Line 1\nLine 2'       # Line 1\nLine 2
echo '${var}'                # ${var}
echo '$((2 + 3))'            # $((2 + 3))

# Special characters are literal
echo 'It'\''s a test'       # It's a test (embedded single quote trick)
echo 'He said "hello"'      # He said "hello"
echo 'Backslash: \n \t \\'  # Backslash: \n \t \\

# Embedding a single quote in single quotes
# Method 1: End quote, escaped quote, start quote
echo 'It'\''s'              # It's
echo 'can'\''t'             # can't

# Method 2: Use double quotes for the whole string
echo "It's"                 # It's

# Method 3: Use ANSI-C quoting for the whole string
echo $'It\'s'               # It's
```

### When to Use Single Quotes

```bash
# ✅ Literal strings with special characters
echo 'Price: $5.00'

# ✅ Patterns for grep (prevent shell globbing)
grep '*.txt' file.txt       # Searches for literal *.txt
grep '\.txt$' file.txt      # Searches for .txt at end of line

# ✅ Regular expressions
grep '^[0-9]\+$' file.txt   # Lines that are only digits

# ✅ Preserving whitespace
echo '   spaces   preserved   '

# ✅ Protecting from injection
user_input='; rm -rf /'
echo "$user_input"           # Safe with double quotes too
echo '$user_input'           # Literally: $user_input
```

## Double Quotes

Double quotes preserve most special characters but still expand `$` variables, `` ` `` command substitutions, and `\` escapes.

```bash
# Variables are expanded
name="World"
echo "Hello, $name!"         # Hello, World!

# Command substitutions are expanded
echo "Today is $(date +%A)"  # Today is Monday

# Arithmetic is expanded
echo "2 + 3 = $((2 + 3))"   # 2 + 3 = 5

# Backslash escapes
echo "Line 1\nLine 2"        # Line 1\nLine 2 (literal \n in echo)
printf "Line 1\nLine 2\n"    # Line 1
                              # Line 2

# Some backslash escapes are interpreted in double quotes:
echo "Quotes: \" \\"         # Quotes: " \
echo "Dollar: \$"            # Dollar: $
echo "Backtick: \`"          # Backtick: `
echo "Bang: \!"              # Bang: \! (or ! in interactive bash)

# These are NOT interpreted in double quotes:
echo "Newline: \n"           # Newline: \n (literal)
echo "Tab: \t"               # Tab: \t (literal)
echo "Alert: \a"             # Alert: \a (literal)

# Glob characters are NOT expanded
echo "*.txt"                 # *.txt (literal)

# Word splitting is NOT performed
var="one two three"
echo "$var"                  # one two three (single argument)
```

### Preserving Whitespace

```bash
# ✅ Double quotes preserve whitespace in variables
files="file1.txt file2.txt file3.txt"
for f in "$files"; do        # One iteration
    echo "[$f]"
done
# [file1.txt file2.txt file3.txt]

# ❌ Without quotes: word splitting
for f in $files; do          # Three iterations
    echo "[$f]"
done
# [file1.txt]
# [file2.txt]
# [file3.txt]

# ✅ Array expansion with double quotes
arr=("file 1.txt" "file 2.txt" "file 3.txt")
for f in "${arr[@]}"; do     # Three iterations, spaces preserved
    echo "[$f]"
done
# [file 1.txt]
# [file 2.txt]
# [file 3.txt]
```

### When to Use Double Quotes

```bash
# ✅ Almost always for variable expansion
echo "$HOME"
echo "${array[@]}"
echo "$(command)"

# ✅ Strings that need variable expansion
greeting="Hello, $name!"

# ✅ Command arguments with spaces
file="my file.txt"
cat "$file"

# ✅ Preserving whitespace while allowing expansion
echo "   $var   "
```

## Backslash

The backslash (`\`) escapes a single character, preventing its interpretation.

```bash
# Escape special characters
echo \$HOME              # $HOME
echo \*.txt              # *.txt
echo \"                  # "
echo \\                  # \
echo \!                  # ! (in interactive bash)

# Line continuation
echo "This is a very long \
command that continues \
on the next line"
# This is a very long command that continues on the next line

# In commands
grep '\.txt$' file.txt   # \. is literal dot (in regex context)
find . -name "*.txt"     # \ not needed here

# Escape newlines (line continuation)
total=$((1 + \
        2 + \
        3))
echo "$total"            # 6

# Escape spaces (rarely useful)
echo hello\ world        # hello world

# In double quotes, backslash only escapes: $ ` " \ ! newline
echo "\$HOME is $HOME"   # $HOME is /home/user
echo "quote: \""          # quote: "
echo "backslash: \\"      # backslash: \

# In single quotes, backslash is literal
echo '\$HOME'             # \$HOME
echo '\\'                 # \\ (two characters)
```

### Backslash in Different Contexts

```bash
# In glob patterns: escape special characters
ls \[file\].txt          # Literal [file].txt
ls file\?.txt            # Literal file?.txt

# In regular expressions
grep 'end\$' file.txt    # Lines ending with literal $
grep '^start' file.txt   # Lines starting with "start"

# In sed
sed 's/old\\/new\\/g'    # Replace "old\" with "new\"

# In awk
awk '{print \$1}'        # Print first field ($1 is awk variable)
```

## ANSI-C Quoting $''

ANSI-C quoting (`$'...'`) interprets C-style escape sequences while preventing other shell expansions.

```bash
# Escape sequences interpreted:
echo $'Line 1\nLine 2'        # Line 1
                               # Line 2

echo $'Tab\there'              # Tab	here

echo $'Bell\a'                 # Bell (with audible bell)

echo $'Backspace\b'            # Backspac (cursor moves back)

echo $'Carriage\rReturn'       # Return (overwrites)

echo $'Form\fFeed'             # Form feed

echo $'Null\x00'               # Null byte

echo $'Unicode: \u2764'        # Unicode: ❤

echo $'Octal: \101\102\103'    # Octal: ABC

echo $'Hex: \x41\x42\x43'     # Hex: ABC

# Embedded single quotes
echo $'It\'s a test'           # It's a test

# Mixed with variables (variable expansion happens BEFORE $'')
name="World"
echo $'Hello, '"$name"'!'      # Hello, World!
# Explanation: $'Hello, ' → Hello,  + "$name" → World + '!' → !
```

### ANSI-C Escape Sequences

| Sequence | Description |
|----------|-------------|
| `\a` | Alert (bell) |
| `\b` | Backspace |
| `\e`, `\E` | Escape character |
| `\f` | Form feed |
| `\n` | Newline |
| `\r` | Carriage return |
| `\t` | Horizontal tab |
| `\v` | Vertical tab |
| `\\` | Backslash |
| `\'` | Single quote |
| `\"` | Double quote |
| `\?` | Question mark |
| `\nnn` | Octal value (1-3 digits) |
| `\xHH` | Hexadecimal value (1-2 digits) |
| `\uHHHH` | Unicode (1-4 hex digits) |
| `\UHHHHHHHH` | Unicode (1-8 hex digits) |
| `\cx` | Control character |

### Practical Uses of ANSI-C Quoting

```bash
# Create files with special characters
touch $'file with\nnewline.txt'    # File with newline in name

# Working with binary data
echo $'\x00\x01\x02\x03' | xxd

# ANSI color codes (more readable)
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[0;33m'
BLUE=$'\033[0;34m'
BOLD=$'\033[1m'
RESET=$'\033[0m'

echo "${RED}Error${RESET}: file not found"
echo "${GREEN}Success${RESET}"

# Multi-byte characters
CHECKMARK=$'\u2714'   # ✔
CROSSMARK=$'\u2718'   # ✘
ARROW=$'\u2192'       # →
STAR=$'\u2605'        # ★

# Control characters
TAB=$'\t'
NEWLINE=$'\n'
CR=$'\r'
NULL=$'\0'

# IFS with special characters
IFS=$'\n\t'
```

## Here-Docs (<<)

Here-documents provide multi-line input to a command.

### Basic Here-Doc

```bash
# Basic here-doc
cat <<EOF
Hello, World!
This is a here-document.
EOF

# With variable expansion
name="World"
cat <<EOF
Hello, $name!
Today is $(date +%A).
EOF

# Without variable expansion (quoted delimiter)
cat <<'EOF'
$name is literal.
$(command) is literal.
$((2 + 3)) is literal.
EOF

# With variable expansion (unquoted delimiter)
cat <<EOF
$name is expanded.
$(command) is expanded.
$((2 + 3)) is expanded.
EOF
```

### Here-Doc Variants

```bash
# <<- : Strip leading tabs (for indentation in scripts)
if true; then
	cat <<-EOF
	Hello, World!
	This text has leading tabs stripped.
	EOF
fi

# <<< : Here-string (single line)
grep "pattern" <<< "$variable"
cat <<< "Hello, World!"

# Here-doc with custom delimiter
cat <<ENDOFMESSAGE
This is a multi-line message.
The delimiter can be any word.
ENDOFMESSAGE

# Here-doc in a function
send_email() {
    mail -s "Subject" user@example.com <<EOF
Hello,

This is an automated email.

Best regards,
The System
EOF
}

# Here-doc for SQL
mysql -u root -p <<EOF
CREATE DATABASE IF NOT EXISTS mydb;
USE mydb;
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100)
);
EOF

# Here-doc for configuration files
cat > /etc/nginx/conf.d/app.conf <<'EOF'
server {
    listen 80;
    server_name example.com;
    root /var/www/html;
    
    location / {
        try_files $uri $uri/ =404;
    }
}
EOF
```

### Here-Doc with eval

```bash
# Dynamic here-doc with eval
template="Hello, \$name! Today is \$(date +%A)."
name="World"
eval "cat <<EOF
$template
EOF"
# Output: Hello, World! Today is Monday.
```

## Here-Strings (<<<)

Here-strings are a shorthand for feeding a single line to a command's stdin.

```bash
# Basic here-string
cat <<< "Hello, World!"

# With variable expansion
var="Hello"
cat <<< "$var, World!"

# With command substitution
cat <<< "$(date)"

# With arithmetic
cat <<< "$((2 + 3))"

# Practical uses
read -r first last <<< "John Doe"
echo "$first"    # John
echo "$last"     # Doe

grep "pattern" <<< "$text"

while read -r line; do
    echo "$line"
done <<< "$multiline_var"

# Feed to awk
awk '{print $2}' <<< "one two three"

# Here-string vs here-doc
# Here-string: single line
cat <<< "one line"

# Here-doc: multiple lines
cat <<EOF
line 1
line 2
line 3
EOF
```

## Quoting Best Practices

### Always Quote Variables

```bash
# ❌ Unquoted: subject to word splitting and globbing
echo $var
cat $file
rm $file

# ✅ Quoted: safe
echo "$var"
cat "$file"
rm "$file"
```

### Use Single Quotes for Literals

```bash
# ✅ Single quotes for literal strings
echo 'The price is $5.00'
grep '^[0-9]+$' file.txt

# ❌ Double quotes need escaping
echo "The price is \$5.00"
```

### Use Double Quotes for Variable Expansion

```bash
# ✅ Double quotes when you need variables
echo "Hello, $name!"
echo "Today is $(date +%A)"
```

### Use $'' for Escape Sequences

```bash
# ✅ ANSI-C quoting for escape sequences
echo $'Line 1\nLine 2'
TAB=$'\t'
RED=$'\033[0;31m'
```

### Concatenating Quoted Strings

```bash
# Bash concatenates adjacent strings
greeting="Hello, "$name"!"      # Mixed quoting
greeting='Hello, '"$name"'!'    # Same result
greeting=$'Hello, '"$name"$'!\n'  # With escapes

# Common pattern: variable in single-quoted context
echo 'User: '"$USER"' Home: '"$HOME"
# User: user Home: /home/user
```

### Here-Docs for Multi-Line Strings

```bash
# ✅ Here-doc for configuration
cat > config.txt <<'EOF'
key1=value1
key2=value2
key3=value3
EOF

# ✅ Here-doc with expansion
cat > report.txt <<EOF
Report generated: $(date)
User: $USER
Host: $(hostname)
EOF
```

## Common Pitfalls

### 1. Missing Quote on Variable

```bash
# ❌ Filename with spaces
file="my document.txt"
cat $file            # Tries to cat "my" and "document.txt"

# ✅ Always quote
cat "$file"
```

### 2. Quoting Array Expansion

```bash
# ❌ Without quotes: each element word-split
arr=("file one" "file two")
for f in ${arr[@]}; do echo "$f"; done
# file
# one
# file
# two

# ✅ With quotes: elements preserved
for f in "${arr[@]}"; do echo "$f"; done
# file one
# file two
```

### 3. Here-Doc Indentation

```bash
# ❌ Tabs/spaces preserved in here-doc
if true; then
    cat <<EOF
    This line has leading spaces.
    So does this one.
    EOF
fi
# Error: EOF not found (because it's indented with spaces)

# ✅ Use <<- to strip leading tabs
if true; then
    cat <<-EOF
    This line has no leading tabs.
    EOF
fi
```

### 4. Single Quote Inside Single Quotes

```bash
# ❌ Can't embed single quote directly
echo 'It's a test'    # Syntax error

# ✅ End quote, escaped quote, start quote
echo 'It'\''s a test'

# ✅ Use double quotes
echo "It's a test"

# ✅ Use ANSI-C quoting
echo $'It\'s a test'
```

### 5. Globbing in Double Quotes

```bash
# ✅ Double quotes prevent globbing
echo "*.txt"           # *.txt (literal)

# ❌ Without quotes: glob expansion
echo *.txt             # file1.txt file2.txt (expanded)
```

## Exercises

### Exercise 1: Quote Conversion
Convert these unquoted commands to properly quoted versions:
```bash
echo $HOME/$USER
cat /path/to/my file.txt
grep ^[0-9]+$ file.txt
echo "Price: $5.00"
```

### Exercise 2: Here-Doc Generator
Write a script that uses here-docs to generate:
- An nginx configuration file
- A systemd service unit file
- A cron job entry
All with variable substitution for customization.

### Exercise 3: ANSI-C Quoting
Write a colored output function using ANSI-C quoting that supports:
- Multiple colors (red, green, yellow, blue, cyan, magenta)
- Bold, underline, and italic attributes
- Reset functionality
- Nested formatting

### Exercise 4: Quote Safety Audit
Write a script that checks other scripts for quoting issues:
- Unquoted variables in command arguments
- Missing quotes around `$@` or `$*`
- Incorrect here-doc delimiter quoting
- Unquoted command substitutions

### Exercise 5: String Building
Implement a string builder that uses different quoting mechanisms to construct complex strings containing:
- Variables
- Command substitutions
- Literal special characters ($, !, ", ', \)
- Newlines and tabs
- Unicode characters

## References

- [Bash Manual: Quoting](https://www.gnu.org/software/bash/manual/bash.html#Quoting)
- [POSIX: Quoting](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_02)
- [Greg's Wiki: Quoting](https://mywiki.wooledge.org/Quotes)
- [Bash Hackers: Quoting](https://wiki.bash-hackers.org/syntax/quoting)
- [Bash Pitfalls: Quoting](https://mywiki.wooledge.org/BashPitfalls)
- [ANSI-C Quoting](https://www.gnu.org/software/bash/manual/bash.html#ANSI_002dC-Quoting)
