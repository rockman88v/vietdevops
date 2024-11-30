#!/bin/bash

# Disable all swap
sudo swapoff -a

# Remove any swap entry from /etc/fstab
sudo sed -i '/\sswap\s/d' /etc/fstab

echo "Swap has been disabled permanently."

