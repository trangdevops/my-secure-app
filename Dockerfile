# Sử dụng Nginx bản Alpine (Rất nhẹ và ít lỗ hổng hệ điều hành)
FROM nginx:alpine

# Copy file code của chúng ta vào thư mục web mặc định của Nginx
COPY index.html /usr/share/nginx/html/index.html

# Mở port 80 cho ứng dụng
EXPOSE 80
