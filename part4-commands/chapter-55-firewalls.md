# Chapter 55: Firewalls — iptables, nftables, ufw, firewalld

## Overview

Linux firewalls control network traffic at the kernel level using the Netfilter framework. This chapter covers the major firewall tools: `iptables` (legacy), `nftables` (modern replacement), `ufw` (Ubuntu/Debian frontend), and `firewalld` (RHEL/CentOS frontend).

---

## Netfilter Architecture

Netfilter provides hooks in the Linux kernel's network stack:

```
Packet Flow:
                    ┌─────────────┐
   Incoming ──────►│ PREROUTING  │
                    └──────┬──────┘
                           │
                    ┌──────▼──────┐
                    │   Routing   │
                    │  Decision   │
                    └──┬──────┬───┘
                       │      │
              ┌────────▼┐  ┌──▼────────┐
              │  INPUT   │  │  FORWARD  │
              └────┬─────┘  └─────┬─────┘
                   │              │
            ┌──────▼──────┐      │
            │ Local Process│      │
            └──────┬──────┘      │
                   │              │
            ┌──────▼──────┐      │
            │   OUTPUT    │      │
            └──────┬──────┘      │
                   │              │
                   ▼              ▼
            ┌─────────────┐      │
            │ POSTROUTING │◄─────┘
            └──────┬──────┘
                   │
              Outgoing
```

### Tables

| Table | Purpose | Chains |
|-------|---------|--------|
| `filter` | Packet filtering (default) | INPUT, FORWARD, OUTPUT |
| `nat` | Network Address Translation | PREROUTING, INPUT, OUTPUT, POSTROUTING |
| `mangle` | Packet modification | All five chains |
| `raw` | Connection tracking bypass | PREROUTING, OUTPUT |
| `security` | SELinux marking | INPUT, OUTPUT, FORWARD |

---

## iptables — Legacy Firewall

### Purpose

`iptables` configures Linux kernel packet filtering rules. It's the traditional firewall tool, being replaced by `nftables`.

### Syntax

```
iptables [-t table] -A chain rule-specification
iptables [-t table] -D chain rule-number
iptables [-t table] -I chain [number] rule-specification
iptables [-t table] -R chain number rule-specification
iptables [-t table] -L chain [options]
iptables [-t table] -F [chain]
iptables [-t table] -Z [chain]
iptables [-t table] -P chain target
iptables [-t table] -N chain
iptables [-t table] -X [chain]
iptables [-t table] -E old-name new-name
iptables [-t table] -S [chain]
```

### Commands

| Command | Description |
|---------|-------------|
| `-A` | Append rule |
| `-D` | Delete rule |
| `-I` | Insert rule |
| `-R` | Replace rule |
| `-L` | List rules |
| `-F` | Flush chain |
| `-Z` | Zero counters |
| `-P` | Set default policy |
| `-N` | New chain |
| `-X` | Delete chain |
| `-E` | Rename chain |
| `-S` | Print rules as commands |
| `-C` | Check if rule exists |

### Rule Specifications

| Option | Description |
|--------|-------------|
| `-p PROTO` | Protocol (tcp, udp, icmp, all) |
| `-s ADDR[/MASK]` | Source address |
| `-d ADDR[/MASK]` | Destination address |
| `-i IFACE` | Input interface |
| `-o IFACE` | Output interface |
| `--sport PORT` | Source port |
| `--dport PORT` | Destination port |
| `--tcp-flags MASK COMP` | TCP flags |
| `--syn` | SYN flag set |
| `--state STATE` | Connection state |
| `-m MODULE` | Match extension |
| `-j TARGET` | Jump to target |
| `--comment "text"` | Comment |

### Targets

| Target | Description |
|--------|-------------|
| `ACCEPT` | Allow packet |
| `DROP` | Silently discard |
| `REJECT` | Discard with error |
| `LOG` | Log packet |
| `MASQUERADE` | Masquerade (NAT) |
| `SNAT` | Source NAT |
| `DNAT` | Destination NAT |
| `REDIRECT` | Redirect to local port |
| `MARK` | Set mark |
| `RETURN` | Return to calling chain |
| `QUEUE` | Pass to userspace |

### Match Extensions

| Module | Description |
|--------|-------------|
| `conntrack` | Connection tracking |
| `multiport` | Multiple ports |
| `iprange` | IP range |
| `string` | String matching |
| `limit` | Rate limiting |
| `recent` | Recent connections |
| `owner` | Packet owner |
| `tcp` | TCP options |
| `udp` | UDP options |
| `icmp` | ICMP options |
| `state` | Connection state |

### Examples

```bash
# List rules
iptables -L
iptables -L -n -v
iptables -L -n -v --line-numbers
iptables -S

# Flush all rules
iptables -F
iptables -X
iptables -Z

# Default policies
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Allow loopback
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Allow established connections
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Allow SSH
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# Allow HTTP/HTTPS
iptables -A INPUT -p tcp -m multiport --dports 80,443 -j ACCEPT

# Allow ICMP (ping)
iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT

# Allow from specific IP
iptables -A INPUT -s 192.168.1.100 -j ACCEPT

# Allow from subnet
iptables -A INPUT -s 192.168.1.0/24 -j ACCEPT

# Block specific IP
iptables -A INPUT -s 10.0.0.1 -j DROP

# Log dropped packets
iptables -A INPUT -j LOG --log-prefix "IPTables-Dropped: " --log-level 4

# Rate limit
iptables -A INPUT -p tcp --dport 22 -m limit --limit 3/min --limit-burst 3 -j ACCEPT

# Connection limit
iptables -A INPUT -p tcp --dport 80 -m connlimit --connlimit-above 50 -j REJECT

# Port forwarding
iptables -t nat -A PREROUTING -p tcp --dport 8080 -j REDIRECT --to-port 80

# DNAT (destination NAT)
iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination 10.0.0.1:80

# SNAT (source NAT)
iptables -t nat -A POSTROUTING -s 10.0.0.0/24 -j SNAT --to-source 192.168.1.100

# Masquerade (dynamic NAT)
iptables -t nat -A POSTROUTING -s 10.0.0.0/24 -o eth0 -j MASQUERADE

# Insert rule at position
iptables -I INPUT 1 -p tcp --dport 22 -j ACCEPT

# Delete specific rule
iptables -D INPUT -p tcp --dport 80 -j ACCEPT

# Delete by line number
iptables -D INPUT 3

# Replace rule
iptables -R INPUT 3 -p tcp --dport 443 -j ACCEPT

# Custom chain
iptables -N mychain
iptables -A mychain -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -j mychain

# String matching
iptables -A INPUT -p tcp --dport 80 -m string --string "malware" --algo bm -j DROP

# Time-based rules
iptables -A INPUT -p tcp --dport 80 -m time --timestart 09:00 --timestop 17:00 -j ACCEPT

# Save rules
iptables-save > /etc/iptables/rules.v4
ip6tables-save > /etc/iptables/rules.v6

# Restore rules
iptables-restore < /etc/iptables/rules.v4

# IPv6
ip6tables -A INPUT -p tcp --dport 22 -j ACCEPT
```

---

## nftables — Modern Firewall

### Purpose

`nftables` is the successor to `iptables`, providing a more consistent syntax, better performance, and atomic rule replacement.

### Syntax

```
nft [options] command [arguments]
```

### Commands

| Command | Description |
|---------|-------------|
| `list tables` | List all tables |
| `list table TABLE` | List specific table |
| `add table TABLE` | Create table |
| `delete table TABLE` | Delete table |
| `add chain TABLE CHAIN` | Create chain |
| `delete chain TABLE CHAIN` | Delete chain |
| `add rule TABLE CHAIN RULE` | Add rule |
| `delete rule TABLE CHAIN HANDLE` | Delete rule |
| `insert rule TABLE CHAIN RULE` | Insert rule |
| `flush table TABLE` | Flush table |
| `flush chain TABLE CHAIN` | Flush chain |
| `list ruleset` | List all rules |
| `export json` | Export as JSON |

### Examples

```bash
# List all rules
nft list ruleset

# Create table
nft add table inet filter

# Create chains
nft add chain inet filter input { type filter hook input priority 0 \; policy drop \; }
nft add chain inet filter forward { type filter hook forward priority 0 \; policy drop \; }
nft add chain inet filter output { type filter hook output priority 0 \; policy accept \; }

# Add rules
nft add rule inet filter input ct state established,related accept
nft add rule inet filter input iif lo accept
nft add rule inet filter input tcp dport 22 accept
nft add rule inet filter input tcp dport { 80, 443 } accept
nft add rule inet filter input icmp type echo-request accept

# List chain rules
nft list chain inet filter input

# Delete rule by handle
nft delete rule inet filter input handle 5

# Flush chain
nft flush chain inet filter input

# NAT table
nft add table ip nat
nft add chain ip nat prerouting { type nat hook prerouting priority -100 \; }
nft add chain ip nat postrouting { type nat hook postrouting priority 100 \; }

# Masquerade
nft add rule ip nat postrouting oif eth0 masquerade

# DNAT
nft add rule ip nat prerouting tcp dport 80 dnat to 10.0.0.1:80

# Save rules
nft list ruleset > /etc/nftables.conf

# Restore rules
nft -f /etc/nftables.conf

# Atomic rule replacement
nft -f new_rules.conf

# Create set
nft add set inet filter blacklist { type ipv4_addr \; }
nft add element inet filter blacklist { 10.0.0.1, 10.0.0.2 }
nft add rule inet filter input ip saddr @blacklist drop

# Rate limiting
nft add rule inet filter input tcp dport 22 ct state new limit rate 3/minute accept

# Logging
nft add rule inet filter input log prefix "nft-drop: " level warn

# JSON export
nft -j list ruleset
```

---

## ufw — Uncomplicated Firewall

### Purpose

`ufw` is a user-friendly frontend for `iptables`/`nftables`, designed for Ubuntu/Debian.

### Syntax

```
ufw [--dry-run] command [arguments]
```

### Key Commands

| Command | Description |
|---------|-------------|
| `enable` | Enable firewall |
| `disable` | Disable firewall |
| `reload` | Reload rules |
| `status` | Show status |
| `status verbose` | Verbose status |
| `status numbered` | Show rule numbers |
| `default allow/deny` | Set default policy |
| `allow PORT` | Allow port |
| `deny PORT` | Deny port |
| `reject PORT` | Reject port |
| `allow proto PORT` | Allow specific protocol |
| `allow from ADDR` | Allow from address |
| `deny from ADDR` | Deny from address |
| `delete RULE` | Delete rule |
| `insert N RULE` | Insert at position N |
| `app list` | List applications |
| `app info NAME` | Show app info |
| `logging on/off` | Enable/disable logging |
| `reset` | Reset all rules |

### Examples

```bash
# Enable firewall
sudo ufw enable

# Disable firewall
sudo ufw disable

# Show status
sudo ufw status
sudo ufw status verbose
sudo ufw status numbered

# Default policies
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH
sudo ufw allow ssh
sudo ufw allow 22/tcp

# Allow HTTP/HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow http
sudo ufw allow https

# Allow from specific IP
sudo ufw allow from 192.168.1.100

# Allow from subnet to specific port
sudo ufw allow from 192.168.1.0/24 to any port 22

# Allow specific port range
sudo ufw allow 3000:4000/tcp

# Deny port
sudo ufw deny 23/tcp

# Deny from IP
sudo ufw deny from 10.0.0.1

# Delete rule
sudo ufw delete allow 80/tcp
sudo ufw delete 3  # By number

# Application profiles
sudo ufw app list
sudo ufw allow 'OpenSSH'
sudo ufw allow 'Nginx Full'

# Logging
sudo ufw logging on
sudo ufw logging low
sudo ufw logging medium
sudo ufw logging high

# Reset
sudo ufw reset

# Rate limiting
sudo ufw limit ssh

# Deny outgoing to specific IP
sudo ufw deny out to 10.0.0.1
```

---

## firewalld — Dynamic Firewall Manager

### Purpose

`firewalld` is a dynamic firewall manager for RHEL/CentOS/Fedora, using zones and services.

### Key Concepts

| Concept | Description |
|---------|-------------|
| **Zones** | Trust levels (drop, block, public, external, dmz, work, home, internal, trusted) |
| **Services** | Predefined service definitions (http, https, ssh) |
| **Rich Rules** | Complex rules with logging, limits, etc. |
| **Direct Rules** | Direct iptables/nftables rules |
| **Interfaces** | Network interfaces assigned to zones |
| **Sources** | Source addresses assigned to zones |

### Commands

```bash
# Show status
firewall-cmd --state

# Show zones
firewall-cmd --get-zones

# Show default zone
firewall-cmd --get-default-zone

# Show active zones
firewall-cmd --get-active-zones

# Show zone services
firewall-cmd --zone=public --list-services

# Show zone ports
firewall-cmd --zone=public --list-ports

# Add service
firewall-cmd --zone=public --add-service=http --permanent
firewall-cmd --zone=public --add-service=https --permanent

# Add port
firewall-cmd --zone=public --add-port=8080/tcp --permanent

# Remove service
firewall-cmd --zone=public --remove-service=http --permanent

# Remove port
firewall-cmd --zone=public --remove-port=8080/tcp --permanent

# Add source to zone
firewall-cmd --zone=trusted --add-source=192.168.1.0/24 --permanent

# Add interface to zone
firewall-cmd --zone=internal --change-interface=eth0 --permanent

# Rich rules
firewall-cmd --zone=public --add-rich-rule='rule family="ipv4" source address="192.168.1.0/24" port port="22" protocol="tcp" accept' --permanent

# Rate limit
firewall-cmd --zone=public --add-rich-rule='rule service name="ssh" limit value="3/m" accept' --permanent

# Log
firewall-cmd --zone=public --add-rich-rule='rule family="ipv4" source address="10.0.0.1" log prefix="blocked: " level="warning" drop' --permanent

# Port forwarding
firewall-cmd --zone=public --add-forward-port=port=8080:proto=tcp:toport=80 --permanent

# NAT masquerade
firewall-cmd --zone=external --add-masquerade --permanent

# Reload
firewall-cmd --reload

# List all
firewall-cmd --list-all
firewall-cmd --list-all-zones

# Panic mode (block all)
firewall-cmd --panic-on
firewall-cmd --panic-off

# Runtime vs permanent
firewall-cmd --runtime-to-permanent
```

---

## Summary

### Tool Comparison

| Feature | iptables | nftables | ufw | firewalld |
|---------|----------|----------|-----|-----------|
| Complexity | High | Medium | Low | Medium |
| Syntax | Verbose | Clean | Simple | Command-based |
| Atomic replace | No | Yes | Yes | Yes |
| Sets/maps | Limited | Yes | No | Yes |
| IPv4+IPv6 | Separate | Combined | Separate | Combined |
| Default distro | Legacy | Modern Debian/Ubuntu | Ubuntu/Debian | RHEL/CentOS |

### Quick Reference

```bash
# iptables
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -P INPUT DROP
iptables-save > rules.v4

# nftables
nft add rule inet filter input tcp dport 22 accept

# ufw
ufw allow 22/tcp
ufw enable
ufw status

# firewalld
firewall-cmd --add-service=ssh --permanent
firewall-cmd --reload
```

### Security Best Practices

1. **Default deny**: Set INPUT policy to DROP/REJECT.
2. **Allow only needed services**: Whitelist approach.
3. **Log dropped packets**: For auditing and debugging.
4. **Use rate limiting**: Prevent brute-force attacks.
5. **Keep rules atomic**: Use nftables atomic replacement.
6. **Backup rules**: Save and version control firewall rules.
7. **Test before applying**: Use `--dry-run` or test on staging first.
8. **Monitor logs**: Regularly review firewall logs.
