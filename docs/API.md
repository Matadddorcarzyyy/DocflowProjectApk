# API документация DockFlow

## Базовый URL

```
http://localhost:8080/api
```

## Аутентификация

Все API запросы (кроме аутентификации) требуют JWT токен в заголовке:

```
Authorization: Bearer <jwt_token>
```

## Endpoints

### Аутентификация

#### POST /api/auth/login

Вход в систему

**Запрос:**
```json
{
  "username": "lawyer1",
  "password": "password123"
}
```

**Ответ (200):**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "username": "lawyer1",
    "full_name": "Иван Петров",
    "role": "lawyer"
  }
}
```

**Ответ (401):**
```json
{
  "error": "Неверные учетные данные"
}
```

### Чаты

#### GET /api/chats

Получить список чатов

**Заголовки:**
```
Authorization: Bearer <token>
```

**Ответ (200):**
```json
[
  {
    "id": 1,
    "visitor_id": "visitor_123",
    "created_at": "2024-12-17T10:30:00Z"
  },
  {
    "id": 2,
    "visitor_id": "visitor_456",
    "created_at": "2024-12-17T11:15:00Z"
  }
]
```

#### POST /api/chats

Создать новый чат

**Запрос:**
```json
{
  "visitor_id": "visitor_789"
}
```

**Ответ (201):**
```json
{
  "id": 3,
  "visitor_id": "visitor_789",
  "created_at": "2024-12-17T12:00:00Z"
}
```

#### GET /api/chats/available

Получить доступные чаты для юристов

**Заголовки:**
```
Authorization: Bearer <token>
```

**Ответ (200):**
```json
[
  {
    "id": 1,
    "visitor_id": "visitor_123",
    "created_at": "2024-12-17T10:30:00Z",
    "isAssigned": false,
    "assignedToMe": false
  },
  {
    "id": 2,
    "visitor_id": "visitor_456",
    "created_at": "2024-12-17T11:15:00Z",
    "isAssigned": true,
    "assignedToMe": true
  }
]
```

#### POST /api/chats/:chatId/assign

Назначить чат юристу

**Параметры:**
- `chatId` (integer) - ID чата

**Заголовки:**
```
Authorization: Bearer <token>
```

**Ответ (200):**
```json
{
  "success": true,
  "chatId": 1,
  "assignedTo": 1
}
```

### Сообщения

#### GET /api/chats/:chatId/messages

Получить сообщения чата

**Параметры:**
- `chatId` (integer) - ID чата

**Заголовки:**
```
Authorization: Bearer <token>
```

**Ответ (200):**
```json
[
  {
    "id": 1,
    "sender": "visitor",
    "text": "Здравствуйте! Мне нужна помощь с договором",
    "created_at": "2024-12-17T10:30:00Z"
  },
  {
    "id": 2,
    "sender": "lawyer",
    "text": "Добро пожаловать! Чем могу помочь?",
    "lawyer_name": "Иван Петров",
    "created_at": "2024-12-17T10:31:00Z"
  }
]
```

## Socket.IO события

### Клиент → Сервер

#### auth

Аутентификация пользователя

```javascript
socket.emit('auth', {
  token: 'jwt_token_here'
});
```

#### join-chat

Присоединиться к чату

```javascript
socket.emit('join-chat', {
  chatId: 1
});
```

#### leave-chat

Покинуть чат

```javascript
socket.emit('leave-chat', {
  chatId: 1
});
```

#### message

Отправить сообщение

```javascript
socket.emit('message', {
  chatId: 1,
  text: 'Текст сообщения'
});
```

### Сервер → Клиент

#### presence

Статус пользователя

```javascript
socket.on('presence', (data) => {
  console.log(data);
  // {
  //   chatId: 1,
  //   online: true,
  //   role: 'lawyer',
  //   lawyer_name: 'Иван Петров'
  // }
});
```

#### message

Новое сообщение

```javascript
socket.on('message', (data) => {
  console.log(data);
  // {
  //   chatId: 1,
  //   sender: 'lawyer',
  //   text: 'Текст сообщения',
  //   lawyer_name: 'Иван Петров',
  //   created_at: '2024-12-17T10:30:00Z'
  // }
});
```

#### new-chat-assigned

Новый чат назначен

```javascript
socket.on('new-chat-assigned', (data) => {
  console.log(data);
  // {
  //   chatId: 1,
  //   visitor_id: 'visitor_123'
  // }
});
```

#### visitor-queued

Посетитель в очереди

```javascript
socket.on('visitor-queued', (data) => {
  console.log(data);
  // {
  //   position: 2,
  //   estimatedWait: 5
  // }
});
```

#### lawyer-assigned

Юрист назначен

```javascript
socket.on('lawyer-assigned', (data) => {
  console.log(data);
  // {
  //   lawyer_name: 'Иван Петров',
  //   chatId: 1
  // }
});
```

#### auto-join-chat

Автоматическое присоединение к чату

```javascript
socket.on('auto-join-chat', (data) => {
  console.log(data);
  // {
  //   chatId: 1
  // }
});
```

## Коды ошибок

### HTTP статусы

- `200` - Успешный запрос
- `201` - Ресурс создан
- `400` - Неверный запрос
- `401` - Не авторизован
- `403` - Доступ запрещен
- `404` - Ресурс не найден
- `500` - Внутренняя ошибка сервера

### Коды ошибок Socket.IO

- `auth_error` - Ошибка аутентификации
- `chat_not_found` - Чат не найден
- `permission_denied` - Нет прав доступа
- `validation_error` - Ошибка валидации данных

## Примеры использования

### JavaScript (Frontend)

```javascript
// Подключение к Socket.IO
const socket = io('http://localhost:8080');

// Аутентификация
socket.emit('auth', { token: 'jwt_token_here' });

// Присоединение к чату
socket.emit('join-chat', { chatId: 1 });

// Отправка сообщения
socket.emit('message', {
  chatId: 1,
  text: 'Привет! Как дела?'
});

// Обработка входящих сообщений
socket.on('message', (data) => {
  console.log('Новое сообщение:', data.text);
  // Добавить сообщение в UI
});

// Обработка присоединения юриста
socket.on('presence', (data) => {
  if (data.online && data.role === 'lawyer') {
    console.log(`Юрист ${data.lawyer_name} подключился`);
  }
});
```

### cURL примеры

```bash
# Вход в систему
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"lawyer1","password":"password123"}'

# Получение чатов
curl -X GET http://localhost:8080/api/chats \
  -H "Authorization: Bearer jwt_token_here"

# Создание чата
curl -X POST http://localhost:8080/api/chats \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer jwt_token_here" \
  -d '{"visitor_id":"visitor_123"}'

# Получение сообщений
curl -X GET http://localhost:8080/api/chats/1/messages \
  -H "Authorization: Bearer jwt_token_here"
```

### Python пример

```python
import requests
import socketio

# HTTP API
base_url = "http://localhost:8080/api"
headers = {"Authorization": "Bearer jwt_token_here"}

# Вход в систему
login_data = {"username": "lawyer1", "password": "password123"}
response = requests.post(f"{base_url}/auth/login", json=login_data)
token = response.json()["token"]

# Получение чатов
headers = {"Authorization": f"Bearer {token}"}
chats = requests.get(f"{base_url}/chats", headers=headers).json()

# Socket.IO
sio = socketio.Client()

@sio.event
def connect():
    print("Подключен к серверу")
    sio.emit('auth', {'token': token})

@sio.event
def message(data):
    print(f"Сообщение: {data['text']}")

@sio.event
def presence(data):
    print(f"Статус: {data}")

sio.connect('http://localhost:8080')
```

## Лимиты и ограничения

### Rate Limiting

- **API запросы:** 100 запросов в минуту на IP
- **Socket.IO события:** 50 событий в минуту на соединение
- **Сообщения:** 10 сообщений в минуту на чат

### Размеры данных

- **Сообщения:** максимум 1000 символов
- **Имена пользователей:** максимум 50 символов
- **Описания чатов:** максимум 500 символов

### Таймауты

- **HTTP запросы:** 30 секунд
- **Socket.IO соединения:** 5 минут неактивности
- **Чат сессии:** 24 часа

## Безопасность

### HTTPS

Все API запросы должны использовать HTTPS в продакшене:

```
https://yourdomain.com/api
```

### CORS

Настройки CORS для фронтенда:

```javascript
// Разрешенные домены
const allowedOrigins = [
  'http://localhost:3000',
  'https://yourdomain.com'
];
```

### Валидация данных

Все входящие данные валидируются:

- **Типы данных:** строгая проверка типов
- **Длина строк:** ограничения по длине
- **SQL инъекции:** параметризованные запросы
- **XSS:** экранирование HTML

---

**Следующий шаг:** [Развертывание в продакшене](PRODUCTION.md)