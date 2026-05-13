#!/bin/bash

systemctl is-active --quiet haproxy

if [ $? -eq 0 ]; then
  exit 0
else
  exit 1
fi