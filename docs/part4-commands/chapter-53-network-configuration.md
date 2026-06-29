# Chapter 53: Network Configuration — ip, ss, netstat, nmcli

## Overview

Network configuration in Linux has evolved from `ifconfig` and `route` to the modern `ip` command suite (from iproute2). This chapter covers the current tools for managing network interfaces, addresses, routes, and connections.

---

## ip — Show / Manipulate Routing, Devices, Policy Routing and Tunnels

### Purpose

`ip` (from iproute2) is the modern tool for configuring network interfaces, addresses, routes, neighbors, and tunnels. It replaces `ifconfig`, `route`, `arp`, and many other legacy tools.

### Syntax

```
ip [OPTIONS] OBJECT { COMMAND | help }
```

### Objects

| Object | Description |
|--------|-------------|
| `link` | Network device |
| `address` | Protocol address (IP) |
| `route` | Routing table entry |
| `neigh` | ARP/NDP neighbor table |
| `rule` | Routing policy |
| `maddress` | Multicast address |
| `mroute` | Multicast routing |
| `tunnel` | Tunnel |
| `netns` | Network namespace |
| `vrf` | VRF |
| `xfrm` | IPsec policies |
| `l2tp` | L2TP tunnel |
| `tcpmetrics` | TCP metrics |
| `macsec` | MACsec |
| `veth` | Virtual ethernet |
| `link` | Device management |
| `monitor` | State monitoring |

### Key Options

| Option | Description |
|--------|-------------|
| `-4` | IPv4 only |
| `-6` | IPv6 only |
| `-V` | Version |
| `-s` | Statistics |
| `-d` | Details |
| `-f FAMILY` | Address family |
| `-j` | JSON output |
| `-p` | Pretty output |
| `-o` | One line |
| `-n` | No DNS resolution |
| `-r` | Resolve DNS |
| `-t` | Timestamp |
| `-ts` | Short timestamp |
| `-iec` | IEC units |

---

### ip link — Network Device Management

```bash
# Show all interfaces
ip link show

# Show specific interface
ip link show eth0

# Show with statistics
ip -s link show

# Bring interface up
ip link set eth0 up

# Bring interface down
ip link set eth0 down

# Set MTU
ip link set eth0 mtu 9000

# Set MAC address
ip link set eth0 address 00:11:22:33:44:55

# Set promiscuous mode
ip link set eth0 promisc on

# Set TX queue length
ip link set eth0 txqueuelen 1000

# Enable/disable multicast
ip link set eth0 multicast on

# Set alias
ip link set eth0 alias "WAN Interface"

# Create dummy interface
ip link add dummy0 type dummy

# Create bridge
ip link add br0 type bridge

# Create VLAN
ip link add link eth0 name eth0.100 type vlan id 100

# Create veth pair
ip link add veth0 type veth peer name veth1

# Delete interface
ip link del dummy0

# Show with details
ip -d link show

# Show with JSON
ip -j link show

# Monitor link changes
ip monitor link
```

---

### ip address — Protocol Address Management

```bash
# Show all addresses
ip addr show

# Show specific interface
ip addr show eth0

# Show IPv4 only
ip -4 addr show

# Show IPv6 only
ip -6 addr show

# Add IP address
ip addr add 192.168.1.100/24 dev eth0

# Add with label
ip addr add 192.168.1.101/24 dev eth0 label eth0:1

# Add secondary address
ip addr add 10.0.0.1/24 dev eth0

# Add IPv6 address
ip addr add 2001:db8::1/64 dev eth0

# Delete address
ip addr del 192.168.1.100/24 dev eth0

# Flush addresses
ip addr flush dev eth0

# Flush IPv4 only
ip -4 addr flush dev eth0

# Show statistics
ip -s addr show

# Show only IPv4
ip -4 a

# JSON output
ip -j addr show

# One line per address
ip -o addr show
```

---

### ip route — Routing Table Management

```bash
# Show routing table
ip route show

# Show all tables
ip route show table all

# Show specific table
ip route show table main

# Add default route
ip route add default via 192.168.1.1

# Add route
ip route add 10.0.0.0/8 via 192.168.1.1

# Add route via specific interface
ip route add 172.16.0.0/16 via 192.168.1.1 dev eth0

# Add with metric
ip route add 10.0.0.0/8 via 192.168.1.1 metric 100

# Add blackhole route
ip route add blackhole 192.168.100.0/24

# Add unreachable route
ip route add unreachable 192.168.200.0/24

# Delete route
ip route del 10.0.0.0/8

# Replace route
ip route replace 10.0.0.0/8 via 192.168.1.2

# Show route to specific destination
ip route get 8.8.8.8

# Show route to specific destination from specific source
ip route get 8.8.8.8 from 192.168.1.100

# Flush routes
ip route flush table main

# Add multipath route
ip route add default \
    nexthop via 192.168.1.1 weight 1 \
    nexthop via 192.168.2.1 weight 2

# Policy routing
ip rule add from 192.168.1.0/24 table 100
ip route add default via 10.0.0.1 table 100

# Show rules
ip rule show

# Add route with scope
ip route add 192.168.1.0/24 dev eth0 scope link

# Add route with proto
ip route add 10.0.0.0/8 via 192.168.1.1 proto static

# Show cached routes
ip route show cache

# JSON output
ip -j route show
```

---

### ip neigh — ARP/NDP Neighbor Table

```bash
# Show ARP table
ip neigh show

# Show specific interface
ip neigh show dev eth0

# Add static ARP entry
ip neigh add 192.168.1.1 lladdr 00:11:22:33:44:55 dev eth0

# Change ARP entry
ip neigh change 192.168.1.1 lladdr 00:11:22:33:44:55 dev eth0

# Delete ARP entry
ip neigh del 192.168.1.1 dev eth0

# Flush ARP table
ip neigh flush dev eth0

# Flush all
ip neigh flush all

# Show with statistics
ip -s neigh show

# Show reachable entries only
ip neigh show nud reachable

# Replace entry
ip neigh replace 192.168.1.1 lladdr 00:11:22:33:44:55 dev eth0
```

---

### ip netns — Network Namespaces

```bash
# List namespaces
ip netns list

# Create namespace
ip netns add test

# Delete namespace
ip netns del test

# Run command in namespace
ip netns exec test ip addr show

# Assign interface to namespace
ip link set eth0 netns test

# Create veth pair across namespaces
ip link add veth0 type veth peer name veth1
ip link set veth1 netns test

# Show namespace
ip netns identify $$
```

---

## ss — Socket Statistics

### Purpose

`ss` displays socket statistics. It's the modern replacement for `netstat`, with more features and better performance.

### Key Options

| Option | Description |
|--------|-------------|
| `-t` | TCP sockets |
| `-u` | UDP sockets |
| `-l` | Listening sockets |
| `-a` | All sockets |
| `-n` | Don't resolve names |
| `-p` | Show process using socket |
| `-e` | Extended info |
| `-i` | TCP internal info |
| `-m` | Memory usage |
| `-s` | Summary statistics |
| `-r` | Resolve names |
| `-o` | Show timers |
| `-f FAMILY` | Socket family |
| `-A QUERY` | Query type (all, established, etc.) |
| `-D FILE` | Dump to file |
| `-F FILE` | Filter from file |
| `--kill` | Kill socket |
| `--no-header` | Suppress header |
| `-4` | IPv4 only |
| `-6` | IPv6 only |
| `-K` | Kill sockets |
| `-Z` | SELinux context |
| `-N NS` | Network namespace |
| `-w` | Raw sockets |
| `-x` | Unix sockets |
| `-W` | No limit on display |
| `-v` | Version |
| `-H` | Suppress header |
| `-E` | Events |

### Filter Expressions

```bash
# State filters
ss state established
ss state time-wait
ss state listening
ss state connected

# Address filters
ss src 192.168.1.100
ss dst 192.168.1.1
ss src :80
ss dst :443

# Port filters
ss sport = :80
ss dport = :443
ss sport = :80 or sport = :443

# Complex filters
ss '( dport = :80 or dport = :443 ) and dst 192.168.1.0/24'
```

### Examples

```bash
# Show all TCP connections
ss -t

# Show listening TCP sockets
ss -tl

# Show all sockets
ss -a

# Show with process info
ss -tlnp

# Show UDP
ss -u

# Show Unix sockets
ss -x

# Show with extended info
ss -t -e

# Show memory usage
ss -t -m

# Show TCP internal info
ss -t -i

# Summary statistics
ss -s

# Show timers
ss -t -o

# Show specific state
ss -t state established

# Show only listening with process
ss -tlp

# No DNS resolution
ss -tln

# Filter by address
ss -t dst 192.168.1.1

# Filter by port
ss -t sport = :80

# Complex filter
ss -t '( sport = :80 or sport = :443 )'

# IPv4 only
ss -4 -t

# IPv6 only
ss -6 -t

# Show with line numbers
ss -tnl

# JSON output (newer versions)
ss -t -j

# Kill socket
ss --kill dst 192.168.1.100

# Dump sockets
ss -t -a > sockets.txt

# Filter from file
ss -t -F filter.txt
```

---

## netstat — Network Statistics (Legacy)

### Purpose

`netstat` displays network connections, routing tables, interface statistics, and more. It's being replaced by `ss` and `ip` but still widely used.

### Key Options

| Option | Description |
|--------|-------------|
| `-t` | TCP |
| `-u` | UDP |
| `-l` | Listening |
| `-a` | All |
| `-n` | Numeric |
| `-p` | Program/PID |
| `-r` | Routing table |
| `-i` | Interface statistics |
| `-s` | Protocol statistics |
| `-e` | Extended info |
| `-c` | Continuous |
| `-o` | Timers |
| `-W` | Wide output |
| `-v` | Verbose |
| `-F` | FIB (forwarding) |
| `-C` | Cache |

### Examples

```bash
# All connections
netstat -a

# TCP connections
netstat -at

# Listening sockets
netstat -tl

# With process info
netstat -tlnp

# Routing table
netstat -r

# Interface statistics
netstat -i

# Protocol statistics
netstat -s

# All TCP with program
netstat -atp

# Continuous monitoring
netstat -c
```

---

## nmcli — NetworkManager Command-Line Tool

### Purpose

`nmcli` controls NetworkManager from the command line, managing connections, devices, and network settings.

### Key Objects

| Object | Description |
|--------|-------------|
| `general` | NetworkManager status |
| `connection` | Connection profiles |
| `device` | Network devices |
| `radio` | Wireless radios |
| `monitor` | Monitor changes |

### Examples

```bash
# Show general status
nmcli general status

# Show all connections
nmcli connection show

# Show active connections
nmcli connection show --active

# Show devices
nmcli device status

# Show device details
nmcli device show eth0

# Connect to WiFi
nmcli device wifi connect "SSID" password "password"

# List WiFi networks
nmcli device wifi list

# Rescan WiFi
nmcli device wifi rescan

# Bring connection up
nmcli connection up "connection-name"

# Bring connection down
nmcli connection down "connection-name"

# Create static IP connection
nmcli connection add type ethernet con-name static-eth0 \
    ifname eth0 \
    ipv4.addresses 192.168.1.100/24 \
    ipv4.gateway 192.168.1.1 \
    ipv4.dns "8.8.8.8 8.8.4.4" \
    ipv4.method manual

# Create DHCP connection
nmcli connection add type ethernet con-name dhcp-eth0 ifname eth0

# Modify connection
nmcli connection modify static-eth0 ipv4.addresses "192.168.1.200/24"

# Delete connection
nmcli connection delete "connection-name"

# Reload connections
nmcli connection reload

# Monitor changes
nmcli monitor

# Radio management
nmcli radio wifi on
nmcli radio wifi off
nmcli radio wwan on

# Connection up with specific interface
nmcli connection up "connection-name" ifname eth0

# Show connection details
nmcli connection show "connection-name"

# Add DNS server
nmcli connection modify static-eth0 +ipv4.dns "1.1.1.1"

# Remove DNS server
nmcli connection modify static-eth0 -ipv4.dns "1.1.1.1"

# Set hostname
nmcli general hostname myserver
```

---

## Summary

### Quick Reference

```bash
# Interface management
ip link show                          # Show interfaces
ip link set eth0 up/down              # Enable/disable
ip addr show                          # Show addresses
ip addr add 192.168.1.100/24 dev eth0 # Add IP

# Routing
ip route show                         # Show routes
ip route add default via 192.168.1.1  # Default gateway
ip route get 8.8.8.8                  # Route to destination

# Socket statistics
ss -tlnp                              # Listening TCP with processes
ss -s                                 # Socket summary

# NetworkManager
nmcli general status                  # NM status
nmcli device status                   # Device status
nmcli connection show                 # Connections
nmcli device wifi connect SSID        # WiFi
```
