# 🚀 CICD360 - چک‌لیست تولید (Production Checklist)

## 📋 فهرست کامل پیش‌نیازها برای استقرار روی سرور واقعی

### 🖥️ **1. سرور (VPS/Cloud)**

#### ✅ مشخصات حداقلی:
- [ ] **سیستم عامل**: Ubuntu 20.04+ / CentOS 8+ / Debian 11+
- [ ] **RAM**: حداقل 1GB (پیشنهاد 2GB+)
- [ ] **CPU**: حداقل 1 Core
- [ ] **فضای ذخیره**: حداقل 10GB SSD
- [ ] **IP عمومی**: برای دسترسی از اینترنت
- [ ] **Bandwidth**: حداقل 100Mbps

#### 📍 **ارائه‌دهندگان پیشنهادی**:
```bash
# ایران:
- ArvanCloud
- IranServer  
- Parspack
- ParsVDS

# بین‌الملل:
- DigitalOcean (5$/ماه)
- Linode (5$/ماه)
- Vultr (2.5$/ماه)
- AWS EC2 (t2.micro)
- Google Cloud Platform
```

---

### 🔐 **2. دسترسی‌ها و حساب‌های کاربری**

#### ✅ **GitHub**:
- [ ] اکانت GitHub فعال
- [ ] Repository با دسترسی Admin
- [ ] GitHub Actions فعال باشد
- [ ] Personal Access Token (اختیاری)

#### ✅ **SSH Keys**:
```bash
# تولید SSH Key جدید:
ssh-keygen -t rsa -b 4096 -C "cicd360-deployment"

# فایل‌های تولید شده:
~/.ssh/id_rsa      # Private key (برای GitHub Secret)
~/.ssh/id_rsa.pub  # Public key (برای سرور)
```

#### ✅ **دامنه (اختیاری)**:
- [ ] دامنه تهیه شده
- [ ] DNS تنظیم شده به IP سرور
- [ ] SSL Certificate (Let's Encrypt یا خرید)

---

### ⚙️ **3. GitHub Secrets (الزامی)**

در GitHub Repository خود: `Settings > Secrets and variables > Actions`

#### 🔴 **الزامی**:
```bash
SERVER_HOST=192.168.1.100        # IP عمومی سرور
SERVER_USER=deploy               # نام کاربر deploy
SSH_PRIVATE_KEY=-----BEGIN...    # محتوای کامل ~/.ssh/id_rsa
```

#### 🟡 **اختیاری**:
```bash
SERVER_PORT=22                   # پورت SSH (پیش‌فرض 22)
DOCKER_HUB_USERNAME=username     # اگر از Docker Hub استفاده می‌کنید
DOCKER_HUB_TOKEN=token          # Token دسترسی Docker Hub
NOTIFICATION_WEBHOOK=https://... # برای اطلاع‌رسانی
```

---

### 🐳 **4. نرم‌افزارهای سرور**

#### ✅ **پیش‌نیازهای سیستمی**:
```bash
# پکیج‌های اساسی:
- curl
- wget  
- git
- unzip
- nano/vim
- htop
- jq
- netcat (nc)

# امنیتی:
- ufw (Ubuntu) / firewalld (CentOS)
- fail2ban (پیشنهادی)
```

#### ✅ **Docker & Docker Compose**:
```bash
# نصب خودکار با اسکریپت:
curl -fsSL https://get.docker.com | sh

# یا نصب دستی:
# - Docker Engine 20.10+
# - Docker Compose 2.0+
```

---

### 🔧 **5. تنظیمات شبکه و امنیت**

#### ✅ **پورت‌های مورد نیاز**:
```bash
22/tcp    # SSH
8080/tcp  # Application
80/tcp    # HTTP (Nginx)
443/tcp   # HTTPS (SSL)
```

#### ✅ **فایروال**:
```bash
# Ubuntu/Debian:
sudo ufw enable
sudo ufw allow 22,8080,80,443/tcp

# CentOS/RHEL:
sudo firewall-cmd --permanent --add-port={22,8080,80,443}/tcp
sudo firewall-cmd --reload
```

#### ✅ **SSH Security**:
- [ ] PasswordAuthentication disabled (بعد از تنظیم SSH key)
- [ ] Root login disabled
- [ ] SSH key authentication فعال
- [ ] Port 22 یا پورت سفارشی

---

### 📁 **6. ساختار فایل‌ها در سرور**

#### ✅ **دایرکتوری‌های مورد نیاز**:
```bash
/opt/cicd360/              # دایرکتوری اصلی پروژه
├── backups/               # فایل‌های پشتیبان
├── scripts/               # اسکریپت‌های deployment
├── docker-compose.yml     # فایل Docker Compose
├── .env                   # متغیرهای محیطی
└── nginx.conf             # تنظیمات Nginx (اختیاری)

/var/log/cicd360/          # فایل‌های log
├── app.log                # لاگ‌های برنامه
├── deploy.log             # لاگ‌های deployment
└── health-check.log       # لاگ‌های health check
```

#### ✅ **کاربر سیستمی**:
```bash
# کاربر deploy:
Username: deploy
Home: /home/deploy
Groups: docker
Shell: /bin/bash
SSH: ~/.ssh/authorized_keys
```

---

### 🌍 **7. متغیرهای محیطی (.env)**

فایل `/opt/cicd360/.env` با محتوای زیر:

```bash
# 🌍 Application
ENVIRONMENT=production
APP_NAME=CICD360
PORT=8080
VERSION=1.0.0

# 🔧 Server
HOST=0.0.0.0
READ_TIMEOUT=15s
WRITE_TIMEOUT=15s
IDLE_TIMEOUT=60s

# 📊 Logging
LOG_LEVEL=info
LOG_FORMAT=json
LOG_FILE=/var/log/cicd360/app.log

# 🐳 Docker
DOCKER_REGISTRY=ghcr.io
DOCKER_IMAGE_NAME=mrbardia72/cicd360
DOCKER_TAG=latest

# 🔒 Security
CORS_ALLOWED_ORIGINS=*
CORS_ALLOWED_METHODS=GET,POST,PUT,DELETE,OPTIONS
CORS_ALLOWED_HEADERS=Content-Type,Authorization

# 🚀 Deployment
DEPLOY_DIR=/opt/cicd360
BACKUP_DIR=/opt/cicd360/backups
BACKUP_RETENTION_DAYS=7

# 🌟 Features
ENABLE_METRICS=true
ENABLE_DEBUG=false
ENABLE_CORS=true
ENABLE_REQUEST_LOGGING=true
ENABLE_HEALTH_CHECKS=true

# 🎯 Performance
MAX_CONCURRENT_CONNECTIONS=1000
CONNECTION_TIMEOUT=30s
KEEPALIVE_TIMEOUT=65s

# 🧹 Maintenance
AUTO_CLEANUP=true
CLEANUP_INTERVAL=24h
LOG_ROTATION=true
LOG_MAX_SIZE=100MB
LOG_MAX_FILES=5
```

---

### ⚡ **8. مراحل نصب سریع**

#### 🚀 **تنظیم سرور (یک بار)**:
```bash
# 1. اتصال به سرور
ssh root@YOUR_SERVER_IP

# 2. اجرای اسکریپت نصب
curl -fsSL https://raw.githubusercontent.com/mrbardia72/cicd360/main/scripts/server-setup.sh | sudo bash

# 3. اضافه کردن SSH key
echo "YOUR_PUBLIC_KEY" >> /home/deploy/.ssh/authorized_keys

# 4. تست اتصال
ssh deploy@YOUR_SERVER_IP
```

#### 🔧 **تنظیم GitHub (یک بار)**:
```bash
# در GitHub Repository:
Settings > Secrets and variables > Actions

# اضافه کردن secrets:
SERVER_HOST: YOUR_SERVER_IP
SERVER_USER: deploy  
SSH_PRIVATE_KEY: [محتوای ~/.ssh/id_rsa]
```

#### 🚀 **اولین Deploy**:
```bash
# در پروژه محلی:
git add .
git commit -m "🚀 Initial deployment"
git push origin main

# GitHub Actions خودکار شروع می‌شود
```

---

### ✅ **9. تست‌های نهایی**

#### 🔍 **تست اتصال**:
```bash
# SSH Test
ssh deploy@YOUR_SERVER_IP "echo 'SSH OK'"

# Docker Test  
ssh deploy@YOUR_SERVER_IP "docker --version"

# Port Test
nmap -p 8080 YOUR_SERVER_IP
```

#### 🌐 **تست API**:
```bash
# Health Check
curl http://YOUR_SERVER_IP:8080/health

# Info Endpoint
curl http://YOUR_SERVER_IP:8080/info

# Home Page
curl http://YOUR_SERVER_IP:8080/
```

#### 📊 **Performance Test**:
```bash
# Response Time Test
for i in {1..10}; do
  curl -s -w "Time: %{time_total}s\n" \
    http://YOUR_SERVER_IP:8080/health > /dev/null
done

# Load Test (ساده)
ab -n 100 -c 10 http://YOUR_SERVER_IP:8080/health
```

---

### 🔧 **10. عیب‌یابی رایج**

#### ❌ **مشکلات متداول**:

**SSH Connection Failed:**
```bash
# چک کردن SSH key
ssh-keygen -y -f ~/.ssh/id_rsa

# تست verbose
ssh -v deploy@YOUR_SERVER_IP

# بررسی authorized_keys
cat /home/deploy/.ssh/authorized_keys
```

**GitHub Actions Failed:**
```bash
# بررسی secrets
# GitHub > Settings > Secrets

# بررسی syntax
yamllint .github/workflows/deploy.yml

# بررسی logs در Actions tab
```

**Port Not Accessible:**
```bash
# بررسی فایروال
sudo ufw status
sudo firewall-cmd --list-ports

# بررسی process
sudo netstat -tlnp | grep 8080

# تست local
curl http://localhost:8080/health
```

**Docker Issues:**
```bash
# بررسی Docker service
sudo systemctl status docker

# بررسی container logs
docker logs cicd360

# restart container
docker-compose restart
```

#### 🔧 **Commands مفید**:
```bash
# System Status
htop
df -h
free -h
systemctl status docker

# Application Status  
docker-compose ps
docker stats cicd360
docker logs cicd360 --tail=50

# Network Status
netstat -tlnp
ss -tlnp | grep 8080
```

---

### 📚 **11. منابع اضافی**

#### 📖 **مستندات**:
- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Reference](https://docs.docker.com/compose/)
- [GitHub Actions](https://docs.github.com/en/actions)
- [Ubuntu Server Guide](https://ubuntu.com/server/docs)

#### 🛠️ **ابزارهای مفید**:
```bash
# Monitoring
htop, netstat, ss, curl, wget

# Debugging  
journalctl, systemctl, docker logs

# Security
ufw, firewall-cmd, fail2ban, ssh-audit
```

#### 🔗 **لینک‌های مفید**:
- [DigitalOcean Tutorials](https://www.digitalocean.com/community/tutorials)
- [Let's Encrypt](https://letsencrypt.org/)
- [Docker Hub](https://hub.docker.com/)
- [GitHub Container Registry](https://ghcr.io)

---

## 🎯 **خلاصه سریع**

### ✅ **فهرست کاملی که باید داشته باشید**:

1. **سرور**: Ubuntu/CentOS با 1GB+ RAM
2. **IP عمومی**: برای دسترسی
3. **SSH Key**: برای اتصال امن
4. **GitHub Account**: با repository access
5. **Docker**: نصب شده روی سرور
6. **GitHub Secrets**: SERVER_HOST, SERVER_USER, SSH_PRIVATE_KEY
7. **Firewall**: پورت‌های 22, 8080, 80, 443 باز
8. **کاربر deploy**: با دسترسی docker

### 🚀 **مراحل استقرار**:
1. تنظیم سرور (یک بار)
2. تنظیم GitHub Secrets (یک بار)  
3. Push به branch main
4. GitHub Actions خودکار deploy می‌کند
5. تست API endpoints

### 🎉 **نتیجه**:
برنامه شما در `http://YOUR_SERVER_IP:8080` در دسترس خواهد بود و هر push به `main` خودکار deploy می‌شود!

---

**موفق باشید!** 🚀🎯✨