#!/bin/bash
# Генерация Nginx конфига для разных окружений

SITE_NAME=$1
DOMAIN=$2
ENV=$3
PORT=$4
ENV_SUFFIX=$5
NGINX_CONFIG=$6
APP_DIR=$7

if [ "$ENV" = "test" ]; then
    # Тестовое окружение - HTTP на порту 9000
    cat > /tmp/nginx_config_${NGINX_CONFIG} << EOF
# Upstream for ${SITE_NAME}${ENV_SUFFIX} (TEST)
upstream ${SITE_NAME}${ENV_SUFFIX}_backend {
    server 127.0.0.1:${PORT};
    keepalive 32;
}

# HTTP server for TEST environment (port 9000)
server {
    listen 9000;
    listen [::]:9000;
    server_name ${DOMAIN} _;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/json application/javascript;

    # Client body size limit
    client_max_body_size 10M;

    # Logs
    access_log /var/log/nginx/${NGINX_CONFIG}_access.log;
    error_log /var/log/nginx/${NGINX_CONFIG}_error.log;

    # Proxy settings
    location / {
        proxy_pass http://${SITE_NAME}${ENV_SUFFIX}_backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto http;
        proxy_set_header X-Forwarded-Host \$host;
        proxy_set_header X-Forwarded-Port 9000;
        proxy_cache_bypass \$http_upgrade;
        proxy_read_timeout 120s;
        proxy_connect_timeout 120s;
    }

    # Static files
    location /static/ {
        alias ${APP_DIR}/static/;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
}
EOF
else
    # Продакшн - HTTPS на порту 80/443
    cat > /tmp/nginx_config_${NGINX_CONFIG} << EOF
# Upstream for ${SITE_NAME} (PROD)
upstream ${SITE_NAME}_backend {
    server 127.0.0.1:${PORT};
    keepalive 32;
}

# HTTP server - redirect to HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name ${DOMAIN};

    # Let's Encrypt challenge
    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }

    location / {
        return 301 https://\$server_name\$request_uri;
    }
}

# HTTPS server
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name ${DOMAIN};

    # SSL certificates (Let's Encrypt)
    ssl_certificate /etc/letsencrypt/live/${DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${DOMAIN}/privkey.pem;
    ssl_trusted_certificate /etc/letsencrypt/live/${DOMAIN}/chain.pem;

    # SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    # CSP
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' data:;" always;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/json application/javascript application/xml+rss;

    # Client body size limit
    client_max_body_size 10M;

    # Logs
    access_log /var/log/nginx/${NGINX_CONFIG}_access.log;
    error_log /var/log/nginx/${NGINX_CONFIG}_error.log;

    # Proxy settings
    location / {
        proxy_pass http://${SITE_NAME}_backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host \$host;
        proxy_set_header X-Forwarded-Port \$server_port;
        proxy_cache_bypass \$http_upgrade;
        proxy_read_timeout 120s;
        proxy_connect_timeout 120s;
    }

    # Static files
    location /static/ {
        alias ${APP_DIR}/static/;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
}
EOF
fi

cat /tmp/nginx_config_${NGINX_CONFIG}

