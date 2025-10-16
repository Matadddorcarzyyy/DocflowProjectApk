# Руководство по установке DockFlow

## Системные требования

### Минимальные требования
- **CPU:** 1 ядро, 1 ГГц
- **RAM:** 2 ГБ
- **Диск:** 10 ГБ свободного места
- **ОС:** Ubuntu 20.04+, CentOS 8+, Windows 10+

### Рекомендуемые требования
- **CPU:** 2 ядра, 2 ГГц
- **RAM:** 4 ГБ
- **Диск:** 20 ГБ SSD
- **ОС:** Ubuntu 22.04 LTS

## Установка зависимостей

### Ubuntu/Debian

```bash
# Обновление системы
sudo apt update && sudo apt upgrade -y

# Установка Node.js 18+
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Установка PostgreSQL
sudo apt install -y postgresql postgresql-contrib

# Установка дополнительных инструментов
sudo apt install -y git nginx certbot python3-certbot-nginx
```

### CentOS/RHEL

```bash
# Установка Node.js
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo yum install -y nodejs

# Установка PostgreSQL
sudo yum install -y postgresql-server postgresql-contrib
sudo postgresql-setup initdb
sudo systemctl enable postgresql
sudo systemctl start postgresql
```

### Windows

1. Скачайте и установите [Node.js 18+](https://nodejs.org/)
2. Установите [PostgreSQL](https://www.postgresql.org/download/windows/)
3. Установите [Git for Windows](https://git-scm.com/download/win)

## Настройка базы данных

### 1. Создание пользователя и базы данных

```bash
# Переключение на пользователя postgres
sudo -u postgres psql

# Создание пользователя
CREATE USER dockflow_user WITH PASSWORD 'secure_password_here';

# Создание базы данных
CREATE DATABASE dockflow OWNER dockflow_user;

# Предоставление прав
GRANT ALL PRIVILEGES ON DATABASE dockflow TO dockflow_user;

# Выход
\q
```

### 2. Настройка PostgreSQL

```bash
# Редактирование конфигурации
sudo nano /etc/postgresql/13/main/postgresql.conf

# Убедитесь, что следующие настройки включены:
# listen_addresses = 'localhost'
# port = 5432
# max_connections = 100

# Редактирование pg_hba.conf
sudo nano /etc/postgresql/13/main/pg_hba.conf

# Добавьте строку для локальных соединений:
# local   dockflow        dockflow_user                    md5
# host    dockflow        dockflow_user    127.00.0.1/32   md5
```

### 3. Перезапуск PostgreSQL

```bash
sudo systemctl restart postgresql
sudo systemctl enable postgresql
```

## Установка приложения

### 1. Клонирование репозитория

```bash
# Клонирование
git clone <repository-url>
cd dockflow

# Проверка структуры проекта
ls -la
```

### 2. Настройка окружения

```bash
# Создание .env файла
cd server
cp .env.example .env

# Редактирование .env
nano .env
```

Содержимое `.env` файла:

```env
# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=dockflow
DB_USER=dockflow_user
DB_PASSWORD=secure_password_here

# JWT Configuration
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
JWT_EXPIRES_IN=24h

# Server Configuration
PORT=8080
NODE_ENV=production

# Socket.IO Configuration
SOCKET_CORS_ORIGIN=http://yourdomain.com
```

### 3. Установка зависимостей

```bash
# Backend зависимости
cd server
npm install --production

# Проверка установки
npm list --depth=0
```

### 4. Инициализация базы данных

```bash
# Подключение к базе данных
psql -U dockflow_user -d dockflow -h localhost

# Создание таблиц
\i database/schema.sql

# Добавление тестовых данных (опционально)
\i database/seed.sql

# Выход
\q
```

## Запуск приложения

### Режим разработки

```bash
# Запуск сервера
cd server
npm start

# Или с автоперезагрузкой
npm run dev
```

### Режим продакшена

```bash
# Установка PM2
npm install -g pm2

# Запуск приложения
pm2 start src/index.js --name dockflow --env production

# Сохранение конфигурации PM2
pm2 save

# Настройка автозапуска
pm2 startup
```

## Настройка веб-сервера (Nginx)

### 1. Создание конфигурации Nginx

```bash
sudo nano /etc/nginx/sites-available/dockflow
```

### 2. Конфигурация сайта

```nginx
server {
    listen 80;
    server_name yourdomain.com www.yourdomain.com;
    
    # Frontend
    location / {
        root /path/to/dockflow/frontend;
        index index.html;
        try_files $uri $uri/ /index.html;
    }
    
    # Backend API
    location /api/ {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
    
    # Socket.IO
    location /socket.io/ {
        proxy_pass http://localhost:8080;
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

### 3. Активация сайта

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

## Настройка SSL (Let's Encrypt)

```bash
# Установка Certbot
sudo apt install certbot python3-certbot-nginx

# Получение SSL сертификата
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com

# Проверка автообновления
sudo certbot renew --dry-run
```

## Проверка установки

### 1. Проверка сервисов

```bash
# Статус PM2
pm2 status

# Статус PostgreSQL
sudo systemctl status postgresql

# Статус Nginx
sudo systemctl status nginx
```

### 2. Проверка доступности

```bash
# API
curl http://localhost:8080/api/health

# Frontend
curl http://yourdomain.com

# База данных
psql -U dockflow_user -d dockflow -c "SELECT COUNT(*) FROM users;"
```

### 3. Проверка логов

```bash
# Логи приложения
pm2 logs dockflow

# Логи Nginx
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log

# Логи PostgreSQL
sudo tail -f /var/log/postgresql/postgresql-13-main.log
```

## Обновление приложения

```bash
# Остановка приложения
pm2 stop dockflow

# Обновление кода
git pull origin main

# Установка новых зависимостей
cd server
npm install --production

# Запуск приложения
pm2 start dockflow

# Проверка статуса
pm2 status
```

## Удаление приложения

```bash
# Остановка и удаление из PM2
pm2 delete dockflow

# Удаление базы данных
sudo -u postgres psql -c "DROP DATABASE dockflow;"
sudo -u postgres psql -c "DROP USER dockflow_user;"

# Удаление конфигурации Nginx
sudo rm /etc/nginx/sites-enabled/dockflow
sudo rm /etc/nginx/sites-available/dockflow
sudo systemctl reload nginx

# Удаление файлов приложения
rm -rf /path/to/dockflow
```

## Устранение неполадок

### Проблема: Приложение не запускается

```bash
# Проверка логов
pm2 logs dockflow

# Проверка портов
netstat -tulpn | grep :8080

# Проверка переменных окружения
pm2 env dockflow
```

### Проблема: База данных недоступна

```bash
# Проверка статуса PostgreSQL
sudo systemctl status postgresql

# Проверка подключения
psql -U dockflow_user -d dockflow -h localhost

# Проверка логов
sudo tail -f /var/log/postgresql/postgresql-13-main.log
```

### Проблема: Nginx не проксирует запросы

```bash
# Проверка конфигурации
sudo nginx -t

# Проверка статуса
sudo systemctl status nginx

# Проверка логов
sudo tail -f /var/log/nginx/error.log
```

---

**Следующий шаг:** [Настройка продакшена](PRODUCTION.md)
