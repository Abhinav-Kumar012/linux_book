# Appendix H: Regular Expressions Handbook

## Overview

Regular expressions (regex) are patterns used to match character combinations in strings. This handbook covers BRE (Basic Regular Expressions), ERE (Extended Regular Expressions), and PCRE (Perl-Compatible Regular Expressions).

---

## 1. Regex Flavors Comparison

| Feature | BRE | ERE | PCRE |
|---------|-----|-----|------|
| Literal characters | ✓ | ✓ | ✓ |
| `.` (any char) | ✓ | ✓ | ✓ |
| `^` `$` anchors | ✓ | ✓ | ✓ |
| `*` quantifier | ✓ | ✓ | ✓ |
| `+` `?` quantifiers | `\+` `\?` | `+` `?` | `+` `?` |
| `{n,m}` quantifiers | `\{n,m\}` | `{n,m}` | `{n,m}` |
| `()` grouping | `\(\)` | `()` | `()` |
| `|` alternation | `\|` | `|` | `|` |
| `\d` `\w` `\s` | ✗ | ✗ | ✓ |
| Lookahead `(?=...)` | ✗ | ✗ | ✓ |
| Lookbehind `(?<=...)` | ✗ | ✗ | ✓ |
| Non-greedy `?` | ✗ | ✗ | ✓ |
| Named groups `(?P<name>)` | ✗ | ✗ | ✓ |
| Backreferences `\1` | ✓ | ✗ | ✓ |
| Character classes `[[:alpha:]]` | ✓ | ✓ | ✓ |

### Tools Using Each Flavor

| Flavor | Tools |
|--------|-------|
| BRE | `grep`, `sed`, `vi`, `ed` |
| ERE | `grep -E`, `egrep`, `awk`, `find -regex` |
| PCRE | `grep -P`, `perl`, Python `re`, many editors |

---

## 2. Character Classes

### Literal Characters

| Pattern | Matches |
|---------|---------|
| `abc` | Literal string "abc" |
| `123` | Literal string "123" |
| `\.` | Literal period |
| `\\` | Literal backslash |
| `\*` | Literal asterisk |
| `\[` | Literal opening bracket |
| `\+` | Literal plus (BRE) |
| `\?` | Literal question mark (BRE) |

### Metacharacters

| Metacharacter | Description | Example | Matches |
|---------------|-------------|---------|---------|
| `.` | Any single character (except newline) | `a.c` | "abc", "a1c", "a c" |
| `^` | Start of string/line | `^Hello` | "Hello World" |
| `$` | End of string/line | `World$` | "Hello World" |
| `*` | Zero or more of preceding | `ab*c` | "ac", "abc", "abbc" |
| `+` (ERE/PCRE) | One or more of preceding | `ab+c` | "abc", "abbc" (not "ac") |
| `?` (ERE/PCRE) | Zero or one of preceding | `ab?c` | "ac", "abc" |
| `\b` (PCRE) | Word boundary | `\bword\b` | "a word here" |

### Character Classes `[]`

| Pattern | Description | Matches |
|---------|-------------|---------|
| `[abc]` | Any of a, b, c | "a", "b", "c" |
| `[^abc]` | Not a, b, or c | "d", "e", "1" |
| `[a-z]` | Range: a through z | Any lowercase letter |
| `[A-Za-z]` | Any letter | Any letter |
| `[0-9]` | Any digit | Any digit |
| `[a-zA-Z0-9_]` | Word character | Letters, digits, underscore |
| `[-.]` | Literal - or . | "-", "." |
| `[a-z[0-9]]` | Union (POSIX) | Lowercase or digit |

### POSIX Character Classes

| Class | Description | Equivalent |
|-------|-------------|------------|
| `[:alnum:]` | Letters and digits | `[a-zA-Z0-9]` |
| `[:alpha:]` | Letters | `[a-zA-Z]` |
| `[:ascii:]` | ASCII characters | `[\x00-\x7F]` |
| `[:blank:]` | Space and tab | `[ \t]` |
| `[:cntrl:]` | Control characters | `[\x00-\x1F\x7F]` |
| `[:digit:]` | Digits | `[0-9]` |
| `[:graph:]` | Visible characters | `[!-~]` |
| `[:lower:]` | Lowercase letters | `[a-z]` |
| `[:print:]` | Visible chars + space | `[ -~]` |
| `[:punct:]` | Punctuation | `[!-/:-@[-`{-~]` |
| `[:space:]` | Whitespace | `[ \t\n\r\f\v]` |
| `[:upper:]` | Uppercase letters | `[A-Z]` |
| `[:word:]` (PCRE) | Word characters | `[a-zA-Z0-9_]` |
| `[:xdigit:]` | Hex digits | `[0-9a-fA-F]` |

**Usage**: `[[:alpha:]]` matches any letter. Must be inside `[]`.

### PCRE Shorthand Classes

| Shorthand | Description | Equivalent |
|-----------|-------------|------------|
| `\d` | Digit | `[0-9]` |
| `\D` | Not digit | `[^0-9]` |
| `\w` | Word character | `[a-zA-Z0-9_]` |
| `\W` | Not word character | `[^a-zA-Z0-9_]` |
| `\s` | Whitespace | `[ \t\n\r\f\v]` |
| `\S` | Not whitespace | `[^ \t\n\r\f\v]` |
| `\h` | Horizontal whitespace | `[ \t]` |
| `\H` | Not horizontal whitespace | `[^ \t]` |
| `\v` | Vertical whitespace | `[\n\r\f\v]` |
| `\V` | Not vertical whitespace | `[^\n\r\f\v]` |

---

## 3. Quantifiers

### Basic Quantifiers

| Quantifier | Description | Example | Matches |
|------------|-------------|---------|---------|
| `*` | Zero or more | `ab*c` | "ac", "abc", "abbc" |
| `+` | One or more | `ab+c` | "abc", "abbc" |
| `?` | Zero or one | `ab?c` | "ac", "abc" |
| `{n}` | Exactly n | `a{3}` | "aaa" |
| `{n,}` | n or more | `a{2,}` | "aa", "aaa", "aaaa" |
| `{n,m}` | Between n and m | `a{2,4}` | "aa", "aaa", "aaaa" |
| `{0,1}` | Zero or one (same as ?) | `a{0,1}` | "", "a" |
| `{1,}` | One or more (same as +) | `a{1,}` | "a", "aa", "aaa" |

### BRE Quantifiers (Escaped)

| BRE | ERE Equivalent |
|-----|----------------|
| `\{n\}` | `{n}` |
| `\{n,\}` | `{n,}` |
| `\{n,m\}` | `{n,m}` |
| `\+` | `+` |
| `\?` | `?` |

### Greedy vs Non-Greedy (PCRE)

| Quantifier | Behavior | Example (on "aabab") | Matches |
|------------|----------|----------------------|---------|
| `.*` | Greedy (longest) | `a.*b` | "aabab" |
| `.*?` | Non-greedy (shortest) | `a.*?b` | "aab" |
| `.+` | Greedy | `a.+b` | "aabab" |
| `.+?` | Non-greedy | `a.+?b` | "aab" |
| `.??` | Non-greedy optional | `a??b` | "b" |

### Possessive Quantifiers (PCRE)

| Quantifier | Description | Example |
|------------|-------------|---------|
| `*+` | Possessive zero or more | `a*+b` |
| `++` | Possessive one or more | `a++b` |
| `?+` | Possessive zero or one | `a?+b` |
| `{n,m}+` | Possessive range | `a{2,4}+b` |

Possessive quantifiers never backtrack, which can be faster but may cause matches to fail.

---

## 4. Anchors and Boundaries

| Anchor | Description | Example | Matches |
|--------|-------------|---------|---------|
| `^` | Start of string/line | `^Hello` | "Hello World" |
| `$` | End of string/line | `World$` | "Hello World" |
| `\A` (PCRE) | Start of string (no multiline) | `\AHello` | Start of string |
| `\Z` (PCRE) | End of string (before final newline) | `World\Z` | End of string |
| `\z` (PCRE) | Absolute end of string | `World\z` | Very end |
| `\b` (PCRE) | Word boundary | `\bword\b` | "a word here" |
| `\B` (PCRE) | Not word boundary | `\Bword\B` | "swordfish" |

### Word Boundary Examples

```
\bcat\b    → matches "the cat sat" (but not "concatenate")
\bcat      → matches "cat" and "catalog"
cat\b      → matches "cat" and "concat"
\Bcat\B    → matches "concatenate" (but not "cat" or "catalog")
```

---

## 5. Grouping and Capturing

### Basic Groups

| Pattern | Description | Example |
|---------|-------------|---------|
| `(abc)` | Capturing group | `(ab)+` matches "abab" |
| `(?:abc)` (ERE/PCRE) | Non-capturing group | `(?:ab)+` matches "abab" |
| `\1` `\2` (BRE/PCRE) | Backreference | `(a)\1` matches "aa" |
| `(?P<name>abc)` (PCRE) | Named group | `(?P<word>\w+)` |
| `(?P=name)` (PCRE) | Named backreference | `(?P<word>\w+) (?P=word)` |

### Group Numbering

```
((a)(b(c)))    → Group 1: "abc"
                 Group 2: "a"
                 Group 3: "bc"
                 Group 4: "c"
```

### Backreferences

| Pattern | Matches | Example |
|---------|---------|---------|
| `(a)\1` | Same char repeated | "aa", "aaa" |
| `(\w+)\s+\1` | Repeated word | "the the" |
| `(.)\1+` | Any repeated char | "aa", "bbb", "cccc" |
| `(['"])[^'"]*\1` | Matching quotes | "text" or 'text' |

---

## 6. Assertions (Lookahead/Lookbehind)

### Lookahead

| Pattern | Description | Example | Matches |
|---------|-------------|---------|---------|
| `(?=abc)` | Positive lookahead | `\w+(?=,)` | "one" in "one,two" |
| `(?!abc)` | Negative lookahead | `\d{3}(?!\d)` | "123" in "1234" as last 3 |

### Lookbehind

| Pattern | Description | Example | Matches |
|---------|-------------|---------|---------|
| `(?<=abc)` | Positive lookbehind | `(?<=\$)\d+` | "100" in "$100" |
| `(?<!abc)` | Negative lookbehind | `(?<!\$)\d+` | "100" in "100" |

### Examples

```python
# Positive lookahead: find word followed by number
re.findall(r'\w+(?=\d)', 'item1 item2 item3')
# → ['item', 'item', 'item']

# Negative lookahead: find "cat" not followed by "s"
re.findall(r'cat(?!s)', 'cat cats catastrophe')
# → ['cat', 'cat']

# Positive lookbehind: find numbers after $
re.findall(r'(?<=\$)\d+', '$100 €200 $300')
# → ['100', '300']

# Negative lookbehind: find numbers not after $
re.findall(r'(?<!\$)\d+', '$100 €200 $300')
# → ['100', '200', '300']
```

---

## 7. Common Patterns

### Email (Simplified)

```
[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}
```

### URL (Simplified)

```
https?://[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}(/[a-zA-Z0-9._~:/?#\[\]@!$&'()*+,;=-]*)?
```

### IPv4 Address

```
\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b
```

### IPv6 Address (Simplified)

```
(?:[0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}
```

### MAC Address

```
(?:[0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}
```

### Date (YYYY-MM-DD)

```
\d{4}-(?:0[1-9]|1[0-2])-(?:0[1-9]|[12]\d|3[01])
```

### Time (HH:MM:SS)

```
(?:[01]\d|2[0-3]):[0-5]\d:[0-5]\d
```

### Hex Color

```
#(?:[0-9a-fA-F]{3}){1,2}
```

### HTML Tag

```
<([a-zA-Z][a-zA-Z0-9]*)\b[^>]*>.*?</\1>
```

### Quoted String

```
"(?:[^"\\]|\\.)*"
```

### Integer

```
-?\d+
```

### Floating Point

```
-?\d+\.?\d*(?:[eE][+-]?\d+)?
```

### File Path (Unix)

```
/(?:[^/\0]+/)*[^/\0]*
```

### Username

```
[a-zA-Z0-9_-]{3,16}
```

### Password Strength

```
^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$
```

---

## 8. grep Examples

### Basic grep (BRE)

```bash
# Literal match
grep "error" /var/log/syslog

# Line numbers
grep -n "error" /var/log/syslog

# Count matches
grep -c "error" /var/log/syslog

# Case insensitive
grep -i "error" /var/log/syslog

# Invert match
grep -v "debug" /var/log/syslog

# Whole word
grep -w "error" /var/log/syslog

# Recursive
grep -r "TODO" /home/user/src/

# Show filenames only
grep -rl "error" /var/log/

# Show context
grep -B 3 -A 3 "error" /var/log/syslog

# BRE: basic patterns
grep 'error\|warning' file        # alternation
grep 'ab\{2,4\}c' file           # quantifier
grep '\(ab\)\{2\}' file          # grouping
grep '\<word\>' file              # word boundary (GNU)
```

### Extended grep (ERE)

```bash
# Extended regex
grep -E "error|warning" file

# Quantifiers
grep -E "ab{2,4}c" file
grep -E "ab+c" file
grep -E "ab?c" file

# Groups
grep -E "(ab){2}" file

# Character classes
grep -E "[[:alpha:]]+" file
grep -E "[0-9]{3}-[0-9]{4}" file

# Anchors
grep -E "^Start" file
grep -E "End$" file
grep -E "^$" file          # Empty lines
```

### Perl-compatible grep (PCRE)

```bash
# PCRE patterns
grep -P "\d{3}-\d{4}" file         # Digits
grep -P "\b\w+@\w+\.\w+\b" file   # Email-like
grep -P "(?<=error: ).*" file      # Lookbehind
grep -P "(?!debug)\w+" file        # Negative lookahead

# Non-greedy
grep -P "<.*?>" file               # Non-greedy HTML tags

# Named groups (with -o and -P)
grep -oP '(?P<ip>\d+\.\d+\.\d+\.\d+)' access.log

# Unicode
grep -P "\p{L}+" file              # Unicode letters
```

---

## 9. sed Examples

### Basic sed (BRE)

```bash
# Substitute
sed 's/old/new/' file              # First occurrence per line
sed 's/old/new/g' file             # All occurrences
sed 's/old/new/gi' file            # Case insensitive

# Delete lines
sed '/pattern/d' file
sed '3d' file                      # Delete line 3
sed '2,5d' file                    # Delete lines 2-5
sed '/^$/d' file                   # Delete empty lines

# Print specific lines
sed -n '10p' file                  # Print line 10
sed -n '10,20p' file               # Print lines 10-20

# Insert/Append
sed '3i\New line' file             # Insert before line 3
sed '3a\New line' file             # Append after line 3

# In-place editing
sed -i 's/old/new/g' file
sed -i.bak 's/old/new/g' file     # With backup
```

### Extended sed (ERE)

```bash
# Use -E for extended regex
sed -E 's/[0-9]+/NUM/g' file
sed -E 's/(foo|bar)/baz/g' file
sed -E 's/([a-z]+)-([a-z]+)/\2-\1/g' file  # Swap groups
```

---

## 10. awk Examples

```bash
# Pattern matching
awk '/pattern/ {print}' file
awk '!/pattern/ {print}' file     # Invert match

# Field processing
awk -F: '{print $1, $3}' /etc/passwd
awk -F, '{print NR, NF, $0}' data.csv

# Regex in awk
awk '/^[0-9]+$/ {print}' file           # Lines that are only digits
awk '$1 ~ /^[A-Z]/ {print}' file        # First field starts with uppercase
awk '$0 !~ /debug/ {print}' file        # Lines not containing "debug"

# Capture groups (GNU awk)
echo "2024-01-15" | awk '{
    match($0, /([0-9]{4})-([0-9]{2})-([0-9]{2})/, arr)
    print "Year:", arr[1], "Month:", arr[2], "Day:", arr[3]
}'
```

---

## 11. Regex Testing and Debugging

### Testing in the Shell

```bash
# Test regex with grep
echo "test string" | grep -P 'regex'

# Test with bash
[[ "test" =~ ^[a-z]+$ ]] && echo "match"

# Show what matches
echo "test string" | grep -oP 'regex'

# Debug: show match positions
echo "test string" | grep -oP '(?=regex)' | wc -l
```

### Common Debugging Tips

1. **Escape metacharacters**: `.`, `*`, `+`, `?`, `(`, `)`, `[`, `]`, `{`, `}`, `|`, `^`, `$`, `\`
2. **Check greedy vs non-greedy**: `.*` matches everything; `.*?` matches minimally
3. **Check anchors**: `^` and `$` may not work as expected with multiline
4. **Check character encoding**: Unicode vs ASCII affects `\w`, `\d`, etc.
5. **Test with simple inputs first**: Build regex incrementally

---

## 12. Performance Tips

| Tip | Description |
|-----|-------------|
| Use specific characters | `[a-z]` instead of `.` |
| Use non-capturing groups | `(?:...)` when you don't need the capture |
| Avoid backtracking | `[^"]*` instead of `.*?` |
| Anchor patterns | `^pattern$` when possible |
| Use possessive quantifiers | `a*+` instead of `a*` (PCRE) |
| Avoid alternation in tight loops | `[abc]` instead of `a\|b\|c` |
| Precompile patterns | Store compiled regex for reuse |

---

*For comprehensive regex reference, consult the PCRE documentation or tools like regex101.com for interactive testing.*
