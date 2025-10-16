# Развертывание в продакшене

## Подготовка сервера

### Системные требования

**Минимальные:**
- CPU: 2 ядра, 2 ГГц
- RAM: 4 ГБ
- Диск: 50 ГБ SSD
- ОС: Ubuntu 22.04 LTS

**Рекомендуемые:**
- CPU: 4 ядра, 3 ГГц
- RAM: 8 ГБ
- Диск: 100 ГБ SSD
- ОС: Ubuntu 22.04 LTS

### Настройка сервера

```bash
# Обновление системы
sudo apt update && sudo apt upgrade -y

# Установка необходимых пакетов
sudo apt install -y curl wget git nginx postgresql postgresql-contrib certbot python3-certbot-nginx ufw fail2ban

# Настройка файрвола
sudo ufw enable
sudo ufw allow ssh
sudo ufw allow 80
sudo ufw allow 443
sudo ufw deny 8080  # Закрыть прямой доступ к API
```

## Установка Node.js

```bash
# Установка Node.js 18 LTS
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Проверка версии
node --version
npm --version

# Установка PM2
sudo npm install -g pm2
```

## Настройка PostgreSQL

### 1. Создание пользователя и базы данных

```bash
# Переключение на пользователя postgres
sudo -u postgres psql

# Создание пользователя
CREATE USER dockflow_user WITH PASSWORD 'super_secure_password_here';

# Создание базы данных
CREATE DATABASE dockflow OWNER dockflow_user;

# Предоставление прав
GRANT ALL PRIVILEGES ON DATABASE dockflow TO dockflow_user;

# Выход
\q
```

### 2. Настройка безопасности

```bash
# Редактирование postgresql.conf
sudo nano /etc/postgresql/14/main/postgresql.conf

# Основные настройки
listen_addresses = 'localhost'
port = 5432
max_connections = 100
shared_buffers = 256MB
effective_cache_size = 1GB
maintenance_work_mem = 64MB
checkpoint_completion_target = 0.9
wal_buffers = 16MB
default_statistics_target = 100
random_page_cost = 1.1
effective_io_concurrency = 200

# Редактирование pg_hba.conf
sudo nano /etc/postgresql/14/main/pg_hba.conf

# Добавление правил доступа
local   dockflow        dockflow_user                    md5
host    dockflow        dockflow_user    127.0.0.1/32   md5
host    dockflow        dockflow_user    ::1/128         md5

# Перезапуск PostgreSQL
sudo systemctl restart postgresql
sudo systemctl enable postgresql
```

## Развертывание приложения

### 1. Клонирование и настройка

```bash
# Создание пользователя для приложения
sudo useradd -m -s /bin/bash dockflow
sudo usermod -aG sudo dockflow

# Переключение на пользователя dockflow
sudo su - dockflow

# Клонирование репозитория
git clone <repository-url> /home/dockflow/app
cd /home/dockflow/app

# Установка зависимостей
cd server
npm install --production
```

### 2. Настройка окружения

```bash
# Создание .env файла
nano .env
```

Содержимое `.env`:

```env
# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=dockflow
DB_USER=dockflow_user
DB_PASSWORD=super_secure_password_here

# JWT Configuration
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production-minimum-32-characters
JWT_EXPIRES_IN=24h

# Server Configuration
PORT=8080
NODE_ENV=production

# Socket.IO Configuration
SOCKET_CORS_ORIGIN=https://yourdomain.com

# Security
BCRYPT_ROUNDS=12
SESSION_SECRET=your-session-secret-key-here

# Monitoring
LOG_LEVEL=info
ENABLE_METRICS=true
```

### 3. Инициализация базы данных

```bash
# Создание таблиц
psql -U dockflow_user -d dockflow -h localhost -f database/schema.sql

# Добавление начальных данных
psql -U dockflow_user -d dockflow -h localhost -f database/seed.sql
```

### 4. Запуск с PM2

```bash
# Создание конфигурации PM2
nano ecosystem.config.js
```

Содержимое `ecosystem.config.js`:

```javascript
module.exports = {
  apps: [{
    name: 'dockflow',
    script: 'src/index.js',
    cwd: '/home/dockflow/app/server',
    instances: 2,
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'production',
      PORT: 8080
    },
    error_file: '/var/log/dockflow/error.log',
    out_file: '/var/log/dockflow/out.log',
    log_file: '/var/log/dockflow/combined.log',
    time: true,
    max_memory_restart: '1G',
    node_args: '--max-old-space-size=1024'
  }]
};
```

```bash
# Создание директории для логов
sudo mkdir -p /var/log/dockflow
sudo chown dockflow:dockflow /var/log/dockflow

# Запуск приложения
pm2 start ecosystem.config.js

# Сохранение конфигурации PM2
pm2 save

# Настройка автозапуска
pm2 startup
```

## Настройка Nginx

### 1. Создание конфигурации

```bash
sudo nano /etc/nginx/sites-available/dockflow
```

Содержимое конфигурации:

```nginx
# Rate limiting
limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
limit_req_zone $binary_remote_addr zone=login:10m rate=5r/m;

# Upstream для балансировки нагрузки
upstream dockflow_backend {
    server 127.0.0.1:8080;
    keepalive 32;
}

server {
    listen 80;
    server_name yourdomain.com www.yourdomain.com;
    
    # Редирект на HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name yourdomain.com www.yourdomain.com;
    
    # SSL конфигурация
    ssl_certificate /etc/letsencrypt/live/yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Security headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;
    
    # Frontend
    location / {
        root /home/dockflow/app/frontend;
        index index.html;
        try_files $uri $uri/ /index.html;
        
        # Cache static assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
    
    # API endpoints
    location /api/ {
        limit_req zone=api burst=20 nodelay;
        
        proxy_pass http://dockflow_backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }
    
    # Socket.IO
    location /socket.io/ {
        proxy_pass http://dockflow_backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }
    
    # Health check
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
```

### 2. Активация сайта

```bash
# Создание символической ссылки
sudo ln -s /etc/nginx/sites-available/dockflow /etc/nginx/sites-enabled/

# Удаление дефолтного сайта
sudo rm /etc/nginx/sites-enabled/default

# Проверка конфигурации
sudo nginx -t

# Перезапуск Nginx
sudo systemctl restart nginx
sudo systemctl enable nginx
```

## Настройка SSL

### 1. Получение SSL сертификата

```bash
# Получение сертификата
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com

# Проверка автообновления
sudo certbot renew --dry-run
```

### 2. Настройка автообновления

```bash
# Добавление в crontab
sudo crontab -e

# Добавление строки (проверка дважды в день)
0 12 * * * /usr/bin/certbot renew --quiet
```

## Мониторинг и логирование

### 1. Настройка логирования

```bash
# Создание директории для логов
sudo mkdir -p /var/log/dockflow
sudo chown dockflow:dockflow /var/log/dockflow

# Настройка logrotate
sudo nano /etc/logrotate.d/dockflow
```

Содержимое `/etc/logrotate.d/dockflow`:

```
/var/log/dockflow/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 dockflow dockflow
    postrotate
        pm2 reload dockflow
    endscript
}
```

### 2. Мониторинг системы

```bash
# Установка htop
sudo apt install htop

# Установка iotop для мониторинга диска
sudo apt install iotop

# Мониторинг PM2
pm2 monit
```

### 3. Настройка алертов

```bash
# Создание скрипта мониторинга
sudo nano /usr/local/bin/dockflow-monitor.sh
```

Содержимое скрипта:

```bash
#!/bin/bash

# Проверка доступности приложения
if ! curl -f http://localhost:8080/health > /dev/null 2>&1; then
    echo "DockFlow application is down!" | mail -s "DockFlow Alert" admin@yourdomain.com
    pm2 restart dockflow
fi

# Проверка использования диска
DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ $DISK_USAGE -gt 80 ]; then
    echo "Disk usage is ${DISK_USAGE}%" | mail -s "DockFlow Disk Alert" admin@yourdomain.com
fi

# Проверка использования памяти
MEMORY_USAGE=$(free | awk 'NR==2{printf "%.2f", $3*100/$2}')
if (( $(echo "$MEMORY_USAGE > 90" | bc -l) )); then
    echo "Memory usage is ${MEMORY_USAGE}%" | mail -s "DockFlow Memory Alert" admin@yourdomain.com
fi
```

```bash
# Сделать скрипт исполняемым
sudo chmod +x /usr/local/bin/dockflow-monitor.sh

# Добавить в crontab (каждые 5 минут)
sudo crontab -e
# Добавить: */5 * * * * /usr/local/bin/dockflow-monitor.sh
```

## Резервное копирование

### 1. Автоматическое резервное копирование

```bash
# Создание скрипта бэкапа
sudo nano /usr/local/bin/dockflow-backup.sh
```

Содержимое скрипта:

```bash
#!/bin/bash

BACKUP_DIR="/backups/dockflow"
DB_USER="dockflow_user"
DB_NAME="dockflow"
RETENTION_DAYS=30
DATE=$(date +%Y%m%d_%H%M%S)

# Создание директории для бэкапов
mkdir -p $BACKUP_DIR

# Создание бэкапа базы данных
pg_dump -U $DB_USER -h localhost -d $DB_NAME | gzip > $BACKUP_DIR/dockflow_db_$DATE.sql.gz

# Создание бэкапа файлов приложения
tar -czf $BACKUP_DIR/dockflow_app_$DATE.tar.gz /home/dockflow/app

# Создание бэкапа конфигурации
tar -czf $BACKUP_DIR/dockflow_config_$DATE.tar.gz /etc/nginx/sites-available/dockflow /home/dockflow/app/server/.env

# Удаление старых бэкапов
find $BACKUP_DIR -name "dockflow_*" -mtime +$RETENTION_DAYS -delete

# Проверка успешности
if [ $? -eq 0 ]; then
    echo "Backup completed successfully at $(date)" | mail -s "DockFlow Backup Success" admin@yourdomain.com
else
    echo "Backup failed at $(date)" | mail -s "DockFlow Backup Error" admin@yourdomain.com
fi
```

```bash
# Сделать скрипт исполняемым
sudo chmod +x /usr/local/bin/dockflow-backup.sh

# Добавить в crontab (ежедневно в 2:00)
sudo crontab -e
# Добавить: 0 2 * * * /usr/local/bin/dockflow-backup.sh
```

### 2. Восстановление из бэкапа

```bash
# Восстановление базы данных
gunzip -c /backups/dockflow/dockflow_db_20241217_020000.sql.gz | psql -U dockflow_user -d dockflow

# Восстановление файлов приложения
tar -xzf /backups/dockflow/dockflow_app_20241217_020000.tar.gz -C /

# Восстановление конфигурации
tar -xzf /backups/dockflow/dockflow_config_20241217_020000.tar.gz -C /
```

## Безопасность

### 1. Настройка Fail2Ban

```bash
# Создание конфигурации для Nginx
sudo nano /etc/fail2ban/jail.local
```

Содержимое:

```ini
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[nginx-http-auth]
enabled = true
port = http,https
logpath = /var/log/nginx/error.log

[nginx-limit-req]
enabled = true
port = http,https
logpath = /var/log/nginx/error.log
maxretry = 10
```

```bash
# Перезапуск Fail2Ban
sudo systemctl restart fail2ban
sudo systemctl enable fail2ban
```

### 2. Настройка автоматических обновлений

```bash
# Настройка автоматических обновлений безопасности
sudo dpkg-reconfigure unattended-upgrades

# Проверка конфигурации
sudo cat /etc/apt/apt.conf.d/50unattended-upgrades
```

### 3. Мониторинг безопасности

```bash
# Установка AIDE для мониторинга файлов
sudo apt install aide

# Инициализация базы данных AIDE
sudo aideinit

# Проверка целостности файлов
sudo aide --check
```

## Масштабирование

### 1. Горизонтальное масштабирование

```bash
# Увеличение количества процессов PM2
pm2 scale dockflow 4

# Настройка балансировки нагрузки в Nginx
upstream dockflow_backend {
    server 127.0.0.1:8080;
    server 127.0.0.1:8081;
    server 127.0.0.1:8082;
    server 127.0.0.1:8083;
}
```

### 2. Настройка Redis для сессий

```bash
# Установка Redis
sudo apt install redis-server

# Настройка Redis
sudo nano /etc/redis/redis.conf
# uncomment: bind 127.0.0.1
# set: maxmemory 256mb
# set: maxmemory-policy allkeys-lru

# Перезапуск Redis
sudo systemctl restart redis-server
sudo systemctl enable redis-server
```

## Обслуживание

### 1. Обновление приложения

```bash
# Создание скрипта обновления
sudo nano /usr/local/bin/dockflow-update.sh
```

Содержимое:

```bash
#!/bin/bash

set -e

echo "Starting DockFlow update..."

# Создание бэкапа
/usr/local/bin/dockflow-backup.sh

# Остановка приложения
pm2 stop dockflow

# Обновление кода
cd /home/dockflow/app
git pull origin main

# Установка зависимостей
cd server
npm install --production

# Запуск приложения
pm2 start dockflow

# Проверка статуса
pm2 status

echo "DockFlow update completed!"
```

### 2. Мониторинг производительности

```bash
# Установка инструментов мониторинга
sudo apt install htop iotop nethogs

# Мониторинг в реальном времени
htop
iotop
nethogs
```

---

**Следующий шаг:** [Устранение неполадок](TROUBLESHOOTING.md)
