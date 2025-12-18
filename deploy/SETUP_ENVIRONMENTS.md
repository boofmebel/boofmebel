# Настройка окружений на сервере

## Текущая ситуация

**GitHub Actions (deploy.yml):**
- ✅ `main` → деплой в `/var/www/boofmebel` (продакшн, порт 80)
- ✅ `dev` → деплой в `/var/www/boofmebel-test` (тест, порт 9000)

**Но на сервере нужно сначала создать оба окружения!**

## Шаги для настройки

### 1. Создать продакшн окружение (если ещё не создано)

```bash
# На сервере
cd /path/to/repo
./deploy/setup.sh boofmebel boofmebel.com prod
```

Создаст:
- `/var/www/boofmebel` - директория
- `boofmebel.service` - systemd сервис
- Nginx конфиг на порту 80 (HTTPS)

### 2. Создать тестовое окружение

```bash
# На сервере
cd /path/to/repo
./deploy/setup.sh boofmebel boofmebel-test.com test
```

Создаст:
- `/var/www/boofmebel-test` - директория
- `boofmebel-test.service` - systemd сервис
- Nginx конфиг на порту 9000 (HTTP)

### 3. Проверить что работает

```bash
# Проверить сервисы
sudo systemctl status boofmebel.service
sudo systemctl status boofmebel-test.service

# Проверить Nginx
sudo nginx -t
sudo systemctl status nginx

# Проверить порты
sudo netstat -tlnp | grep -E ':(80|9000)'
```

## После настройки

**Автоматический деплой будет работать:**
- Push в `main` → `/var/www/boofmebel` (порт 80)
- Push в `dev` → `/var/www/boofmebel-test` (порт 9000)

## Важно

⚠️ **Тестовое окружение нужно создать ОДИН РАЗ вручную на сервере!**

После этого GitHub Actions будет автоматически деплоить в нужную директорию.

