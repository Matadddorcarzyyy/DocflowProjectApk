#!/bin/bash

# Скрипт деплоя DocFlow на сервер
# Использование: ./deploy.sh your-server-ip

set -e

SERVER_IP=$1
if [ -z "$SERVER_IP" ]; then
    echo "Использование: $0 <server-ip>"
    exit 1
fi

echo "🚀 Деплой DocFlow на $SERVER_IP"

# Создаем директорию фронтенда
echo "📁 Подготовка файлов фронтенда..."
mkdir -p frontend
cp *.html frontend/
cp *.xml frontend/
cp *.txt frontend/

# Создаем архив для передачи
echo "📦 Создание архива..."
tar -czf docflow-deploy.tar.gz \
    docker-compose.prod.yml \
    nginx.conf \
    env.example \
    server/ \
    frontend/

# Передаем файлы на сервер
echo "📤 Передача файлов на сервер..."
scp docflow-deploy.tar.gz root@$SERVER_IP:/root/
scp deploy-remote.sh root@$SERVER_IP:/root/

# Запускаем деплой на сервере
echo "🔧 Запуск деплоя на сервере..."
ssh root@$SERVER_IP "chmod +x deploy-remote.sh && ./deploy-remote.sh"

# Очистка
rm -rf frontend docflow-deploy.tar.gz

echo "✅ Деплой завершен!"
echo "🌐 Сайт доступен по адресу: http://$SERVER_IP"
echo "🔧 Админ панель: http://$SERVER_IP/admin.html"
