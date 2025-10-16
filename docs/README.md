# DockFlow - Система создания юридических документов

Полнофункциональная веб-система для создания юридических документов с чатом поддержки и AI-ассистентом.

## 📋 Содержание

- [Обзор проекта](#обзор-проекта)
- [Архитектура](#архитектура)
- [Быстрый старт](#быстрый-старт)
- [Установка и настройка](#установка-и-настройка)
- [Запуск на сервере](#запуск-на-сервере)
- [Конфигурация базы данных](#конфигурация-базы-данных)
- [API документация](#api-документация)
- [Развертывание в продакшене](#развертывание-в-продакшене)
- [Мониторинг и логирование](#мониторинг-и-логирование)
- [Безопасность](#безопасность)
- [Устранение неполадок](#устранение-неполадок)

## 🎯 Обзор проекта

DockFlow - это современная система для автоматизированного создания юридических документов, включающая:

- **Интерактивные формы** для создания документов
- **Чат с юристами** в реальном времени
- **AI-ассистент** для помощи пользователям
- **Система очередей** для распределения чатов
- **Управление пользователями** и ролями
- **Экспорт документов** в Word/PDF

## 🏗️ Архитектура

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   Backend       │    │   Database      │
│   (React/HTML)  │◄──►│   (Node.js)     │◄──►│   (PostgreSQL)  │
│                 │    │                 │    │                 │
│ • Главная       │    │ • Express API   │    │ • Пользователи  │
│ • Чат           │    │ • Socket.IO     │    │ • Чаты          │
│ • Админ панель  │    │ • JWT Auth      │    │ • Сообщения     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Технологический стек

**Frontend:**
- HTML5, CSS3, JavaScript (ES6+)
- Socket.IO Client
- Responsive Design

**Backend:**
- Node.js 18+
- Express.js
- Socket.IO
- JWT Authentication
- PostgreSQL

**DevOps:**
- Docker & Docker Compose
- Nginx (опционально)
- PM2 (для продакшена)

## 🚀 Быстрый старт

### Предварительные требования

- Node.js 18+ 
- PostgreSQL 13+
- Docker (опционально)
- Git

### Локальная разработка

1. **Клонирование репозитория:**
```bash
git clone <repository-url>
cd dockflow
```

2. **Установка зависимостей:**
```bash
# Backend
cd server
npm install

# Frontend (если нужен отдельный сервер)
cd ../frontend
# Статические файлы уже готовы
```

3. **Настройка базы данных:**
```bash
# Создание базы данных
createdb dockflow

# Запуск миграций (если есть)
npm run migrate
```

4. **Запуск приложения:**
```bash
# Backend
cd server
npm start

# Frontend (откройте в браузере)
open http://localhost:3000
```

## ⚙️ Установка и настройка

### 1. Настройка окружения

Создайте файл `.env` в папке `server/`:

```env
# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=dockflow
DB_USER=your_username
DB_PASSWORD=your_password

# JWT
JWT_SECRET=your-super-secret-jwt-key
JWT_EXPIRES_IN=24h

# Server
PORT=8080
NODE_ENV=development

# Socket.IO
SOCKET_CORS_ORIGIN=http://localhost:3000
```

### 2. Структура базы данных

```sql
-- Пользователи
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100),
    role VARCHAR(20) DEFAULT 'visitor',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Чаты
CREATE TABLE chats (
    id SERIAL PRIMARY KEY,
    visitor_id VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Сообщения
CREATE TABLE messages (
    id SERIAL PRIMARY KEY,
    chat_id INTEGER REFERENCES chats(id),
    sender VARCHAR(20) NOT NULL,
    text TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 3. Конфигурация сервера

Основные настройки в `server/src/index.js`:

```javascript
const PORT = process.env.PORT || 8080;
const DB_CONFIG = {
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'dockflow',
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD
};
```

## 🖥️ Запуск на сервере

### Вариант 1: Docker Compose (Рекомендуется)

1. **Подготовка:**
```bash
# Клонирование и настройка
git clone <repository-url>
cd dockflow

# Создание .env файла
cp .env.example .env
# Отредактируйте .env файл
```

2. **Запуск:**
```bash
# Запуск всех сервисов
docker-compose up -d

# Проверка статуса
docker-compose ps

# Просмотр логов
docker-compose logs -f
```

3. **Остановка:**
```bash
docker-compose down
```

### Вариант 2: Ручная установка

1. **Установка зависимостей на сервере:**
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install nodejs npm postgresql

# CentOS/RHEL
sudo yum install nodejs npm postgresql-server
```

2. **Настройка PostgreSQL:**
```bash
# Создание пользователя и базы
sudo -u postgres psql
CREATE USER dockflow_user WITH PASSWORD 'secure_password';
CREATE DATABASE dockflow OWNER dockflow_user;
GRANT ALL PRIVILEGES ON DATABASE dockflow TO dockflow_user;
\q
```

3. **Запуск приложения:**
```bash
# Установка зависимостей
cd server
npm install --production

# Запуск с PM2
npm install -g pm2
pm2 start src/index.js --name dockflow
pm2 save
pm2 startup
```

### Вариант 3: Nginx + PM2

1. **Установка Nginx:**
```bash
sudo apt install nginx
```

2. **Конфигурация Nginx:**
```nginx
# /etc/nginx/sites-available/dockflow
server {
    listen 80;
    server_name your-domain.com;

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

3. **Активация сайта:**
```bash
sudo ln -s /etc/nginx/sites-available/dockflow /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

## 🗄️ Конфигурация базы данных

### Создание таблиц

```sql
-- Подключение к базе данных
psql -U dockflow_user -d dockflow

-- Выполнение SQL скриптов
\i server/database/schema.sql
\i server/database/seed.sql
```

### Резервное копирование

```bash
# Создание бэкапа
pg_dump -U dockflow_user -h localhost dockflow > backup_$(date +%Y%m%d).sql

# Восстановление
psql -U dockflow_user -d dockflow < backup_20241217.sql
```

### Мониторинг производительности

```sql
-- Активные соединения
SELECT * FROM pg_stat_activity WHERE datname = 'dockflow';

-- Размер базы данных
SELECT pg_size_pretty(pg_database_size('dockflow'));

-- Медленные запросы
SELECT query, mean_time, calls 
FROM pg_stat_statements 
ORDER BY mean_time DESC 
LIMIT 10;
```

## 📡 API документация

### Аутентификация

```http
POST /api/auth/login
Content-Type: application/json

{
  "username": "lawyer1",
  "password": "password123"
}
```

**Ответ:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "username": "lawyer1",
    "full_name": "Иван Петров",
    "role": "lawyer"
  }
}
```

### Чаты

```http
GET /api/chats
Authorization: Bearer <token>
```

```http
POST /api/chats
Content-Type: application/json

{
  "visitor_id": "visitor_123"
}
```

### Сообщения

```http
GET /api/chats/:chatId/messages
Authorization: Bearer <token>
```

```http
POST /api/chats/:chatId/messages
Authorization: Bearer <token>
Content-Type: application/json

{
  "text": "Привет! Как дела?"
}
```

### Socket.IO события

**Клиент → Сервер:**
- `auth` - аутентификация
- `join-chat` - присоединение к чату
- `leave-chat` - выход из чата
- `message` - отправка сообщения

**Сервер → Клиент:**
- `presence` - статус пользователя
- `message` - новое сообщение
- `new-chat-assigned` - новый чат назначен
- `visitor-queued` - посетитель в очереди

## 🚀 Развертывание в продакшене

### 1. Подготовка сервера

```bash
# Обновление системы
sudo apt update && sudo apt upgrade -y

# Установка необходимых пакетов
sudo apt install -y nginx postgresql postgresql-contrib certbot python3-certbot-nginx

# Установка Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs
```

### 2. Настройка SSL

```bash
# Получение SSL сертификата
sudo certbot --nginx -d your-domain.com

# Автоматическое обновление
sudo crontab -e
# Добавить: 0 12 * * * /usr/bin/certbot renew --quiet
```

### 3. Мониторинг

```bash
# Установка PM2
npm install -g pm2

# Запуск приложения
pm2 start server/src/index.js --name dockflow --env production

# Мониторинг
pm2 monit
pm2 logs dockflow
```

### 4. Автоматический деплой

Создайте скрипт `deploy.sh`:

```bash
#!/bin/bash
set -e

echo "Deploying DockFlow..."

# Обновление кода
git pull origin main

# Установка зависимостей
cd server
npm install --production

# Перезапуск приложения
pm2 restart dockflow

# Проверка статуса
pm2 status

echo "Deployment completed!"
```

## 📊 Мониторинг и логирование

### Логи приложения

```bash
# PM2 логи
pm2 logs dockflow

# Nginx логи
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log

# PostgreSQL логи
sudo tail -f /var/log/postgresql/postgresql-13-main.log
```

### Мониторинг ресурсов

```bash
# Использование CPU и памяти
htop

# Дисковое пространство
df -h

# Сетевые соединения
netstat -tulpn | grep :8080
```

### Настройка алертов

Создайте скрипт мониторинга `monitor.sh`:

```bash
#!/bin/bash

# Проверка доступности приложения
if ! curl -f http://localhost:8080/api/health > /dev/null 2>&1; then
    echo "Application is down!" | mail -s "DockFlow Alert" admin@yourdomain.com
fi

# Проверка использования диска
DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ $DISK_USAGE -gt 80 ]; then
    echo "Disk usage is ${DISK_USAGE}%" | mail -s "DockFlow Disk Alert" admin@yourdomain.com
fi
```

## 🔒 Безопасность

### 1. Настройка файрвола

```bash
# UFW (Ubuntu)
sudo ufw enable
sudo ufw allow ssh
sudo ufw allow 80
sudo ufw allow 443
sudo ufw deny 8080  # Закрыть прямой доступ к API
```

### 2. Настройка PostgreSQL

```bash
# Редактирование postgresql.conf
sudo nano /etc/postgresql/13/main/postgresql.conf

# Настройки безопасности
listen_addresses = 'localhost'
ssl = on
password_encryption = scram-sha-256

# Редактирование pg_hba.conf
sudo nano /etc/postgresql/13/main/pg_hba.conf

# Только локальные соединения
local   all             all                                     scram-sha-256
host    all             all             127.0.0.1/32            scram-sha-256
```

### 3. Обновление зависимостей

```bash
# Проверка уязвимостей
npm audit

# Автоматическое исправление
npm audit fix

# Обновление зависимостей
npm update
```

### 4. Резервное копирование

```bash
# Ежедневный бэкап (crontab)
0 2 * * * pg_dump -U dockflow_user -h localhost dockflow | gzip > /backups/dockflow_$(date +\%Y\%m\%d).sql.gz

# Очистка старых бэкапов
0 3 * * 0 find /backups -name "dockflow_*.sql.gz" -mtime +30 -delete
```

## 🔧 Устранение неполадок

### Частые проблемы

**1. Приложение не запускается:**
```bash
# Проверка логов
pm2 logs dockflow

# Проверка портов
netstat -tulpn | grep :8080

# Проверка переменных окружения
pm2 env dockflow
```

**2. База данных недоступна:**
```bash
# Проверка статуса PostgreSQL
sudo systemctl status postgresql

# Проверка подключения
psql -U dockflow_user -h localhost -d dockflow -c "SELECT 1;"

# Проверка логов
sudo tail -f /var/log/postgresql/postgresql-13-main.log
```

**3. Socket.IO не работает:**
```bash
# Проверка CORS настроек
# В server/src/index.js проверьте:
# io = new Server(server, { cors: { origin: "http://yourdomain.com" } });
```

**4. Высокое использование памяти:**
```bash
# Перезапуск приложения
pm2 restart dockflow

# Очистка кэша Node.js
pm2 flush dockflow

# Мониторинг памяти
pm2 monit
```

### Логи и отладка

```bash
# Включение debug режима
NODE_ENV=development pm2 restart dockflow

# Детальные логи Socket.IO
DEBUG=socket.io:* pm2 restart dockflow

# Логи базы данных
sudo tail -f /var/log/postgresql/postgresql-13-main.log | grep dockflow
```

## 📞 Поддержка

Для получения помощи:

1. Проверьте [FAQ](FAQ.md)
2. Изучите [логи приложения](#мониторинг-и-логирование)
3. Создайте issue в репозитории
4. Обратитесь к администратору системы

---

**Версия документации:** 1.0  
**Последнее обновление:** 17 декабря 2024
