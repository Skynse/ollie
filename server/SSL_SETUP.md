# SSL/TLS Setup for Ollie WebSocket Server

This guide explains how to configure SSL/TLS certificates to enable secure WebSocket connections (WSS) for production deployment.

## Quick Overview

The server automatically detects SSL certificates and switches between HTTP/WS (development) and HTTPS/WSS (production) modes based on environment variables.

## Prerequisites

- A domain name pointing to your server
- SSH access to your production server
- Root or sudo privileges

## Option 1: Using Let's Encrypt (Recommended for Production)

### Step 1: Install Certbot

On Ubuntu/Debian:
```bash
sudo apt update
sudo apt install certbot
```

On CentOS/RHEL:
```bash
sudo yum install certbot
```

### Step 2: Generate SSL Certificates

Stop any service using port 80, then run:
```bash
sudo certbot certonly --standalone -d your-domain.com
```

This will create certificates at:
- Certificate: `/etc/letsencrypt/live/your-domain.com/fullchain.pem`
- Private Key: `/etc/letsencrypt/live/your-domain.com/privkey.pem`

### Step 3: Configure Docker Compose

Edit `docker-compose.yml` and uncomment the SSL configuration:

```yaml
environment:
  - NODE_ENV=production
  - PORT=3000
  - SSL_CERT_PATH=/etc/ssl/certs/fullchain.pem
  - SSL_KEY_PATH=/etc/ssl/certs/privkey.pem

volumes:
  - /etc/letsencrypt/live/your-domain.com/fullchain.pem:/etc/ssl/certs/fullchain.pem:ro
  - /etc/letsencrypt/live/your-domain.com/privkey.pem:/etc/ssl/certs/privkey.pem:ro
```

Replace `your-domain.com` with your actual domain name.

### Step 4: Deploy

```bash
docker-compose down
docker-compose up -d --build
```

Check the logs to verify SSL is enabled:
```bash
docker-compose logs -f
```

You should see: `Running in HTTPS/WSS mode`

### Step 5: Auto-Renewal Setup

Let's Encrypt certificates expire after 90 days. Set up auto-renewal:

```bash
sudo crontab -e
```

Add this line:
```
0 3 * * * certbot renew --quiet && docker-compose -f /path/to/docker-compose.yml restart
```

## Option 2: Using Self-Signed Certificates (Development/Testing Only)

**Warning**: Self-signed certificates will show security warnings in browsers and may not work with mobile apps.

### Generate Self-Signed Certificate

```bash
mkdir -p ./certs
openssl req -x509 -newkey rsa:4096 -keyout ./certs/privkey.pem -out ./certs/fullchain.pem -days 365 -nodes
```

### Configure Docker Compose

Edit `docker-compose.yml`:

```yaml
environment:
  - NODE_ENV=production
  - PORT=3000
  - SSL_CERT_PATH=/etc/ssl/certs/fullchain.pem
  - SSL_KEY_PATH=/etc/ssl/certs/privkey.pem

volumes:
  - ./certs/fullchain.pem:/etc/ssl/certs/fullchain.pem:ro
  - ./certs/privkey.pem:/etc/ssl/certs/privkey.pem:ro
```

## Option 3: Using a Reverse Proxy (Alternative Approach)

Instead of handling SSL in Node.js, you can use a reverse proxy like Nginx or Caddy.

### Using Nginx

1. Install Nginx:
```bash
sudo apt install nginx
```

2. Configure Nginx (`/etc/nginx/sites-available/ollie-ws`):
```nginx
server {
    listen 443 ssl;
    server_name your-domain.com;

    ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

3. Enable the site:
```bash
sudo ln -s /etc/nginx/sites-available/ollie-ws /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

4. Run Docker without SSL (Nginx handles it):
```bash
docker-compose up -d
```

### Using Caddy (Easiest - Auto SSL)

1. Create `Caddyfile`:
```
your-domain.com {
    reverse_proxy localhost:3000 {
        header_up Upgrade {http.request.header.Upgrade}
        header_up Connection {http.request.header.Connection}
    }
}
```

2. Run Caddy:
```bash
caddy run
```

Caddy automatically obtains and renews SSL certificates!

## Verification

### Test SSL Certificate
```bash
openssl s_client -connect your-domain.com:3000 -showcerts
```

### Test WebSocket Connection
```bash
# Install wscat if not already installed
npm install -g wscat

# Connect to secure WebSocket
wscat -c wss://your-domain.com:3000
```

### Health Check
```bash
curl https://your-domain.com:3000/health
```

Expected response:
```json
{
  "status": "ok",
  "uptime": 123.456,
  "activeBoards": 0,
  "totalConnections": 0
}
```

## Troubleshooting

### "Failed to load SSL certificates" error
- Check file paths in environment variables
- Verify certificates exist: `ls -la /etc/letsencrypt/live/your-domain.com/`
- Ensure Docker has read permissions
- Check logs: `docker-compose logs`

### Connection refused
- Verify port 3000 is open: `sudo ufw allow 3000`
- Check if server is listening: `netstat -tulpn | grep 3000`
- Review firewall rules

### Certificate expired
- Renew manually: `sudo certbot renew`
- Restart container: `docker-compose restart`

### Client shows "insecure connection"
- Verify client is using `wss://` not `ws://`
- Check certificate is valid for your domain
- Ensure certificate chain is complete (use fullchain.pem, not cert.pem)

## Production Checklist

- [ ] Domain name configured and pointing to server
- [ ] SSL certificates obtained from Let's Encrypt
- [ ] Docker Compose configured with correct certificate paths
- [ ] Auto-renewal cron job set up
- [ ] Firewall allows port 3000 (or 443 if using reverse proxy)
- [ ] Client app updated to use `wss://` URL
- [ ] Health check endpoint accessible
- [ ] WebSocket connection tested with wscat
- [ ] Monitoring/alerting configured for certificate expiry

## Security Best Practices

1. **Use Let's Encrypt** for free, trusted certificates
2. **Enable auto-renewal** to prevent expiry
3. **Keep certificates private** - never commit to git
4. **Use strong cipher suites** (modern TLS 1.2+)
5. **Regular updates** - keep Node.js and dependencies updated
6. **Monitor certificate expiry** - set up alerts 30 days before expiry
7. **Use reverse proxy** for additional security and features

## Environment Variables Reference

| Variable | Required | Description | Example |
|----------|----------|-------------|---------|
| `PORT` | No | Server port | `3000` |
| `NODE_ENV` | No | Environment | `production` |
| `SSL_CERT_PATH` | For SSL | Path to certificate | `/etc/ssl/certs/fullchain.pem` |
| `SSL_KEY_PATH` | For SSL | Path to private key | `/etc/ssl/certs/privkey.pem` |

## Additional Resources

- [Let's Encrypt Documentation](https://letsencrypt.org/docs/)
- [Certbot Instructions](https://certbot.eff.org/)
- [WebSocket Security Best Practices](https://developer.mozilla.org/en-US/docs/Web/API/WebSockets_API)
- [Node.js HTTPS Documentation](https://nodejs.org/api/https.html)
