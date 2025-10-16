# DocFlow - Простой деплой через веб-сервисы

## 🚀 Вариант 1: Railway (Рекомендуется)

Railway - самый простой способ для Node.js приложений.

### Шаги:
1. Зайдите на https://railway.app
2. Войдите через GitHub
3. Нажмите "New Project" → "Deploy from GitHub repo"
4. Подключите ваш репозиторий
5. Railway автоматически определит Node.js и развернет

### Настройка переменных в Railway:
```
DATABASE_URL=postgresql://postgres:password@host:port/dbname
SESSION_SECRET=your_secret_here
ADMIN_EMAIL=admin@example.com
ADMIN_PASSWORD=admin123
ALLOWED_ORIGINS=https://your-app.railway.app
```

### Результат:
- Получите URL вида: `https://your-app.railway.app`
- База данных PostgreSQL включена
- Автоматические деплои при push в GitHub

---

## 🌐 Вариант 2: Render

### Для фронтенда (статика):
1. Зайдите на https://render.com
2. "New" → "Static Site"
3. Подключите GitHub репозиторий
4. Build Command: `echo "Static site"`
5. Publish Directory: `/` (корень)

### Для бэкенда (API):
1. "New" → "Web Service"
2. Подключите GitHub репозиторий
3. Root Directory: `server`
4. Build Command: `npm install`
5. Start Command: `npm start`

### Настройка переменных в Render:
```
DATABASE_URL=postgresql://user:pass@host:port/db
SESSION_SECRET=your_secret
ADMIN_EMAIL=admin@example.com
ADMIN_PASSWORD=admin123
```

---

## ☁️ Вариант 3: Vercel (для фронтенда) + Railway (для API)

### Фронтенд на Vercel:
1. Зайдите на https://vercel.com
2. "Import Project" → GitHub репозиторий
3. Framework Preset: "Other"
4. Build Command: `echo "Static"`
5. Output Directory: `/`

### API на Railway:
- Как описано выше в варианте 1

---

## 🔧 Вариант 4: Heroku (классический)

### Подготовка файлов:
1. Создайте `Procfile` в корне:
```
web: cd server && npm start
```

2. Создайте `package.json` в корне:
```json
{
  "name": "docflow",
  "scripts": {
    "start": "cd server && npm start"
  }
}
```

### Деплой:
1. Установите Heroku CLI
2. `heroku login`
3. `heroku create your-app-name`
4. `heroku addons:create heroku-postgresql:hobby-dev`
5. `git push heroku main`

---

## 📱 Вариант 5: Netlify (фронтенд) + Supabase (база)

### Фронтенд на Netlify:
1. Зайдите на https://netlify.com
2. "New site from Git" → GitHub
3. Build command: `echo "Static"`
4. Publish directory: `/`

### База данных на Supabase:
1. Зайдите на https://supabase.com
2. Создайте новый проект
3. Получите connection string
4. Используйте для API

---

## 🎯 Самый простой способ (Railway):

1. **Создайте GitHub репозиторий** с вашим кодом
2. **Зайдите на Railway.app** и войдите через GitHub
3. **Нажмите "Deploy from GitHub"**
4. **Выберите ваш репозиторий**
5. **Добавьте переменные окружения** в настройках проекта
6. **Готово!** Получите URL сайта

### Переменные для Railway:
```
NODE_ENV=production
DATABASE_URL=postgresql://postgres:password@containers-us-west-xxx.railway.app:5432/railway
SESSION_SECRET=your_very_long_secret_key_here
ADMIN_EMAIL=admin@yourdomain.com
ADMIN_PASSWORD=your_admin_password
ADMIN_FULL_NAME=Admin
ALLOWED_ORIGINS=https://your-app.railway.app
PORT=8080
```

Railway автоматически:
- Создаст PostgreSQL базу
- Развернет ваш Node.js API
- Настроит домен
- Обеспечит HTTPS

**Результат:** Ваш сайт будет доступен по адресу `https://your-app.railway.app`
