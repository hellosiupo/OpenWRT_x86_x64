#!/bin/bash

# 1. 身份与固件命名 (Bugwrt-Siu)
sed -i 's/192.168.1.1/192.168.1.1/g' package/base-files/files/bin/config_generate
sed -i "s/ImmortalWrt/Bugwrt/g" package/base-files/files/bin/config_generate
# 修改输出固件文件名为 Bugwrt-Siu
sed -i 's/IMG_PREFIX:=$(VERSION_DIST_SANITIZED)/IMG_PREFIX:=Bugwrt-Siu/g' include/image.mk

# 2. 修改默认主题为 Design
sed -i 's/luci-theme-bootstrap/luci-theme-design/g' feeds/luci/collections/luci/Makefile

# 3. 预设 WAN 口为 PPPoE 协议并优化 MTU (安全版：不含账号密码)
sed -i "s/option proto 'dhcp'/option proto 'pppoe'/g" package/base-files/files/bin/config_generate
sed -i "/set network.wan.proto=pppoe/a \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ set network.wan.mtu='1492'" package/base-files/files/bin/config_generate

# 4. 注入极致 TCP 调优参数 (针对 i9 + 16G 内存 + 10ms-18ms 环境)
cat >> package/base-files/files/etc/sysctl.conf <<EOF

# 开启 BBR 拥塞控制和 FQ 调度
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr

# 暴力 64MB 缓冲区：支持单线程万兆爆发
net.core.rmem_max=67108864
net.core.wmem_max=67108864
net.ipv4.tcp_rmem=4096 4194304 67108864
net.ipv4.tcp_wmem=4096 4194304 67108864

# TCP 内存管理优化
net.ipv4.tcp_mem=786432 1048576 2097152
net.ipv4.tcp_moderate_rcvbuf=1

# 提高连接追踪上限与内核队列长度
net.netfilter.nf_conntrack_max=1048576
net.core.netdev_max_backlog=65536
net.core.somaxconn=16384

# 跨洋 VPS 长连接、MTU 探测与 TCP 快速打开
net.ipv4.tcp_keepalive_time=600
net.ipv4.tcp_mtu_probing=1
net.ipv4.tcp_fastopen=3
net.ipv4.tcp_tw_reuse=1
EOF

# 5. 增大 X550 网卡发送队列长度 (防止高带宽瞬时断流)
sed -i '/exit 0/i ip link set dev eth0 txqueuelen 10000' package/base-files/files/etc/rc.local
sed -i '/exit 0/i ip link set dev eth1 txqueuelen 10000' package/base-files/files/etc/rc.local

# 只有在文件存在时才执行修改，防止报错中断编译
if [ -f "feeds/luci/applications/luci-app-ttyd/root/etc/config/ttyd" ]; then
    sed -i 's/login/0/g' feeds/luci/applications/luci-app-ttyd/root/etc/config/ttyd
fi
