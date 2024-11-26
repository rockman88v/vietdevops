#!/bin/bash

# Thay thế APP_NAME bằng biến môi trường
sed -i "s/APP_NAME/${APPNAME}/g" /usr/share/nginx/html/index.html

# Khởi động NGINX
nginx -g "daemon off;"
