# Руководство по базе данных DockFlow

## Обзор

DockFlow использует PostgreSQL как основную базу данных для хранения:
- Пользователей и их ролей
- Чатов и сообщений
- Настроек системы
- Логов активности

## Схема базы данных

### Таблица `users`

```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100),
    role VARCHAR(20) DEFAULT 'visitor' CHECK (role IN ('visitor', 'lawyer', 'admin', 'owner')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP,
    is_active BOOLEAN DEFAULT true
);

-- Индексы
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_active ON users(is_active);
```

### Таблица `chats`

```sql
CREATE TABLE chats (
    id SERIAL PRIMARY KEY,
    visitor_id VARCHAR(100) NOT NULL,
    lawyer_id INTEGER REFERENCES users(id),
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'closed', 'archived')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    closed_at TIMESTAMP,
    last_activity TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Индексы
CREATE INDEX idx_chats_visitor_id ON chats(visitor_id);
CREATE INDEX idx_chats_lawyer_id ON chats(lawyer_id);
CREATE INDEX idx_chats_status ON chats(status);
CREATE INDEX idx_chats_created_at ON chats(created_at);
```

### Таблица `messages`

```sql
CREATE TABLE messages (
    id SERIAL PRIMARY KEY,
    chat_id INTEGER NOT NULL REFERENCES chats(id) ON DELETE CASCADE,
    sender VARCHAR(20) NOT NULL CHECK (sender IN ('visitor', 'lawyer', 'system', 'ai')),
    text TEXT NOT NULL,
    lawyer_name VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_read BOOLEAN DEFAULT false
);

-- Индексы
CREATE INDEX idx_messages_chat_id ON messages(chat_id);
CREATE INDEX idx_messages_sender ON messages(sender);
CREATE INDEX idx_messages_created_at ON messages(created_at);
CREATE INDEX idx_messages_is_read ON messages(is_read);
```

### Таблица `document_templates`

```sql
CREATE TABLE document_templates (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    category VARCHAR(50),
    template_content TEXT NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Индексы
CREATE INDEX idx_templates_category ON document_templates(category);
CREATE INDEX idx_templates_active ON document_templates(is_active);
```

### Таблица `system_settings`

```sql
CREATE TABLE system_settings (
    id SERIAL PRIMARY KEY,
    key VARCHAR(100) UNIQUE NOT NULL,
    value TEXT,
    description TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Начальные настройки
INSERT INTO system_settings (key, value, description) VALUES
('max_chats_per_lawyer', '5', 'Максимальное количество чатов на юриста'),
('queue_timeout_minutes', '30', 'Таймаут очереди в минутах'),
('ai_enabled', 'true', 'Включен ли AI ассистент'),
('maintenance_mode', 'false', 'Режим технического обслуживания');
```

## Установка и настройка

### 1. Создание базы данных

```bash
# Подключение к PostgreSQL
sudo -u postgres psql

# Создание пользователя
CREATE USER dockflow_user WITH PASSWORD 'secure_password';

# Создание базы данных
CREATE DATABASE dockflow OWNER dockflow_user;

# Предоставление прав
GRANT ALL PRIVILEGES ON DATABASE dockflow TO dockflow_user;

# Выход
\q
```

### 2. Создание таблиц

```bash
# Подключение к базе данных
psql -U dockflow_user -d dockflow -h localhost

# Выполнение SQL скрипта
\i database/schema.sql
```

### 3. Добавление тестовых данных

```bash
# Добавление тестовых пользователей
\i database/seed.sql
```

## Управление данными

### Резервное копирование

```bash
# Полный бэкап
pg_dump -U dockflow_user -h localhost -d dockflow > backup_$(date +%Y%m%d_%H%M%S).sql

# Сжатый бэкап
pg_dump -U dockflow_user -h localhost -d dockflow | gzip > backup_$(date +%Y%m%d_%H%M%S).sql.gz

# Только схема
pg_dump -U dockflow_user -h localhost -d dockflow --schema-only > schema_backup.sql

# Только данные
pg_dump -U dockflow_user -h localhost -d dockflow --data-only > data_backup.sql
```

### Восстановление

```bash
# Восстановление из полного бэкапа
psql -U dockflow_user -d dockflow < backup_20241217_143000.sql

# Восстановление из сжатого бэкапа
gunzip -c backup_20241217_143000.sql.gz | psql -U dockflow_user -d dockflow

# Восстановление в новую базу данных
createdb -U dockflow_user dockflow_restored
psql -U dockflow_user -d dockflow_restored < backup_20241217_143000.sql
```

## Мониторинг и оптимизация

### Проверка производительности

```sql
-- Размер базы данных
SELECT pg_size_pretty(pg_database_size('dockflow'));

-- Размер таблиц
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Медленные запросы
SELECT 
    query,
    mean_time,
    calls,
    total_time
FROM pg_stat_statements 
ORDER BY mean_time DESC 
LIMIT 10;
```

### Индексы и статистика

```sql
-- Статистика использования индексов
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch
FROM pg_stat_user_indexes
ORDER BY idx_scan DESC;

-- Неиспользуемые индексы
SELECT 
    schemaname,
    tablename,
    indexname
FROM pg_stat_user_indexes
WHERE idx_scan = 0;

-- Статистика таблиц
SELECT 
    schemaname,
    tablename,
    n_tup_ins as inserts,
    n_tup_upd as updates,
    n_tup_del as deletes,
    n_live_tup as live_tuples,
    n_dead_tup as dead_tuples
FROM pg_stat_user_tables;
```

### Очистка и обслуживание

```sql
-- Обновление статистики
ANALYZE;

-- Переиндексация таблиц
REINDEX TABLE messages;
REINDEX TABLE chats;
REINDEX TABLE users;

-- Очистка мертвых кортежей
VACUUM ANALYZE;

-- Полная очистка (только в нерабочее время)
VACUUM FULL;
```

## Безопасность

### Настройка доступа

```bash
# Редактирование pg_hba.conf
sudo nano /etc/postgresql/13/main/pg_hba.conf

# Добавление правил доступа
# local   dockflow        dockflow_user                    md5
# host    dockflow        dockflow_user    127.0.0.1/32   md5
# host    dockflow        dockflow_user    ::1/128         md5

# Перезапуск PostgreSQL
sudo systemctl restart postgresql
```

### Шифрование паролей

```sql
-- Проверка метода шифрования
SHOW password_encryption;

-- Установка SCRAM-SHA-256 (рекомендуется)
ALTER SYSTEM SET password_encryption = 'scram-sha-256';
SELECT pg_reload_conf();

-- Смена пароля пользователя
ALTER USER dockflow_user WITH PASSWORD 'new_secure_password';
```

### Аудит и логирование

```sql
-- Включение логирования подключений
ALTER SYSTEM SET log_connections = on;
ALTER SYSTEM SET log_disconnections = on;

-- Логирование медленных запросов
ALTER SYSTEM SET log_min_duration_statement = 1000; -- 1 секунда

-- Логирование DDL операций
ALTER SYSTEM SET log_statement = 'ddl';

-- Применение изменений
SELECT pg_reload_conf();
```

## Миграции

### Создание миграции

```bash
# Создание файла миграции
touch database/migrations/001_add_user_avatar.sql
```

Пример миграции:

```sql
-- 001_add_user_avatar.sql
-- Добавление поля avatar в таблицу users

-- Добавление колонки
ALTER TABLE users ADD COLUMN avatar_url VARCHAR(255);

-- Создание индекса
CREATE INDEX idx_users_avatar ON users(avatar_url);

-- Обновление существующих записей
UPDATE users SET avatar_url = '/default-avatar.png' WHERE avatar_url IS NULL;

-- Добавление ограничения
ALTER TABLE users ALTER COLUMN avatar_url SET NOT NULL;
```

### Применение миграций

```bash
# Скрипт для применения миграций
#!/bin/bash
# apply_migrations.sh

DB_USER="dockflow_user"
DB_NAME="dockflow"
MIGRATIONS_DIR="database/migrations"

for migration in $MIGRATIONS_DIR/*.sql; do
    echo "Applying migration: $(basename $migration)"
    psql -U $DB_USER -d $DB_NAME -f $migration
    if [ $? -eq 0 ]; then
        echo "Migration $(basename $migration) applied successfully"
    else
        echo "Error applying migration $(basename $migration)"
        exit 1
    fi
done
```

## Резервное копирование и восстановление

### Автоматическое резервное копирование

```bash
#!/bin/bash
# backup.sh - Скрипт автоматического резервного копирования

BACKUP_DIR="/backups/dockflow"
DB_USER="dockflow_user"
DB_NAME="dockflow"
RETENTION_DAYS=30

# Создание директории для бэкапов
mkdir -p $BACKUP_DIR

# Создание бэкапа
BACKUP_FILE="$BACKUP_DIR/dockflow_$(date +%Y%m%d_%H%M%S).sql.gz"
pg_dump -U $DB_USER -h localhost -d $DB_NAME | gzip > $BACKUP_FILE

# Проверка успешности
if [ $? -eq 0 ]; then
    echo "Backup created: $BACKUP_FILE"
    
    # Удаление старых бэкапов
    find $BACKUP_DIR -name "dockflow_*.sql.gz" -mtime +$RETENTION_DAYS -delete
    
    # Отправка уведомления (опционально)
    echo "Backup completed successfully" | mail -s "DockFlow Backup" admin@yourdomain.com
else
    echo "Backup failed!"
    echo "Backup failed at $(date)" | mail -s "DockFlow Backup Error" admin@yourdomain.com
fi
```

### Настройка cron для автоматических бэкапов

```bash
# Редактирование crontab
crontab -e

# Добавление задачи (ежедневно в 2:00)
0 2 * * * /path/to/backup.sh

# Еженедельный полный бэкап (воскресенье в 3:00)
0 3 * * 0 /path/to/full_backup.sh
```

## Мониторинг производительности

### Настройка pg_stat_statements

```sql
-- Включение расширения
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Настройка в postgresql.conf
-- shared_preload_libraries = 'pg_stat_statements'
-- track_activity_query_size = 2048
-- pg_stat_statements.max = 10000
-- pg_stat_statements.track = all
```

### Создание дашборда мониторинга

```sql
-- Представление для мониторинга
CREATE VIEW db_monitoring AS
SELECT 
    'Database Size' as metric,
    pg_size_pretty(pg_database_size('dockflow')) as value
UNION ALL
SELECT 
    'Active Connections',
    count(*)::text
FROM pg_stat_activity 
WHERE datname = 'dockflow'
UNION ALL
SELECT 
    'Slow Queries',
    count(*)::text
FROM pg_stat_statements 
WHERE mean_time > 1000;
```

---

**Следующий шаг:** [API документация](API.md)
