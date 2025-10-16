# DocFlow - Быстрый деплой через Railway

## 🎯 Самый простой способ (5 минут):

### 1. Подготовка файлов
```bash
# Запустите скрипт подготовки
bash prepare-github.sh
```

### 2. Создание GitHub репозитория
1. Зайдите на https://github.com
2. Нажмите "New repository"
3. Название: `docflow` (или любое другое)
4. Сделайте репозиторий публичным
5. Нажмите "Create repository"

### 3. Загрузка кода на GitHub
```bash
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git
git push -u origin main
```

### 4. Деплой через Railway
1. Зайдите на https://railway.app
2. Нажмите "Login" → выберите GitHub
3. Нажмите "Deploy from GitHub repo"
4. Выберите ваш репозиторий `docflow`
5. Railway автоматически определит Node.js и начнет деплой

### 5. Настройка переменных окружения
В настройках проекта Railway добавьте:

```
SESSION_SECRET=your_very_long_random_secret_key_here_123456789
ADMIN_EMAIL=admin@example.com
ADMIN_PASSWORD=admin123
ADMIN_FULL_NAME=Site Administrator
ALLOWED_ORIGINS=https://your-app.railway.app
PORT=8080
```

**ВАЖНО:** `DATABASE_URL` Railway создаст автоматически!

### 6. Готово! 🎉
- Ваш сайт будет доступен по адресу: `https://your-app.railway.app`
- Админ панель: `https://your-app.railway.app/admin.html`
- API: `https://your-app.railway.app/api/health`

---

## 🔧 Альтернативные сервисы:

### Render.com (бесплатно):
1. Зайдите на https://render.com
2. "New" → "Web Service"
3. Подключите GitHub репозиторий
4. Root Directory: `server`
5. Build Command: `npm install`
6. Start Command: `npm start`

### Heroku (классический):
1. Установите Heroku CLI
2. `heroku login`
3. `heroku create your-app-name`
4. `heroku addons:create heroku-postgresql:hobby-dev`
5. `git push heroku main`

### Vercel + Supabase:
- Фронтенд на Vercel
- База данных на Supabase
- API на Vercel Functions

---

## 📱 Мобильная версия:
Railway автоматически оптимизирует сайт для мобильных устройств.

## 🔒 Безопасность:
- HTTPS включен автоматически
- Переменные окружения защищены
- База данных изолирована

## 💰 Стоимость:
- Railway: бесплатно до 500 часов в месяц
- Render: бесплатно до 750 часов в месяц
- Heroku: бесплатно до 550 часов в месяц

---

## 🆘 Если что-то не работает:

### Проверьте логи:
1. В Railway Dashboard → ваш проект → "Deployments"
2. Нажмите на последний деплой
3. Посмотрите логи в разделе "Build Logs" и "Deploy Logs"

### Частые проблемы:
- **Ошибка базы данных**: проверьте переменную `DATABASE_URL`
- **Ошибка авторизации**: проверьте `SESSION_SECRET`
- **CORS ошибки**: проверьте `ALLOWED_ORIGINS`

### Поддержка:
- Railway Discord: https://discord.gg/railway
- Документация: https://docs.railway.app
