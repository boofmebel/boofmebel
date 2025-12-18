#!/bin/bash
# Скрипт для добавления GitHub Secrets через GitHub CLI
# Требует: gh CLI установлен и авторизован (gh auth login)

set -e

echo "🔐 GitHub Secrets Setup Script"
echo "================================"
echo ""

# Проверка наличия gh CLI
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) не установлен!"
    echo "Установите: https://cli.github.com/"
    exit 1
fi

# Проверка авторизации
if ! gh auth status &> /dev/null; then
    echo "❌ Не авторизован в GitHub CLI"
    echo "Выполните: gh auth login"
    exit 1
fi

# Запрос данных
echo "Введите данные для GitHub Secrets:"
echo ""

read -p "GitHub репозиторий (формат: owner/repo): " REPO
read -p "IP или домен сервера (SERVER_HOST): " SERVER_HOST
read -p "Пользователь SSH (SERVER_USER) [deploy]: " SERVER_USER
SERVER_USER=${SERVER_USER:-deploy}

echo ""
read -p "Путь к приватному SSH ключу [~/.ssh/id_ed25519]: " SSH_KEY_PATH
SSH_KEY_PATH=${SSH_KEY_PATH:-~/.ssh/id_ed25519}

# Расширение ~ до полного пути
SSH_KEY_PATH="${SSH_KEY_PATH/#\~/$HOME}"

if [ ! -f "$SSH_KEY_PATH" ]; then
    echo "❌ Файл SSH ключа не найден: $SSH_KEY_PATH"
    exit 1
fi

# Чтение SSH ключа
SSH_KEY=$(cat "$SSH_KEY_PATH")

echo ""
echo "📋 Будут добавлены секреты:"
echo "  Репозиторий: $REPO"
echo "  SERVER_HOST: $SERVER_HOST"
echo "  SERVER_USER: $SERVER_USER"
echo "  SERVER_SSH_KEY: [из файла $SSH_KEY_PATH]"
echo ""

read -p "Продолжить? (y/n): " CONFIRM
if [ "$CONFIRM" != "y" ]; then
    echo "Отменено"
    exit 0
fi

echo ""
echo "🔄 Добавление секретов..."

# Добавление секретов
gh secret set SERVER_HOST --repo "$REPO" --body "$SERVER_HOST"
echo "✅ SERVER_HOST добавлен"

gh secret set SERVER_USER --repo "$REPO" --body "$SERVER_USER"
echo "✅ SERVER_USER добавлен"

echo "$SSH_KEY" | gh secret set SERVER_SSH_KEY --repo "$REPO"
echo "✅ SERVER_SSH_KEY добавлен"

echo ""
echo "✅ Все секреты успешно добавлены!"
echo ""
echo "Проверить можно командой:"
echo "  gh secret list --repo $REPO"

