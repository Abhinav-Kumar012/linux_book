# Chapter 131: Networking Syscalls

## 1. Introduction

Linux networking syscalls provide the interface for creating and managing network connections. While the BSD socket API is the user-facing interface, underneath are syscalls like `socket`, `bind`, `listen`, `accept4`, `connect`, `sendto`, `recvfrom`, `sendmsg`, and `recvmsg`. This chapter covers each in detail.

---

## 2. socket

### 2.1 Purpose

`socket` creates a communication endpoint (a file descriptor for network I/O).

### 2.2 Prototype

```c
#include <sys/socket.h>
int socket(int domain, int type, int protocol);
```

### 2.3 Arguments

**`domain`** (address family):

| Domain | Description |
|--------|-------------|
| `AF_INET` | IPv4 |
| `AF_INET6` | IPv6 |
| `AF_UNIX` | Local (Unix domain) sockets |
| `AF_NETLINK` | Netlink socket (kernel communication) |
| `AF_PACKET` | Low-level packet access |
| `AF_VSOCK` | VM sockets |

**`type`**:

| Type | Description |
|------|-------------|
| `SOCK_STREAM` | Reliable, connection-based (TCP) |
| `SOCK_DGRAM` | Connectionless, unreliable (UDP) |
| `SOCK_RAW` | Raw protocol access |
| `SOCK_SEQPACKET` | Sequenced, reliable, connection-based |
| `SOCK_NONBLOCK` | Non-blocking (Linux 2.6.27+) |
| `SOCK_CLOEXEC` | Close-on-exec (Linux 2.6.27+) |

**`protocol`**: Usually 0 (default for the type), or specific protocol like `IPPROTO_TCP`, `IPPROTO_UDP`.

### 2.4 Return Values

- **Success**: File descriptor (>= 0)
- **Failure**: -1 with `errno` set

### 2.5 Kernel Implementation

```c
SYSCALL_DEFINE3(socket, int, family, int, type, int, protocol)
{
    return __sys_socket(family, type, protocol);
}

int __sys_socket(int family, int type, int protocol)
{
    struct socket *sock;
    int flags;
    
    // Extract SOCK_CLOEXEC and SOCK_NONBLOCK from type
    flags = type & ~SOCK_TYPE_MASK;
    type &= SOCK_TYPE_MASK;
    
    // Create socket
    sock_create(family, type, protocol, &sock);
    
    // Get file descriptor
    int fd = sock_alloc_file(sock, flags, NULL);
    
    return fd;
}
```

### 2.6 Example

```c
#include <sys/socket.h>
#include <netinet/in.h>
#include <stdio.h>

int main(void)
{
    // Create TCP socket
    int sockfd = socket(AF_INET, SOCK_STREAM | SOCK_CLOEXEC, 0);
    if (sockfd < 0) { perror("socket"); return 1; }
    
    printf("Socket fd: %d\n", sockfd);
    
    // Create UDP socket
    int udpfd = socket(AF_INET, SOCK_DGRAM | SOCK_NONBLOCK | SOCK_CLOEXEC, 0);
    if (udpfd < 0) { perror("socket"); return 1; }
    
    printf("UDP fd: %d\n", udpfd);
    return 0;
}
```

---

## 3. bind

### 3.1 Purpose

`bind` assigns an address to a socket. For servers, this is the address and port clients will connect to.

### 3.2 Prototype

```c
#include <sys/socket.h>
int bind(int sockfd, const struct sockaddr *addr, socklen_t addrlen);
```

### 3.3 Example

```c
struct sockaddr_in addr = {
    .sin_family = AF_INET,
    .sin_port = htons(8080),
    .sin_addr.s_addr = INADDR_ANY,  // Listen on all interfaces
};

if (bind(sockfd, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
    perror("bind");
    return 1;
}
```

### 3.4 Error Codes

| Error | Description |
|-------|-------------|
| `EACCES` | Port < 1024 without `CAP_NET_BIND_SERVICE` |
| `EADDRINUSE` | Address already in use |
| `EBADF` | Bad file descriptor |

### 3.5 `SO_REUSEADDR` / `SO_REUSEPORT`

```c
int opt = 1;
setsockopt(sockfd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));
// Allows binding to an address in TIME_WAIT state

setsockopt(sockfd, SOL_SOCKET, SO_REUSEPORT, &opt, sizeof(opt));
// Allows multiple sockets to bind to the same port (load balancing)
```

---

## 4. listen

### 4.1 Purpose

`listen` marks a socket as passive (ready to accept connections).

### 4.2 Prototype

```c
int listen(int sockfd, int backlog);
```

### 4.3 Arguments

- **`sockfd`**: Socket file descriptor
- **`backlog`**: Maximum length of the pending connection queue

### 4.4 The Backlog Queue

The kernel maintains two queues:
1. **SYN queue**: Half-open connections (SYN received, SYN+ACK sent)
2. **Accept queue**: Fully established connections waiting for `accept`

The `backlog` parameter limits the accept queue. The SYN queue size is controlled by `/proc/sys/net/ipv4/tcp_max_syn_backlog`.

### 4.5 Kernel Implementation

```c
SYSCALL_DEFINE2(listen, int, fd, int, backlog)
{
    struct socket *sock = sockfd_lookup(fd);
    
    // Clamp backlog to system maximum
    if ((unsigned int)backlog > sysctl_somaxconn)
        backlog = sysctl_somaxconn;
    
    sock->ops->listen(sock, backlog);
}
```

The system-wide maximum backlog is `/proc/sys/net/core/somaxconn` (default 4096).

---

## 5. accept4 / accept

### 5.1 Purpose

`accept` extracts the first connection from the pending queue, creates a new socket for the connection, and returns a new file descriptor.

### 5.2 Prototype

```c
#include <sys/socket.h>
int accept(int sockfd, struct sockaddr *addr, socklen_t *addrlen);
int accept4(int sockfd, struct sockaddr *addr, socklen_t *addrlen, int flags);
```

### 5.3 Flags (accept4)

| Flag | Description |
|------|-------------|
| `SOCK_NONBLOCK` | Set non-blocking on new fd |
| `SOCK_CLOEXEC` | Set close-on-exec on new fd |

### 5.4 Example

```c
struct sockaddr_in client_addr;
socklen_t client_len = sizeof(client_addr);

int client_fd = accept4(sockfd, (struct sockaddr *)&client_addr,
                        &client_len, SOCK_NONBLOCK | SOCK_CLOEXEC);
if (client_fd < 0) {
    if (errno == EAGAIN) return;  // No pending connections (non-blocking)
    perror("accept");
    return;
}

printf("Connection from %s:%d\n",
       inet_ntoa(client_addr.sin_addr), ntohs(client_addr.sin_port));
```

### 5.5 Kernel Implementation

```c
SYSCALL_DEFINE4(accept4, int, fd, struct sockaddr __user *, upeer_sockaddr,
                int __user *, upeer_addrlen, int, flags)
{
    struct socket *sock = sockfd_lookup(fd);
    struct socket *newsock;
    
    // Create new socket
    sock_alloc_file(&newsock, flags, sock->file->f_path.dentry->d_sb);
    
    // Accept connection (calls protocol-specific accept)
    sock->ops->accept(sock, newsock, sock->file->f_flags);
    
    // Copy client address to user space
    if (upeer_sockaddr)
        sock->ops->getname(newsock, upeer_sockaddr, upeer_addrlen, 2);
    
    return newsock->file->f_path.dentry->d_inode->i_ino;  // fd number
}
```

---

## 6. connect

### 6.1 Purpose

`connect` initiates a connection on a socket.

### 6.2 Prototype

```c
int connect(int sockfd, const struct sockaddr *addr, socklen_t addrlen);
```

### 6.3 Behavior by Socket Type

- **SOCK_STREAM (TCP)**: Performs three-way handshake. Blocks until connected (or error).
- **SOCK_DGRAM (UDP)**: Sets default destination address. Returns immediately.
- **SOCK_NONBLOCK**: Returns -1 with `EINPROGRESS` for TCP. Use `poll`/`epoll` to detect completion.

### 6.4 Example

```c
struct sockaddr_in server_addr = {
    .sin_family = AF_INET,
    .sin_port = htons(80),
};
inet_pton(AF_INET, "93.184.216.34", &server_addr.sin_addr);

int sockfd = socket(AF_INET, SOCK_STREAM | SOCK_NONBLOCK | SOCK_CLOEXEC, 0);

int ret = connect(sockfd, (struct sockaddr *)&server_addr, sizeof(server_addr));
if (ret < 0) {
    if (errno == EINPROGRESS) {
        // Connection in progress — wait with poll/epoll
        struct pollfd pfd = { .fd = sockfd, .events = POLLOUT };
        poll(&pfd, 1, 5000);
        
        int err;
        socklen_t errlen = sizeof(err);
        getsockopt(sockfd, SOL_SOCKET, SO_ERROR, &err, &errlen);
        if (err) { /* connection failed */ }
    }
}
```

---

## 7. sendto / recvfrom

### 7.1 Purpose

`sendto` and `recvfrom` send/receive data on a socket, with address specification for connectionless sockets.

### 7.2 Prototype

```c
ssize_t sendto(int sockfd, const void *buf, size_t len, int flags,
               const struct sockaddr *dest_addr, socklen_t addrlen);
ssize_t recvfrom(int sockfd, void *buf, size_t len, int flags,
                 struct sockaddr *src_addr, socklen_t *addrlen);
```

### 7.3 Flags

| Flag | Description |
|------|-------------|
| `MSG_DONTWAIT` | Non-blocking (overrides socket setting) |
| `MSG_NOSIGNAL` | Don't generate SIGPIPE on stream sockets |
| `MSG_PEEK` | Peek at data without removing from queue |
| `MSG_OOB` | Send/receive out-of-band data |
| `MSG_WAITALL` | Block until full buffer received |
| `MSG_MORE` | Hint that more data will follow |
| `MSG_CONFIRM` | Confirm neighbor reachability (Linux 2.3+) |

### 7.4 UDP Example

```c
// Server
int sockfd = socket(AF_INET, SOCK_DGRAM | SOCK_CLOEXEC, 0);
struct sockaddr_in addr = { .sin_family = AF_INET, .sin_port = htons(9999), .sin_addr.s_addr = INADDR_ANY };
bind(sockfd, (struct sockaddr *)&addr, sizeof(addr));

char buf[1024];
struct sockaddr_in client;
socklen_t client_len = sizeof(client);
ssize_t n = recvfrom(sockfd, buf, sizeof(buf), 0, (struct sockaddr *)&client, &client_len);
sendto(sockfd, buf, n, 0, (struct sockaddr *)&client, client_len);

// Client
int sockfd = socket(AF_INET, SOCK_DGRAM | SOCK_CLOEXEC, 0);
struct sockaddr_in server = { .sin_family = AF_INET, .sin_port = htons(9999) };
inet_pton(AF_INET, "127.0.0.1", &server.sin_addr);
sendto(sockfd, "Hello", 5, 0, (struct sockaddr *)&server, sizeof(server));
```

---

## 8. sendmsg / recvmsg

### 8.1 Purpose

`sendmsg` and `recvmsg` are the most general-purpose data transfer syscalls. They support scatter/gather I/O, ancillary data (control messages), and all flags.

### 8.2 Prototype

```c
ssize_t sendmsg(int sockfd, const struct msghdr *msg, int flags);
ssize_t recvmsg(int sockfd, struct msghdr *msg, int flags);
```

### 8.3 The `msghdr` Structure

```c
struct msghdr {
    void         *msg_name;        // Socket address (for connectionless)
    socklen_t     msg_namelen;     // Length of address
    struct iovec *msg_iov;         // Scatter/gather array
    size_t        msg_iovlen;      // Number of iovec elements
    void         *msg_control;     // Ancillary data buffer
    size_t        msg_controllen;  // Length of ancillary data
    int           msg_flags;       // Flags (recvmsg only)
};
```

### 8.4 Ancillary Data

Ancillary data (control messages) is used for:
- Passing file descriptors between processes (`SCM_RIGHTS`)
- Sending credentials (`SCM_CREDENTIALS`)
- Getting/setting packet timestamps (`SO_TIMESTAMPING`)
- Network interface information

```c
// Sending a file descriptor
struct msghdr msg = {0};
struct iovec iov = { .iov_base = "x", .iov_len = 1 };
char buf[CMSG_SPACE(sizeof(int))];
struct cmsghdr *cmsg;

msg.msg_iov = &iov;
msg.msg_iovlen = 1;
msg.msg_control = buf;
msg.msg_controllen = sizeof(buf);

cmsg = CMSG_FIRSTHDR(&msg);
cmsg->cmsg_level = SOL_SOCKET;
cmsg->cmsg_type = SCM_RIGHTS;
cmsg->cmsg_len = CMSG_LEN(sizeof(int));
*(int *)CMSG_DATA(cmsg) = fd_to_pass;

sendmsg(sockfd, &msg, 0);
```

### 8.5 `sendmmsg` / `recvmmsg` (Linux 3.0+)

Batch multiple messages in a single syscall:

```c
int sendmmsg(int sockfd, struct mmsghdr *msgvec, unsigned int vlen, int flags);
int recvmmsg(int sockfd, struct mmsghdr *msgvec, unsigned int vlen, int flags, struct timespec *timeout);
```

---

## 9. Other Networking Syscalls

### 9.1 setsockopt / getsockopt

```c
int setsockopt(int fd, int level, int optname, const void *optval, socklen_t optlen);
int getsockopt(int fd, int level, int optname, void *optval, socklen_t *optlen);
```

Common options:
- `SO_REUSEADDR`, `SO_REUSEPORT` — address/port reuse
- `SO_KEEPALIVE` — TCP keepalive
- `TCP_NODELAY` — disable Nagle's algorithm
- `SO_RCVBUF`, `SO_SNDBUF` — buffer sizes
- `SO_LINGER` — close behavior

### 9.2 getaddrinfo / getnameinfo

While not direct syscalls, these are the modern interfaces for DNS resolution (replacing `gethostbyname`). They're implemented in glibc using `connect` to the system resolver.

### 9.3 shutdown

```c
int shutdown(int sockfd, int how);
```

| How | Description |
|-----|-------------|
| `SHUT_RD` | Close read half |
| `SHUT_WR` | Close write half (send FIN) |
| `SHUT_RDWR` | Close both halves |

### 9.4 getsockname / getpeername

```c
int getsockname(int sockfd, struct sockaddr *addr, socklen_t *addrlen);  // Local address
int getpeername(int sockfd, struct sockaddr *addr, socklen_t *addrlen);  // Remote address
```

---

## 10. Performance Considerations

- **`sendmmsg`/`recvmmsg`**: Amortize syscall overhead for UDP workloads
- **`TCP_NODELAY`**: Disable Nagle for latency-sensitive applications
- **`SO_REUSEPORT`**: Enable kernel-level load balancing across multiple sockets
- **`MSG_ZEROCOPY`** (Linux 4.14+): Avoid copying data to kernel for `send`
- **`TCP_FASTOPEN`** (Linux 3.6+): Send data in SYN packet

---

## 11. Security Implications

- **`CAP_NET_BIND_SERVICE`**: Required for ports < 1024
- **`CAP_NET_RAW`**: Required for raw sockets
- **`IP_PKTINFO`/`SCM_CREDENTIALS`**: Can leak information about the receiving process
- **SYN flood attacks**: Use SYN cookies (`/proc/sys/net/ipv4/tcp_syncookies`)
- **`SO_BINDTODEVICE`**: Restrict socket to specific interface

---

## 12. Common Bugs

```c
// BUG: Not checking sendto/recvfrom return
sendto(fd, buf, len, 0, &addr, sizeof(addr));  // Might send fewer bytes!

// BUG: Forgetting htons for port
addr.sin_port = 8080;  // Wrong! Must be network byte order
addr.sin_port = htons(8080);  // Correct

// BUG: Using accept (not accept4) — fd leaks on exec
int client = accept(server, NULL, NULL);  // No CLOEXEC!
// FIX: Use accept4
int client = accept4(server, NULL, NULL, SOCK_CLOEXEC);
```

---

## 13. Kernel Source References

- **Socket creation**: `net/socket.c`
- **TCP implementation**: `net/ipv4/tcp.c`, `net/ipv4/tcp_input.c`
- **UDP implementation**: `net/ipv4/udp.c`
- **Socket options**: `net/core/sock.c`
- **Ancillary data**: `net/core/scm.c`
- **Address handling**: `net/socket.c`

---

## 14. Summary

Networking syscalls form the foundation of all network communication in Linux:
- **`socket`**: Create communication endpoint
- **`bind`**: Assign address to socket
- **`listen`**: Mark socket as passive (server)
- **`accept4`**: Accept incoming connections
- **`connect`**: Initiate connection (client)
- **`sendto`/`recvfrom`**: Connectionless data transfer
- **`sendmsg`/`recvmsg`**: General-purpose data transfer with ancillary data
- **`sendmmsg`/`recvmmsg`**: Batched data transfer

---

## 15. Detailed Network Syscall Internals

### 15.1 The Socket Layer

The socket layer is the abstraction between user space and protocol implementations:

```c
struct socket {
    socket_state state;
    short type;
    unsigned long flags;
    struct file *file;
    struct sock *sk;           // Protocol-specific socket
    const struct proto_ops *ops;  // Socket operations
};

struct proto_ops {
    int family;
    struct module *owner;
    int (*bind)(struct socket *sock, struct sockaddr *myaddr, int sockaddr_len);
    int (*connect)(struct socket *sock, struct sockaddr *vaddr, int sockaddr_len, int flags);
    int (*accept)(struct socket *sock, struct socket *newsock, struct proto_accept_arg *arg);
    int (*listen)(struct socket *sock, int len);
    int (*sendmsg)(struct socket *sock, struct msghdr *m, size_t total_len);
    int (*recvmsg)(struct socket *sock, struct msghdr *m, size_t total_len, int flags);
    // ...
};
```

### 15.2 TCP Connection State Machine

The kernel TCP implementation manages connection state:

```c
enum tcp_state {
    TCP_ESTABLISHED = 1,
    TCP_SYN_SENT,
    TCP_SYN_RECV,
    TCP_FIN_WAIT1,
    TCP_FIN_WAIT2,
    TCP_TIME_WAIT,
    TCP_CLOSE,
    TCP_CLOSE_WAIT,
    TCP_LAST_ACK,
    TCP_LISTEN,
    TCP_CLOSING,
};
```

**Connection establishment (three-way handshake):**
```
Client                          Server
  |--- SYN --------------------->|
  |<-- SYN+ACK ------------------|
  |--- ACK --------------------->|
  |     Connection established    |
```

The kernel handles the handshake in the TCP softirq context, not in the `connect` syscall. The `connect` syscall initiates the handshake and blocks (or returns `EINPROGRESS` for non-blocking).

### 15.3 Socket Buffer Management

Each socket has send and receive buffers:

```c
struct sock {
    // Receive buffer
    struct sk_buff_head sk_receive_queue;
    int sk_rcvbuf;              // Receive buffer size
    atomic_t sk_rmem_alloc;     // Current receive buffer usage
    
    // Send buffer
    struct sk_buff_head sk_write_queue;
    int sk_sndbuf;              // Send buffer size
    atomic_t sk_wmem_alloc;     // Current send buffer usage
    
    // Congestion control
    struct tcp_congestion_ops *congestion_ops;
    // ...
};
```

**Buffer sizing:**
```c
// Set socket buffer sizes
int rcvbuf = 262144;  // 256KB
setsockopt(fd, SOL_SOCKET, SO_RCVBUF, &rcvbuf, sizeof(rcvbuf));

int sndbuf = 262144;
setsockopt(fd, SOL_SOCKET, SO_SNDBUF, &sndbuf, sizeof(sndbuf));

// Auto-tuning (default on Linux):
// The kernel automatically adjusts buffer sizes based on throughput
// SO_RCVBUF/SO_SNDBUF disable auto-tuning for that socket
```

### 15.4 The Network Buffer (sk_buff)

The `sk_buff` (socket buffer) is the fundamental network data structure:

```c
struct sk_buff {
    // Linked list management
    struct sk_buff *next, *prev;
    struct sk_buff_head *list;
    
    // Time stamps
    ktime_t tstamp;
    
    // Socket binding
    struct sock *sk;
    
    // Network device
    struct net_device *dev;
    
    // Header pointers
    unsigned char *head;    // Start of buffer
    unsigned char *data;    // Start of data
    unsigned char *tail;    // End of data
    unsigned char *end;     // End of buffer
    
    // Protocol headers
    union {
        struct tcphdr *th;
        struct udphdr *uh;
        struct icmphdr *icmph;
        // ...
    } h;
    
    // Network header
    struct iphdr *nh;
    
    // MAC header
    unsigned char *mac;
    
    // Lengths
    unsigned int len;       // Total length
    unsigned int data_len;  // Data length (for frags)
    // ...
};
```

### 15.5 TCP Congestion Control

The kernel implements pluggable congestion control:

```c
struct tcp_congestion_ops {
    u32 (*ssthresh)(struct sock *sk);
    void (*cong_avoid)(struct sock *sk, u32 ack, u32 acked);
    void (*set_state)(struct sock *sk, u8 new_state);
    void (*cwnd_event)(struct sock *sk, enum tcp_ca_event ev);
    void (*in_ack_event)(struct sock *sk, u32 flags);
    void (*pkts_acked)(struct sock *sk, const struct ack_sample *sample);
    u32 (*undo_cwnd)(struct sock *sk);
    // ...
};
```

**Available algorithms:**
- `reno`: Basic TCP congestion control
- `cubic`: Default on Linux (CUBIC algorithm)
- `bbr`: Google's BBR (Bottleneck Bandwidth and RTT)
- `vegas`: TCP Vegas

```bash
# Check current algorithm
sysctl net.ipv4.tcp_congestion_control
# Change algorithm
sysctl -w net.ipv4.tcp_congestion_control=bbr
```

### 15.6 Zero-Copy Networking

Multiple mechanisms exist for zero-copy network I/O:

**sendfile (file to socket):**
```c
sendfile(socket_fd, file_fd, &offset, count);
// Data goes from page cache directly to NIC DMA buffers
```

**MSG_ZEROCOPY (socket send):**
```c
// Requires opt-in
setsockopt(fd, SOL_SOCKET, SO_ZEROCOPY, &opt, sizeof(opt));

// Send with zero-copy
sendmsg(fd, &msg, MSG_ZEROCOPY);

// Completion notification via error queue
struct sock_extended_err *err;
// ... recvmsg with MSG_ERRQUEUE ...
```

**TCP receive zero-copy (MSG_ZEROCOPY for receive):**
Linux 6.0+ supports zero-copy receive for TCP:
```c
// Map the socket's receive buffer
void *addr = mmap(NULL, size, PROT_READ, MAP_SHARED, tcp_fd, 0);
// Data appears directly in mapped memory after recv
```

### 15.7 TCP Fast Open (TFO)

TFO allows data to be sent in the SYN packet:

```c
// Server: Enable TFO
int qlen = 5;
setsockopt(fd, IPPROTO_TCP, TCP_FASTOPEN, &qlen, sizeof(qlen));

// Client: Use TFO
// First connect() performs normal handshake but caches the TFO cookie
// Subsequent connect()s send data in the SYN
sendto(fd, data, len, MSG_FASTOPEN, &addr, addrlen);
```

### 15.8 SO_REUSEPORT Load Balancing

`SO_REUSEPORT` allows multiple sockets to bind to the same port:

```c
int opt = 1;
setsockopt(fd, SOL_SOCKET, SO_REUSEPORT, &opt, sizeof(opt));
bind(fd, &addr, sizeof(addr));
listen(fd, 128);

// Create multiple sockets on the same port
// The kernel distributes connections using a hash (BPF or 4-tuple)
```

**Custom BPF steering:**
```c
// Attach a BPF program to steer connections
setsockopt(fd, SOL_SOCKET, SO_ATTACH_REUSEPORT_CBPF, &prog, sizeof(prog));
```

### 15.9 Socket Timestamping

The kernel can timestamp packets:

```c
// Enable software timestamps
int flags = SOF_TIMESTAMPING_TX_SOFTWARE | SOF_TIMESTAMPING_RX_SOFTWARE;
setsockopt(fd, SOL_SOCKET, SO_TIMESTAMPING, &flags, sizeof(flags));

// Enable hardware timestamps (NIC must support it)
flags = SOF_TIMESTAMPING_TX_HARDWARE | SOF_TIMESTAMPING_RX_HARDWARE;
setsockopt(fd, SOL_SOCKET, SO_TIMESTAMPING, &flags, sizeof(flags));

// Read timestamps via recvmsg with MSG_ERRQUEUE
```

### 15.10 Network Namespaces and Socket Creation

Sockets are always created in the current network namespace:

```c
// After unshare(CLONE_NEWNET):
int fd = socket(AF_INET, SOCK_STREAM, 0);
// This socket is in the new (empty) network namespace
// It can only see the loopback interface
```

To use sockets across namespaces, you need to pass file descriptors via Unix domain sockets (SCM_RIGHTS) or use veth pairs.

### 15.11 Socket Options Deep Dive

**TCP_NODELAY (disable Nagle's algorithm):**
```c
int flag = 1;
setsockopt(fd, IPPROTO_TCP, TCP_TCP_NODELAY, &flag, sizeof(flag));
// Small packets are sent immediately instead of waiting to coalesce
// Essential for latency-sensitive applications (SSH, gaming)
```

**SO_KEEPALIVE:**
```c
int keepalive = 1;
setsockopt(fd, SOL_SOCKET, SO_KEEPALIVE, &keepalive, sizeof(keepalive));

// TCP keepalive parameters
int idle = 60;    // Start probes after 60s idle
int interval = 10; // Probe every 10s
int count = 5;    // Drop after 5 failed probes
setsockopt(fd, IPPROTO_TCP, TCP_KEEPIDLE, &idle, sizeof(idle));
setsockopt(fd, IPPROTO_TCP, TCP_KEEPINTVL, &interval, sizeof(interval));
setsockopt(fd, IPPROTO_TCP, TCP_KEEPCNT, &count, sizeof(count));
```

**SO_LINGER:**
```c
struct linger lg = { .l_onoff = 1, .l_linger = 5 };
setsockopt(fd, SOL_SOCKET, SO_LINGER, &lg, sizeof(lg));
// When close() is called:
// - If l_onoff: Wait up to l_linger seconds for data to be sent
// - If l_linger: Send RST after timeout
```

### 15.12 Non-blocking Socket Patterns

```c
// Set non-blocking
int flags = fcntl(fd, F_GETFL);
fcntl(fd, F_SETFL, flags | O_NONBLOCK);

// Non-blocking connect
int ret = connect(fd, &addr, addrlen);
if (ret < 0 && errno == EINPROGRESS) {
    // Wait for connection with epoll
    struct epoll_event ev = { .events = EPOLLOUT, .data.fd = fd };
    epoll_ctl(epfd, EPOLL_CTL_ADD, fd, &ev);
    
    // After epoll reports EPOLLOUT, check for errors
    int err;
    socklen_t errlen = sizeof(err);
    getsockopt(fd, SOL_SOCKET, SO_ERROR, &err, &errlen);
    if (err) { /* Connection failed */ }
}

// Non-blocking accept
int client = accept4(server, NULL, NULL, SOCK_NONBLOCK | SOCK_CLOEXEC);
```

### 15.13 sendmmsg/recvmmsg for High-Performance UDP

```c
#define BATCH_SIZE 64

struct mmsghdr msgs[BATCH_SIZE];
struct iovec iovecs[BATCH_SIZE];
char bufs[BATCH_SIZE][1500];

for (int i = 0; i < BATCH_SIZE; i++) {
    iovecs[i].iov_base = bufs[i];
    iovecs[i].iov_len = sizeof(bufs[i]);
    msgs[i].msg_hdr.msg_iov = &iovecs[i];
    msgs[i].msg_hdr.msg_iovlen = 1;
}

// Receive multiple packets in one syscall
int n = recvmmsg(fd, msgs, BATCH_SIZE, MSG_DONTWAIT, NULL);
for (int i = 0; i < n; i++) {
    process_packet(bufs[i], msgs[i].msg_len);
}
```

### 15.14 Unix Domain Sockets

Unix domain sockets provide IPC on the same machine:

```c
// Stream socket (SOCK_STREAM)
int fd = socket(AF_UNIX, SOCK_STREAM | SOCK_CLOEXEC, 0);
struct sockaddr_un addr = { .sun_family = AF_UNIX };
strncpy(addr.sun_path, "/tmp/mysocket", sizeof(addr.sun_path));
bind(fd, (struct sockaddr *)&addr, sizeof(addr));
listen(fd, 5);

// Datagram socket (SOCK_DGRAM)
int fd = socket(AF_UNIX, SOCK_DGRAM | SOCK_CLOEXEC, 0);
```

**Abstract namespace (Linux-specific):**
```c
struct sockaddr_un addr = { .sun_family = AF_UNIX };
addr.sun_path[0] = '\0';  // Abstract namespace (no filesystem entry)
strncpy(addr.sun_path + 1, "mysocket", sizeof(addr.sun_path) - 2);
```
