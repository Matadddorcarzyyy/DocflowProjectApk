# Устранение неполадок DockFlow

## Общие проблемы

### Приложение не запускается

**Симптомы:**
- PM2 показывает статус "errored" или "stopped"
- Ошибки в логах приложения
- Порт 8080 не прослушивается

**Диагностика:**
```bash
# Проверка статуса PM2
pm2 status

# Просмотр логов
pm2 logs dockflow

# Проверка портов
netstat -tulpn | grep :8080

# Проверка переменных окружения
pm2 env dockflow
```

**Решения:**
1. **Проверьте .env файл:**
```bash
cd /home/dockflow/app/server
cat .env
# Убедитесь, что все переменные заполнены корректно
```

2. **Проверьте зависимости:**
```bash
cd /home/dockflow/app/server
npm install
```

3. **Проверьте права доступа:**
```bash
sudo chown -R dockflow:dockflow /home/dockflow/app
```

4. **Перезапустите приложение:**
```bash
pm2 restart dockflow
```

### База данных недоступна

**Симптомы:**
- Ошибки подключения к PostgreSQL
- "ECONNREFUSED" в логах
- Приложение не может создать таблицы

**Диагностика:**
```bash
# Проверка статуса PostgreSQL
sudo systemctl status postgresql

# Проверка подключения
psql -U dockflow_user -d dockflow -h localhost

# Проверка логов PostgreSQL
sudo tail -f /var/log/postgresql/postgresql-14-main.log
```

**Решения:**
1. **Запустите PostgreSQL:**
```bash
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

2. **Проверьте конфигурацию:**
```bash
# Проверьте pg_hba.conf
sudo cat /etc/postgresql/14/main/pg_hba.conf | grep dockflow

# Проверьте postgresql.conf
sudo cat /etc/postgresql/14/main/postgresql.conf | grep listen_addresses
```

3. **Создайте пользователя и базу данных:**
```bash
sudo -u postgres psql
CREATE USER dockflow_user WITH PASSWORD 'your_password';
CREATE DATABASE dockflow OWNER dockflow_user;
GRANT ALL PRIVILEGES ON DATABASE dockflow TO dockflow_user;
\q
```

### Nginx не проксирует запросы

**Симптомы:**
- 502 Bad Gateway ошибки
- Сайт не загружается
- API недоступен

**Диагностика:**
```bash
# Проверка статуса Nginx
sudo systemctl status nginx

# Проверка конфигурации
sudo nginx -t

# Проверка логов Nginx
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/access.log
```

**Решения:**
1. **Проверьте конфигурацию:**
```bash
sudo nginx -t
# Если есть ошибки, исправьте их в /etc/nginx/sites-available/dockflow
```

2. **Проверьте upstream:**
```bash
# Убедитесь, что приложение запущено на порту 8080
netstat -tulpn | grep :8080
```

3. **Перезапустите Nginx:**
```bash
sudo systemctl restart nginx
```

### Socket.IO не работает

**Симптомы:**
- Чат не подключается
- Сообщения не отправляются
- Ошибки WebSocket в консоли браузера

**Диагностика:**
```bash
# Проверка логов приложения
pm2 logs dockflow | grep socket

# Проверка CORS настроек
grep -r "cors" /home/dockflow/app/server/src/
```

**Решения:**
1. **Проверьте CORS настройки:**
```javascript
// В server/src/index.js
const io = new Server(server, {
  cors: {
    origin: "https://yourdomain.com", // Замените на ваш домен
    methods: ["GET", "POST"]
  }
});
```

2. **Проверьте Nginx конфигурацию для Socket.IO:**
```nginx
location /socket.io/ {
    proxy_pass http://dockflow_backend;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    # ... остальные настройки
}
```

### Высокое использование памяти

**Симптомы:**
- Медленная работа приложения
- PM2 перезапускает процессы
- Ошибки "out of memory"

**Диагностика:**
```bash
# Мониторинг памяти
htop
pm2 monit

# Проверка использования памяти процессами
ps aux --sort=-%mem | head -10
```

**Решения:**
1. **Ограничьте память в PM2:**
```javascript
// В ecosystem.config.js
module.exports = {
  apps: [{
    name: 'dockflow',
    script: 'src/index.js',
    max_memory_restart: '1G', // Перезапуск при превышении 1GB
    node_args: '--max-old-space-size=1024'
  }]
};
```

2. **Оптимизируйте базу данных:**
```sql
-- Очистка мертвых кортежей
VACUUM ANALYZE;

-- Переиндексация
REINDEX TABLE messages;
```

3. **Увеличьте swap:**
```bash
# Создание swap файла
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Добавление в fstab
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

## Проблемы с производительностью

### Медленные запросы к базе данных

**Диагностика:**
```sql
-- Включение логирования медленных запросов
ALTER SYSTEM SET log_min_duration_statement = 1000; -- 1 секунда
SELECT pg_reload_conf();

-- Просмотр медленных запросов
SELECT query, mean_time, calls 
FROM pg_stat_statements 
ORDER BY mean_time DESC 
LIMIT 10;
```

**Решения:**
1. **Добавьте индексы:**
```sql
-- Для часто используемых запросов
CREATE INDEX idx_messages_chat_id_created_at ON messages(chat_id, created_at);
CREATE INDEX idx_chats_status_created_at ON chats(status, created_at);
```

2. **Оптимизируйте запросы:**
```sql
-- Используйте EXPLAIN для анализа запросов
EXPLAIN ANALYZE SELECT * FROM messages WHERE chat_id = 1 ORDER BY created_at DESC;
```

### Медленная загрузка страниц

**Диагностика:**
```bash
# Проверка времени ответа
curl -w "@curl-format.txt" -o /dev/null -s "https://yourdomain.com"

# Создайте curl-format.txt:
cat > curl-format.txt << EOF
     time_namelookup:  %{time_namelookup}\n
        time_connect:  %{time_connect}\n
     time_appconnect:  %{time_appconnect}\n
    time_pretransfer:  %{time_pretransfer}\n
       time_redirect:  %{time_redirect}\n
  time_starttransfer:  %{time_starttransfer}\n
                     ----------\n
          time_total:  %{time_total}\n
EOF
```

**Решения:**
1. **Включите gzip сжатие в Nginx:**
```nginx
gzip on;
gzip_vary on;
gzip_min_length 1024;
gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;
```

2. **Настройте кэширование:**
```nginx
# Кэширование статических файлов
location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
}
```

## Проблемы с безопасностью

### SSL сертификат не работает

**Симптомы:**
- "Not Secure" в браузере
- Ошибки SSL в логах
- Сайт не загружается по HTTPS

**Диагностика:**
```bash
# Проверка сертификата
sudo certbot certificates

# Проверка конфигурации Nginx
sudo nginx -t

# Проверка SSL
openssl s_client -connect yourdomain.com:443 -servername yourdomain.com
```

**Решения:**
1. **Обновите сертификат:**
```bash
sudo certbot renew --dry-run
sudo certbot renew
```

2. **Проверьте конфигурацию Nginx:**
```nginx
server {
    listen 443 ssl http2;
    ssl_certificate /etc/letsencrypt/live/yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem;
    # ... остальные настройки
}
```

### Атаки на сервер

**Симптомы:**
- Высокая нагрузка на CPU
- Множественные неудачные попытки входа
- Подозрительная активность в логах

**Диагностика:**
```bash
# Проверка логов атак
sudo tail -f /var/log/fail2ban.log

# Проверка активных соединений
netstat -tulpn | grep :80
netstat -tulpn | grep :443

# Проверка логов Nginx
sudo tail -f /var/log/nginx/access.log | grep -E "(40[0-9]|50[0-9])"
```

**Решения:**
1. **Настройте Fail2Ban:**
```bash
# Проверьте статус
sudo systemctl status fail2ban

# Просмотр заблокированных IP
sudo fail2ban-client status nginx-http-auth
```

2. **Ограничьте rate limiting:**
```nginx
# В конфигурации Nginx
limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
limit_req_zone $binary_remote_addr zone=login:10m rate=5r/m;
```

## Проблемы с резервным копированием

### Бэкап не создается

**Симптомы:**
- Скрипт бэкапа завершается с ошибкой
- Отсутствуют файлы бэкапа
- Ошибки в логах cron

**Диагностика:**
```bash
# Проверка логов cron
sudo tail -f /var/log/cron.log

# Ручной запуск скрипта бэкапа
sudo /usr/local/bin/dockflow-backup.sh

# Проверка прав доступа
ls -la /usr/local/bin/dockflow-backup.sh
```

**Решения:**
1. **Проверьте права доступа:**
```bash
sudo chmod +x /usr/local/bin/dockflow-backup.sh
sudo chown root:root /usr/local/bin/dockflow-backup.sh
```

2. **Проверьте директорию бэкапов:**
```bash
sudo mkdir -p /backups/dockflow
sudo chown root:root /backups/dockflow
```

### Восстановление не работает

**Симптомы:**
- Ошибки при восстановлении базы данных
- Файлы не восстанавливаются
- Ошибки прав доступа

**Решения:**
1. **Проверьте права доступа к файлам бэкапа:**
```bash
ls -la /backups/dockflow/
sudo chown dockflow:dockflow /backups/dockflow/*
```

2. **Проверьте доступность базы данных:**
```bash
psql -U dockflow_user -d dockflow -c "SELECT 1;"
```

## Мониторинг и алерты

### Настройка мониторинга

```bash
# Создание скрипта мониторинга
sudo nano /usr/local/bin/dockflow-monitor.sh
```

```bash
#!/bin/bash

# Проверка доступности приложения
if ! curl -f http://localhost:8080/health > /dev/null 2>&1; then
    echo "DockFlow is down at $(date)" | mail -s "DockFlow Alert" admin@yourdomain.com
    pm2 restart dockflow
fi

# Проверка использования диска
DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ $DISK_USAGE -gt 80 ]; then
    echo "Disk usage is ${DISK_USAGE}% at $(date)" | mail -s "DockFlow Disk Alert" admin@yourdomain.com
fi

# Проверка использования памяти
MEMORY_USAGE=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
if [ $MEMORY_USAGE -gt 90 ]; then
    echo "Memory usage is ${MEMORY_USAGE}% at $(date)" | mail -s "DockFlow Memory Alert" admin@yourdomain.com
fi
```

### Настройка алертов

```bash
# Установка mailutils для отправки email
sudo apt install mailutils

# Настройка почты
sudo nano /etc/postfix/main.cf
# Добавьте: relayhost = [smtp.gmail.com]:587

# Добавление в crontab
sudo crontab -e
# Добавьте: */5 * * * * /usr/local/bin/dockflow-monitor.sh
```

## Полезные команды

### Диагностика системы

```bash
# Общая информация о системе
uname -a
lsb_release -a

# Использование ресурсов
htop
df -h
free -h

# Сетевые соединения
netstat -tulpn
ss -tulpn

# Процессы
ps aux --sort=-%cpu | head -10
ps aux --sort=-%mem | head -10
```

### Логи и отладка

```bash
# Логи приложения
pm2 logs dockflow --lines 100

# Логи Nginx
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/access.log

# Логи PostgreSQL
sudo tail -f /var/log/postgresql/postgresql-14-main.log

# Логи системы
sudo journalctl -u dockflow -f
sudo journalctl -u nginx -f
sudo journalctl -u postgresql -f
```

### Восстановление после сбоев

```bash
# Полное восстановление
sudo systemctl restart postgresql
pm2 restart dockflow
sudo systemctl restart nginx

# Проверка статуса
pm2 status
sudo systemctl status postgresql nginx
```

---

**Нужна помощь?** Создайте issue в репозитории или обратитесь к администратору системы.
