#!/bin/bash
set -euo pipefail
## NOTE: Run in all nodes
export DEBIAN_FRONTEND=noninteractive

# Kubernetes master nodes
MASTERS=(
  "master1 192.168.10.51"
  "master2 192.168.10.52"
  "master3 192.168.10.53"
)
HAPROXY_CFG="/etc/haproxy/haproxy.cfg"

# ==========================================
# Install and setup Rsyslog
# ==========================================
RSYSLOG_CONF="/etc/rsyslog.conf"
HAPROXY_RSYSLOG_CONF="/etc/rsyslog.d/49-haproxy.conf"

echo "===== install rsyslog ====="

sudo apt-get update
sudo apt-get install -y -o Dpkg::Options::="--force-confold" rsyslog

echo "===== configure rsyslog for haproxy ====="
# Create haproxy logging config
cat <<EOF | sudo tee "$HAPROXY_RSYSLOG_CONF" > /dev/null
# HAProxy logs
local0.*    /var/log/haproxy.log

# Stop processing after writing
& stop
EOF

echo "===== validate rsyslog config ====="
sudo rsyslogd -N1

echo "===== restart rsyslog ====="
sudo systemctl enable rsyslog
sudo systemctl restart rsyslog
echo "===== rsyslog configured successfully ====="


# Install HAProxy
sudo apt-get update -y
sudo apt-get install -y haproxy

# Config HAProxy
# Generate backend servers
BACKEND_SERVERS=""

for master in "${MASTERS[@]}"; do
  read -r HOSTNAME IP <<< "$master"

  BACKEND_SERVERS+="    server ${HOSTNAME} ${IP}:6443 check"$'\n'
done

# Generate haproxy config
cat <<EOF | sudo tee "$HAPROXY_CFG" > /dev/null
global
    log /dev/log local0
    log /dev/log local1 notice
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin
    stats timeout 30s
    user haproxy
    group haproxy
    daemon

defaults
    log     global
    mode    tcp
    option  tcplog
    timeout connect 5000
    timeout client  50000
    timeout server  50000

frontend kubernetes-api
    bind *:6443
    mode tcp
    option tcplog
    default_backend kubernetes-api

backend kubernetes-api
    mode tcp
    balance roundrobin
    option tcp-check
    tcp-check connect port 6443

${BACKEND_SERVERS}
EOF

sudo systemctl enable haproxy
sudo systemctl restart haproxy

echo "===== haproxy configured successfully ====="