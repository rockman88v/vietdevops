#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 <new_hostname>"
  exit 1
fi

NEW_HOSTNAME=$1

# Cập nhật hostname tạm thời
sudo hostnamectl set-hostname "$NEW_HOSTNAME"

# Cập nhật hostname trong file /etc/hostname
echo "$NEW_HOSTNAME" | sudo tee /etc/hostname > /dev/null

# Cập nhật hostname trong file /etc/hosts
sudo sed -i "s/127.0.1.1.*/127.0.1.1\t$NEW_HOSTNAME/g" /etc/hosts

echo "Hostname updated to: $NEW_HOSTNAME"

