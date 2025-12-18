# Чеклист для деплоя на сервер

## ✅ Подготовка кода

- [x] FastAPI приложение готово
- [x] Миграции Alembic настроены
- [x] GitHub Actions workflow создан
- [x] Setup скрипт готов
- [x] Nginx конфиг готов
- [x] Systemd service готов

## 📋 Перед деплоем

### 1. Локально

- [ ] Проверить, что код работает локально
- [ ] Создать `.env.example` с примерами переменных
- [ ] Закоммитить и запушить в GitHub

### 2. На сервере

#### Первоначальная настройка

```bash
# 1. Установить зависимости системы
sudo apt update
sudo apt install -y python3 python3-pip python3-venv postgresql nginx certbot python3-certbot-nginx git

# 2. Создать пользователя для деплоя (если нет)
sudo adduser deploy
sudo usermod -aG sudo deploy
sudo su - deploy

# 3. Настроить SSH ключ для GitHub
ssh-keygen -t ed25519 -C "deploy@server"
# Добавить публичный ключ в GitHub: Settings → SSH and GPG keys

# 4. Клонировать репозиторий
cd /var/www
sudo mkdir -p /var/www
sudo chown deploy:deploy /var/www
git clone git@github.com:YOUR_USERNAME/YOUR_REPO.git boofmebel
cd boofmebel

# 5. Запустить setup
chmod +x deploy/setup.sh
./deploy/setup.sh boofmebel boofmebel.com
```

#### Настройка PostgreSQL

```bash
# Создать БД и пользователя
sudo -u postgres psql

CREATE DATABASE boofmebel;
CREATE USER boofmebel_user WITH PASSWORD 'secure_password_here';
GRANT ALL PRIVILEGES ON DATABASE boofmebel TO boofmebel_user;
\q
```

#### Настройка .env

```bash
cd /var/www/boofmebel
nano .env
```

```env
DATABASE_URL=postgresql+asyncpg://boofmebel_user:secure_password_here@localhost:5432/boofmebel
CORS_ORIGINS=https://boofmebel.com,http://localhost:3000
SENTRY_DSN=
SECRET_KEY=your_secret_key_here_use_openssl_rand_hex_32
```

#### Применить миграции

```bash
cd /var/www/boofmebel
source venv/bin/activate
alembic upgrade head
```

#### Настроить SSL

```bash
sudo certbot --nginx -d boofmebel.com -d www.boofmebel.com
```

#### Перезапустить сервисы

```bash
sudo systemctl restart boofmebel
sudo systemctl reload nginx
```

### 3. GitHub Secrets

В репозитории: Settings → Secrets and variables → Actions

Добавить:
- `SERVER_HOST` - IP или домен сервера (например, `123.45.67.89` или `server.example.com`)
- `SERVER_USER` - пользователь для SSH (например, `deploy`)
- `SERVER_SSH_KEY` - приватный SSH ключ (содержимое `~/.ssh/id_rsa` или `~/.ssh/id_ed25519`)

**Как получить SSH ключ:**
```bash
# На вашем локальном компьютере
cat ~/.ssh/id_rsa
# Или если используете ed25519
cat ~/.ssh/id_ed25519
```

Скопировать весь вывод (включая `-----BEGIN OPENSSH PRIVATE KEY-----` и `-----END OPENSSH PRIVATE KEY-----`)

## 🧪 Проверка после деплоя

```bash
# 1. Проверить статус сервиса
sudo systemctl status boofmebel

# 2. Проверить логи
sudo journalctl -u boofmebel -f

# 3. Проверить Nginx
sudo nginx -t
sudo systemctl status nginx

# 4. Проверить доступность
curl https://boofmebel.com/health
curl https://boofmebel.com/ready

# 5. Проверить API
curl https://boofmebel.com/
```

## 🔄 Автоматический деплой

После настройки secrets, каждый push в `main`/`master` автоматически:
1. Устанавливает зависимости
2. Подключается к серверу
3. Делает `git pull`
4. Обновляет зависимости
5. Применяет миграции
6. Перезапускает сервис

## 🐛 Troubleshooting

### Сервис не запускается

```bash
# Проверить логи
sudo journalctl -u boofmebel -n 50

# Проверить права
ls -la /var/www/boofmebel

# Проверить .env
cat /var/www/boofmebel/.env
```

### Nginx ошибки

```bash
# Проверить конфиг
sudo nginx -t

# Проверить логи
sudo tail -f /var/log/nginx/boofmebel_error.log
```

### Проблемы с БД

```bash
# Проверить подключение
sudo -u postgres psql -d boofmebel -U boofmebel_user

# Проверить миграции
cd /var/www/boofmebel
source venv/bin/activate
alembic current
alembic history
```

## 📝 Добавление второго сайта

```bash
cd /var/www
git clone git@github.com:YOUR_USERNAME/YOUR_REPO.git site2
cd site2

# В setup.sh изменить порт на 8001
# Или создать отдельный скрипт

# Создать БД
sudo -u postgres createdb site2

# Запустить setup
./deploy/setup.sh site2 site2.com

# В systemd service изменить:
# --bind 127.0.0.1:8001
# И в Nginx upstream: server 127.0.0.1:8001;
```

