# 🚀 CICD360 - راهنمای کامل استقرار روی سرور

این راهنمای قدم به قدم برای استقرار پروژه CICD360 روی سرور واقعی است.

## 📋 پیش‌نیازهای سرور واقعی

### 1️⃣ مشخصات سرور مورد نیاز

```bash
# حداقل مشخصات:
- Ubuntu 20.04+ / CentOS 8+ / Debian 11+
- RAM: 1GB (پیشنهاد 2GB+)
- CPU: 1 Core
- Storage: 10GB
- IP عمومی
- پورت 22 (SSH) باز باشد
```

### 2️⃣ موارد مورد نیاز قبل از شروع

- [ ] سرور لینوکس با دسترسی root
- [ ] IP عمومی سرور
- [ ] SSH Key pair (عمومی و خصوصی)
- [ ] اکانت GitHub با دسترسی repository
- [ ] دامنه (اختیاری)

## 🔧 مرحله ۱: تنظیم اولیه سرور

### الف) اتصال به سرور
```bash
# اتصال اولیه با رمز عبور
ssh root@YOUR_SERVER_IP

# یا با SSH key
ssh -i ~/.ssh/your-key root@YOUR_SERVER_IP
```

### ب) اجرای اسکریپت تنظیمات
```bash
# دانلود اسکریپت تنظیم سرور
curl -fsSL https://raw.githubusercontent.com/mrbardia72/cicd360/main/scripts/server-setup.sh -o server-setup.sh

# اجرای اسکریپت
sudo bash server-setup.sh

# یا اجرای دستی:
chmod +x server-setup.sh
sudo ./server-setup.sh
```

### ج) تنظیم SSH Key دستی (اگر اسکریپت کار نکرد)
```bash
# ساخت کاربر deploy
sudo useradd -m -s /bin/bash deploy
sudo usermod -aG docker deploy

# ساخت دایرکتوری SSH
sudo mkdir -p /home/deploy/.ssh
sudo chmod 700 /home/deploy/.ssh

# اضافه کردن public key
echo "YOUR_PUBLIC_SSH_KEY" | sudo tee /home/deploy/.ssh/authorized_keys
sudo chmod 600 /home/deploy/.ssh/authorized_keys
sudo chown -R deploy:deploy /home/deploy/.ssh

# تست اتصال
ssh deploy@YOUR_SERVER_IP
```

## 🐳 مرحله ۲: نصب Docker (اگر اتوماتیک نصب نشد)

```bash
# نصب Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# شروع Docker service
sudo systemctl start docker
sudo systemctl enable docker

# نصب Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# تست
docker --version
docker-compose --version
```

## 📁 مرحله ۳: ساخت دایرکتوری‌های مورد نیاز

```bash
# ساخت دایرکتوری‌های پروژه
sudo mkdir -p /opt/cicd360
sudo mkdir -p /opt/cicd360/backups
sudo mkdir -p /opt/cicd360/scripts
sudo mkdir -p /var/log/cicd360

# تنظیم مالکیت
sudo chown -R deploy:deploy /opt/cicd360
sudo chown -R deploy:deploy /var/log/cicd360
```

## 🔐 مرحله ۴: تنظیم فایروال

```bash
# Ubuntu/Debian (UFW)
sudo ufw enable
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 8080/tcp  # Application
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS

# CentOS/RHEL (firewalld)
sudo firewall-cmd --permanent --add-port=22/tcp
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --permanent --add-port=443/tcp
sudo firewall-cmd --reload
```

## ⚙️ مرحله ۵: تنظیم GitHub Secrets

در مخزن GitHub خود به `Settings > Secrets and variables > Actions` رفته و این secrets را اضافه کنید:

### الزامی:
```
SERVER_HOST=YOUR_SERVER_IP          # مثال: 192.168.1.100
SERVER_USER=deploy                   # نام کاربر deploy
SSH_PRIVATE_KEY=-----BEGIN RSA...    # محتوای کامل private key
```

### اختیاری:
```
SERVER_PORT=22                       # پورت SSH (پیش‌فرض 22)
DOCKER_HUB_USERNAME=your-username    # برای Docker Hub
DOCKER_HUB_TOKEN=your-token         # برای Docker Hub
```

## 🔑 مرحله ۶: تولید SSH Key (اگر ندارید)

```bash
# در کامپیوتر محلی خود:
ssh-keygen -t rsa -b 4096 -C "cicd360-deployment"

# نمایش public key برای کپی
cat ~/.ssh/id_rsa.pub

# نمایش private key برای GitHub Secret
cat ~/.ssh/id_rsa
```

## 📝 مرحله ۷: تنظیم فایل محیطی روی سرور

```bash
# ورود به سرور
ssh deploy@YOUR_SERVER_IP

# ساخت فایل .env
cd /opt/cicd360
nano .env
```

محتوای فایل `.env`:

```bash
# 🌍 Application Environment
ENVIRONMENT=production
APP_NAME=CICD360
PORT=8080
VERSION=1.0.0

# 🔧 Server Configuration
HOST=0.0.0.0
READ_TIMEOUT=15s
WRITE_TIMEOUT=15s
IDLE_TIMEOUT=60s

# 📊 Logging Configuration
LOG_LEVEL=info
LOG_FORMAT=json
LOG_FILE=/var/log/cicd360/app.log

# 🐳 Docker Configuration
DOCKER_REGISTRY=ghcr.io
DOCKER_IMAGE_NAME=mrbardia72/cicd360
DOCKER_TAG=latest

# 🔒 Security Configuration
CORS_ALLOWED_ORIGINS=*
CORS_ALLOWED_METHODS=GET,POST,PUT,DELETE,OPTIONS
CORS_ALLOWED_HEADERS=Content-Type,Authorization

# 🚀 Deployment Configuration
DEPLOY_DIR=/opt/cicd360
BACKUP_DIR=/opt/cicd360/backups
BACKUP_RETENTION_DAYS=7

# 🌟 Feature Flags
ENABLE_METRICS=true
ENABLE_DEBUG=false
ENABLE_CORS=true
ENABLE_REQUEST_LOGGING=true
ENABLE_HEALTH_CHECKS=true

# 🔄 CI/CD Configuration
GITHUB_REPOSITORY=mrbardia72/cicd360
DEPLOYMENT_BRANCH=main
AUTO_DEPLOY=true

# 🎯 Performance Configuration
MAX_CONCURRENT_CONNECTIONS=1000
CONNECTION_TIMEOUT=30s
KEEPALIVE_TIMEOUT=65s

# 🧹 Maintenance Configuration
AUTO_CLEANUP=true
CLEANUP_INTERVAL=24h
LOG_ROTATION=true
LOG_MAX_SIZE=100MB
LOG_MAX_FILES=5
```

## 🎯 مرحله ۸: تست دستی اولیه

```bash
# در سرور، ساخت فایل docker-compose.yml موقت
cat > /opt/cicd360/docker-compose.yml << 'EOF'
services:
  app:
    image: ghcr.io/mrbardia72/cicd360:latest
    container_name: cicd360
    restart: unless-stopped
    ports:
      - "8080:8080"
    environment:
      - PORT=8080
      - ENVIRONMENT=production
      - APP_NAME=CICD360
    volumes:
      - app-logs:/var/log/cicd360
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s

volumes:
  app-logs:
    name: cicd360-app-logs
EOF

# تست اجرا (ممکن است fail کند تا image build نشده)
docker-compose up -d
```

## 🚀 مرحله ۹: اولین Deployment

### الف) Push کردن کد
```bash
# در پروژه محلی:
git add .
git commit -m "🚀 Deploy to production server"
git push origin main
```

### ب) نظارت بر GitHub Actions
1. به مخزن GitHub بروید
2. تب `Actions` را کلیک کنید  
3. Workflow اجرا را مشاهده کنید

### ج) بررسی در سرور
```bash
# بررسی logs
ssh deploy@YOUR_SERVER_IP
docker-compose logs -f

# بررسی وضعیت
docker-compose ps

# تست API
curl http://localhost:8080/health
```

## ✅ مرحله ۱۰: تست نهایی

### API Endpoints:
```bash
# Health Check
curl http://YOUR_SERVER_IP:8080/health
# انتظار: {"status":"OK",...}

# Info
curl http://YOUR_SERVER_IP:8080/info
# انتظار: {"application":"CICD360",...}

# Home
curl http://YOUR_SERVER_IP:8080/
# انتظار: {"message":"Welcome to CICD360! 🚀",...}
```

### Performance Test:
```bash
# تست سرعت
for i in {1..10}; do
  curl -s -w "Response time: %{time_total}s\n" \
    http://YOUR_SERVER_IP:8080/health > /dev/null
done
```

## 🔧 عیب‌یابی رایج

### خطای SSH:
```bash
# بررسی اتصال SSH
ssh -v deploy@YOUR_SERVER_IP

# بررسی SSH key
ssh-add -l

# تست key
ssh-keygen -y -f ~/.ssh/id_rsa
```

### خطای Docker:
```bash
# بررسی Docker service
sudo systemctl status docker

# بررسی logs
docker logs cicd360

# restart Docker
sudo systemctl restart docker
```

### خطای فایروال:
```bash
# بررسی پورت‌ها
sudo ufw status
sudo netstat -tlnp | grep 8080

# تست از خارج
telnet YOUR_SERVER_IP 8080
```

### خطای GitHub Actions:
```bash
# بررسی secrets در GitHub
# Settings > Secrets and variables > Actions

# بررسی syntax فایل workflow
# .github/workflows/deploy.yml
```

## 📊 نظارت و مانیتورینگ

### Commands مفید:
```bash
# وضعیت کلی
docker-compose ps
docker stats

# Logs
docker-compose logs -f --tail=50
tail -f /var/log/cicd360/app.log

# Resource usage
htop
df -h
free -h

# Network
netstat -tlnp
ss -tlnp
```

### Health Checks:
```bash
# اسکریپت خودکار health check
cat > /opt/cicd360/health-monitor.sh << 'EOF'
#!/bin/bash
while true; do
  if ! curl -f http://localhost:8080/health > /dev/null 2>&1; then
    echo "$(date): Health check failed, restarting..." >> /var/log/cicd360/monitor.log
    docker-compose restart
  fi
  sleep 60
done
EOF

chmod +x /opt/cicd360/health-monitor.sh
```

## 🔄 به‌روزرسانی و نگهداری

### Backup:
```bash
# Backup دستی
cd /opt/cicd360
tar -czf "backup-$(date +%Y%m%d).tar.gz" .

# Automated backup
echo "0 2 * * * cd /opt/cicd360 && tar -czf backups/backup-\$(date +\%Y\%m\%d).tar.gz --exclude=backups ." | crontab -
```

### Update:
```bash
# برای به‌روزرسانی، فقط push به main branch کنید
git push origin main
```

## 🎉 تبریک!

پروژه شما اکنون روی سرور واقعی در حال اجراست:

- 🌐 **URL**: `http://YOUR_SERVER_IP:8080`
- 🏥 **Health**: `http://YOUR_SERVER_IP:8080/health`
- ℹ️ **Info**: `http://YOUR_SERVER_IP:8080/info`

هر تغییر در branch `main` خودکار deploy خواهد شد! 🚀

## 📞 پشتیبانی

اگر مشکلی پیش آمد:
1. logs را بررسی کنید
2. GitHub Actions را چک کنید
3. SSH connection را تست کنید  
4. فایروال و پورت‌ها را بررسی کنید

موفق باشید! 🎯