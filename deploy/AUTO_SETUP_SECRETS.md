# Автоматическая настройка GitHub Secrets

Я создал 2 скрипта для автоматического добавления секретов в GitHub.

## 🚀 Вариант 1: Через GitHub CLI (рекомендуется)

### Установка GitHub CLI

**macOS:**
```bash
brew install gh
```

**Linux:**
```bash
# Ubuntu/Debian
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh
```

**Windows:**
Скачать с https://cli.github.com/

### Использование

```bash
# 1. Авторизоваться в GitHub CLI
gh auth login

# 2. Запустить скрипт
cd deploy
./add-github-secrets.sh
```

Скрипт запросит:
- Репозиторий (формат: `username/repo-name`)
- IP/домен сервера
- Пользователь SSH (по умолчанию: `deploy`)
- Путь к SSH ключу (по умолчанию: `~/.ssh/id_ed25519`)

## 🐍 Вариант 2: Через Python скрипт

### Установка зависимостей

```bash
pip install requests pynacl python-dotenv
```

### Использование

```bash
# 1. Создать GitHub Personal Access Token
# GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
# Права: repo (полный доступ к репозиториям)

# 2. Установить токен в переменную окружения
export GITHUB_TOKEN="your_token_here"

# Или создать .env файл:
echo "GITHUB_TOKEN=your_token_here" > .env

# 3. Запустить скрипт
cd deploy
python3 add-secrets-python.py
```

## 📋 Для нескольких репозиториев

Если у вас 2 репозитория, запустите скрипт **дважды**:

```bash
# Первый репозиторий
./add-github-secrets.sh
# Ввести: owner/repo1

# Второй репозиторий
./add-github-secrets.sh
# Ввести: owner/repo2
```

## ✅ Проверка

После добавления секретов:

```bash
# Через GitHub CLI
gh secret list --repo owner/repo-name

# Или через веб-интерфейс
# Репозиторий → Settings → Secrets and variables → Actions
```

## 🔑 Создание GitHub Personal Access Token (для Python скрипта)

1. GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Generate new token (classic)
3. Выбрать права: `repo` (полный доступ)
4. Скопировать токен (показывается только один раз!)

## 🐛 Troubleshooting

### GitHub CLI: "authentication required"
```bash
gh auth login
```

### Python: "PyNaCl not found"
```bash
pip install pynacl
```

### Python: "Invalid token"
- Проверить, что токен имеет права `repo`
- Проверить, что токен не истёк

### SSH ключ не найден
```bash
# Проверить наличие ключа
ls -la ~/.ssh/

# Если нет, создать:
ssh-keygen -t ed25519 -C "github-actions@server"
```

