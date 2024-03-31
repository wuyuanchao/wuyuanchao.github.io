---
title: "Bind9"
weight: 1
# bookFlatSection: false
# bookToc: true
# bookHidden: false
# bookCollapseSection: false
# bookComments: false
# bookSearchExclude: false
---

#### 一. DNS和BIND的基础概念
##### 1.DNS
DNS是一个层级的、分布式的数据库，存储网络主机名和IP地址的相互映射等信息。
> The Domain Name System (DNS) is a hierarchical, distributed database. It stores information for mapping Internet host names to IP addresses and vice versa, mail routing information, and other data used by Internet applications.

The Internet Domain Name System (DNS) 由以下三部分组成：
- the syntax to specify the names of entities in the Internet in a hierarchical manner.（以分层方式指定 Internet 中实体名称的语法。）
-  the rules used for delegating authority over names.（用于委派名称权限的规则。）
- the system implementation that actually maps names to Internet addresses.（实际将名称映射到Internet地址的系统实现）

术语：
- Domains and Domain Names（域和域名）：
domain names are organized as a tree according to organizational or administrative boundaries.Each node of the tree, called a domain, is given a label.The domain name of the node is the concatenation of all the labels on the path from the node to the root node.

- zones:
the name space is partitioned into areas called zones.


Start of Authority (SOA)

递归查询与迭代查询 recursion no和 allow-recursion

2. Bind9配置入门in k8s

#### bind9的镜像
https://hub.docker.com/r/ubuntu/bind9

#### bind9安装与配置
```
---
apiVersion: v1
kind: Service
metadata:
  name: bind9-service
  labels:
    app: bind9
spec:
  selector:
    app: bind9
  ports:
  - port: 53
    protocol: UDP
    name: udp
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: bind9-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: bind9
  template:
    metadata:
      labels:
        app: bind9
    spec:
      volumes:
        - name: config-ref
          configMap:
            name: bind9-conf
            items:
              - key: "db.wuyc.com"
                path: db.wuyc.com
              - key: "named.conf.options"
                path: named.conf.options
              - key: "named.conf.local"
                path: named.conf.local
      containers:
      - name: bind9
        image: ubuntu/bind9:edge
        env:
        - name: TZ
          value: Asia/Shanghai
        volumeMounts:
          - name: config-ref
            mountPath: "/etc/bind/db.wuyc.com"
            subPath: "db.wuyc.com"
            readOnly: true
          - name: config-ref
            mountPath: "/etc/bind/named.conf.options"
            subPath: "named.conf.options"
            readOnly: true
          - name: config-ref
            mountPath: "/etc/bind/named.conf.local"
            subPath: "named.conf.local"
            readOnly: true
        ports:
        - containerPort: 53
          name: bind9
          protocol: UDP
---
apiVersion: v1
kind: ConfigMap
metadata:
  labels:
    cattle.io/creator: norman
  name: bind9-conf
  namespace: default
data:
  db.wuyc.com: |-
    $TTL    604800
    @   IN  SOA ns.wuyc.com. root.wuyc.com. (
                      3     ; Serial
                 604800     ; Refresh
                  86400     ; Retry
                2419200     ; Expire
                 604800 )   ; Negative Cache TTL
        IN  NS  ns.wuyc.com.
    test    IN  A   10.244.8.37
    *    IN  A   172.31.0.108
  named.conf.local: |-
    //
    // Do any local configuration here
    //

    // Consider adding the 1918 zones here, if they are not used in your
    // organization
    //include "/etc/bind/zones.rfc1918";

    zone "wuyc.com" {
            type master;
            file "/etc/bind/db.wuyc.com";
            };
  named.conf.options: |-
    options {
      directory "/var/cache/bind";
      allow-query { any; };
      allow-recursion { any; };
      dnssec-enable no;
      dnssec-validation no;
      recursion yes; #是否允许递归查询
      forward first;
      forwarders {
        172.31.0.5;
      };
    };    
```

#### 注意事项
因为查询dns是通过udp进行通讯的，所以service需要配置protocol为UDP。
