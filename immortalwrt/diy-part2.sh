#!/bin/bash

# 1. 修改默认登录 IP 为 192.168.1.1
sed -i 's/192.168.1.1/192.168.1.1/g' package/base-files/files/bin/config_generate

# 2. 修改默认主机名为 Bugwrt
# 把默认的 ImmortalWrt 替换成你想要的 Bugwrt
sed -i "s/ImmortalWrt/Bugwrt/g" package/base-files/files/bin/config_generate

# 3. 注入极致 TCP 调优参数 (针对 i9 + 16G 内存 + 10ms-18ms 极速环境)
cat >> package/base-files/files/etc/sysctl.conf <<EOF

# 开启 BBR 拥塞控制和 FQ 调度
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr

# 暴力 64MB 缓冲区：支持单线程万兆爆发，不再受延迟限制
net.core.rmem_max=67108864
net.core.wmem_max=67108864
net.ipv4.tcp_rmem=4096 4194304 67108864
net.ipv4.tcp_wmem=4096 4194304 67108864

# TCP 内存管理优化 (适配 16GB 物理内存)
net.ipv4.tcp_mem=786432 1048576 2097152
net.ipv4.tcp_moderate_rcvbuf=1

# 提高连接追踪上限与内核队列长度
net.netfilter.nf_conntrack_max=1048576
net.core.netdev_max_backlog=65536
net.core.somaxconn=16384

# 跨洋 VPS 长连接、MTU 探测与 TCP 快速打开 (TFO)
net.ipv4.tcp_keepalive_time=600
net.ipv4.tcp_mtu_probing=1
net.ipv4.tcp_fastopen=3
net.ipv4.tcp_tw_reuse=1
EOF

# 4. 增大 X550 网卡发送队列长度 (防止高带宽瞬时断流)
# 针对 eth0 和 eth1 进行加固
sed -i '/exit 0/i ip link set dev eth0 txqueuelen 10000' package/base-files/files/etc/rc.local
sed -i '/exit 0/i ip link set dev eth1 txqueuelen 10000' package/base-files/files/etc/rc.local
# 设置 TTYd 免密登录（可选，为了方便）
sed -i 's/\/bin\/login/\/bin\/login -f root/g' feeds/luci/applications/luci-app-ttyd/root/etc/config/ttyd
