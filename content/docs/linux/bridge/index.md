## 目标：
```markdown
        Namespace ns1               Namespace ns2
     +----------------+          +----------------+
     |                |          |                |
     | eth0 10.0.0.2  |          | eth0 10.0.0.3  |
     +-------▲--------+          +--------▲-------+
             │                            │
         veth-ns1                    veth-ns2
=============│============================│=============
      veth-br1                      veth-br2
             │                            │
             └──────────┬─────────────────┘
                        │
                  Linux Bridge (br0)
                  10.0.0.1/24
```

#### 启动一个docker容器当作实验环境
```markdown
docker run -itd \
  --name linux-net-lab \
  --privileged \
  ubuntu:latest bash
```

`--privileged`参数给容器所有 Linux Capabilities。否则会因为权限不够而： <font style="color:#2fff12;background-color:rgba(0, 0, 0, 0.9);">RTNETLINK answers: Operation not permitted</font>

Linux 早就把 root 权限拆成了几十种 Capability。

| Capability | 权限 |
| --- | --- |
| CAP_NET_ADMIN | 修改网络设备、路由、iptables、bridge |
| CAP_NET_RAW | 创建 raw socket、ping |
| CAP_SYS_ADMIN | mount、namespace、很多系统管理功能（非常强） |
| CAP_SYS_TIME | 修改系统时间 |
| CAP_SYS_MODULE | 加载内核模块 |


```markdown
apt update
apt install -y \
iproute2 \
iputils-ping \
iptables \
bridge-utils \
net-tools \
tcpdump \
curl \
dnsutils \
procps \
vim
```

```markdown
ip -V
bridge -V
ip addr
ip link
bridge link
```

#### 创建一个 Linux Bridge
```markdown
ip link add br0 type bridge
```

然后启动

```markdown
ip link set br0 up
```

查看

```markdown
bridge link
```

此时，`bridge link`应该没有任何输出，因为没有任何端口连接。

#### 创建第一对 veth Pair
```markdown
ip linkve add veth-br1 type veth peer name veth-ns1
```

Virtual Ethernet Pair（虚拟以太网对）

```systemverilog
11: br0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
link/ether 16:73:53:8c:8e:72 brd ff:ff:ff:ff:ff:ff
12: veth-ns1@veth-br1: <BROADCAST,MULTICAST,M-DOWN> mtu 1500 qdisc noop state DOWN mode DEFAULT group default qlen 1000
link/ether d6:8f:8b:3c:4c:d5 brd ff:ff:ff:ff:ff:ff
13: veth-br1@veth-ns1: <BROADCAST,MULTICAST,M-DOWN> mtu 1500 qdisc noop state DOWN mode DEFAULT group default qlen 1000
link/ether 12:cb:1d:96:4b:5c brd ff:ff:ff:ff:ff:ff
```

成对创建 `veth-ns1@veth-br1`和`veth-br1@veth-ns1`，有两个mac地址说明是两块独立的虚拟网卡。删除一块，另一块自动删除。

```systemverilog
ip link set veth-br1 up
```

把 `veth-br1`接到 `br0`

```systemverilog
ip link set veth-br1 master br0
```

#### 创建namespace
```systemverilog
ip netns add ns1
```

```systemverilog
ip netns list
```

```systemverilog
ip netns exec ns1 ip link
```

Loopback（回环网卡）

把 veth-ns1 从 Host Namespace 移动到 ns1

```systemverilog
ip link set veth-ns1 netns ns1
```

移动到ns1后给veth-ns1换个名字

```systemverilog
ip netns exec ns1 ip link set veth-ns1 name eth0
```

启动

```systemverilog
ip netns exec ns1 ip link set eth0 up
```

#### 分配IP
```systemverilog
ip addr add 10.0.0.1/24 dev br0
```

```systemverilog
ip netns exec ns1 ip addr add 10.0.0.2/24 dev eth0
```

```systemverilog
ip netns exec ns1 ping -c 3 10.0.0.1
```

第一次 Ping 的过程：

第一步：发送 ARP Request。而不是直接发送ICMP。因为系统不知道 10.0.0.1 的 MAC。

```systemverilog
Who has 10.0.0.1 ?
Tell 10.0.0.2
```

Bridge收到广播，由于不知道MAC，于是Flood，然后 Host回复：

```systemverilog
I am 10.0.0.1
MAC xx:xx:xx
```

Namespace缓存ARP。

第二步，发送 ICMP Echo Request。

验证ARP

```systemverilog
ip netns exec ns1 ip neigh
```

查看HOST的ARP

```systemverilog
ip neigh
```

#### 创建第二个namespace
```systemverilog
ip netns add ns2
```

创建veth对

```systemverilog
ip link add veth-br2 type veth peer name veth-ns2
```

启动 veth-br2并接入br0

```systemverilog
ip link set veth-br2 master br0
ip link set veth-br2 up
```

移动veth-ns2到ns2，改名成eth0并启动

```systemverilog
ip link set veth-ns2 netns ns2
ip netns exec ns2 ip link set veth-ns2 name eth0
ip netns exec ns2 ip link set eth0 up
```

配置ip

```systemverilog
ip netns exec ns2 ip addr add 10.0.0.3/24 dev eth0
```

## 网络设备：
| 设备 | OSI 层级 | 转发依据 |
| --- | --- | --- |
| **Hub（集线器）** | **第一层：物理层（Physical Layer）** | 电信号 |
| **Bridge（网桥）** | **第二层：数据链路层（Data Link Layer）** | MAC 地址 |
| **Switch（交换机）** | **第二层（现代部分支持第三层）** | MAC 地址（L2）/ IP 地址（L3） |
| **Router（路由器）** | **第三层：网络层（Network Layer）** | IP 地址 |




二层设备和三层设备的区别

| 设备 | 保存 MAC Table | 保存 ARP Cache |
| --- | --- | --- |
| **PC（普通主机）** | ❌ | ✅ |
| **二层交换机（L2 Switch）** | ✅ | ❌（通常没有） |
| **三层交换机（L3 Switch）** | ✅ | ✅ |
| **路由器（Router）** | ❌（一般不维护二层交换MAC学习表） | ✅ |


| 表 | 是否有 | 谁维护 |
| --- | --- | --- |
| **MAC Table（FDB）** | ✅ | 内部交换机 |
| **ARP Cache** | ✅ | 路由器（Linux 内核） |
| **Routing Table** | ✅ | 路由器 |
| **NAT Table（Conntrack）** | ✅ | 路由器 |


FDB = Forwarding Database（转发表）

