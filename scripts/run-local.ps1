$env:NODE_ENV = "development"
# Если есть файл .env, dotenv подхватит его автоматически
# В противном случае можно раскомментировать локальные переменные ниже:
# $env:PORT = "8080"
# $env:DATABASE_URL = "postgres://postgres:123@localhost:5432/docflow"
# $env:ALLOWED_ORIGINS = "http://localhost,http://127.0.0.1"

node src/index.js



