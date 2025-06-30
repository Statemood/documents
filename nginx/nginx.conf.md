# Nginx Configuration 



配置文件 *nginx.conf*

```
user nobody;
worker_processes 4;
worker_rlimit_nofile 65535;
events {
    use epoll;
    worker_connections 65535;
}
http {
    include mime.types;
    default_type application/octet-stream;
    log_format default '$remote_addr $remote_port $remote_user $time_iso8601 $status $body_bytes_sent '
                       '"$request" "$http_referer" "$http_user_agent" "$http_x_forwarded_for"';

    fastcgi_connect_timeout 300;
    fastcgi_send_timeout 300;
    fastcgi_read_timeout 300;
    fastcgi_buffer_size 64k;
    fastcgi_buffers 8 32k;
    fastcgi_busy_buffers_size 128k;
    fastcgi_temp_file_write_size 128k;
    sendfile on;
    keepalive_timeout 65;
    gzip on;
    gzip_min_length 1k;
    gzip_buffers 4 16k;
    gzip_http_version 1.0;
    gzip_comp_level 2;
    gzip_types text/plain application/x-javascript text/css application/xml text/vnd.wap.wml;
    gzip_vary on;
    open_file_cache max=32768 inactive=20s;
    open_file_cache_min_uses 1;
    open_file_cache_valid 30s;
    proxy_ignore_client_abort on;
    client_max_body_size 1G;
    client_body_buffer_size 256k;
    proxy_connect_timeout 30;
    proxy_send_timeout 30;
    proxy_read_timeout 60;
    proxy_buffer_size 256k;
    proxy_buffers 4 256k;
    proxy_busy_buffers_size 256k;
    proxy_temp_file_write_size 256k;
    proxy_http_version 1.1;

    include conf.d/*.conf;
}

include conf.d/L4-Proxy/*.conf;
```