#!/bin/bash
# Setup script for deploying BoofMebel to server
# Usage: ./deploy/setup.sh <site_name> <domain>

set -e

SITE_NAME=${1:-boofmebel}
DOMAIN=${2:-boofmebel.example.com}
APP_DIR="/var/www/${SITE_NAME}"
SERVICE_NAME="${SITE_NAME}"

echo "🚀 Setting up ${SITE_NAME} at ${DOMAIN}"

# Create app directory
sudo mkdir -p ${APP_DIR}
sudo chown -R $USER:$USER ${APP_DIR}

# Clone repository (if not exists)
if [ ! -d "${APP_DIR}/.git" ]; then
    echo "📦 Cloning repository..."
    git clone <YOUR_GITHUB_REPO_URL> ${APP_DIR}
fi

cd ${APP_DIR}

# Create virtual environment
if [ ! -d "venv" ]; then
    echo "🐍 Creating virtual environment..."
    python3 -m venv venv
fi

source venv/bin/activate

# Install dependencies
echo "📥 Installing dependencies..."
pip install --upgrade pip
pip install -r requirements.txt

# Create .env file if not exists
if [ ! -f ".env" ]; then
    echo "⚙️  Creating .env file..."
    cat > .env << EOF
DATABASE_URL=postgresql+asyncpg://user:password@localhost:5432/${SITE_NAME}
CORS_ORIGINS=https://${DOMAIN},http://localhost:3000
SENTRY_DSN=
SECRET_KEY=$(openssl rand -hex 32)
EOF
    echo "✅ .env created. Please edit it with your actual values!"
fi

# Run migrations
echo "🗄️  Running migrations..."
alembic upgrade head

# Create systemd service
echo "🔧 Creating systemd service..."
sudo tee /etc/systemd/system/${SERVICE_NAME}.service > /dev/null << EOF
[Unit]
Description=BoofMebel API - ${SITE_NAME}
After=network.target postgresql.service

[Service]
Type=notify
User=${USER}
Group=${USER}
WorkingDirectory=${APP_DIR}
Environment="PATH=${APP_DIR}/venv/bin"
ExecStart=${APP_DIR}/venv/bin/gunicorn app.main:app \
    --workers 4 \
    --worker-class uvicorn.workers.UvicornWorker \
    --bind 127.0.0.1:8000 \
    --timeout 120 \
    --access-logfile ${APP_DIR}/logs/access.log \
    --error-logfile ${APP_DIR}/logs/error.log
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Create logs directory
mkdir -p ${APP_DIR}/logs

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable ${SERVICE_NAME}.service
sudo systemctl start ${SERVICE_NAME}.service

echo "✅ Service ${SERVICE_NAME} created and started!"

# Create Nginx config
echo "🌐 Creating Nginx configuration..."
sudo tee /etc/nginx/sites-available/${SITE_NAME} > /dev/null << EOF
# Upstream for ${SITE_NAME}
upstream ${SITE_NAME}_backend {
    server 127.0.0.1:8000;
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

    # CSP (adjust as needed)
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' data:;" always;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/json application/javascript application/xml+rss;

    # Brotli compression (if available)
    # brotli on;
    # brotli_types text/plain text/css text/xml text/javascript application/json application/javascript;

    # Client body size limit
    client_max_body_size 10M;

    # Logs
    access_log /var/log/nginx/${SITE_NAME}_access.log;
    error_log /var/log/nginx/${SITE_NAME}_error.log;

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

    # Static files (if serving from Nginx)
    location /static/ {
        alias ${APP_DIR}/static/;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
}
EOF

# Enable site
sudo ln -sf /etc/nginx/sites-available/${SITE_NAME} /etc/nginx/sites-enabled/${SITE_NAME}

# Test Nginx config
sudo nginx -t

echo "✅ Nginx configuration created!"
echo ""
echo "📋 Next steps:"
echo "1. Install SSL certificate: sudo certbot --nginx -d ${DOMAIN}"
echo "2. Reload Nginx: sudo systemctl reload nginx"
echo "3. Check service status: sudo systemctl status ${SERVICE_NAME}"
echo "4. Check logs: sudo journalctl -u ${SERVICE_NAME} -f"

