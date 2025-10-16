# DocFlow - Инструкция по деплою

## Быстрый старт

### 1. Подготовка сервера
- VPS с Ubuntu 20.04+ или CentOS 8+
- Минимум 2GB RAM, 20GB диска
- Root доступ или sudo права

### 2. Автоматический деплой
```bash
# На вашем компьютере
./deploy.sh YOUR_SERVER_IP
```

### 3. Ручной деплой

#### На сервере:
```bash
# Установка Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Установка Docker Compose
curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Копирование файлов проекта
scp -r . root@YOUR_SERVER_IP:/root/docflow/
```

#### Настройка:
```bash
cd /root/docflow
cp env.example .env
nano .env  # Отредактируйте переменные
```

#### Запуск:
```bash
docker-compose -f docker-compose.prod.yml up -d --build
```

## Настройка переменных окружения

Отредактируйте файл `.env`:

```bash
# Обязательные
DB_PASSWORD=strong_password_123
SESSION_SECRET=very_long_random_string_here
ADMIN_EMAIL=admin@yourdomain.com
ADMIN_PASSWORD=admin_password_123
ALLOWED_ORIGINS=https://yourdomain.com

# Опциональные
YOOKASSA_SHOP_ID=your_shop_id
YOOKASSA_SECRET_KEY=your_secret_key
PAY_RETURN_URL=https://yourdomain.com
```

## Настройка домена

### 1. В панели управления хостингом:
- Добавьте A-запись: `yourdomain.com` → `YOUR_SERVER_IP`
- Добавьте CNAME: `www.yourdomain.com` → `yourdomain.com`

### 2. Обновите nginx.conf:
```bash
# Замените server_name _; на:
server_name yourdomain.com www.yourdomain.com;
```

### 3. Настройте SSL (Let's Encrypt):
```bash
# Установка certbot
apt install certbot python3-certbot-nginx

# Получение сертификата
certbot --nginx -d yourdomain.com -d www.yourdomain.com

# Автообновление
crontab -e
# Добавьте: 0 12 * * * /usr/bin/certbot renew --quiet
```

## Проверка работы

После деплоя проверьте:
- Главная страница: `http://YOUR_SERVER_IP`
- Админ панель: `http://YOUR_SERVER_IP/admin.html`
- API здоровье: `http://YOUR_SERVER_IP/api/health`

## Управление сервисами

```bash
# Статус
docker-compose -f docker-compose.prod.yml ps

# Логи
docker-compose -f docker-compose.prod.yml logs -f

# Перезапуск
docker-compose -f docker-compose.prod.yml restart

# Остановка
docker-compose -f docker-compose.prod.yml down

# Обновление
git pull
docker-compose -f docker-compose.prod.yml up -d --build
```

## Безопасность

1. **Смените пароли по умолчанию**
2. **Настройте файрвол:**
   ```bash
   ufw allow 22
   ufw allow 80
   ufw allow 443
   ufw enable
   ```
3. **Регулярно обновляйте систему**
4. **Настройте резервное копирование БД**

## Мониторинг

```bash
# Использование ресурсов
docker stats

# Логи приложения
docker-compose -f docker-compose.prod.yml logs api

# Логи базы данных
docker-compose -f docker-compose.prod.yml logs db
```

## Решение проблем

### Сайт не открывается:
```bash
# Проверьте статус сервисов
docker-compose -f docker-compose.prod.yml ps

# Проверьте логи
docker-compose -f docker-compose.prod.yml logs
```

### Ошибки базы данных:
```bash
# Пересоздание БД
docker-compose -f docker-compose.prod.yml down -v
docker-compose -f docker-compose.prod.yml up -d --build
```

### Проблемы с SSL:
```bash
# Проверка сертификата
certbot certificates

# Обновление сертификата
certbot renew --force-renewal
```
