# Appendix F: Networking Cheat Sheet

## Overview

This appendix provides quick reference one-liners and short examples for Linux networking tools: `ip`, `ss`, `iptables`, `nftables`, and `tcpdump`.

---

## 1. ip — Network Configuration

### Address Management

```bash
# Show all addresses
ip addr show
ip a

# Show addresses for specific interface
ip addr show dev eth0

# Show only IPv4 addresses
ip -4 addr show

# Show only IPv6 addresses
ip -6 addr show

# Add IP address
ip addr add 192.168.1.100/24 dev eth0

# Add secondary address
ip addr add 192.168.1.101/24 dev eth0 label eth0:1

# Delete IP address
ip addr del 192.168.1.100/24 dev eth0

# Flush all addresses on interface
ip addr flush dev eth0

# Show addresses in brief format
ip -br addr show
```

### Link (Interface) Management

```bash
# Show all interfaces
ip link show
ip l

# Show specific interface
ip link show dev eth0

# Bring interface up
ip link set eth0 up

# Bring interface down
ip link set eth0 down

# Set MTU
ip link set eth0 mtu 9000

# Set MAC address
ip link set eth0 address 00:11:22:33:44:55

# Enable promiscuous mode
ip link set eth0 promisc on

# Set TX queue length
ip link set eth0 txqueuelen 1000

# Show interface statistics
ip -s link show eth0

# Show interface statistics (detailed)
ip -s -s link show eth0
```

### Bridge Management

```bash
# Show bridges
ip link show type bridge

# Create bridge
ip link add name br0 type bridge

# Add interface to bridge
ip link set eth0 master br0

# Remove interface from bridge
ip link set eth0 nomaster

# Set bridge options
ip link set br0 type bridge stp_state 1

# Show bridge details
ip -d link show type bridge
```

### VLAN Management

```bash
# Create VLAN
ip link add link eth0 name eth0.100 type vlan id 100

# Configure VLAN interface
ip addr add 192.168.100.1/24 dev eth0.100
ip link set eth0.100 up

# Show VLANs
ip -d link show type vlan

# Delete VLAN
ip link delete eth0.100
```

### Routing

```bash
# Show routing table
ip route show
ip r

# Show specific route
ip route show 192.168.1.0/24

# Show route for destination
ip route get 8.8.8.8

# Add default route
ip route add default via 192.168.1.1

# Add static route
ip route add 10.0.0.0/8 via 192.168.1.254

# Add route via specific interface
ip route add 10.0.0.0/8 via 192.168.1.254 dev eth0

# Delete route
ip route del 10.0.0.0/8

# Replace route (add or update)
ip route replace 10.0.0.0/8 via 192.168.1.254

# Add route with metric
ip route add 10.0.0.0/8 via 192.168.1.254 metric 100

# Flush routing cache
ip route flush cache

# Show routing table for specific table
ip route show table main
ip route show table 100

# Policy routing: add rule
ip rule add from 192.168.1.0/24 table 100

# Show policy rules
ip rule show
```

### Neighbor (ARP/NDP)

```bash
# Show ARP/NDP table
ip neigh show
ip n

# Show neighbors on specific interface
ip neigh show dev eth0

# Add static ARP entry
ip neigh add 192.168.1.1 lladdr 00:11:22:33:44:55 dev eth0

# Delete ARP entry
ip neigh del 192.168.1.1 dev eth0

# Flush ARP cache
ip neigh flush dev eth0

# Show only reachable entries
ip neigh show nud reachable
```

### Tunnel Management

```bash
# Create GRE tunnel
ip tunnel add gre1 mode gre remote 203.0.113.1 local 198.51.100.1 ttl 255

# Create IPIP tunnel
ip tunnel add ipip1 mode ipip remote 203.0.113.1 local 198.51.100.1

# Create VXLAN
ip link add vxlan0 type vxlan id 42 remote 203.0.113.1 dstport 4789 dev eth0

# Configure tunnel interface
ip addr add 10.0.0.1/30 dev gre1
ip link set gre1 up

# Show tunnels
ip tunnel show
```

### VRF (Virtual Routing and Forwarding)

```bash
# Create VRF
ip link add vrf-blue type vrf table 100

# Assign interface to VRF
ip link set eth0 master vrf-blue

# Show VRFs
ip -d link show type vrf

# Show routes in VRF
ip route show vrf vrf-blue
```

---

## 2. ss — Socket Statistics

### Basic Usage

```bash
# Show all TCP sockets
ss -t

# Show all UDP sockets
ss -u

# Show all listening sockets
ss -lt

# Show all established connections
ss -t state established

# Show all sockets (TCP + UDP)
ss -tu

# Show listening and established
ss -tlu state established

# Show all sockets (including UNIX)
ss -tua

# Numeric output (don't resolve names)
ss -nt

# Show process using socket
ss -tlnp

# Show timer information
ss -to

# Show memory usage
ss -tm

# Show internal TCP information
ss -ti

# Show detailed info
ss -tlnpi
```

### Filtering

```bash
# Filter by port
ss -tln sport = :80
ss -tln sport = :443

# Filter by port range
ss -tln 'sport >= :1024 and sport <= :65535'

# Filter by destination
ss -tn dst 192.168.1.0/24

# Filter by source port
ss -tn src :80

# Filter by state
ss -t state established
ss -t state time-wait
ss -t state close-wait

# Multiple state filters
ss -t state established '( sport = :80 or sport = :443 )'

# Filter by process
ss -tlnp '( dport = :80 or dport = :443 )'

# Show connections to specific host
ss -tn dst 10.0.0.1
```

### Common Patterns

```bash
# Count established connections
ss -t state established | wc -l

# Find connections from specific IP
ss -tn | grep 192.168.1.100

# Show connections by state
ss -s

# Find high-port connections (outbound)
ss -tn state established '( sport >= :32768 and sport <= :60999 )'

# Show all connections to port 80
ss -tnp '( sport = :80 or dport = :80 )'

# Show sockets with zero receive buffer
ss -tn state established '( rcv_space = 0 )'

# Monitor new connections (watch)
watch -n 1 'ss -tlnp'

# Show connections sorted by receive queue
ss -tnr
```

---

## 3. iptables — Legacy Packet Filtering

### Table/Chain Structure

```
Tables:
  filter (default) — packet filtering
  nat — network address translation
  mangle — packet modification
  raw — connection tracking bypass

Chains (filter):
  INPUT — incoming packets
  OUTPUT — outgoing packets
  FORWARD — routed packets

Chains (nat):
  PREROUTING — before routing
  POSTROUTING — after routing
  OUTPUT — locally generated packets
```

### Basic Rules

```bash
# List all rules
iptables -L -n -v
iptables -L -n -v --line-numbers

# List specific table
iptables -t nat -L -n -v

# Flush all rules
iptables -F

# Flush specific chain
iptables -F INPUT

# Set default policy
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Allow established connections
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Allow loopback
iptables -A INPUT -i lo -j ACCEPT

# Allow SSH
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# Allow HTTP/HTTPS
iptables -A INPUT -p tcp -m multiport --dports 80,443 -j ACCEPT

# Allow ICMP (ping)
iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT

# Drop invalid packets
iptables -A INPUT -m conntrack --ctstate INVALID -j DROP

# Log dropped packets
iptables -A INPUT -j LOG --log-prefix "IPT-DROP: " --log-level 4

# Drop and log
iptables -A INPUT -j LOG --log-prefix "IPT-DROP: "
iptables -A INPUT -j DROP
```

### Advanced Rules

```bash
# Rate limiting
iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -m recent --set
iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -m recent --update --seconds 60 --hitcount 4 -j DROP

# Limit connections per IP
iptables -A INPUT -p tcp --dport 80 -m connlimit --connlimit-above 50 -j DROP

# Time-based rules
iptables -A INPUT -p tcp --dport 80 -m time --timestart 09:00 --timestop 17:00 --days Mon,Tue,Wed,Thu,Fri -j ACCEPT

# String matching
iptables -A INPUT -p tcp --dport 80 -m string --string "bad-pattern" --algo bm -j DROP

# Geo-blocking (with ipset)
ipset create blocked_countries hash:net
ipset add blocked_countries 1.0.0.0/8
iptables -A INPUT -m set --match-set blocked_countries src -j DROP
```

### NAT (Network Address Translation)

```bash
# Source NAT (masquerade)
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# SNAT (static)
iptables -t nat -A POSTROUTING -o eth0 -j SNAT --to-source 203.0.113.1

# DNAT (port forwarding)
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 80 -j DNAT --to-destination 192.168.1.10:80

# DNAT with port change
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 8080 -j DNAT --to-destination 192.168.1.10:80

# Hairpin NAT (internal access to DNAT)
iptables -t nat -A POSTROUTING -s 192.168.1.0/24 -d 192.168.1.10 -p tcp --dport 80 -j SNAT --to-source 192.168.1.1

# Show NAT table
iptables -t nat -L -n -v
```

### Saving and Restoring

```bash
# Save rules
iptables-save > /etc/iptables/rules.v4
ip6tables-save > /etc/iptables/rules.v6

# Restore rules
iptables-restore < /etc/iptables/rules.v4

# Save with counters
iptables-save -c > /etc/iptables/rules.v4

# Restore (flush first)
iptables-restore --counters < /etc/iptables/rules.v4
```

---

## 4. nftables — Modern Packet Filtering

### Basic Commands

```bash
# Show all rules
nft list ruleset

# Show specific table
nft list table inet filter

# Show specific chain
nft list chain inet filter input

# Flush all rules
nft flush ruleset

# Create table
nft add table inet filter

# Create chain
nft add chain inet filter input { type filter hook input priority 0 \; policy drop \; }

# Add rule
nft add rule inet filter input ct state established,related accept
nft add rule inet filter input iif lo accept
nft add rule inet filter input tcp dport { 22, 80, 443 } accept
nft add rule inet filter input icmp type echo-request accept

# Delete rule (by handle)
nft delete rule inet filter input handle 4

# Insert rule (at position)
nft insert rule inet filter input position 4 tcp dport 22 accept
```

### Sets and Maps

```bash
# Create set
nft add set inet filter blocked_ips { type ipv4_addr \; }
nft add element inet filter blocked_ips { 192.168.1.100, 10.0.0.50 }

# Use set in rule
nft add rule inet filter input ip saddr @blocked_ips drop

# Create interval set (for ranges)
nft add set inet filter trusted_nets { type ipv4_addr \; flags interval \; }
nft add element inet filter trusted_nets { 192.168.1.0/24, 10.0.0.0/8 }

# Create map
nft add map inet filter port_to_action { type inet_service : verdict \; }
nft add element inet filter port_to_action { 22 : accept, 80 : accept, 443 : accept }
nft add rule inet filter input tcp dport vmap @port_to_action
```

### NAT with nftables

```bash
# Create NAT table
nft add table ip nat
nft add chain ip nat prerouting { type nat hook prerouting priority -100 \; }
nft add chain ip nat postrouting { type nat hook postrouting priority 100 \; }

# Masquerade
nft add rule ip nat postrouting oif eth0 masquerade

# DNAT (port forwarding)
nft add rule ip nat prerouting iif eth0 tcp dport 80 dnat to 192.168.1.10:80

# SNAT
nft add rule ip nat postrouting oif eth0 snat to 203.0.113.1
```

### Saving and Restoring

```bash
# Save ruleset
nft list ruleset > /etc/nftables.conf

# Restore ruleset
nft -f /etc/nftables.conf

# Atomic restore (replace entire ruleset)
nft -f /etc/nftables.conf
```

---

## 5. tcpdump — Packet Capture

### Basic Capture

```bash
# Capture on interface
tcpdump -i eth0

# Capture on all interfaces
tcpdump -i any

# Capture with verbose output
tcpdump -vvv -i eth0

# Capture with very verbose (hex + ASCII)
tcpdump -XX -i eth0

# Don't resolve hostnames
tcpdump -n -i eth0

# Don't resolve hostnames or ports
tcpdump -nn -i eth0

# Capture specific number of packets
tcpdump -c 100 -i eth0

# Write to file (pcap)
tcpdump -i eth0 -w capture.pcap

# Read from file
tcpdump -r capture.pcap

# Limit snaplen (bytes per packet)
tcpdump -s 96 -i eth0

# Full packet capture
tcpdump -s 0 -i eth0

# Capture with timestamp
tcpdump -tttt -i eth0
```

### Filtering Expressions

```bash
# Filter by host
tcpdump -i eth0 host 192.168.1.100

# Filter by source
tcpdump -i eth0 src host 192.168.1.100

# Filter by destination
tcpdump -i eth0 dst host 192.168.1.100

# Filter by port
tcpdump -i eth0 port 80

# Filter by source port
tcpdump -i eth0 src port 80

# Filter by destination port
tcpdump -i eth0 dst port 443

# Filter by protocol
tcpdump -i eth0 tcp
tcpdump -i eth0 udp
tcpdump -i eth0 icmp
tcpdump -i eth0 arp

# Filter by network
tcpdump -i eth0 net 192.168.1.0/24

# Combine filters (AND)
tcpdump -i eth0 host 192.168.1.100 and port 80

# Combine filters (OR)
tcpdump -i eth0 port 80 or port 443

# Negate filter
tcpdump -i eth0 not port 22

# Complex filter
tcpdump -i eth0 '(tcp port 80 or tcp port 443) and host 192.168.1.100'

# Filter by TCP flags
tcpdump -i eth0 'tcp[tcpflags] & (tcp-syn) != 0'
tcpdump -i eth0 'tcp[tcpflags] & (tcp-rst) != 0'
tcpdump -i eth0 'tcp[tcpflags] & (tcp-fin) != 0'

# Filter SYN packets only
tcpdump -i eth0 'tcp[tcpflags] == tcp-syn'

# Filter TCP SYN-ACK
tcpdump -i eth0 'tcp[tcpflags] == (tcp-syn|tcp-ack)'

# Filter by packet size
tcpdump -i eth0 'greater 1000'
tcpdump -i eth0 'less 100'

# Filter by VLAN
tcpdump -i eth0 vlan

# Filter by MAC address
tcpdump -i eth0 ether host 00:11:22:33:44:55

# Filter broadcast
tcpdump -i eth0 broadcast

# Filter multicast
tcpdump -i eth0 multicast
```

### Common Capture Patterns

```bash
# Capture DNS queries
tcpdump -i eth0 port 53 -nn

# Capture HTTP traffic
tcpdump -i eth0 port 80 -A -nn

# Capture HTTPS (headers only)
tcpdump -i eth0 port 443 -nn

# Capture SSH brute force attempts
tcpdump -i eth0 'tcp[tcpflags] == tcp-syn and dst port 22' -nn

# Capture ICMP (ping)
tcpdump -i eth0 icmp -nn

# Capture ARP
tcpdump -i eth0 arp -nn

# Capture DHCP
tcpdump -i eth0 port 67 or port 68 -nn

# Capture NTP
tcpdump -i eth0 port 123 -nn

# Capture SMTP
tcpdump -i eth0 port 25 -A -nn

# Capture MySQL queries
tcpdump -i eth0 port 3306 -A -nn | grep -i "select\|insert\|update\|delete"

# Monitor for port scans
tcpdump -i eth0 'tcp[tcpflags] & (tcp-syn) != 0 and tcp[tcpflags] & (tcp-ack) == 0' -nn

# Capture retransmissions
tcpdump -i eth0 'tcp[tcpflags] & (tcp-syn|tcp-fin|tcp-rst) == 0' -nn

# Capture large packets
tcpdump -i eth0 'ip[2:2] > 1000' -nn

# Capture traffic between two hosts
tcpdump -i eth0 host 192.168.1.1 and host 192.168.1.2 -nn

# Capture with time-based rotation
tcpdump -i eth0 -w capture.pcap -G 3600 -W 24
# -G: rotate every 3600 seconds
# -W: keep at most 24 files

# Capture with size-based rotation
tcpdump -i eth0 -w capture.pcap -C 100 -W 10
# -C: rotate at 100 MB
# -W: keep at most 10 files
```

### Reading and Analyzing Captures

```bash
# Read pcap file
tcpdump -r capture.pcap

# Read and filter
tcpdump -r capture.pcap port 80

# Read with timestamps
tcpdump -r capture.pcap -tttt

# Read and count packets
tcpdump -r capture.pcap | wc -l

# Read specific time range
tcpdump -r capture.pcap -tttt 'greater 2024-01-01 00:00:00 and less 2024-01-02 00:00:00'

# Extract specific fields
tcpdump -r capture.pcap -nn -e | awk '{print $1, $3, $4, $5}'
```

---

## 6. Quick Diagnostic Recipes

### Network Connectivity

```bash
# Test connectivity
ping -c 4 8.8.8.8

# Test DNS resolution
dig +short google.com

# Trace route
traceroute -n google.com

# Check open ports on remote host
nc -zv 192.168.1.1 80
nc -zv 192.168.1.1 22

# Check listening ports locally
ss -tlnp

# Show routing table
ip route show

# Check interface status
ip link show
ethtool eth0
```

### Connection Debugging

```bash
# Find who is using a port
ss -tlnp sport = :80
lsof -i :80

# Check connection states
ss -s

# Monitor connections in real-time
watch -n 1 'ss -t state established | wc -l'

# Find connections from specific IP
ss -tn | awk '{print $5}' | grep 192.168.1.100

# Check ARP table
ip neigh show
arp -a

# Check interface errors
ip -s link show eth0
ethtool -S eth0
```

### Firewall Debugging

```bash
# iptables: list with packet counts
iptables -L -n -v --line-numbers

# iptables: watch rule hits
watch -n 1 'iptables -L -n -v | head -20'

# nftables: list with counters
nft list ruleset -a

# Check if port is firewalled
nc -zv -w 3 192.168.1.1 80

# Check iptables NAT
iptables -t nat -L -n -v
```

---

*For detailed information on any command, consult its man page. For iptables migration to nftables, see `iptables-translate`.*
