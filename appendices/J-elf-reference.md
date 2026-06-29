# Appendix J: ELF Reference

## Overview

ELF (Executable and Linkable Format) is the standard binary format for executables, object files, shared libraries, and core dumps on Linux and most UNIX-like systems. This appendix documents ELF header fields, section types, relocation types, and symbol binding.

---

## 1. ELF File Types

| Type | Value | Description |
|------|-------|-------------|
| `ET_NONE` | 0 | Unknown type |
| `ET_REL` | 1 | Relocatable file (`.o` object file) |
| `ET_EXEC` | 2 | Executable file |
| `ET_DYN` | 3 | Shared object (`.so`) or PIE executable |
| `ET_CORE` | 4 | Core dump |

---

## 2. ELF Header (Elf64_Ehdr)

The ELF header is located at offset 0 of the file.

| Field | Size | Description |
|-------|------|-------------|
| `e_ident[EI_MAG0-3]` | 4 bytes | Magic number: `0x7f 'E' 'L' 'F'` |
| `e_ident[EI_CLASS]` | 1 byte | File class: 1=32-bit, 2=64-bit |
| `e_ident[EI_DATA]` | 1 byte | Data encoding: 1=LE, 2=BE |
| `e_ident[EI_VERSION]` | 1 byte | ELF version (1) |
| `e_ident[EI_OSABI]` | 1 byte | OS/ABI identification |
| `e_ident[EI_ABIVERSION]` | 1 byte | ABI version |
| `e_ident[EI_PAD]` | 7 bytes | Padding (reserved) |
| `e_type` | 2 bytes | Object file type (see above) |
| `e_machine` | 2 bytes | Target architecture |
| `e_version` | 4 bytes | ELF version (1) |
| `e_entry` | 8 bytes | Entry point address |
| `e_phoff` | 8 bytes | Program header table offset |
| `e_shoff` | 8 bytes | Section header table offset |
| `e_flags` | 4 bytes | Processor-specific flags |
| `e_ehsize` | 2 bytes | ELF header size (64 bytes for 64-bit) |
| `e_phentsize` | 2 bytes | Program header entry size |
| `e_phnum` | 2 bytes | Number of program header entries |
| `e_shentsize` | 2 bytes | Section header entry size |
| `e_shnum` | 2 bytes | Number of section header entries |
| `e_shstrndx` | 2 bytes | Section name string table index |

### Machine Types

| Value | Name | Description |
|-------|------|-------------|
| 0 | `EM_NONE` | No machine |
| 1 | `EM_M32` | AT&T WE 32100 |
| 2 | `EM_SPARC` | SPARC |
| 3 | `EM_386` | Intel 80386 (x86) |
| 4 | `EM_68K` | Motorola 68000 |
| 8 | `EM_MIPS` | MIPS |
| 20 | `EM_PPC` | PowerPC |
| 21 | `EM_PPC64` | PowerPC 64-bit |
| 22 | `EM_S390` | IBM S/390 |
| 40 | `EM_ARM` | ARM |
| 42 | `EM_SH` | Hitachi SH |
| 43 | `EM_SPARCV9` | SPARC V9 |
| 50 | `EM_IA_64` | Intel IA-64 |
| 62 | `EM_X86_64` | AMD x86-64 |
| 183 | `EM_AARCH64` | ARM AArch64 |
| 243 | `EM_RISCV` | RISC-V |

---

## 3. Section Header (Elf64_Shdr)

| Field | Size | Description |
|-------|------|-------------|
| `sh_name` | 4 bytes | Section name (index into string table) |
| `sh_type` | 4 bytes | Section type |
| `sh_flags` | 8 bytes | Section flags |
| `sh_addr` | 8 bytes | Virtual address in memory |
| `sh_offset` | 8 bytes | Offset in file |
| `sh_size` | 8 bytes | Section size in bytes |
| `sh_link` | 4 bytes | Link to another section |
| `sh_info` | 4 bytes | Additional information |
| `sh_addralign` | 8 bytes | Address alignment |
| `sh_entsize` | 8 bytes | Entry size (for tables) |

### Section Types

| Type | Value | Description |
|------|-------|-------------|
| `SHT_NULL` | 0 | Inactive (no associated section) |
| `SHT_PROGBITS` | 1 | Program-defined data (code, data) |
| `SHT_SYMTAB` | 2 | Symbol table |
| `SHT_STRTAB` | 3 | String table |
| `SHT_RELA` | 4 | Relocations with addends |
| `SHT_HASH` | 5 | Symbol hash table |
| `SHT_DYNAMIC` | 6 | Dynamic linking information |
| `SHT_NOTE` | 7 | Notes (e.g., build ID) |
| `SHT_NOBITS` | 8 | No bits (BSS, uninitialized data) |
| `SHT_REL` | 9 | Relocations without addends |
| `SHT_DYNSYM` | 11 | Dynamic symbol table |
| `SHT_INIT_ARRAY` | 14 | Array of constructors |
| `SHT_FINI_ARRAY` | 15 | Array of destructors |
| `SHT_PREINIT_ARRAY` | 16 | Array of pre-constructors |
| `SHT_GROUP` | 17 | Section group |
| `SHT_SYMTAB_SHNDX` | 18 | Symbol table section index |
| `SHT_GNU_HASH` | 0x6ffffff6 | GNU hash table |
| `SHT_GNU_VERDEF` | 0x6ffffffd | Version definitions |
| `SHT_GNU_VERNEED` | 0x6ffffffe | Version requirements |
| `SHT_GNU_VERSYM` | 0x6fffffff | Version symbol table |

### Section Flags

| Flag | Value | Description |
|------|-------|-------------|
| `SHF_WRITE` | 0x1 | Writable data |
| `SHF_ALLOC` | 0x2 | Occupies memory during execution |
| `SHF_EXECINSTR` | 0x4 | Contains executable instructions |
| `SHF_MERGE` | 0x10 | May be merged |
| `SHF_STRINGS` | 0x20 | Contains null-terminated strings |
| `SHF_INFO_LINK` | 0x40 | `sh_info` contains section index |
| `SHF_LINK_ORDER` | 0x80 | Special ordering requirement |
| `SHF_OS_NONCONFORMING` | 0x100 | OS-specific processing required |
| `SHF_GROUP` | 0x200 | Member of section group |
| `SHF_TLS` | 0x400 | Thread-local storage |

---

## 4. Standard Section Names

| Section | Type | Description |
|---------|------|-------------|
| `.text` | `SHT_PROGBITS` | Executable code |
| `.rodata` | `SHT_PROGBITS` | Read-only data (constants, strings) |
| `.data` | `SHT_PROGBITS` | Initialized data |
| `.bss` | `SHT_NOBITS` | Uninitialized data (zero-initialized) |
| `.data.rel.ro` | `SHT_PROGBITS` | Relocatable read-only data |
| `.got` | `SHT_PROGBITS` | Global Offset Table |
| `.plt` | `SHT_PROGBITS` | Procedure Linkage Table |
| `.symtab` | `SHT_SYMTAB` | Symbol table |
| `.dynsym` | `SHT_DYNSYM` | Dynamic symbol table |
| `.strtab` | `SHT_STRTAB` | String table (for `.symtab`) |
| `.dynstr` | `SHT_STRTAB` | String table (for `.dynsym`) |
| `.rel.text` | `SHT_REL` | Relocations for `.text` |
| `.rela.text` | `SHT_RELA` | Relocations with addends for `.text` |
| `.rel.dyn` | `SHT_REL` | Dynamic relocations |
| `.rela.dyn` | `SHT_RELA` | Dynamic relocations with addends |
| `.rel.plt` | `SHT_REL` | PLT relocations |
| `.rela.plt` | `SHT_RELA` | PLT relocations with addends |
| `.dynamic` | `SHT_DYNAMIC` | Dynamic linking information |
| `.hash` | `SHT_HASH` | Symbol hash table |
| `.gnu.hash` | `SHT_GNU_HASH` | GNU hash table (faster) |
| `.interp` | `SHT_PROGBITS` | Program interpreter path |
| `.note` | `SHT_NOTE` | Notes |
| `.note.gnu.build-id` | `SHT_NOTE` | Build ID |
| `.comment` | `SHT_PROGBITS` | Version control strings |
| `.debug_*` | `SHT_PROGBITS` | DWARF debug information |
| `.eh_frame` | `SHT_PROGBITS` | Exception handling frame |
| `.eh_frame_hdr` | `SHT_PROGBITS` | Exception handling frame header |
| `.init` | `SHT_PROGBITS` | Initialization code |
| `.fini` | `SHT_PROGBITS` | Finalization code |
| `.init_array` | `SHT_INIT_ARRAY` | Constructor function pointers |
| `.fini_array` | `SHT_FINI_ARRAY` | Destructor function pointers |
| `.gnu.version` | `SHT_GNU_VERSYM` | Symbol versioning |
| `.gnu.version_d` | `SHT_GNU_VERDEF` | Version definitions |
| `.gnu.version_r` | `SHT_GNU_VERNEED` | Version requirements |
| `.ctors` | `SHT_PROGBITS` | Constructors (legacy) |
| `.dtors` | `SHT_PROGBITS` | Destructors (legacy) |
| `.tbss` | `SHT_NOBITS` | Thread-local BSS |
| `.tdata` | `SHT_PROGBITS` | Thread-local data |

---

## 5. Symbol Table (Elf64_Sym)

### Symbol Entry

| Field | Size | Description |
|-------|------|-------------|
| `st_name` | 4 bytes | Symbol name (index into string table) |
| `st_info` | 1 byte | Symbol type and binding |
| `st_other` | 1 byte | Symbol visibility |
| `st_shndx` | 2 bytes | Section index |
| `st_value` | 8 bytes | Symbol value (address) |
| `st_size` | 8 bytes | Symbol size in bytes |

### Symbol Binding (upper 4 bits of `st_info`)

| Binding | Value | Description |
|---------|-------|-------------|
| `STB_LOCAL` | 0 | Local symbol (not visible outside object file) |
| `STB_GLOBAL` | 1 | Global symbol (visible to all object files) |
| `STB_WEAK` | 2 | Weak symbol (like global but lower precedence) |
| `STB_LOOS` | 10 | OS-specific start |
| `STB_HIOS` | 12 | OS-specific end |
| `STB_LOPROC` | 13 | Processor-specific start |
| `STB_HIPROC` | 15 | Processor-specific end |

### Symbol Type (lower 4 bits of `st_info`)

| Type | Value | Description |
|------|-------|-------------|
| `STT_NOTYPE` | 0 | Type not specified |
| `STT_OBJECT` | 1 | Data object (variable, array) |
| `STT_FUNC` | 2 | Function |
| `STT_SECTION` | 3 | Section symbol |
| `STT_FILE` | 4 | Source file name |
| `STT_COMMON` | 5 | Common data object (uninitialized) |
| `STT_TLS` | 6 | Thread-local storage |
| `STT_LOOS` | 10 | OS-specific start |
| `STT_HIOS` | 12 | OS-specific end |
| `STT_LOPROC` | 13 | Processor-specific start |
| `STT_HIPROC` | 15 | Processor-specific end |

### Symbol Visibility (lower 3 bits of `st_other`)

| Visibility | Value | Description |
|------------|-------|-------------|
| `STV_DEFAULT` | 0 | Default visibility (exported) |
| `STV_INTERNAL` | 1 | Processor-specific hidden class |
| `STV_HIDDEN` | 2 | Not exported (hidden) |
| `STV_PROTECTED` | 3 | Not preemptible (protected) |

### Special Section Indices

| Index | Name | Description |
|-------|------|-------------|
| 0 | `SHN_UNDEF` | Undefined symbol |
| 0xfff1 | `SHN_ABS` | Absolute value (not relocatable) |
| 0xfff2 | `SHN_COMMON` | Common symbol (unallocated) |

---

## 6. Program Header (Elf64_Phdr)

| Field | Size | Description |
|-------|------|-------------|
| `p_type` | 4 bytes | Segment type |
| `p_flags` | 4 bytes | Segment flags |
| `p_offset` | 8 bytes | Offset in file |
| `p_vaddr` | 8 bytes | Virtual address |
| `p_paddr` | 8 bytes | Physical address |
| `p_filesz` | 8 bytes | Size in file |
| `p_memsz` | 8 bytes | Size in memory |
| `p_align` | 8 bytes | Alignment |

### Segment Types

| Type | Value | Description |
|------|-------|-------------|
| `PT_NULL` | 0 | Unused |
| `PT_LOAD` | 1 | Loadable segment |
| `PT_DYNAMIC` | 2 | Dynamic linking information |
| `PT_INTERP` | 3 | Program interpreter |
| `PT_NOTE` | 4 | Notes |
| `PT_SHLIB` | 5 | Reserved |
| `PT_PHDR` | 6 | Program header table |
| `PT_TLS` | 7 | Thread-local storage |
| `PT_GNU_EH_FRAME` | 0x6474e550 | Exception handling frame |
| `PT_GNU_STACK` | 0x6474e551 | Stack (executable/non-executable) |
| `PT_GNU_RELRO` | 0x6474e552 | Read-only after relocation |

### Segment Flags

| Flag | Value | Description |
|------|-------|-------------|
| `PF_X` | 0x1 | Executable |
| `PF_W` | 0x2 | Writable |
| `PF_R` | 0x4 | Readable |

---

## 7. Relocation Types

### x86_64 Relocations

| Type | Value | Description |
|------|-------|-------------|
| `R_X86_64_NONE` | 0 | No relocation |
| `R_X86_64_64` | 1 | S + A (64-bit) |
| `R_X86_64_PC32` | 2 | S + A - P (32-bit PC-relative) |
| `R_X86_64_GOT32` | 3 | G + A (GOT entry) |
| `R_X86_64_PLT32` | 4 | L + A - P (PLT entry) |
| `R_X86_64_COPY` | 5 | Copy symbol at runtime |
| `R_X86_64_GLOB_DAT` | 6 | S (GOT entry for data) |
| `R_X86_64_JUMP_SLOT` | 7 | S (PLT entry for function) |
| `R_X86_64_RELATIVE` | 8 | B + A (relative) |
| `R_X86_64_GOTPCREL` | 9 | G + GOT + A - P (GOT PC-relative) |
| `R_X86_64_32` | 10 | S + A (32-bit, zero-extend) |
| `R_X86_64_32S` | 11 | S + A (32-bit, sign-extend) |
| `R_X86_64_16` | 12 | S + A (16-bit) |
| `R_X86_64_PC16` | 13 | S + A - P (16-bit PC-relative) |
| `R_X86_64_8` | 14 | S + A (8-bit) |
| `R_X86_64_PC8` | 15 | S + A - P (8-bit PC-relative) |
| `R_X86_64_DTPMOD64` | 16 | Module number (TLS) |
| `R_X86_64_DTPOFF64` | 17 | Module-relative offset (TLS) |
| `R_X86_64_TPOFF64` | 18 | Thread-pointer-relative offset (TLS) |
| `R_X86_64_TLSGD` | 19 | GD GOT entry |
| `R_X86_64_TLSLD` | 20 | LD GOT entry |
| `R_X86_64_DTPOFF32` | 21 | Module-relative offset (32-bit TLS) |
| `R_X86_64_GOTTPOFF` | 22 | GOT entry for IE TLS |
| `R_X86_64_TPOFF32` | 23 | Thread-pointer-relative offset (32-bit TLS) |
| `R_X86_64_PC64` | 24 | S + A - P (64-bit PC-relative) |
| `R_X86_64_GOTOFF64` | 25 | S + A - GOT |
| `R_X86_64_GOTPC32` | 26 | GOT + A - P |
| `R_X86_64_GOT64` | 27 | G + A |
| `R_X86_64_GOTPCREL64` | 28 | G + GOT + A - P |
| `R_X86_64_GOTPC64` | 29 | GOT + A - P |
| `R_X86_64_GOTPLT64` | 30 | G + A (PLT) |
| `R_X86_64_PLTOFF64` | 31 | L + A - GOT |
| `R_X86_64_SIZE32` | 32 | Z + A (32-bit size) |
| `R_X86_64_SIZE64` | 33 | Z + A (64-bit size) |
| `R_X86_64_IRELATIVE` | 37 | Indirect relative (ifunc) |

### Relocation Formula Legend

| Symbol | Meaning |
|--------|---------|
| `A` | Addend (stored in relocation entry for RELA) |
| `B` | Base address of shared object |
| `G` | Offset of symbol's GOT entry |
| `GOT` | Address of GOT |
| `L` | Address of symbol's PLT entry |
| `P` | Address of relocation target |
| `S` | Value of symbol |

---

## 8. Dynamic Section (Elf64_Dyn)

### Dynamic Entry

| Field | Size | Description |
|-------|------|-------------|
| `d_tag` | 8 bytes | Type of dynamic entry |
| `d_un.d_val` | 8 bytes | Integer value |
| `d_un.d_ptr` | 8 bytes | Virtual address |

### Dynamic Tags

| Tag | Value | Description |
|-----|-------|-------------|
| `DT_NULL` | 0 | End of dynamic section |
| `DT_NEEDED` | 1 | Name of needed library |
| `DT_PLTRELSZ` | 2 | Size of PLT relocations |
| `DT_PLTGOT` | 3 | Address of PLT/GOT |
| `DT_HASH` | 4 | Address of symbol hash table |
| `DT_STRTAB` | 5 | Address of string table |
| `DT_SYMTAB` | 6 | Address of symbol table |
| `DT_RELA` | 7 | Address of RELA relocations |
| `DT_RELASZ` | 8 | Size of RELA relocations |
| `DT_RELAENT` | 9 | Size of RELA entry |
| `DT_STRSZ` | 10 | Size of string table |
| `DT_SYMENT` | 11 | Size of symbol entry |
| `DT_INIT` | 12 | Address of init function |
| `DT_FINI` | 13 | Address of fini function |
| `DT_SONAME` | 14 | Shared object name |
| `DT_RPATH` | 15 | Library search path (deprecated) |
| `DT_SYMBOLIC` | 16 | Symbolic binding |
| `DT_REL` | 17 | Address of REL relocations |
| `DT_RELSZ` | 18 | Size of REL relocations |
| `DT_RELENT` | 19 | Size of REL entry |
| `DT_PLTREL` | 20 | Type of PLT relocation (REL or RELA) |
| `DT_DEBUG` | 21 | Debug information |
| `DT_TEXTREL` | 22 | Text segment has relocations |
| `DT_JMPREL` | 23 | Address of PLT relocations |
| `DT_BIND_NOW` | 24 | Bind now (no lazy resolution) |
| `DT_INIT_ARRAY` | 25 | Address of init array |
| `DT_FINI_ARRAY` | 26 | Address of fini array |
| `DT_INIT_ARRAYSZ` | 27 | Size of init array |
| `DT_FINI_ARRAYSZ` | 28 | Size of fini array |
| `DT_RUNPATH` | 29 | Library search path |
| `DT_FLAGS` | 30 | Flags |
| `DT_PREINIT_ARRAY` | 32 | Address of pre-init array |
| `DT_PREINIT_ARRAYSZ` | 33 | Size of pre-init array |
| `DT_GNU_HASH` | 0x6ffffef5 | GNU hash table address |
| `DT_VERSYM` | 0x6ffffff0 | Version symbol table |
| `DT_VERDEF` | 0x6ffffffc | Version definitions |
| `DT_VERDEFNUM` | 0x6ffffffd | Number of version definitions |
| `DT_VERNEED` | 0x6ffffffe | Version requirements |
| `DT_VERNEEDNUM` | 0x6fffffff | Number of version requirements |

---

## 9. Inspecting ELF Files

### Using readelf

```bash
# File header
readelf -h /bin/ls

# Section headers
readelf -S /bin/ls

# Program headers
readelf -l /bin/ls

# Symbol table
readelf -s /bin/ls

# Dynamic section
readelf -d /usr/lib/libc.so.6

# Relocations
readelf -r /usr/lib/libc.so.6

# Notes
readelf -n /bin/ls

# All headers
readelf -a /bin/ls

# Version information
readelf -V /usr/lib/libc.so.6
```

### Using objdump

```bash
# Disassemble
objdump -d /bin/ls

# Disassemble with source
objdump -S /bin/ls

# Section headers
objdump -h /bin/ls

# Symbol table
objdump -t /bin/ls

# Dynamic symbols
objdump -T /bin/ls

# Raw data
objdump -s -j .rodata /bin/ls
```

### Using nm

```bash
# List symbols
nm /usr/lib/libc.a

# Dynamic symbols
nm -D /usr/lib/libc.so.6

# Undefined symbols only
nm -u /bin/ls

# Sorted by address
nm -n /bin/ls

# External symbols only
nm --extern-only /bin/ls

# Demangle C++ names
nm -C /usr/lib/libstdc++.so.6
```

### Using file

```bash
# Identify ELF type
file /bin/ls
# Output: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, for GNU/Linux 3.2.0, stripped

file /usr/lib/libc.so.6
# Output: ELF 64-bit LSB shared object, x86-64, version 1 (GNU/Linux), dynamically linked, ...
```

### Using size

```bash
# Show section sizes
size /bin/ls

# Berkeley format (default)
size -A /bin/ls

# SysV format
size --format=sysv /bin/ls
```

### Using strip

```bash
# Strip debug info
strip /bin/ls

# Strip all symbols
strip -s /bin/ls

# Strip to minimum
strip --strip-all /bin/ls

# Keep specific symbols
strip --keep-symbol=main /bin/ls

# Extract debug info
objcopy --only-keep-debug /bin/ls /bin/ls.debug
strip --strip-debug /bin/ls
objcopy --add-gnu-debuglink=/bin/ls.debug /bin/ls
```

---

## 10. ELF Linking

### Static Linking

```
source.c → [compiler] → source.o (ET_REL)
source.o + lib.a → [linker] → program (ET_EXEC)
```

### Dynamic Linking

```
source.c → [compiler] → source.o (ET_REL)
source.o + lib.so → [linker] → program (ET_DYN/ET_EXEC)
program + lib.so → [dynamic linker: ld-linux.so] → running process
```

### Linker Script

```bash
# Show default linker script
ld --verbose

# Custom linker script
ld -T script.lds -o output input.o
```

### Shared Library Versioning

```
libfoo.so → libfoo.so.1 → libfoo.so.1.2.3

libfoo.so.1.2.3  # Real name (actual file)
libfoo.so.1      # SONAME (used by dynamic linker)
libfoo.so        # Linker name (used at compile time)
```

```bash
# Create versioned library
gcc -shared -Wl,-soname,libfoo.so.1 -o libfoo.so.1.2.3 foo.c

# Create symlinks
ln -s libfoo.so.1.2.3 libfoo.so.1
ln -s libfoo.so.1 libfoo.so
```

---

## 11. ELF Security Considerations

### RELRO (Read-Only Relocations)

```bash
# Partial RELRO (default)
gcc -Wl,-z,relro -o prog prog.c

# Full RELRO (all GOT entries resolved at load time)
gcc -Wl,-z,relro,-z,now -o prog prog.c
```

### Stack Protection

```bash
# Non-executable stack (default)
gcc -Wl,-z,noexecstack -o prog prog.c

# Executable stack (dangerous)
gcc -Wl,-z,execstack -o prog prog.c

# Check stack permissions
readelf -l prog | grep GNU_STACK
```

### Position Independent Code

```bash
# Position Independent Executable (PIE)
gcc -fPIE -pie -o prog prog.c

# Position Independent shared library
gcc -fPIC -shared -o libfoo.so foo.c

# Check if PIE
file prog
# "shared object" = PIE, "executable" = not PIE
```

### Symbol Visibility

```c
// Hide symbols by default
// Compile with: -fvisibility=hidden

// Export specific symbols
__attribute__((visibility("default")))
void exported_function(void) { ... }
```

---

*For complete ELF specification, see the System V ABI or `man 5 elf`. Tool documentation: `man readelf`, `man objdump`, `man nm`.*
