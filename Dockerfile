# Sử dụng phiên bản Nginx unprivileged chính thức từ NGINX Inc.
FROM nginxinc/nginx-unprivileged:alpine

# Copy mã nguồn vào thư mục web
COPY index.html /usr/share/nginx/html/index.html

# Mở port 8080 thay vì 80 (vì Linux không cho phép user thường mở port dưới 1024)
EXPOSE 8080
