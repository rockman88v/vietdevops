#!/bin/bash

set -e
echo "===== Install packages ====="

apt update
apt install -y \
  openssh-server \
  curl \
  vim \
  net-tools \
  git \
  wget
echo "===== Done ====="