#!/bin/bash

# Check and install policycoreutils if getenforce or setenforce is missing
if ! command -v getenforce &> /dev/null || ! command -v setenforce &> /dev/null; then
  echo "Installing policycoreutils to manage SELinux..."
  sudo yum install -y policycoreutils || sudo apt-get install -y policycoreutils
fi

# Check and disable SELinux
echo "Checking SELinux status..."
SELINUX_STATUS=$(getenforce)
if [ "$SELINUX_STATUS" != "Disabled" ]; then
  echo "SELinux is currently $SELINUX_STATUS. Disabling SELinux..."
  sudo setenforce 0
  sudo sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
  echo "SELinux has been disabled."
else
  echo "SELinux is already disabled."
fi

# Check and disable firewalld (if it exists)
if systemctl list-unit-files | grep -q "^firewalld.service"; then
  echo "Checking firewalld status..."
  FIREWALLD_STATUS=$(sudo systemctl is-active firewalld)
  if [ "$FIREWALLD_STATUS" = "active" ]; then
    echo "firewalld is active. Disabling firewalld..."
    sudo systemctl stop firewalld
    sudo systemctl disable firewalld
    echo "firewalld has been disabled."
  else
    echo "firewalld is already disabled."
  fi
else
  echo "firewalld service does not exist on this system."
fi

# Check and enable IPv4 IP forwarding
echo "Checking IPv4 IP forwarding status..."
IP_FORWARD_STATUS=$(sysctl net.ipv4.ip_forward | awk '{print $3}')
if [ "$IP_FORWARD_STATUS" = "0" ]; then
  echo "IPv4 IP forwarding is disabled. Enabling it..."
  sudo sysctl -w net.ipv4.ip_forward=1
  sudo sed -i 's/^net.ipv4.ip_forward=.*/net.ipv4.ip_forward=1/' /etc/sysctl.conf
  echo "IPv4 IP forwarding has been enabled."
else
  echo "IPv4 IP forwarding is already enabled."
fi

echo "All tasks completed."

