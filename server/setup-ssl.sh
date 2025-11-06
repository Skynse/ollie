#!/bin/bash

# Ollie WebSocket Server - SSL Setup Script
# This script helps set up Let's Encrypt SSL certificates for production

set -e

echo "==================================="
echo "Ollie WebSocket SSL Setup Script"
echo "==================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Please run as root (use: sudo bash setup-ssl.sh)"
    exit 1
fi

# Get domain name
read -p "Enter your domain name (e.g., ws.ollie.com): " DOMAIN

if [ -z "$DOMAIN" ]; then
    echo "❌ Domain name is required"
    exit 1
fi

echo ""
echo "📋 Domain: $DOMAIN"
echo ""

# Verify domain points to this server
echo "🔍 Verifying domain points to this server..."
SERVER_IP=$(curl -s ifconfig.me)
DOMAIN_IP=$(dig +short $DOMAIN | tail -n1)

echo "   Server IP: $SERVER_IP"
echo "   Domain IP: $DOMAIN_IP"

if [ "$SERVER_IP" != "$DOMAIN_IP" ]; then
    echo ""
    echo "⚠️  WARNING: Domain does not point to this server!"
    echo "   Please update your DNS A record to point to: $SERVER_IP"
    read -p "   Continue anyway? (y/N): " CONTINUE
    if [[ ! $CONTINUE =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo ""
echo "📦 Installing Certbot..."
if command -v apt-get &> /dev/null; then
    # Ubuntu/Debian
    apt-get update
    apt-get install -y certbot
elif command -v yum &> /dev/null; then
    # CentOS/RHEL
    yum install -y certbot
else
    echo "❌ Unsupported OS. Please install certbot manually."
    exit 1
fi

echo ""
echo "🔐 Obtaining SSL certificate..."
echo "   This will use port 80 temporarily. Make sure it's not in use."
echo ""

# Stop any service using port 80
if lsof -Pi :80 -sTCP:LISTEN -t >/dev/null ; then
    echo "⚠️  Port 80 is in use. Attempting to stop services..."
    systemctl stop nginx 2>/dev/null || true
    systemctl stop apache2 2>/dev/null || true
fi

# Get certificate
certbot certonly --standalone -d $DOMAIN --non-interactive --agree-tos --register-unsafely-without-email

if [ $? -ne 0 ]; then
    echo "❌ Failed to obtain SSL certificate"
    exit 1
fi

echo ""
echo "✅ SSL certificate obtained successfully!"
echo ""
echo "📝 Certificate locations:"
echo "   Certificate: /etc/letsencrypt/live/$DOMAIN/fullchain.pem"
echo "   Private Key: /etc/letsencrypt/live/$DOMAIN/privkey.pem"
echo ""

# Configure docker-compose.yml
echo "📝 Updating docker-compose.yml..."
cd "$(dirname "$0")"

if [ ! -f "docker-compose.yml" ]; then
    echo "❌ docker-compose.yml not found"
    exit 1
fi

# Backup original
cp docker-compose.yml docker-compose.yml.backup

# Update docker-compose.yml with SSL configuration
cat > docker-compose.yml << EOF
version: '3.8'

services:
  ollie-realtime:
    build: .
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - PORT=3000
      - SSL_CERT_PATH=/etc/ssl/certs/fullchain.pem
      - SSL_KEY_PATH=/etc/ssl/certs/privkey.pem
    volumes:
      - /etc/letsencrypt/live/$DOMAIN/fullchain.pem:/etc/ssl/certs/fullchain.pem:ro
      - /etc/letsencrypt/live/$DOMAIN/privkey.pem:/etc/ssl/certs/privkey.pem:ro
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "--no-check-certificate", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
EOF

echo "✅ docker-compose.yml updated"
echo ""

# Set up auto-renewal
echo "📅 Setting up automatic certificate renewal..."

# Create renewal script
cat > /usr/local/bin/renew-ollie-certs.sh << EOF
#!/bin/bash
certbot renew --quiet
if [ \$? -eq 0 ]; then
    cd $(pwd)
    docker-compose restart
    echo "[\$(date)] Ollie SSL certificates renewed and service restarted" >> /var/log/ollie-cert-renewal.log
fi
EOF

chmod +x /usr/local/bin/renew-ollie-certs.sh

# Add to crontab (runs daily at 3 AM)
(crontab -l 2>/dev/null | grep -v "renew-ollie-certs"; echo "0 3 * * * /usr/local/bin/renew-ollie-certs.sh") | crontab -

echo "✅ Auto-renewal configured (daily check at 3 AM)"
echo ""

# Open firewall port if needed
echo "🔥 Checking firewall..."
if command -v ufw &> /dev/null; then
    ufw allow 3000/tcp
    echo "✅ Firewall rule added (port 3000)"
elif command -v firewall-cmd &> /dev/null; then
    firewall-cmd --permanent --add-port=3000/tcp
    firewall-cmd --reload
    echo "✅ Firewall rule added (port 3000)"
else
    echo "⚠️  No firewall detected. Make sure port 3000 is open."
fi

echo ""
echo "🚀 Deploying with SSL..."

# Check if docker-compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "❌ docker-compose not found. Please install it first."
    exit 1
fi

# Deploy
docker compose down
docker compose up -d --build

echo ""
echo "⏳ Waiting for service to start..."
sleep 10

# Check logs
echo ""
echo "📋 Service logs (checking for SSL mode):"
docker compose logs | tail -20

echo ""
echo "================================"
echo "✅ SSL Setup Complete!"
echo "================================"
echo ""
echo "Your WebSocket server should now be running with SSL/TLS enabled."
echo ""
echo "🔍 Verify with:"
echo "   curl https://$DOMAIN:3000/health"
echo "   wscat -c wss://$DOMAIN:3000"
echo ""
echo "📱 Update your Flutter app to use:"
echo "   static const String serverUrl = 'wss://$DOMAIN:3000';"
echo ""
echo "📁 Backup saved: docker-compose.yml.backup"
echo "📝 Renewal log: /var/log/ollie-cert-renewal.log"
echo ""
