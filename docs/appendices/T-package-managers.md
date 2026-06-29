# Appendix T: Package Managers Comparison

## Overview

This appendix compares five major Linux package managers: apt (Debian/Ubuntu), dnf (Fedora/RHEL), pacman (Arch), portage (Gentoo), and zypper (openSUSE).

---

## 1. Feature Comparison Matrix

| Feature | apt | dnf | pacman | portage | zypper |
|---------|-----|-----|--------|---------|--------|
| **Distribution** | Debian, Ubuntu | Fedora, RHEL, CentOS | Arch, Manjaro | Gentoo | openSUSE, SLES |
| **Package format** | .deb | .rpm | .pkg.tar.zst | ebuild | .rpm |
| **Source builds** | No (apt-build) | No (rpmbuild) | makepkg | Yes (native) | No (rpmbuild) |
| **Rolling release** | No (Debian stable) | Fedora Rawhide | Yes | Yes | Tumbleweed |
| **Dependency resolution** | Excellent | Excellent | Good | Excellent | Excellent |
| **Parallel downloads** | Yes | Yes | Yes | Yes | Yes |
| **Transaction history** | Yes | Yes | Yes | Yes | Yes |
| **Rollback** | Partial | Yes | Yes | Yes | Yes |
| **Delta updates** | No | Yes | Yes | Yes | Yes |
| **Snapshots** | No | No | No | Yes (NFS/Btrfs) | Yes (Btrfs) |
| **Sandboxing** | No | No | No | Yes (sandbox) | No |
| **USE flags** | No | No | No | Yes | No |
| **Package signing** | Yes | Yes | Yes | Yes | Yes |
| **Repo priority** | Yes | Yes | Yes | Yes | Yes |
| **Proxy support** | Yes | Yes | Yes | Yes | Yes |

---

## 2. apt (Advanced Package Tool)

### Common Commands

```bash
# Update package index
sudo apt update

# Upgrade all packages
sudo apt upgrade

# Full upgrade (may remove packages)
sudo apt full-upgrade

# Install package
sudo apt install nginx

# Install specific version
sudo apt install nginx=1.18.0-0ubuntu1

# Install local .deb file
sudo apt install ./package.deb

# Remove package
sudo apt remove nginx

# Remove package and config
sudo apt purge nginx

# Remove unused dependencies
sudo apt autoremove

# Search packages
apt search nginx

# Show package info
apt show nginx

# List installed packages
apt list --installed

# List upgradable packages
apt list --upgradable

# Show package dependencies
apt depends nginx

# Show reverse dependencies
apt rdepends nginx

# Download package without installing
apt download nginx

# Clean package cache
sudo apt clean
sudo apt autoclean

# Fix broken dependencies
sudo apt --fix-broken install

# Add repository
sudo add-apt-repository ppa:user/repo

# Hold package version
sudo apt-mark hold nginx
sudo apt-mark unhold nginx
```

### dpkg (Low-Level)

```bash
# Install .deb file
sudo dpkg -i package.deb

# List installed packages
dpkg -l | grep nginx

# Show package info
dpkg -s nginx

# List package files
dpkg -L nginx

# Find which package owns a file
dpkg -S /usr/bin/nginx

# Reconfigure package
sudo dpkg-reconfigure tzdata

# Remove package
sudo dpkg -r nginx

# Purge package
sudo dpkg -P nginx
```

### Configuration

```bash
# /etc/apt/sources.list
deb http://archive.ubuntu.com/ubuntu jammy main restricted
deb http://archive.ubuntu.com/ubuntu jammy-updates main restricted

# /etc/apt/sources.list.d/custom.list
deb https://example.com/repo stable main

# /etc/apt/apt.conf.d/
Acquire::http::Proxy "http://proxy:8080";
APT::Install-Recommends "false";
```

---

## 3. dnf (Dandified YUM)

### Common Commands

```bash
# Install package
sudo dnf install nginx

# Install specific version
sudo dnf install nginx-1.20.1

# Install from file
sudo dnf install ./package.rpm

# Update all packages
sudo dnf update

# Update specific package
sudo dnf update nginx

# Remove package
sudo dnf remove nginx

# Remove with dependencies
sudo dnf autoremove

# Search packages
dnf search nginx

# Show package info
dnf info nginx

# List installed packages
dnf list installed

# List available packages
dnf list available

# List updates
dnf check-update

# Show package dependencies
dnf deplist nginx

# Show what provides a file
dnf provides /usr/bin/nginx

# Show transaction history
dnf history

# Undo transaction
sudo dnf history undo 5

# Rollback to transaction
sudo dnf history rollback 3

# Clean cache
sudo dnf clean all

# Download package
dnf download --destdir=/tmp nginx

# Install module stream
sudo dnf module enable nginx:1.20
sudo dnf module install nginx:1.20/common

# Group install
sudo dnf group install "Development Tools"

# List groups
dnf group list

# Repository management
dnf repolist
sudo dnf config-manager --add-repo https://example.com/repo.rpm
sudo dnf config-manager --set-enabled repo-name
```

### DNF Configuration

```bash
# /etc/dnf/dnf.conf
[main]
gpgcheck=1
installonly_limit=3
clean_requirements_on_remove=True
best=False
skip_if_unavailable=True
max_parallel_downloads=10
fastestmirror=True
deltarpm=True
```

---

## 4. pacman (Arch Linux)

### Common Commands

```bash
# Update package database
sudo pacman -Sy

# Full system upgrade
sudo pacman -Syu

# Install package
sudo pacman -S nginx

# Install specific version
sudo pacman -S nginx=1.20.1

# Install from file
sudo pacman -U package.pkg.tar.zst

# Remove package
sudo pacman -R nginx

# Remove with dependencies
sudo pacman -Rs nginx

# Remove with config
sudo pacman -Rns nginx

# Search packages
pacman -Ss nginx

# Search installed
pacman -Qs nginx

# Show package info
pacman -Si nginx   # From sync database
pacman -Qi nginx   # Installed

# List installed packages
pacman -Q

# List explicitly installed
pacman -Qe

# List orphaned packages
pacman -Qdt

# List package files
pacman -Ql nginx

# Find which package owns a file
pacman -Qo /usr/bin/nginx

# Download package
pacman -Sw nginx

# Clean package cache
sudo pacman -Sc    # Remove uninstalled
sudo pacman -Scc   # Remove all cached

# Show package dependencies
pactree nginx

# Show reverse dependencies
pactree -r nginx

# Mark as explicitly installed
sudo pacman -D --asexplicit nginx

# Mark as dependency
sudo pacman -D --asdeps nginx
```

### AUR (Arch User Repository)

```bash
# Using yay (AUR helper)
yay -S package-name

# Search AUR
yay -Ss package-name

# Update AUR packages
yay -Syu

# Using paru
paru -S package-name
paru -Syu
```

### Makepkg

```bash
# Build package from PKGBUILD
makepkg -si

# Build without installing
makepkg -s

# Install dependencies only
makepkg -s --nobuild

# Clean build
makepkg -sCf
```

---

## 5. portage (Gentoo)

### Common Commands

```bash
# Sync repository
sudo emerge --sync

# Update system
sudo emerge -avuDN @world

# Install package
sudo emerge -av nginx

# Install with specific USE flags
sudo emerge -av nginx NGINX_MODULES_HTTP="ssl proxy"

# Remove package
sudo emerge -C nginx

# Remove with dependencies
sudo emerge -av --depclean

# Search packages
emerge -s nginx
emerge --search nginx

# Show package info
emerge -av --info nginx

# List installed packages
qlist -IC
equery list '*'

# Show package dependencies
emerge -ep nginx

# Pretend (dry run)
emerge -p nginx

# Resume interrupted emerge
sudo emerge --resume

# Clean world
sudo emerge --depclean

# Rebuild reverse dependencies
sudo revdep-rebuild

# Show USE flags
equery uses nginx

# Set USE flags per-package
# /etc/portage/package.use
www-servers/nginx NGINX_MODULES_HTTP_SSL

# Show package files
equery files nginx

# Show which package owns a file
equery belongs /usr/sbin/nginx

# Show reverse dependencies
equery depends nginx
```

### Portage Configuration

```bash
# /etc/portage/make.conf
USE="X gtk3 systemd pulseaudio"
CFLAGS="-O2 -pipe -march=native"
CXXFLAGS="${CFLAGS}"
MAKEOPTS="-j$(nproc)"
FEATURES="parallel-fetch ccache"
ACCEPT_KEYWORDS="~amd64"

# /etc/portage/package.use
www-servers/nginx NGINX_MODULES_HTTP_SSL NGINX_MODULES_HTTP_REWRITE

# /etc/portage/package.accept_keywords
=app-editors/vim-9.0.0 ~amd64

# /etc/portage/repos.conf/gentoo.conf
[DEFAULT]
main-repo = gentoo

[gentoo]
location = /var/db/repos/gentoo
sync-type = git
sync-uri = https://github.com/gentoo-mirror/gentoo.git
```

---

## 6. zypper (openSUSE/SLES)

### Common Commands

```bash
# Refresh repositories
sudo zypper refresh

# Update all packages
sudo zypper update

# Dist-upgrade (Tumbleweed)
sudo zypper dist-upgrade

# Install package
sudo zypper install nginx

# Install specific version
sudo zypper install nginx=1.20.1

# Remove package
sudo zypper remove nginx

# Remove with dependencies
sudo zypper remove --clean-deps nginx

# Search packages
zypper search nginx

# Show package info
zypper info nginx

# List installed packages
zypper packages --installed-only

# List updates
zypper list-updates

# Show package dependencies
zypper info --requires nginx

# Show reverse dependencies
zypper info --requires nginx

# Add repository
sudo zypper addrepo https://example.com/repo.repo

# Remove repository
sudo zypper removerepo repo-alias

# List repositories
zypper repos

# Enable repository
sudo zypper modifyrepo --enable repo-alias

# Clean cache
sudo zypper clean

# Download package
zypper download nginx

# Verify all packages
sudo zypper verify

# Install local RPM
sudo zypper install ./package.rpm

# Show history
zypper history
```

### Patterns and Patches

```bash
# List patterns
zypper patterns

# Install pattern
sudo zypper install pattern_name

# List patches
zypper patches

# Install patches
sudo zypper patch

# List security patches
zypper list-patches --category security
```

---

## 7. Common Tasks Comparison

### Installing a Package

| Manager | Command |
|---------|---------|
| apt | `sudo apt install nginx` |
| dnf | `sudo dnf install nginx` |
| pacman | `sudo pacman -S nginx` |
| portage | `sudo emerge -av nginx` |
| zypper | `sudo zypper install nginx` |

### Removing a Package

| Manager | Command |
|---------|---------|
| apt | `sudo apt remove nginx` |
| dnf | `sudo dnf remove nginx` |
| pacman | `sudo pacman -Rs nginx` |
| portage | `sudo emerge -C nginx` |
| zypper | `sudo zypper remove nginx` |

### Updating All Packages

| Manager | Command |
|---------|---------|
| apt | `sudo apt update && sudo apt upgrade` |
| dnf | `sudo dnf update` |
| pacman | `sudo pacman -Syu` |
| portage | `sudo emerge -avuDN @world` |
| zypper | `sudo zypper update` |

### Searching for a Package

| Manager | Command |
|---------|---------|
| apt | `apt search nginx` |
| dnf | `dnf search nginx` |
| pacman | `pacman -Ss nginx` |
| portage | `emerge -s nginx` |
| zypper | `zypper search nginx` |

### Showing Package Info

| Manager | Command |
|---------|---------|
| apt | `apt show nginx` |
| dnf | `dnf info nginx` |
| pacman | `pacman -Si nginx` |
| portage | `emerge -av --info nginx` |
| zypper | `zypper info nginx` |

### Listing Installed Packages

| Manager | Command |
|---------|---------|
| apt | `apt list --installed` |
| dnf | `dnf list installed` |
| pacman | `pacman -Q` |
| portage | `qlist -IC` |
| zypper | `zypper packages --installed-only` |

### Finding Which Package Owns a File

| Manager | Command |
|---------|---------|
| apt | `dpkg -S /usr/bin/nginx` |
| dnf | `dnf provides /usr/bin/nginx` |
| pacman | `pacman -Qo /usr/bin/nginx` |
| portage | `equery belongs /usr/sbin/nginx` |
| zypper | `zypper search --provides /usr/sbin/nginx` |

### Cleaning Cache

| Manager | Command |
|---------|---------|
| apt | `sudo apt clean` |
| dnf | `sudo dnf clean all` |
| pacman | `sudo pacman -Scc` |
| portage | `sudo eclean distfiles` |
| zypper | `sudo zypper clean` |

---

## 8. Repository Configuration

### apt Sources

```bash
# /etc/apt/sources.list
deb http://archive.ubuntu.com/ubuntu jammy main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu jammy-updates main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu jammy-security main restricted universe multiverse

# Third-party
# /etc/apt/sources.list.d/docker.list
deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu jammy stable
```

### dnf Repos

```bash
# /etc/yum.repos.d/fedora.repo
[fedora]
name=Fedora $releasever - $basearch
baseurl=https://download.example.com/fedora/linux/releases/$releasever/Everything/$basearch/os/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
enabled=1

# Third-party
sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
```

### pacman Repos

```bash
# /etc/pacman.conf
[core]
Include = /etc/pacman.d/mirrorlist

[extra]
Include = /etc/pacman.d/mirrorlist

[community]
Include = /etc/pacman.d/mirrorlist

# Custom repo
[custom]
Server = https://example.com/repo/$arch
```

---

*Each package manager has extensive documentation: `man apt`, `man dnf`, `man pacman`, `man emerge`, `man zypper`.*
