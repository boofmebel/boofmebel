# Деплой на сервер с поддержкой нескольких сайтов

## Архитектура

```
Сервер
├── /var/www/
│   ├── boofmebel/          # Сайт 1
│   │   ├── app/
│   │   ├── venv/
│   │   ├── logs/
│   │   └── .env
│   ├── site2/              # Сайт 2
│   └── site3/              # Сайт 3
├── /etc/nginx/
│   ├── sites-available/
│   │   ├── boofmebel
│   │   ├── site2
│   │   └── site3
│   └── sites-enabled/      # Symlinks
└── /etc/systemd/system/
    ├── boofmebel.service
    ├── site2.service
    └── site3.service
```

## Быстрый старт

### 1. На сервере: Первоначальная настройка

```bash
# Клонировать репозиторий
cd /var/www
git clone <YOUR_GITHUB_REPO_URL> boofmebel
cd boofmebel

# Запустить setup скрипт
chmod +x deploy/setup.sh
./deploy/setup.sh boofmebel boofmebel.com
```

### 2. Настройка GitHub Secrets

В GitHub репозитории: Settings → Secrets and variables → Actions

Добавить:
- `SERVER_HOST` - IP или домен сервера
- `SERVER_USER` - пользователь для SSH (например, `deploy`)
- `SERVER_SSH_KEY` - приватный SSH ключ для доступа к серверу

### 3. Настройка PostgreSQL

```bash
# Создать БД для каждого сайта
sudo -u postgres psql
CREATE DATABASE boofmebel;
CREATE USER boofmebel_user WITH PASSWORD 'secure_password';
GRANT ALL PRIVILEGES ON DATABASE boofmebel TO boofmebel_user;
\q
```

### 4. Настройка SSL (Let's Encrypt)

```bash
sudo certbot --nginx -d boofmebel.com -d www.boofmebel.com
```

### 5. Проверка

```bash
# Статус сервиса
sudo systemctl status boofmebel

# Логи
sudo journalctl -u boofmebel -f

# Nginx
sudo nginx -t
sudo systemctl reload nginx
```

## Добавление нового сайта

```bash
# 1. Создать директорию и клонировать репозиторий
cd /var/www
git clone <REPO_URL> newsite
cd newsite

# 2. Запустить setup с другим именем и портом
./deploy/setup.sh newsite newsite.com
# В setup.sh изменить порт на 8001, 8002 и т.д.

# 3. Создать БД
sudo -u postgres createdb newsite

# 4. Настроить SSL
sudo certbot --nginx -d newsite.com

# 5. Перезапустить
sudo systemctl restart newsite
sudo systemctl reload nginx
```

## Автоматический деплой через GitHub Actions

После настройки secrets, каждый push в `main`/`master` автоматически:
1. Устанавливает зависимости
2. Запускает тесты (если есть)
3. Подключается к серверу по SSH
4. Делает `git pull`
5. Обновляет зависимости
6. Применяет миграции
7. Перезапускает сервис
8. Перезагружает Nginx

## Порты для разных сайтов

Каждый сайт должен использовать свой порт:
- `boofmebel`: 8000
- `site2`: 8001
- `site3`: 8002
- и т.д.

Изменить порт в:
1. Systemd service файл (`--bind 127.0.0.1:8001`)
2. Nginx upstream (`server 127.0.0.1:8001`)

## Мониторинг

```bash
# Все сервисы
sudo systemctl list-units --type=service | grep -E "boofmebel|site2"

# Логи всех сайтов
sudo tail -f /var/log/nginx/*_access.log
sudo tail -f /var/log/nginx/*_error.log

# Логи приложений
sudo journalctl -u boofmebel -f
```

## Резервное копирование

```bash
# Бэкап БД
pg_dump -U boofmebel_user boofmebel > backup_$(date +%Y%m%d).sql

# Бэкап кода
tar -czf backup_code_$(date +%Y%m%d).tar.gz /var/www/boofmebel
```

