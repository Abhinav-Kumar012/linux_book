# Chapter 54: Network Analysis — tcpdump, tshark, dig, nslookup, host, arp, nmap

## Overview

Network analysis tools are essential for diagnosing connectivity issues, debugging applications, investigating security incidents, and understanding network behavior. This chapter covers packet capture, DNS queries, ARP inspection, and network scanning.

---

## tcpdump — Packet Analyzer

### Purpose

`tcpdump` captures and displays network packets. It's the standard command-line packet analyzer on Linux.

### Key Options

| Option | Description |
|--------|-------------|
| `-i INTERFACE` | Capture on interface |
| `-c COUNT` | Stop after COUNT packets |
| `-w FILE` | Write packets to file |
| `-r FILE` | Read packets from file |
| `-n` | Don't resolve hostnames |
| `-nn` | Don't resolve hostnames or ports |
| `-v`, `-vv`, `-vvv` | Increasing verbosity |
| `-e` | Show link-layer header |
| `-X` | Show hex and ASCII |
| `-A` | Show ASCII only |
| `-s SNAPLEN` | Capture snap length |
| `-s 0` | Full packet capture |
| `-q` | Quick output |
| `-t` | Don't print timestamp |
| `-tttt` | Print date and time |
| `-l` | Line-buffered output |
| `-D` | List interfaces |
| `-L` | List data link types |
| `-F FILE` | Read filter from file |
| `-G SECONDS` | Rotate files |
| `-C SIZE` | Rotate by size (MB) |
| `-W COUNT` | Max number of files |
| `-Z USER` | Drop privileges |
| `-p` | Don't capture in promiscuous mode |
| `-S` | Print absolute TCP sequence numbers |
| `-E algo:secret` | Decrypt IPsec |
| `-K` | Don't verify checksums |
| `-B SIZE` | Buffer size |
| `-j TIMESTAMP` | Timestamp type |
| `-J` | List timestamp types |
| `--immediate-mode` | Immediate mode |
| `--print` | Print while capturing |
| `--time-stamp-precision` | Timestamp precision |

### Filter Expressions (BPF)

```bash
# Host filter
host 192.168.1.100
src host 192.168.1.100
dst host 192.168.1.100

# Port filter
port 80
src port 80
dst port 443
portrange 80-443

# Protocol filter
tcp
udp
icmp
arp

# Network filter
net 192.168.1.0/24
src net 192.168.1.0/24

# Combination
host 192.168.1.100 and port 80
host 192.168.1.100 and (port 80 or port 443)
not port 22
tcp and not port 22
src host 10.0.0.1 and dst port 80

# TCP flags
tcp[tcpflags] & tcp-syn != 0
tcp[tcpflags] & tcp-rst != 0
tcp[tcpflags] == tcp-syn

# Payload
tcp port 80 and (((ip[2:2] - ((ip[0]&0xf)<<2)) - ((tcp[12]&0xf0)>>2)) != 0)

# VLAN
vlan and host 192.168.1.100

# Direction
inbound
outbound
```

### Examples

```bash
# List interfaces
tcpdump -D

# Capture on interface
tcpdump -i eth0

# Capture with no DNS resolution
tcpdump -nn -i eth0

# Capture specific host
tcpdump -nn -i eth0 host 192.168.1.100

# Capture specific port
tcpdump -nn -i eth0 port 80

# Capture HTTP traffic
tcpdump -nn -i eth0 port 80 -A

# Capture with hex dump
tcpdump -nn -i eth0 port 80 -X

# Save to file
tcpdump -nn -i eth0 -w capture.pcap

# Read from file
tcpdump -r capture.pcap

# Capture with count
tcpdump -nn -i eth0 -c 100

# Capture TCP SYN packets
tcpdump -nn -i eth0 'tcp[tcpflags] & tcp-syn != 0'

# Capture DNS queries
tcpdump -nn -i eth0 port 53

# Capture ICMP (ping)
tcpdump -nn -i eth0 icmp

# Full packet capture
tcpdump -nn -i eth0 -s 0 -w full.pcap

# Capture on specific VLAN
tcpdump -nn -i eth0 vlan and host 192.168.1.100

# Verbose output
tcpdump -nn -vvv -i eth0

# Capture with timestamp
tcpdump -nn -tttt -i eth0

# Rotate capture files
tcpdump -nn -i eth0 -w capture.pcap -C 10 -W 10

# Line-buffered (for piping)
tcpdump -nn -i eth0 -l | grep pattern

# Exclude SSH traffic
tcpdump -nn -i eth0 not port 22

# Capture between two hosts
tcpdump -nn -i eth0 host 10.0.0.1 and host 10.0.0.2

# Capture HTTP GET requests
tcpdump -nn -i eth0 -A -s 0 'tcp port 80 and (((ip[2:2] - ((ip[0]&0xf)<<2)) - ((tcp[12]&0xf0)>>2)) != 0)' | grep "GET"

# Show Ethernet headers
tcpdump -nn -e -i eth0

# Capture ARP
tcpdump -nn -i eth0 arp

# Monitor multiple interfaces
tcpdump -nn -i eth0 -i eth1
```

### Performance

- **Capture speed**: `tcpdump` can capture at line rate on modern hardware with `-s 0` (full packets).
- **Filtering**: BPF filters are compiled to bytecode and run in the kernel, minimizing overhead.
- **Output**: Writing to file (`-w`) is faster than printing to terminal.

---

## tshark — Wireshark CLI

### Purpose

`tshark` is the command-line version of Wireshark. It captures and analyzes packets with Wireshark's protocol dissectors.

### Key Options

| Option | Description |
|--------|-------------|
| `-i INTERFACE` | Capture interface |
| `-f FILTER` | Capture filter (BPF) |
| `-Y DISPLAY_FILTER` | Display filter (Wireshark syntax) |
| `-w FILE` | Write to pcap file |
| `-r FILE` | Read from file |
| `-c COUNT` | Packet count |
| `-a DURATION` | Capture duration |
| `-T fields` | Output specific fields |
| `-e FIELD` | Field to extract |
| `-E separator=TAB` | Field separator |
| `-V` | Verbose (full packet decode) |
| `-x` | Hex dump |
| `-O PROTOCOL` | Show protocol details |
| `-n` | No name resolution |
| `-N RESOLV` | Name resolution options |
| `-q` | Quiet (stats mode) |
| `-z STAT` | Statistics |
| `--color` | Color output |
| `-J PROTOCOL` | Protocol filter |
| `-t ad` | Absolute date/time |

### Examples

```bash
# Capture on interface
tshark -i eth0

# Capture with filter
tshark -i eth0 -f "port 80"

# Display filter
tshark -i eth0 -Y "http.request"

# Extract specific fields
tshark -i eth0 -T fields -e ip.src -e ip.dst -e tcp.port

# Read pcap file
tshark -r capture.pcap

# Verbose output
tshark -r capture.pcap -V

# Show HTTP requests
tshark -r capture.pcap -Y "http.request" -T fields -e http.host -e http.request.uri

# Statistics
tshark -r capture.pcap -z conv,ip
tshark -r capture.pcap -z io,stat,1

# Protocol hierarchy
tshark -r capture.pcap -z io,phs

# Capture DNS queries
tshark -i eth0 -Y "dns.qry.name" -T fields -e dns.qry.name

# Extract TLS SNI
tshark -i eth0 -Y "tls.handshake.extensions_server_name" -T fields -e tls.handshake.extensions_server_name

# Write filtered output
tshark -r input.pcap -Y "http" -w http_only.pcap

# Multiple fields with separator
tshark -i eth0 -T fields -e frame.time -e ip.src -e ip.dst -e _ws.col.Protocol -E separator="|"
```

---

## dig — DNS Lookup

### Purpose

`dig` (Domain Information Groper) queries DNS servers for domain information.

### Key Options

| Option | Description |
|--------|-------------|
| `@server` | DNS server to query |
| `-t TYPE` | Query type (A, AAAA, MX, NS, TXT, etc.) |
| `-p PORT` | DNS server port |
| `-4` | IPv4 only |
| `-6` | IPv6 only |
| `+short` | Short answer |
| `+noall +answer` | Only answer section |
| `+trace` | Trace delegation path |
| `+recurse` | Recursive query (default) |
| `+norecurse` | Non-recursive query |
| `+tcp` | Use TCP |
| `+dnssec` | Request DNSSEC records |
| `+ttlid` | Show TTL |
| `+nostats` | No statistics |
| `+time=N` | Timeout |
| `+tries=N` | Retry count |
| `-x ADDR` | Reverse DNS lookup |
| `-f FILE` | Batch queries from file |
| `-k FILE` | TSIG key file |
| `-y KEY` | TSIG key |

### Query Types

| Type | Description |
|------|-------------|
| `A` | IPv4 address |
| `AAAA` | IPv6 address |
| `MX` | Mail exchange |
| `NS` | Name server |
| `TXT` | Text records |
| `SOA` | Start of authority |
| `CNAME` | Canonical name |
| `PTR` | Pointer (reverse DNS) |
| `SRV` | Service |
| `CAA` | Certificate authority |
| `ANY` | All records |
| `AXFR` | Zone transfer |

### Examples

```bash
# Basic lookup
dig example.com

# Specific record type
dig example.com MX
dig example.com NS
dig example.com TXT
dig example.com AAAA

# Short answer
dig +short example.com

# Only answer section
dig +noall +answer example.com

# Specific DNS server
dig @8.8.8.8 example.com

# Reverse DNS
dig -x 8.8.8.8

# Trace delegation
dig +trace example.com

# Check DNSSEC
dig +dnssec example.com

# TCP query
dig +tcp example.com

# Multiple queries
dig example.com A example.com AAAA

# Batch queries
dig -f domains.txt

# Zone transfer (if allowed)
dig @ns1.example.com example.com AXFR

# TTL
dig +ttlid +noall +answer example.com

# Short reverse
dig +short -x 8.8.8.8

# Check specific subdomain
dig +short mail.example.com MX

# Query for DKIM
dig +short selector._domainkey.example.com TXT

# Check DMARC
dig +short _dmarc.example.com TXT

# Check SPF
dig +short example.com TXT | grep "v=spf1"

# Check CAA
dig +short example.com CAA

# Authority section
dig +noall +authority example.com

# Additional section
dig +noall +additional example.com
```

---

## nslookup — DNS Lookup (Legacy)

### Purpose

`nslookup` queries DNS servers. It's simpler than `dig` but less powerful.

### Interactive Mode

```bash
nslookup
> server 8.8.8.8
> set type=MX
> example.com
> exit
```

### Command-Line Mode

```bash
# Basic lookup
nslookup example.com

# Specific DNS server
nslookup example.com 8.8.8.8

# Specific record type
nslookup -type=MX example.com
nslookup -type=NS example.com
nslookup -type=TXT example.com

# Reverse DNS
nslookup 8.8.8.8

# Debug mode
nslookup -debug example.com
```

---

## host — DNS Lookup Utility

### Purpose

`host` provides simple DNS lookups with concise output.

### Examples

```bash
# Basic lookup
host example.com

# Specific DNS server
host example.com 8.8.8.8

# Reverse DNS
host 8.8.8.8

# All records
host -a example.com

# Specific record type
host -t MX example.com
host -t NS example.com
host -t TXT example.com

# Verbose
host -v example.com
```

---

## arp — ARP Table Manipulation

### Purpose

`arp` displays and modifies the ARP (Address Resolution Protocol) table.

### Examples

```bash
# Show ARP table
arp -a

# Show specific interface
arp -i eth0 -a

# Show numeric (no DNS)
arp -n

# Add static entry
arp -s 192.168.1.1 00:11:22:33:44:55

# Delete entry
arp -d 192.168.1.1

# Using ip command (preferred)
ip neigh show
ip neigh add 192.168.1.1 lladdr 00:11:22:33:44:55 dev eth0
```

---

## nmap — Network Scanner

### Purpose

`nmap` (Network Mapper) discovers hosts, services, and security information on networks.

### Key Options

| Option | Description |
|--------|-------------|
| `-sS` | TCP SYN scan (default, root) |
| `-sT` | TCP connect scan |
| `-sU` | UDP scan |
| `-sV` | Service/version detection |
| `-O` | OS detection |
| `-A` | Aggressive (OS, version, script, traceroute) |
| `-p PORTS` | Port specification |
| `-p-` | All ports (1-65535) |
| `-F` | Fast scan (top 100 ports) |
| `--top-ports N` | Top N ports |
| `-T0` to `-5` | Timing template |
| `-Pn` | Skip host discovery |
| `-sn` | Ping scan (no port scan) |
| `-sP` | Same as `-sn` |
| `-PS/PA/PU` | TCP SYN/ACK/UDP discovery |
| `-PE/PP/PM` | ICMP discovery |
| `-n` | No DNS resolution |
| `-R` | Always resolve DNS |
| `-oN FILE` | Normal output |
| `-oX FILE` | XML output |
| `-oG FILE` | Grepable output |
| `-oA BASE` | All formats |
| `-v`, `-vv` | Verbose |
| `-d`, `-dd` | Debug |
| `--script SCRIPT` | NSE scripts |
| `--script-args` | Script arguments |
| `-e IFACE` | Interface |
| `-S ADDR` | Source address |
| `-g PORT` | Source port |
| `--privileged` | Assume privileged |
| `--open` | Show open ports only |
| `--reason` | Show reason for state |
| `--min-rate N` | Minimum rate |
| `--max-rate N` | Maximum rate |
| `--host-timeout TIME` | Host timeout |
| `--max-retries N` | Max retries |

### Scan Types

| Type | Description |
|------|-------------|
| `-sS` | SYN scan (half-open, fast, stealthy) |
| `-sT` | TCP connect (full handshake) |
| `-sU` | UDP scan (slow) |
| `-sV` | Version detection |
| `-sA` | ACK scan (firewall mapping) |
| `-sW` | Window scan |
| `-sN/-sF/-sX` | NULL/FIN/Xmas scans |
| `-sI` | Idle scan (zombie) |
| `-sO` | IP protocol scan |
| `-b` | FTP bounce |

### Examples

```bash
# Scan single host
nmap 192.168.1.1

# Scan network
nmap 192.168.1.0/24

# Scan specific ports
nmap -p 22,80,443 192.168.1.1

# Scan all ports
nmap -p- 192.168.1.1

# Fast scan
nmap -F 192.168.1.1

# Service version detection
nmap -sV 192.168.1.1

# OS detection
nmap -O 192.168.1.1

# Aggressive scan
nmap -A 192.168.1.1

# UDP scan
nmap -sU 192.168.1.1

# Ping scan (host discovery)
nmap -sn 192.168.1.0/24

# Skip host discovery
nmap -Pn 192.168.1.1

# No DNS resolution
nmap -n 192.168.1.1

# Verbose
nmap -vv 192.168.1.1

# Save output
nmap -oN scan.txt 192.168.1.1
nmap -oX scan.xml 192.168.1.1
nmap -oA scan 192.168.1.1

# Run scripts
nmap --script=http-title 192.168.1.1
nmap --script=vuln 192.168.1.1

# Timing
nmap -T4 192.168.1.1    # Aggressive timing
nmap -T0 192.168.1.1    # Paranoid (slow, stealthy)

# Scan from specific source
nmap -S 10.0.0.1 192.168.1.1

# Show only open ports
nmap --open 192.168.1.1

# Show reason for state
nmap --reason 192.168.1.1

# Specific interface
nmap -e eth0 192.168.1.1

# Multiple targets
nmap 192.168.1.1 192.168.1.2 10.0.0.1

# Exclude hosts
nmap 192.168.1.0/24 --exclude 192.168.1.1,192.168.1.2

# Read targets from file
nmap -iL targets.txt
```

---

## Summary

### Quick Reference

```bash
# Packet capture
tcpdump -nn -i eth0 port 80
tcpdump -nn -i eth0 -w capture.pcap
tshark -i eth0 -Y "http.request"

# DNS
dig example.com
dig +short example.com
dig example.com MX
dig -x 8.8.8.8

# Network scanning
nmap -sn 192.168.1.0/24
nmap -sV -p 22,80,443 host
nmap -A host

# ARP
arp -a
ip neigh show
```
