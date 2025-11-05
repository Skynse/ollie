# Step-by-Step Guide: Deploy SSL for Ollie WebSocket Server

This guide will walk you through setting up SSL certificates on your Digital Ocean server (137.184.120.233) to enable secure WebSocket connections.

## Prerequisites Checklist

Before starting, make sure you have:

- [ ] SSH access to your Digital Ocean server (137.184.120.233)
- [ ] Root or sudo privileges
- [ ] A domain name (e.g., `ws.ollie.com` or `ollie-ws.yourdomain.com`)
- [ ] Domain's DNS A record pointing to 137.184.120.233
- [ ] Docker and Docker Compose installed on the server

## Part 1: Configure Your Domain (Do This First!)

### Option A: Use a Subdomain (Recommended)

1. Go to your domain registrar or DNS provider (e.g., Cloudflare, Namecheap, GoDaddy)
2. Add an A record:
   - **Type**: A
   - **Name**: `ws` (or `ollie-ws`, your choice)
   - **Value**: `137.184.120.233`
   - **TTL**: 300 (or automatic)

Example: If your domain is `myapp.com`, this creates `ws.myapp.com`

### Option B: Use the Root Domain

If you want to use your main domain (e.g., `myapp.com`):
- **Type**: A
- **Name**: `@` or leave blank
- **Value**: `137.184.120.233`

### Verify DNS Propagation

Wait 5-10 minutes, then test:
```bash
# On your local machine
nslookup ws.myapp.com
# Should return 137.184.120.233

# Or use online tools:
# https://dnschecker.org
```

---

## Part 2: Upload Files to Server

### Step 1: Push Your Changes to Git

On your local machine:
```bash
cd C:\Users\austi\projects\ollie
git add server/
git commit -m "Add SSL support to WebSocket server"
git push origin main
```

### Step 2: SSH into Your Server

```bash
ssh root@137.184.120.233
# Or if using a different user:
ssh youruser@137.184.120.233
```

### Step 3: Navigate to Your Server Directory

If the server code is already on the server:
```bash
cd /path/to/ollie/server
git pull origin main
```

If starting fresh:
```bash
cd /opt
git clone https://github.com/yourusername/ollie.git
cd ollie/server
```

---

## Part 3: Automated Setup (Easy Way)

### Run the Setup Script

```bash
# Make script executable
chmod +x setup-ssl.sh

# Run as root
sudo bash setup-ssl.sh
```

The script will:
1. Ask for your domain name
2. Verify DNS is configured
3. Install Certbot
4. Obtain SSL certificates
5. Update docker-compose.yml
6. Configure auto-renewal
7. Open firewall ports
8. Deploy the server

**That's it!** Skip to Part 5 if using the script.

---

## Part 4: Manual Setup (If You Prefer Step-by-Step)

### Step 1: Install Certbot

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install certbot -y
```

**CentOS/RHEL:**
```bash
sudo yum install certbot -y
```

### Step 2: Stop Any Service Using Port 80

Certbot needs port 80 temporarily:
```bash
# Check what's using port 80
sudo lsof -i :80

# If nginx is running:
sudo systemctl stop nginx

# If apache is running:
sudo systemctl stop apache2
```

### Step 3: Obtain SSL Certificate

Replace `ws.myapp.com` with your actual domain:
```bash
sudo certbot certonly --standalone -d ws.myapp.com
```

You'll be prompted for:
- Email address (for renewal notifications)
- Agree to Terms of Service (Y)

Certificates will be saved to:
```
/etc/letsencrypt/live/ws.myapp.com/fullchain.pem
/etc/letsencrypt/live/ws.myapp.com/privkey.pem
```

### Step 4: Update docker-compose.yml

Edit the file:
```bash
nano docker-compose.yml
```

Update to (replace `ws.myapp.com` with your domain):
```yaml
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
      - /etc/letsencrypt/live/ws.myapp.com/fullchain.pem:/etc/ssl/certs/fullchain.pem:ro
      - /etc/letsencrypt/live/ws.myapp.com/privkey.pem:/etc/ssl/certs/privkey.pem:ro
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "--no-check-certificate", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
```

Save and exit (Ctrl+X, Y, Enter)

### Step 5: Open Firewall Port

**UFW (Ubuntu):**
```bash
sudo ufw allow 3000/tcp
sudo ufw status
```

**Firewalld (CentOS):**
```bash
sudo firewall-cmd --permanent --add-port=3000/tcp
sudo firewall-cmd --reload
```

**Digital Ocean Firewall:**
If you have a Digital Ocean firewall configured:
1. Go to Digital Ocean dashboard → Networking → Firewalls
2. Add inbound rule: TCP, Port 3000, All IPv4/IPv6

### Step 6: Deploy the Server

```bash
# Stop existing container
docker-compose down

# Build and start with SSL
docker-compose up -d --build

# Check logs to verify SSL is enabled
docker-compose logs -f
```

Look for: `Running in HTTPS/WSS mode`

### Step 7: Set Up Auto-Renewal

Create renewal script:
```bash
sudo nano /usr/local/bin/renew-ollie-certs.sh
```

Add this content:
```bash
#!/bin/bash
certbot renew --quiet
if [ $? -eq 0 ]; then
    cd /path/to/ollie/server
    docker-compose restart
    echo "[$(date)] Ollie SSL certificates renewed" >> /var/log/ollie-cert-renewal.log
fi
```

Make it executable:
```bash
sudo chmod +x /usr/local/bin/renew-ollie-certs.sh
```

Add to crontab:
```bash
sudo crontab -e
```

Add this line (runs daily at 3 AM):
```
0 3 * * * /usr/local/bin/renew-ollie-certs.sh
```

---

## Part 5: Verify Everything Works

### Test 1: Health Check (HTTPS)

Replace `ws.myapp.com` with your domain:
```bash
curl https://ws.myapp.com:3000/health
```

Expected output:
```json
{
  "status": "ok",
  "uptime": 123.45,
  "activeBoards": 0,
  "totalConnections": 0
}
```

### Test 2: WebSocket Connection

Install wscat (if not already installed):
```bash
npm install -g wscat
```

Test secure WebSocket:
```bash
wscat -c wss://ws.myapp.com:3000
```

You should see:
```
Connected (press CTRL+C to quit)
>
```

Try joining a board:
```
> {"type":"join-board","boardId":"test123","userId":"user1","userName":"TestUser","color":4294198070}
```

You should receive a response with current cursors.

Press Ctrl+C to exit.

### Test 3: Check Docker Logs

```bash
docker-compose logs -f
```

You should see:
- `Running in HTTPS/WSS mode`
- No SSL-related errors
- Connection logs when you tested with wscat

---

## Part 6: Update Your Flutter App

Update the WebSocket URL in your Flutter app:

**File**: `lib/services/cursor_service.dart`

Change line 18 from:
```dart
static const String serverUrl = 'wss://137.184.120.233:3000';
```

To (replace with your domain):
```dart
static const String serverUrl = 'wss://ws.myapp.com:3000';
```

Rebuild and test your app!

---

## Troubleshooting

### Problem: "Failed to load SSL certificates"

**Solution:**
```bash
# Check if certificates exist
sudo ls -la /etc/letsencrypt/live/ws.myapp.com/

# Check docker-compose volumes match your domain
cat docker-compose.yml | grep letsencrypt

# Restart container
docker-compose restart
```

### Problem: "Connection refused"

**Solution:**
```bash
# Check if server is running
docker-compose ps

# Check if port is listening
sudo netstat -tulpn | grep 3000

# Check firewall
sudo ufw status
```

### Problem: "Certificate verification failed"

**Solution:**
```bash
# Test certificate
sudo certbot certificates

# Check certificate validity
openssl s_client -connect ws.myapp.com:3000 -showcerts

# If expired, renew manually
sudo certbot renew
docker-compose restart
```

### Problem: DNS not resolving

**Solution:**
```bash
# Test DNS
dig ws.myapp.com

# Wait for propagation (can take up to 48 hours, usually 5-10 min)
# Check at: https://dnschecker.org
```

### Problem: Port 80 in use during certificate generation

**Solution:**
```bash
# Find what's using port 80
sudo lsof -i :80

# Stop it temporarily
sudo systemctl stop nginx  # or apache2

# Try certbot again
sudo certbot certonly --standalone -d ws.myapp.com

# Restart the service
sudo systemctl start nginx  # or apache2
```

---

## Maintenance

### Check Certificate Expiry

```bash
sudo certbot certificates
```

### Manual Renewal

```bash
sudo certbot renew
docker-compose restart
```

### View Renewal Logs

```bash
cat /var/log/ollie-cert-renewal.log
```

### Update Server Code

```bash
cd /opt/ollie/server
git pull
docker-compose up -d --build
```

---

## Quick Command Reference

| Task | Command |
|------|---------|
| View logs | `docker-compose logs -f` |
| Restart server | `docker-compose restart` |
| Stop server | `docker-compose down` |
| Start server | `docker-compose up -d` |
| Check certificates | `sudo certbot certificates` |
| Renew certificates | `sudo certbot renew` |
| Test health | `curl https://ws.myapp.com:3000/health` |
| Test WebSocket | `wscat -c wss://ws.myapp.com:3000` |

---

## Support

If you encounter issues:
1. Check the troubleshooting section above
2. Review server logs: `docker-compose logs -f`
3. Check SSL_SETUP.md for more detailed information
4. Verify DNS with: https://dnschecker.org

---

## Summary

After following this guide:
- ✅ SSL certificates installed from Let's Encrypt
- ✅ WebSocket server running with WSS (secure)
- ✅ Auto-renewal configured
- ✅ Firewall configured
- ✅ Health checks passing
- ✅ Client app can connect securely

Your production WebSocket server is now secure! 🎉
