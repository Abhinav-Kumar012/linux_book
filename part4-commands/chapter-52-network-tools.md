# Chapter 52: Network Tools — curl, wget, nc (netcat), socat, ping, traceroute, mtr

## Overview

Network tools are essential for testing connectivity, transferring data, debugging network issues, and automating web interactions. This chapter covers the most important command-line network utilities.

---

## curl — Client URL

### Purpose

`curl` transfers data to/from URLs using various protocols (HTTP, HTTPS, FTP, SCP, SFTP, TFTP, DICT, TELNET, LDAP, FILE, POP3, IMAP, SMTP, RTSP, RTMP, GOPHER).

### Key Options

| Option | Description |
|--------|-------------|
| `-o FILE` | Output to file |
| `-O` | Save with remote filename |
| `-L` | Follow redirects |
| `-k` | Allow insecure SSL |
| `-s` | Silent (no progress) |
| `-S` | Show errors (with `-s`) |
| `-v` | Verbose |
| `-V` | Version |
| `-d DATA` | POST data |
| `-X METHOD` | HTTP method |
| `-H HEADER` | Custom header |
| `-A USER-AGENT` | User agent |
| `-b COOKIE` | Cookie |
| `-c FILE` | Save cookies |
| `-u USER:PASS` | Authentication |
| `-U USER:PASS` | Proxy authentication |
| `-x PROXY` | Use proxy |
| `-e REFERRER` | Referrer |
| `-f` | Fail silently on HTTP errors |
| `-F KEY=VALUE` | Multipart form data |
| `-I` | Headers only (HEAD request) |
| `-i` | Include headers in output |
| `--compressed` | Request compressed response |
| `-C OFFSET` | Resume at offset |
| `--retry N` | Retry N times |
| `--retry-delay SECS` | Delay between retries |
| `--connect-timeout SECS` | Connection timeout |
| `-m SECS` | Max time |
| `-w FORMAT` | Output format |
| `-K FILE` | Config file |
| `-n` | Use .netrc |
| `-#` | Progress bar |
| `--data-urlencode DATA` | URL-encode data |
| `--json DATA` | JSON POST (sets Content-Type) |
| `--upload-file FILE` | Upload file (PUT) |
| `--ftp-create-dirs` | Create FTP directories |
| `--proto-default PROTO` | Default protocol |
| `-4` | Force IPv4 |
| `-6` | Force IPv6 |
| `--interface IFACE` | Bind to interface |
| `--dns-servers SERVERS` | DNS servers |
| `--resolve HOST:PORT:ADDR` | Custom DNS resolution |
| `--cert CERT` | Client certificate |
| `--key KEY` | Private key |
| `--cacert CA` | CA certificate |
| `--pinnedpubkey HASH` | Pin public key |

### Examples

```bash
# GET request
curl https://example.com

# Save to file
curl -o page.html https://example.com
curl -O https://example.com/file.zip

# Follow redirects
curl -L https://short.url/abc

# POST data
curl -d "name=value" https://api.example.com/endpoint

# POST JSON
curl -X POST -H "Content-Type: application/json" \
     -d '{"key":"value"}' https://api.example.com/endpoint

# JSON shorthand (curl 7.82+)
curl --json '{"key":"value"}' https://api.example.com/endpoint

# Headers only
curl -I https://example.com

# Include headers
curl -i https://example.com

# Custom headers
curl -H "Authorization: Bearer token" https://api.example.com

# Authentication
curl -u username:password https://api.example.com

# Multipart form upload
curl -F "file=@photo.jpg" -F "name=photo" https://upload.example.com

# Upload file
curl -T localfile.txt ftp://ftp.example.com/remote.txt

# Resume download
curl -C - -O https://example.com/largefile.zip

# With timeout
curl --connect-timeout 10 -m 30 https://example.com

# Silent with errors
curl -sS https://example.com

# Verbose
curl -v https://example.com

# Show transfer stats
curl -w "Time: %{time_total}s\nSize: %{size_download}\n" -o /dev/null -s https://example.com

# Custom DNS
curl --resolve example.com:443:1.2.3.4 https://example.com

# Proxy
curl -x http://proxy:8080 https://example.com

# SOCKS proxy
curl --socks5 localhost:1080 https://example.com

# Cookie handling
curl -b cookies.txt -c cookies.txt https://example.com

# Insecure SSL (dev only)
curl -k https://self-signed.example.com

# Retry
curl --retry 3 --retry-delay 5 https://unstable-api.example.com

# Multiple URLs
curl https://example.com/{1,2,3}.html

# Parallel downloads (curl 7.66+)
curl -Z https://example.com/file1 https://example.com/file2

# Rate limit
curl --limit-rate 100K -O https://example.com/largefile.zip

# HTTP/2
curl --http2 https://example.com

# Output format
curl -w "%{http_code}\n" -o /dev/null -s https://example.com

# JSON pretty-print
curl -s https://api.example.com/data | jq .

# Check endpoint health
curl -sf -o /dev/null https://health.example.com/ready && echo "OK" || echo "FAIL"

# Send email (SMTP)
curl --url "smtp://mail.example.com" \
     --mail-from sender@example.com \
     --mail-rcpt receiver@example.com \
     -T email.txt
```

### Performance

- **curl** uses efficient C code with minimal memory overhead.
- **Connection reuse**: `curl` supports HTTP keep-alive by default.
- **Multi-protocol**: Single tool for many protocols reduces dependencies.

---

## wget — Network Downloader

### Purpose

`wget` downloads files from the web. It's designed for non-interactive downloads (scripts, cron jobs) and supports recursive downloading.

### Key Options

| Option | Description |
|--------|-------------|
| `-O FILE` | Output filename |
| `-P DIR` | Save to directory |
| `-c` | Continue partial download |
| `-q` | Quiet |
| `-v` | Verbose |
| `-b` | Background mode |
| `-t N` | Retry count (0=infinite) |
| `--wait=SECS` | Wait between requests |
| `--random-wait` | Random wait (0.5-1.5x) |
| `--limit-rate=RATE` | Download rate limit |
| `-r` | Recursive download |
| `-l DEPTH` | Recursion depth |
| `--no-parent` | Don't follow to parent |
| `-A LIST` | Accept list |
| `-R LIST` | Reject list |
| `--domains=LIST` | Restrict to domains |
| `--mirror` | Mirror site |
| `--convert-links` | Convert links for offline viewing |
| `--page-requisites` | Download page resources |
| `--adjust-extension` | Add .html to XHTML pages |
| `-i FILE` | Read URLs from file |
| `--header=HEADER` | Custom header |
| `--user-agent=UA` | User agent |
| `--no-check-certificate` | Ignore SSL errors |
| `--password=PASS` | HTTP password |
| `--user=USER` | HTTP user |
| `--execute COMMAND` | Execute command (.wgetrc) |
| `--spider` | Don't download, just check |
| `--delete-after` | Delete after download |
| `--reject=LIST` | Reject patterns |
| `--accept=LIST` | Accept patterns |
| `--timestamping` | Download only if newer |
| `--no-clobber` | Don't overwrite |
| `-e COMMAND` | Execute .wgetrc command |
| `--content-disposition` | Use server filename |

### Examples

```bash
# Download file
wget https://example.com/file.zip

# Save with different name
wget -O output.zip https://example.com/file.zip

# Continue interrupted download
wget -c https://example.com/largefile.zip

# Background download
wget -b https://example.com/largefile.zip

# Recursive download (mirror)
wget -r -np -l 5 https://example.com/docs/

# Mirror site
wget --mirror --convert-links --page-requisites https://example.com/

# Read URLs from file
wget -i urls.txt

# Rate limit
wget --limit-rate=200k https://example.com/largefile.zip

# Retry on failure
wget -t 5 https://unstable.example.com/file.zip

# Spider (check if URL exists)
wget --spider https://example.com/page.html

# Wait between requests
wget --wait=1 -r https://example.com/

# Custom headers
wget --header="Authorization: Bearer token" https://api.example.com/data

# Ignore SSL errors
wget --no-check-certificate https://self-signed.example.com/

# Download with timestamping
wget -N https://example.com/data.csv

# Multiple URLs
wget https://example.com/{file1,file2,file3}.zip
```

### curl vs wget

| Feature | curl | wget |
|---------|------|------|
| Download files | ✓ | ✓ |
| Upload | ✓ | Limited |
| Recursive download | ✗ | ✓ |
| Multiple protocols | ✓ (more) | HTTP/FTP |
| Resume downloads | ✓ | ✓ |
| POST/PUT | ✓ | Limited |
| Cookie handling | ✓ | ✓ |
| Output format | Flexible | File-oriented |
| Scripting | Excellent | Good |

---

## nc (netcat) — TCP/UDP Connection Tool

### Purpose

`nc` (netcat) is the "Swiss army knife" of networking — it reads and writes data across network connections using TCP or UDP.

### Key Options

| Option | Description |
|--------|-------------|
| `-l` | Listen mode |
| `-p PORT` | Source port |
| `-u` | UDP mode |
| `-v` | Verbose |
| `-w SECS` | Timeout |
| `-z` | Zero-I/O mode (scan) |
| `-n` | No DNS resolution |
| `-e COMMAND` | Execute command on connection |
| `-k` | Keep listening after disconnect |
| `-q SECS` | Quit after EOF delay |
| `-s ADDR` | Source address |
| `-4` | IPv4 only |
| `-6` | IPv6 only |
| `-U` | Unix socket |
| `-X PROXY` | Proxy protocol |
| `-x ADDR` | Proxy address |

### Examples

```bash
# Simple chat (listener)
nc -l 12345

# Connect to listener
nc localhost 12345

# Port scan
nc -zv host 80-100

# UDP mode
nc -u host 53

# Transfer file (sender)
nc -l 12345 < file.tar.gz

# Transfer file (receiver)
nc host 12345 > file.tar.gz

# Simple HTTP request
echo -e "GET / HTTP/1.1\r\nHost: example.com\r\n\r\n" | nc example.com 80

# Execute shell on connection (DANGEROUS)
nc -l -e /bin/bash 12345

# Keep listening after disconnect
nc -lk 12345

# Timeout
nc -w 5 host 12345

# Listen on specific address
nc -l -s 0.0.0.0 -p 12345

# Unix socket
nc -U /var/run/docker.sock

# Scan multiple ports
nc -zv host 22 80 443 3306

# Check if port is open
nc -zv host 22 2>&1 | grep succeeded

# Simple HTTP server
while true; do echo -e "HTTP/1.1 200 OK\r\n\r\nHello" | nc -l -p 8080; done
```

---

## socat — Multipurpose Relay

### Purpose

`socat` (SOcket CAT) is a more powerful alternative to `netcat`, supporting bidirectional data transfer between two data channels (sockets, files, pipes, devices, etc.).

### Key Options

| Option | Description |
|--------|-------------|
| `-` | stdin/stdout |
| `TCP:host:port` | TCP connection |
| `TCP-LISTEN:port` | TCP listener |
| `UDP:host:port` | UDP connection |
| `UNIX-CONNECT:path` | Unix socket |
| `UNIX-LISTEN:path` | Unix socket listener |
| `EXEC:cmd` | Execute command |
| `OPEN:file` | Open file |
| `PIPE:file` | Named pipe |
| `STDIN` | Standard input |
| `STDOUT` | Standard output |
| `FD:n` | File descriptor |
| `GOPEN:file` | Generic open |

### Examples

```bash
# TCP forwarder (port 8080 → remote:80)
socat TCP-LISTEN:8080,fork TCP:remote:80

# Unix socket to TCP
socat UNIX-CONNECT:/var/run/docker.sock TCP-LISTEN:2375,fork

# SSL forwarder
socat TCP-LISTEN:443,fork OPENSSL:remote:443

# Execute command on connection
socat TCP-LISTEN:12345,fork EXEC:/bin/cat

# File transfer (sender)
socat TCP-LISTEN:12345 FILE:file.tar.gz

# File transfer (receiver)
socat TCP:sender:12345 FILE:output.tar.gz,create

# Bidirectional pipe
socat - TCP:localhost:80

# UDP echo
socat UDP-LISTEN:12345,fork UDP:echo.example.com:7

# TTY over network
socat TCP-LISTEN:12345,fork EXEC:"/bin/bash -li",pty,stderr,setsid,sigint,sane

# PTY for serial device
socat /dev/ttyS0,raw,echo=0,crnl TCP:serial-server:12345
```

---

## ping — Send ICMP ECHO_REQUEST

### Purpose

`ping` tests network connectivity and measures round-trip time.

### Key Options

| Option | Description |
|--------|-------------|
| `-c COUNT` | Stop after COUNT packets |
| `-i INTERVAL` | Interval between packets (seconds) |
| `-s SIZE` | Packet size |
| `-t TTL` | Time to live |
| `-W TIMEOUT` | Timeout for each packet |
| `-w DEADLINE` | Overall deadline |
| `-f` | Flood ping (root) |
| `-q` | Quiet output |
| `-v` | Verbose |
| `-I INTERFACE` | Source interface |
| `-S SOURCE` | Source address |
| `-4` | Force IPv4 |
| `-6` | Force IPv6 |
| `-p PATTERN` | Pad pattern |
| `-M OPTION` | Path MTU discovery |
| `-n` | Numeric output |

### Examples

```bash
# Basic ping
ping google.com

# Ping 5 times
ping -c 5 google.com

# Fast ping (0.2s interval)
ping -i 0.2 -c 10 google.com

# Large packet
ping -s 1472 google.com

# Quick check
ping -c 1 -W 2 google.com

# Numeric (no DNS)
ping -n 8.8.8.8

# From specific interface
ping -I eth0 google.com

# Flood ping (root)
ping -f google.com

# IPv6
ping -6 google.com

# Set TTL
ping -t 5 google.com

# Quiet summary
ping -c 10 -q google.com

# With deadline
ping -w 30 google.com
```

---

## traceroute — Print Route Packets Take

### Purpose

`traceroute` shows the path packets take to reach a destination, listing each hop (router).

### Key Options

| Option | Description |
|--------|-------------|
| `-n` | No DNS resolution |
| `-m MAX_TTL` | Max hops |
| `-w TIMEOUT` | Wait time per hop |
| `-q N` | Queries per hop |
| `-I` | Use ICMP (instead of UDP) |
| `-T` | Use TCP |
| `-p PORT` | Destination port |
| `-A` | Show AS numbers |
| `-f FIRST_TTL` | First TTL |
| `-z MSEC` | Minimum time between probes |
| `-4` | Force IPv4 |
| `-6` | Force IPv6 |

### Examples

```bash
# Basic traceroute
traceroute google.com

# TCP traceroute (bypasses firewalls)
traceroute -T -p 443 google.com

# ICMP traceroute
traceroute -I google.com

# No DNS resolution
traceroute -n google.com

# Max 15 hops
traceroute -m 15 google.com

# Show AS numbers
traceroute -A google.com

# Custom timeout
traceroute -w 2 google.com
```

---

## mtr — Network Diagnostic Tool

### Purpose

`mtr` combines `ping` and `traceroute` into a single tool that continuously monitors the route to a destination.

### Key Options

| Option | Description |
|--------|-------------|
| `-n` | No DNS resolution |
| `-c COUNT` | Number of pings |
| `-i INTERVAL` | Interval |
| `-r` | Report mode |
| `-w` | Wide report |
| `-b` | Show both IP and hostname |
| `-T` | TCP mode |
| `-P PORT` | TCP port |
| `-u` | UDP mode |
| `-s SIZE` | Packet size |
| `-a ADDR` | Source address |
| `-z` | Show ASN |
| `--json` | JSON output |
| `--csv` | CSV output |
| `-4` | Force IPv4 |
| `-6` | Force IPv6 |

### Examples

```bash
# Interactive mode
mtr google.com

# Report mode (non-interactive)
mtr -r -c 100 google.com

# No DNS
mtr -n google.com

# TCP mode
mtr -T -P 443 google.com

# Wide report
mtr -r -w -c 50 google.com

# JSON output
mtr --json google.com

# CSV output
mtr --csv google.com

# Show ASN
mtr -z google.com

# Custom interval
mtr -i 0.5 google.com
```

---

## Summary

### Quick Reference

```bash
# HTTP requests
curl -s https://api.example.com/data
curl -X POST -H "Content-Type: application/json" -d '{}' url
wget -c https://example.com/file.zip

# Connectivity testing
ping -c 5 host
traceroute -T host
mtr -r -c 100 host

# Port scanning
nc -zv host 80-443
nc -zv host 22 80 443

# Data transfer
nc -l 12345 < file
nc host 12345 > file

# Advanced relays
socat TCP-LISTEN:8080,fork TCP:remote:80
```
