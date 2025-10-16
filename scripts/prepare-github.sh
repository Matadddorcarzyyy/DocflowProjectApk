# Скрипт для загрузки проекта на GitHub и деплоя через Railway

echo "🚀 Подготовка проекта для деплоя через Railway..."

# Создаем .gitignore если его нет
if [ ! -f .gitignore ]; then
cat > .gitignore << EOF
# Dependencies
node_modules/
server/node_modules/

# Environment variables
.env
.env.local
.env.production

# Logs
*.log
npm-debug.log*

# Runtime data
pids
*.pid
*.seed

# Coverage directory used by tools like istanbul
coverage/

# OS generated files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# IDE
.vscode/
.idea/
*.swp
*.swo

# Uploads
server/uploads/*
!server/uploads/.gitkeep
EOF
fi

# Создаем пустой файл для uploads директории
mkdir -p server/uploads
touch server/uploads/.gitkeep

echo "✅ Файлы подготовлены!"
echo ""
echo "📋 Следующие шаги:"
echo "1. Создайте репозиторий на GitHub"
echo "2. Загрузите файлы:"
echo "   git init"
echo "   git add ."
echo "   git commit -m 'Initial commit'"
echo "   git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git"
echo "   git push -u origin main"
echo ""
echo "3. Зайдите на https://railway.app"
echo "4. Войдите через GitHub"
echo "5. Нажмите 'Deploy from GitHub'"
echo "6. Выберите ваш репозиторий"
echo "7. Добавьте переменные окружения в настройках проекта"
echo ""
echo "🌐 Ваш сайт будет доступен по адресу: https://YOUR_APP.railway.app"
