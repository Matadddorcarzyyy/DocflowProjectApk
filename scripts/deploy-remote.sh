#!/bin/bash

# Скрипт для выполнения на сервере
set -e

echo "🔧 Установка зависимостей..."

# Обновляем систему
apt update && apt upgrade -y

# Устанавливаем Docker и Docker Compose
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
fi

if ! command -v docker-compose &> /dev/null; then
    curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
fi

# Распаковываем файлы
echo "📦 Распаковка файлов..."
tar -xzf docflow-deploy.tar.gz
rm docflow-deploy.tar.gz

# Настраиваем переменные окружения
echo "⚙️ Настройка окружения..."
if [ ! -f .env ]; then
    cp env.example .env
    echo "⚠️  ВАЖНО: Отредактируйте файл .env с реальными значениями!"
    echo "   nano .env"
fi

# Создаем директории
mkdir -p ssl
mkdir -p server/uploads

# Запускаем сервисы
echo "🚀 Запуск сервисов..."
docker-compose -f docker-compose.prod.yml down || true
docker-compose -f docker-compose.prod.yml up -d --build

# Ждем запуска базы данных
echo "⏳ Ожидание запуска базы данных..."
sleep 10

# Проверяем статус
echo "📊 Статус сервисов:"
docker-compose -f docker-compose.prod.yml ps

echo "✅ Деплой завершен!"
echo "🌐 Сайт доступен по адресу: http://$(curl -s ifconfig.me)"
echo "🔧 Админ панель: http://$(curl -s ifconfig.me)/admin.html"
echo ""
echo "📝 Следующие шаги:"
echo "1. Отредактируйте .env файл с реальными значениями"
echo "2. Перезапустите сервисы: docker-compose -f docker-compose.prod.yml restart"
echo "3. Настройте SSL сертификат для HTTPS"
echo "4. Настройте домен в панели управления хостингом"
