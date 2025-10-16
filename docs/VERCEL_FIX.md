# Vercel деплой - исправленная инструкция

## 🚀 Деплой на Vercel (исправлено)

### Проблема была:
Vercel искал папку `public`, а у нас файлы в корне.

### Решение:
Я создал правильную структуру файлов и конфигурацию.

---

## 📁 Структура файлов (теперь правильная):

```
SITE/
├── public/                 # Статические файлы для Vercel
│   ├── index.html
│   ├── admin.html
│   ├── lawyer.html
│   ├── vacancies.html
│   ├── privacy.html
│   ├── sitemap.xml
│   ├── robots.txt
│   └── vercel.json
├── server/                 # API сервер
│   ├── src/
│   │   └── index.js
│   ├── package.json
│   └── ...
├── vercel.json            # Конфигурация Vercel
├── package.json           # Корневой package.json
└── ...
```

---

## 🔧 Пошаговая инструкция для Vercel:

### ШАГ 1: Подготовка (уже сделано)
✅ Создана папка `public/`
✅ Скопированы HTML файлы в `public/`
✅ Создан `vercel.json` в корне
✅ Создан `vercel.json` в `public/`

### ШАГ 2: Загрузка на GitHub
```bash
git add .
git commit -m "Fix Vercel deployment structure"
git push
```

### ШАГ 3: Деплой на Vercel
1. **Зайдите на https://vercel.com**
2. **Войдите через GitHub**
3. **Нажмите "New Project"**
4. **Выберите ваш репозиторий**
5. **Настройки проекта:**
   - Framework Preset: **"Other"**
   - Root Directory: **"."** (корень)
   - Build Command: **оставьте пустым**
   - Output Directory: **"public"**
6. **Нажмите "Deploy"**

### ШАГ 4: Настройка переменных окружения
В настройках проекта Vercel добавьте:

```
NODE_ENV=production
SESSION_SECRET=your_very_long_random_secret_key_here
ADMIN_EMAIL=admin@example.com
ADMIN_PASSWORD=admin123
ADMIN_FULL_NAME=Site Administrator
ALLOWED_ORIGINS=https://your-app.vercel.app
```

**ВАЖНО:** Для базы данных используйте внешний сервис:
- **Supabase** (рекомендуется): https://supabase.com
- **PlanetScale**: https://planetscale.com
- **Railway PostgreSQL**: https://railway.app

### ШАГ 5: Настройка базы данных (Supabase)
1. **Зайдите на https://supabase.com**
2. **Создайте новый проект**
3. **Получите connection string** в Settings → Database
4. **Добавьте в Vercel переменные:**
   ```
   DATABASE_URL=postgresql://postgres:password@host:port/dbname
   ```

---

## 🌐 Альтернативные варианты (если Vercel не работает):

### 1. Netlify (только фронтенд) + Supabase (база)
```bash
# Настройки Netlify:
# Build command: echo "Static site"
# Publish directory: public
```

### 2. Render.com (полный стек)
```bash
# Настройки Render:
# Root Directory: server
# Build Command: npm install
# Start Command: npm start
```

### 3. Heroku (классический)
```bash
# Уже настроен Procfile
heroku create your-app-name
heroku addons:create heroku-postgresql:hobby-dev
git push heroku main
```

---

## 🔍 Проверка работы:

После деплоя проверьте:
- ✅ Главная: `https://your-app.vercel.app`
- ✅ Админ: `https://your-app.vercel.app/admin.html`
- ✅ API: `https://your-app.vercel.app/api/health`

---

## 🆘 Если все еще не работает:

### Вариант A: Только статика на Vercel
1. Удалите `server/` папку из репозитория
2. Деплойте только `public/` папку
3. Используйте внешний API (например, на Railway)

### Вариант B: Render.com (проще)
1. Зайдите на https://render.com
2. "New" → "Web Service"
3. Подключите GitHub
4. Root Directory: `server`
5. Build Command: `npm install`
6. Start Command: `npm start`

Какой вариант попробуем?
