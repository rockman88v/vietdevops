# Sử dụng nginx làm base image
FROM nginx:latest

# Copy file index.html vào image
COPY index.html /usr/share/nginx/html/index.html

# Tạo script entrypoint để thay thế biến môi trường trong file HTML
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Thiết lập entrypoint
ENTRYPOINT ["/entrypoint.sh"]
