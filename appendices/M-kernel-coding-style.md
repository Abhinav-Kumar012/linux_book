# Appendix M: Kernel Coding Style

## Overview

The Linux kernel has a strict coding style documented in `Documentation/process/coding-style.rst`. This appendix covers formatting rules, naming conventions, comment style, and common patterns enforced by `checkpatch.pl`.

---

## 1. Indentation

### Tabs vs Spaces

```c
/* Use tabs for indentation, tabs are 8 characters */
static int my_function(int arg)
{
	if (arg < 0)		/* Use tabs, not spaces */
		return -EINVAL;

	switch (arg) {
	case 0:			/* Case labels at same level as switch */
		do_something();
		break;
	case 1:
		do_other();
		break;
	default:
		return -ENOSYS;
	}

	return 0;
}
```

### Line Length

```c
/* Maximum 80 characters per line (strong preference) */
/* Up to 100 characters is acceptable when it improves readability */

/* Bad - exceeds 80 chars */
pr_info("This is a very long message that should be split across multiple lines for readability\n");

/* Good - split long strings */
pr_info("This is a very long message that should be split "
	"across multiple lines for readability\n");

/* Bad - long function call */
ret = some_very_long_function_name(argument1, argument2, argument3, argument4, argument5);

/* Good - wrap arguments */
ret = some_very_long_function_name(argument1, argument2,
				   argument3, argument4,
				   argument5);
```

### Brace Placement

```c
/* Functions: opening brace on next line */
int my_function(int arg)
{
	/* body */
}

/* Everything else: opening brace on same line */
if (condition) {
	/* body */
} else {
	/* body */
}

while (condition) {
	/* body */
}

for (i = 0; i < n; i++) {
	/* body */
}

switch (arg) {
case 0:
	/* body */
	break;
default:
	break;
}
```

### Single-Statement Blocks

```c
/* No braces needed for single statements */
if (condition)
	action();

/* But braces are required if any branch is multi-line */
if (condition) {
	action();
	other_action();
} else {
	alternative();
}
```

---

## 2. Naming Conventions

### Variables and Functions

```c
/* Lowercase with underscores (snake_case) */
int my_variable;
unsigned long page_count;
struct task_struct *task;

/* No CamelCase (except for some existing structures) */
/* Bad:  int MyVariable; */
/* Good: int my_variable; */

/* Function names: lowercase with underscores */
static int calculate_offset(int base, int index)
{
	/* ... */
}

/* Global functions: descriptive, module-prefixed if needed */
void netdev_update_features(struct net_device *dev);
int pci_enable_device(struct pci_dev *dev);
```

### Naming Rules

| Element | Style | Example |
|---------|-------|---------|
| Variables | snake_case | `page_count`, `buf_size` |
| Functions | snake_case | `my_func()`, `get_value()` |
| Structs | snake_case | `struct task_struct` |
| Typedefs | snake_case (avoid) | `typedef int my_int_t` (discouraged) |
| Enums | snake_case | `enum my_state` |
| Macros | UPPER_CASE | `MAX_BUFFER_SIZE` |
| Constants | UPPER_CASE | `PAGE_SIZE`, `HZ` |

### Hungarian Notation

```c
/* NOT used in kernel code */
/* Bad:  int iCount; */
/* Bad:  char *pszName; */
/* Good: int count; */
/* Good: char *name; */
```

---

## 3. Comment Style

### Single-Line Comments

```c
/* This is a single-line comment */

/* NOT this style (C99) */
// This is not preferred in kernel code
```

### Multi-Line Comments

```c
/*
 * This is a multi-line comment.  The opening
 * line is blank after the /*, subsequent lines
 * begin with a *, and the closing line is
 * just * / on its own.
 */
```

### Function Documentation (kernel-doc)

```c
/**
 * my_function - Brief description of function
 * @arg1: Description of first argument
 * @arg2: Description of second argument
 *
 * Longer description of what the function does.  Can span
 * multiple paragraphs.
 *
 * Return: 0 on success, negative errno on failure.
 */
int my_function(int arg1, int arg2)
{
	/* ... */
}
```

### struct Documentation

```c
/**
 * struct my_device - Description of device structure
 * @name: Device name
 * @value: Current value
 * @flags: Device flags
 * @list: List head for device list
 *
 * This structure represents a device in the system.
 */
struct my_device {
	const char *name;
	int value;
	unsigned long flags;
	struct list_head list;
};
```

---

## 4. Functions

### Function Length

```c
/* Functions should be short and sweet */
/* A function should do one thing and do it well */
/* Aim for ~24 lines (fit on one screen) */
/* Maximum around 48 lines for complex functions */

/* Bad - function too long */
int process_everything(struct data *d)
{
	/* 200 lines of mixed concerns */
}

/* Good - split into focused functions */
static int validate_input(struct data *d)
{
	/* validation only */
}

static int transform_data(struct data *d)
{
	/* transformation only */
}

int process_everything(struct data *d)
{
	int ret;

	ret = validate_input(d);
	if (ret)
		return ret;

	return transform_data(d);
}
```

### Local Variables

```c
int my_function(int input)
{
	struct my_struct *ptr;	/* Pointer declarations */
	int ret;		/* Return value */
	int i;			/* Loop counter */
	char *name;		/* String pointer */

	/* Variables declared in order of use */
	/* Most important (most used) first */

	/* ... rest of function ... */
}
```

---

## 5. Preprocessor

### Macros

```c
/* Macros: UPPER_CASE */
#define MAX_BUFFER_SIZE	4096
#define MIN(a, b)	((a) < (b) ? (a) : (b))

/* Multi-line macros: do { } while (0) */
#define my_macro(a, b) \
do {			\
	foo(a);		\
	bar(b);		\
} while (0)

/* Avoid macros that look like functions */
/* Bad: */
#define ABS(x)	((x) < 0 ? -(x) : (x))
/* Good: use inline function instead */

static inline int abs_val(int x)
{
	return x < 0 ? -x : x;
}
```

### Include Guards

```c
/* NOT used in kernel code */
/* Kernel uses #pragma once equivalent via Makefile */

/* Instead, just include: */
#ifndef _MY_HEADER_H
#define _MY_HEADER_H

/* ... header content ... */

#endif /* _MY_HEADER_H */
```

### Conditional Compilation

```c
/* Use IS_ENABLED() for Kconfig options */
if (IS_ENABLED(CONFIG_MY_FEATURE)) {
	/* This code is optimized away if CONFIG_MY_FEATURE is not set */
}

/* Use #ifdef sparingly */
#ifdef CONFIG_MY_FEATURE
	/* Code that only exists when feature is enabled */
#endif
```

---

## 6. Data Structures

### Structure Initialization

```c
/* Designated initializers */
struct my_struct data = {
	.name = "device",
	.value = 42,
	.flags = FLAG_ACTIVE,
};

/* Array initialization */
static const int my_array[] = {
	[0] = 10,
	[1] = 20,
	[2] = 30,
};
```

### Container Of

```c
#include <linux/container_of.h>

struct my_device {
	struct device dev;
	int private_data;
};

/* Get containing struct from member */
struct device *dev = get_device();
struct my_device *mydev = container_of(dev, struct my_device, dev);
```

---

## 7. Alignment

### Function Arguments

```c
/* Align arguments to opening parenthesis */
ret = some_function(argument_one, argument_two,
		    argument_three, argument_four);

/* NOT aligned to tab stop */
ret = some_function(argument_one, argument_two,
		argument_three, argument_four);  /* Bad */
```

### Structure Members

```c
/* Align structure members (optional, use tabs) */
struct my_struct {
	unsigned long	flags;
	int		count;
	char		name[32];
	void		*data;
};
```

---

## 8. Error Handling

### Return Codes

```c
/* Use negative errno values */
static int my_function(void)
{
	if (!resource)
		return -ENOMEM;

	if (!permission)
		return -EACCES;

	return 0;
}

/* NOT: return 1 on error, 0 on success */
/* NOT: return true/false (except for bool functions) */
```

### Goto for Cleanup

```c
static int my_init(void)
{
	int ret;

	ret = allocate_resource1();
	if (ret)
		goto err1;

	ret = allocate_resource2();
	if (ret)
		goto err2;

	ret = allocate_resource3();
	if (ret)
		goto err3;

	return 0;

err3:
	free_resource2();
err2:
	free_resource1();
err1:
	return ret;
}
```

---

## 9. Printing

### printk Levels

```c
/* Use appropriate log levels */
pr_emerg("emergency\n");
pr_alert("alert\n");
pr_crit("critical\n");
pr_err("error: %d\n", ret);
pr_warn("warning\n");
pr_notice("notice\n");
pr_info("info\n");
pr_debug("debug\n");

/* Prefer pr_* over printk */
/* Bad:  printk(KERN_INFO "message\n"); */
/* Good: pr_info("message\n"); */

/* Use dev_* when device is available */
dev_err(dev, "error: %d\n", ret);
dev_warn(dev, "warning\n");
dev_info(dev, "info\n");
dev_dbg(dev, "debug\n");
```

### Format Specifiers

```c
/* Use kernel-specific format specifiers */
pr_info("pid: %d\n", pid);
pr_info("size: %zu\n", size);       /* size_t */
pr_info("offset: %lld\n", offset);  /* loff_t */
pr_info("pointer: %p\n", ptr);      /* Pointer (hashed) */
pr_info("pointer: %px\n", ptr);     /* Pointer (raw, for debugging) */
pr_info("MAC: %pM\n", mac);         /* MAC address */
pr_info("IPv4: %pI4\n", &ip);       /* IPv4 address */
pr_info("IPv6: %pI6\n", &ip6);      /* IPv6 address */
pr_info("UUID: %pU\n", uuid);       /* UUID */
```

---

## 10. checkpatch.pl

### Running checkpatch

```bash
# Check a file
scripts/checkpatch.pl --file path/to/file.c

# Check a patch
scripts/checkpatch.pl my_patch.patch

# Check with strict mode
scripts/checkpatch.pl --strict --file file.c

# Check without tree warnings
scripts/checkpatch.pl --no-tree --file file.c

# Check multiple files
find . -name "*.c" -exec scripts/checkpatch.pl --file {} +

# Fix auto-fixable issues
scripts/checkpatch.pl --fix-inplace --file file.c
```

### Common checkpatch Warnings

| Warning | Fix |
|---------|-----|
| `CHECK: Alignment should match open parenthesis` | Align to `(` |
| `WARNING: line over 80 characters` | Split line |
| `CHECK: Please use a blank line after declarations` | Add blank line |
| `WARNING: Missing a blank line after declarations` | Add blank line |
| `ERROR: space required before the open parenthesis '('` | Add space |
| `CHECK: braces {} are not necessary for single statement blocks` | Remove braces |
| `WARNING: Prefer pr_warn(...)` | Use `pr_warn` over `printk` |
| `ERROR: do not use C99 // comments` | Use `/* */` |
| `WARNING: Static const variables should be const` | Add `const` |
| `CHECK: Unnecessary parentheses` | Remove parens |

---

## 11. Kconfig Style

```
# Menu entries: aligned with tabs
config MY_FEATURE
	bool "Enable my feature"
	depends on OTHER_FEATURE
	default y if OTHER_FEATURE
	help
	  Enable my feature for better performance.

	  If unsure, say N.

config MY_COUNT
	int "Number of devices"
	range 1 256
	default 8
	help
	  Number of devices to create.

config MY_OPTION
	tristate "My loadable module"
	depends on MY_FEATURE
	help
	  This option allows my module to be built.
```

---

## 12. Makefile Style

```makefile
# Kernel Makefile
obj-$(CONFIG_MY_MODULE) += my_module.o

# Multiple objects
obj-$(CONFIG_MY_DRIVER) += my_driver.o
my_driver-objs := main.o helper.o utils.o

# Compiler flags
ccflags-y += -DDEBUG
ccflags-y += -I$(src)/include

# Per-file flags
CFLAGS_main.o += -DVERBOSE
```

---

## 13. Summary Checklist

| Rule | Description |
|------|-------------|
| ✅ Tabs for indentation | 8 characters wide |
| ✅ 80 char line limit | 100 acceptable occasionally |
| ✅ Opening brace on same line | Except functions |
| ✅ Closing brace on own line | With else: `} else {` |
| ✅ snake_case naming | Variables, functions, structs |
| ✅ UPPER_CASE macros | `#define MY_MACRO` |
| ✅ `/* */` comments | Not `//` |
| ✅ kernel-doc for functions | `/** ... */` |
| ✅ Negative errno returns | `-ENOMEM`, `-EINVAL` |
| ✅ `pr_*()` logging | Not `printk()` directly |
| ✅ `IS_ENABLED()` checks | Not `#ifdef` when possible |
| ✅ `checkpatch.pl` clean | Zero warnings/errors |

---

*Reference: Linux kernel coding style documentation at `Documentation/process/coding-style.rst` in the kernel source tree.*
