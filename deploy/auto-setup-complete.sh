#!/bin/bash
# Полностью автоматизированная настройка: создание репозитория + секреты + первый коммит
# Использует переменные окружения или запрашивает минимальные данные

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🚀 Полная автоматическая настройка деплоя${NC}"
echo "=========================================="
echo ""

# Перейти в корень проекта
cd "$(dirname "$0")/.."
PROJECT_DIR=$(pwd)

# Проверка Python зависимостей
echo "📦 Проверка зависимостей..."
python3 -m pip install --quiet --user requests pynacl 2>/dev/null || {
    echo "Установка зависимостей..."
    python3 -m pip install --user requests pynacl
}

# Инициализация git если нужно
if [ ! -d ".git" ]; then
    echo "🔄 Инициализация git..."
    git init
    git branch -M main
    echo -e "${GREEN}✅ Git инициализирован${NC}"
fi

# Получить данные из переменных окружения или запросить
REPO_NAME=${GITHUB_REPO_NAME:-}
GITHUB_USER=${GITHUB_USER:-}
GITHUB_TOKEN=${GITHUB_TOKEN:-}
SERVER_HOST=${SERVER_HOST:-}
SERVER_USER=${SERVER_USER:-deploy}
SSH_KEY_PATH=${SSH_KEY_PATH:-~/.ssh/id_ed25519}

if [ -z "$REPO_NAME" ]; then
    read -p "Название репозитория: " REPO_NAME
fi

if [ -z "$GITHUB_USER" ]; then
    read -p "GitHub username/org: " GITHUB_USER
fi

if [ -z "$GITHUB_TOKEN" ]; then
    echo ""
    echo "🔐 GitHub Personal Access Token"
    echo "Создайте здесь: https://github.com/settings/tokens"
    echo "Права: repo (полный доступ)"
    read -sp "Введите токен: " GITHUB_TOKEN
    echo ""
fi

if [ -z "$SERVER_HOST" ]; then
    read -p "IP или домен сервера: " SERVER_HOST
fi

SSH_KEY_PATH="${SSH_KEY_PATH/#\~/$HOME}"

# Проверка SSH ключа
if [ ! -f "$SSH_KEY_PATH" ]; then
    echo -e "${YELLOW}⚠️  SSH ключ не найден: $SSH_KEY_PATH${NC}"
    read -p "Создать новый? (y/n): " CREATE_KEY
    if [ "$CREATE_KEY" = "y" ]; then
        ssh-keygen -t ed25519 -C "github-actions@server" -f "$SSH_KEY_PATH" -N ""
        echo -e "${GREEN}✅ SSH ключ создан${NC}"
        echo "Добавьте публичный ключ на сервер:"
        echo "  cat ${SSH_KEY_PATH}.pub"
    else
        exit 1
    fi
fi

FULL_REPO="${GITHUB_USER}/${REPO_NAME}"
REPO_URL="https://github.com/${FULL_REPO}.git"

echo ""
echo "📋 Будет создано:"
echo "  Репозиторий: ${FULL_REPO}"
echo "  SERVER_HOST: ${SERVER_HOST}"
echo "  SERVER_USER: ${SERVER_USER}"
echo ""

read -p "Продолжить? (y/n): " CONFIRM
if [ "$CONFIRM" != "y" ]; then
    echo "Отменено"
    exit 0
fi

# Запустить Python скрипт с параметрами
echo ""
echo "🔄 Создание репозитория и настройка..."

python3 << PYEOF
import os
import sys
import json
import base64
import subprocess
from pathlib import Path

try:
    import requests
    from nacl import encoding, public
except ImportError:
    print("❌ Установите зависимости: pip install requests pynacl")
    sys.exit(1)

# Данные
token = "${GITHUB_TOKEN}"
owner = "${GITHUB_USER}"
repo_name = "${REPO_NAME}"
server_host = "${SERVER_HOST}"
server_user = "${SERVER_USER}"
ssh_key_path = "${SSH_KEY_PATH}"
repo_url = "${REPO_URL}"
project_dir = "${PROJECT_DIR}"

# Создать репозиторий
print("🔄 Создание репозитория...")
url = f"https://api.github.com/user/repos"
headers = {
    "Authorization": f"token {token}",
    "Accept": "application/vnd.github.v3+json"
}
data = {
    "name": repo_name,
    "description": "BoofMebel API - FastAPI backend",
    "private": False
}
response = requests.post(url, headers=headers, json=data)
if response.status_code == 201:
    print("✅ Репозиторий создан")
elif response.status_code == 422:
    print("⚠️  Репозиторий уже существует")
else:
    print(f"❌ Ошибка: {response.status_code}")
    print(response.text)
    sys.exit(1)

# Получить публичный ключ
print("🔐 Получение ключа для шифрования...")
url = f"https://api.github.com/repos/{owner}/{repo_name}/actions/secrets/public-key"
response = requests.get(url, headers=headers)
if response.status_code != 200:
    print(f"❌ Ошибка получения ключа: {response.status_code}")
    sys.exit(1)
key_data = response.json()
key_id = key_data["key_id"]
public_key = key_data["key"]

# Зашифровать секреты
def encrypt_secret(pub_key, value):
    pub_key_obj = public.PublicKey(pub_key.encode("utf-8"), encoding.Base64Encoder())
    sealed_box = public.SealedBox(pub_key_obj)
    encrypted = sealed_box.encrypt(value.encode("utf-8"))
    return base64.b64encode(encrypted).decode("utf-8")

# Читать SSH ключ
ssh_key = Path(ssh_key_path).expanduser().read_text()

# Добавить секреты
secrets = {
    "SERVER_HOST": server_host,
    "SERVER_USER": server_user,
    "SERVER_SSH_KEY": ssh_key
}

print("🔐 Добавление секретов...")
for name, value in secrets.items():
    encrypted = encrypt_secret(public_key, value)
    url = f"https://api.github.com/repos/{owner}/{repo_name}/actions/secrets/{name}"
    data = {
        "encrypted_value": encrypted,
        "key_id": key_id
    }
    response = requests.put(url, headers=headers, json=data)
    if response.status_code in [201, 204]:
        print(f"✅ {name} добавлен")
    else:
        print(f"❌ Ошибка {name}: {response.status_code}")

# Настроить git
print("🔄 Настройка git...")
os.chdir(project_dir)

# Добавить remote
try:
    subprocess.run(["git", "remote", "remove", "origin"], 
                  stderr=subprocess.DEVNULL, check=False)
except:
    pass

subprocess.run(["git", "remote", "add", "origin", repo_url], check=True)
print("✅ Remote добавлен")

# Коммит и push
print("📤 Коммит и push...")
subprocess.run(["git", "add", "."], check=True)
try:
    subprocess.run(["git", "commit", "-m", "Initial commit: FastAPI backend with auth and deploy setup"], 
                  check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    print("✅ Коммит создан")
except:
    print("⚠️  Коммит пропущен (возможно, уже есть коммиты)")

try:
    subprocess.run(["git", "push", "-u", "origin", "main"], 
                  check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    print("✅ Код отправлен в репозиторий")
except:
    print("⚠️  Push пропущен (возможно, нужна настройка доступа)")

print("")
print("=" * 50)
print("✅ Готово!")
print("")
print(f"📋 Репозиторий: https://github.com/{owner}/{repo_name}")
print("📋 Секреты добавлены")
print("")
print("🚀 Автодеплой настроен!")
print("При каждом push в main будет автоматический деплой")
PYEOF

echo ""
echo -e "${GREEN}✅ Всё настроено!${NC}"
echo ""
echo "🔍 Проверить:"
echo "  Репозиторий: https://github.com/${FULL_REPO}"
echo "  Секреты: https://github.com/${FULL_REPO}/settings/secrets/actions"
echo "  Actions: https://github.com/${FULL_REPO}/actions"

