# BoofMebel - Интернет-магазин мягкой мебели

Современный интернет-магазин для продажи мягкой мебели собственного производства с интеграцией Яндекс Доставки.

## 🚀 Технологии

### Backend
- **FastAPI** - современный async веб-фреймворк
- **SQLAlchemy 2.0** (async) - ORM
- **PostgreSQL** - база данных
- **Alembic** - миграции БД
- **JWT** - аутентификация (access token в памяти, refresh token в HttpOnly cookie)
- **Gunicorn + Uvicorn** - ASGI сервер для продакшена

### Frontend
- Статический HTML/CSS/JS (в процессе миграции на Angular 16+)

### DevOps
- **GitHub Actions** - CI/CD
- **Nginx** - reverse proxy, SSL/TLS
- **Systemd** - управление сервисами
- **Let's Encrypt** - SSL сертификаты

## 📁 Структура проекта

```
.
├── app/
│   ├── core/           # Конфигурация, БД, безопасность, логирование
│   ├── models/         # SQLAlchemy модели
│   ├── repositories/   # Доступ к БД
│   ├── services/       # Бизнес-логика
│   ├── schemas/        # Pydantic схемы
│   ├── routers/        # API endpoints
│   └── main.py         # Точка входа FastAPI
├── migrations/         # Alembic миграции
├── deploy/             # Скрипты деплоя
├── .github/
│   └── workflows/      # GitHub Actions
└── requirements.txt    # Python зависимости
```

## 🛠️ Локальная разработка

### Требования
- Python 3.11+
- PostgreSQL 14+
- Git

### Установка

```bash
# 1. Клонировать репозиторий
git clone <repo-url>
cd Сайт

# 2. Создать виртуальное окружение
python3 -m venv venv
source venv/bin/activate  # Linux/Mac
# или
venv\Scripts\activate  # Windows

# 3. Установить зависимости
pip install -r requirements.txt

# 4. Создать .env файл
cp .env.example .env
# Отредактировать .env с реальными данными

# 5. Создать БД PostgreSQL
createdb boofmebel

# 6. Применить миграции
alembic upgrade head

# 7. Запустить сервер
uvicorn app.main:app --reload
```

Сервер будет доступен на `http://localhost:8000`

## 📚 API Endpoints

### Health
- `GET /health` - проверка здоровья
- `GET /ready` - готовность к работе

### Auth
- `POST /auth/login` - вход (возвращает access token, устанавливает refresh token в cookie)
- `POST /auth/refresh` - обновление access token
- `POST /auth/logout` - выход
- `GET /auth/me` - информация о текущем пользователе

## 🚀 Деплой на сервер

Подробная инструкция в [DEPLOY_CHECKLIST.md](DEPLOY_CHECKLIST.md)

### Быстрый старт

```bash
# На сервере
cd /var/www
git clone <repo-url> boofmebel
cd boofmebel
./deploy/setup.sh boofmebel boofmebel.com
```

### GitHub Secrets

Настроить в репозитории: Settings → Secrets and variables → Actions
- `SERVER_HOST` - IP или домен сервера
- `SERVER_USER` - пользователь для SSH
- `SERVER_SSH_KEY` - приватный SSH ключ

## 🔒 Безопасность

- ✅ JWT с ротацией refresh токенов
- ✅ HttpOnly Secure SameSite cookies
- ✅ Rate limiting для критичных endpoints
- ✅ Security headers (HSTS, CSP, X-Frame-Options и т.д.)
- ✅ CORS с белым списком origin
- ✅ Валидация входных данных (Pydantic)
- ✅ Хеширование паролей (bcrypt)

## 📝 Миграции БД

```bash
# Создать новую миграцию
alembic revision --autogenerate -m "Description"

# Применить миграции
alembic upgrade head

# Откатить последнюю миграцию
alembic downgrade -1
```

## 🧪 Тестирование

```bash
# Запустить тесты (когда будут добавлены)
pytest

# С coverage
pytest --cov=app
```

## 📖 Документация API

После запуска сервера:
- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

## 🤝 Вклад в проект

1. Создать ветку: `git checkout -b feature/amazing-feature`
2. Закоммитить: `git commit -m 'Add amazing feature'`
3. Запушить: `git push origin feature/amazing-feature`
4. Создать Pull Request

## 📄 Лицензия

[Указать лицензию]

## 👥 Авторы

[Указать авторов]

