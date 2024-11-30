#!/bin/bash

# Check if a new IP address is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <new_ip_address>"
  exit 1
fi

NEW_IP=$1
NETPLAN_CONFIG="/etc/netplan/50-cloud-init.yaml"

# Check if the netplan configuration file exists
if [ ! -f "$NETPLAN_CONFIG" ]; then
  echo "Error: Netplan configuration file not found at $NETPLAN_CONFIG"
  exit 1
fi

# Update the IP address in the configuration file
#sudo sed -i "s/192.168.10.15/$NEW_IP/g" "$NETPLAN_CONFIG"
sudo sed -i "s|192\.168\.10\.[0-9]\+/24|$NEW_IP/24|g" "$NETPLAN_CONFIG"

# Apply the changes
echo "Applying network configuration changes..."
sudo netplan apply

echo "Network configuration updated successfully with IP: $NEW_IP"

